# Kiểm tra hồi quy vật lý cho vật cản xoay, vật cản di chuyển và cổng vàng hiện/ẩn.
# Chạy bằng Godot --headless --script; mã thoát 0 khi mọi kiểm tra đạt, 1 khi có lỗi.
# Mọi sân và bóng thử chỉ được tạo trong bộ nhớ, không ghi thay đổi vào map của người chơi.
extends SceneTree

# Nạp đúng các scene được dùng trên map để kiểm tra cả sprite, hình va chạm lẫn script.
const BAR = preload("res://Objects/Obstacles/RotatingBar.tscn")
const LONG_BAR = preload("res://Objects/Obstacles/RotatingLongBar.tscn")
const DIAMOND = preload("res://Objects/Obstacles/RotatingDiamond.tscn")
const MOVING = preload("res://Objects/Obstacles/MovingObstacle.tscn")
const GATE = preload("res://Objects/Obstacles/BlinkingGate.tscn")
const GATE_LOGIC = preload("res://Objects/Obstacles/blinking_gate.gd")
# Đếm kết quả; nhãn PASS/FAIL được giữ ổn định để tiện đọc log và dùng trong kiểm tra tự động.
var passed := 0
var failed := 0

## Chờ SceneTree khởi tạo xong rồi mới thêm sân và chạy các hàm có await.
func _initialize() -> void:
	call_deferred("_run")

## Ghi kết quả từng điều kiện, nhưng vẫn tiếp tục để thu được toàn bộ lỗi trong một lượt.
func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)
## Đợi số bước vật lý thật; không giả lập chuyển động bằng cách gọi thẳng hàm của vật cản.
func _ticks(count: int) -> void:
	for _i in range(count):
		await physics_frame
## Tạo một sân trống, độc lập để collider từ ca thử trước không ảnh hưởng ca thử sau.
func _course() -> Node2D:
	var course := Node2D.new()
	root.add_child(course)
	return course
## Tạo bóng thử bán kính 3, không trọng lực/damping, có độ nảy giống bóng của game.
## Không dùng script cú đánh để kết quả đo tập trung vào va chạm và chuyển động của vật cản.
func _ball(parent: Node, at: Vector2, velocity: Vector2 = Vector2.ZERO) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.position = at
	ball.gravity_scale = 0
	ball.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	ball.linear_damp = 0
	ball.lock_rotation = true
	ball.can_sleep = false
	ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var material := PhysicsMaterial.new()
	material.friction = 0
	material.bounce = 0.75
	ball.physics_material_override = material
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3
	collider.shape = circle
	ball.add_child(collider)
	ball.linear_velocity = velocity
	parent.add_child(ball)
	return ball
## Xóa sân sau mỗi ca và đợi Godot dọn các thân vật lý trước khi bắt đầu ca tiếp theo.
func _dispose(course: Node) -> void:
	course.queue_free()
	await _ticks(2)

## Đợi pha mong muốn trong giới hạn rõ ràng, tránh test bị treo nếu chu kỳ cửa lỗi.
func _until_phase(gate, target: int, maximum_frames: int = 180) -> bool:
	for _i in range(maximum_frames):
		await physics_frame
		if gate.phase == target:
			return true
	return false

## Trong lúc chuyển tiếp, hình có thể còn thấy nhưng collider phải tắt hoàn toàn.
## Chỉ pha SOLID được chặn bóng, sau khi alpha và scale đã phục hồi đầy đủ.
func _gate_safe(gate) -> bool:
	var sprite: Sprite2D = gate.get_node("Sprite2D")
	var collider: CollisionShape2D = gate.get_node("CollisionShape2D")
	if not collider.disabled:
		return gate.is_solid and sprite.visible and sprite.modulate.a >= 0.999 \
			and sprite.scale.is_equal_approx(Vector2.ONE)
	if gate.is_solid:
		return false
	if gate.is_hidden:
		return not sprite.visible and sprite.modulate.a <= 0.001
	return true

## Chạy các nhóm kiểm tra theo thứ tự; mọi chuyển động đều qua bộ giải vật lý của Godot.
func _run() -> void:
	Engine.physics_ticks_per_second = 60
	# Nhóm xoay: đo góc sau nửa giây, đối chiếu phần ảnh đặc với collider và thử dừng quay.
	var course := _course()
	var bar = BAR.instantiate()
	course.add_child(bar)
	await _ticks(31)
	_check(absf(rad_to_deg(bar.rotation) - 45) < 3, "rotating bar advances 90 degrees/second clockwise")
	_check(bar.get_node("CollisionShape2D").shape.size == Vector2(24, 8) and bar.get_node("Sprite2D").region_rect == Rect2(192, 0, 32, 16), "bar collider matches 24x8 visible pixels")
	bar.enabled = false
	await _ticks(2)
	var stopped_angle: float = bar.rotation
	await _ticks(8)
	_check(absf(bar.rotation - stopped_angle) < 0.001, "disabled rotator holds angle and keeps collider")
	await _dispose(course)
	# Hình thoi dùng cùng script nhưng đổi chiều quay và dùng polygon thay vì hình chữ nhật.
	course = _course()
	var diamond = DIAMOND.instantiate()
	diamond.clockwise = false
	diamond.angular_speed_degrees = 180
	course.add_child(diamond)
	await _ticks(31)
	_check(absf(rad_to_deg(diamond.rotation) + 90) < 5, "diamond supports counterclockwise rotation")
	_check(diamond.get_node("CollisionPolygon2D").polygon.size() == 4, "diamond uses actual diamond collision polygon")
	await _dispose(course)
	# Đặt bóng đang đứng yên sát đường quét: thanh dài phải đẩy bóng bằng collider thật.
	course = _course()
	var long_bar = LONG_BAR.instantiate()
	course.add_child(long_bar)
	var pushed := _ball(course, Vector2(12, 10))
	await _ticks(35)
	_check(pushed.position.distance_to(Vector2(12, 10)) > 2 and pushed.linear_velocity.length() > 1, "rotating collider physically pushes stationary ball")
	_check(long_bar.get_node("CollisionShape2D").shape.size == Vector2(40, 8), "long bar collider matches 40x8 visible pixels")
	await _dispose(course)

	# Nhóm di chuyển: đi hết 48 pixel, giữ EndPoint đứng yên, tạm dừng rồi quay về.
	# Bóng trên đường chạy phải nhận chuyển động; tắt Enabled phải giữ đúng vị trí hiện tại.
	course = _course()
	var moving = MOVING.instantiate()
	moving.travel_duration = 0.5
	moving.pause_duration = 0.2
	course.add_child(moving)
	var marker_position: Vector2 = moving.get_node("EndPoint").global_position
	var moving_ball := _ball(course, Vector2(20, 0))
	await _ticks(31)
	_check(moving.get_node("Body").position.distance_to(Vector2(48, 0)) < 0.1, "moving body reaches EndPoint in configured duration")
	_check(moving.get_node("EndPoint").global_position == marker_position, "endpoint marker stays fixed while body moves")
	await _ticks(6)
	_check(moving.get_node("Body").position.distance_to(Vector2(48, 0)) < 0.1, "moving body pauses at endpoint")
	await _ticks(25)
	_check(moving.get_node("Body").position.x < 40, "moving body reverses toward start after pause")
	_check(moving_ball.position.x > 30 and moving_ball.linear_velocity.x > 1, "moving collider physically pushes ball along path")
	moving.enabled = false
	await _ticks(2)
	var stopped_position: Vector2 = moving.get_node("Body").position
	await _ticks(8)
	_check(moving.get_node("Body").position == stopped_position, "disabled moving obstacle holds current position")
	await _dispose(course)
	# Xoay và dịch node gốc để chắc chắn đường chạy và marker dùng đúng tọa độ local.
	course = _course()
	moving = MOVING.instantiate()
	moving.position = Vector2(100, 100)
	moving.rotation = PI / 2
	moving.travel_duration = 0.5
	course.add_child(moving)
	await _ticks(16)
	_check(moving.get_node("Body").global_position.distance_to(Vector2(100, 124)) < 2.1 and moving.get_node("EndPoint").global_position.distance_to(Vector2(100, 148)) < 0.01, "moving path follows scene translation and rotation")
	await _dispose(course)

	# Nhóm cổng vàng: đợi hình hiện đủ, sau đó bóng phải va chạm và bật lại trước thanh.
	course = _course()
	var gate = GATE.instantiate()
	gate.visible_duration = 5
	gate.hidden_duration = 5
	course.add_child(gate)
	_check(await _until_phase(gate, GATE_LOGIC.GatePhase.SOLID), "gate finishes fade-in before becoming solid")
	_check(gate.is_solid and not gate.is_hidden and _gate_safe(gate), "solid gate is fully opaque with full-size collider")
	var blocked := _ball(course, Vector2(0, -16), Vector2(0, 60))
	await _ticks(22)
	_check(blocked.position.y < -5.5 and blocked.linear_velocity.y < 0, "visible gate blocks and bounces ball")
	await _dispose(course)
	# Trong pha ẩn dài, cùng đường bay đó phải đi xuyên hoàn toàn, không bị collider vô hình chặn.
	course = _course()
	gate = GATE.instantiate()
	gate.start_hidden = true
	gate.hidden_duration = 5
	course.add_child(gate)
	var through := _ball(course, Vector2(0, -16), Vector2(0, 60))
	await _ticks(31)
	_check(gate.is_hidden and not gate.is_solid and _gate_safe(gate), "fully hidden gate disables sprite and collision")
	_check(through.position.y > 10 and absf(through.linear_velocity.y - 60) < 0.01, "hidden gate lets ball pass without invisible blocking")
	await _dispose(course)
	# Hết thời gian ẩn mà bóng còn ở giữa thanh: cổng phải tiếp tục mở, không kẹp/đẩy bóng.
	course = _course()
	gate = GATE.instantiate()
	gate.start_hidden = true
	gate.hidden_duration = 0.1
	gate.visible_duration = 0.1
	course.add_child(gate)
	var inside := _ball(course, Vector2.ZERO)
	await _ticks(20)
	_check(gate.is_hidden and gate.get_node("CollisionShape2D").disabled and inside.position.length() < 0.01, "gate waits open instead of closing inside stationary ball")
	# Chuyển bóng ra xa rồi đợi truy vấn vật lý cập nhật; cổng lúc này phải đóng lại được.
	inside.position = Vector2(40, 0)
	_check(await _until_phase(gate, GATE_LOGIC.GatePhase.SOLID, 60), "gate safely fades in and closes after ball clears its area")
	await _dispose(course)
	# Theo dõi nhiều chu kỳ: hai chiều phải có alpha trung gian và co nhẹ, không bật tắt đột ngột.
	course = _course()
	gate = GATE.instantiate()
	gate.visible_duration = 0.1
	gate.hidden_duration = 0.1
	course.add_child(gate)
	await _ticks(3)
	var transitions := 0
	var old_hidden: bool = gate.is_hidden
	var safe := true
	var seen_fade_in := false
	var seen_fade_out := false
	var seen_squeeze := false
	var seen_warning := false
	for _i in range(150):
		await _ticks(1)
		if gate.is_hidden != old_hidden:
			transitions += 1
			old_hidden = gate.is_hidden
		var alpha: float = gate.get_node("Sprite2D").modulate.a
		if alpha > 0.05 and alpha < 0.95:
			seen_fade_in = seen_fade_in or gate.phase == GATE_LOGIC.GatePhase.FADING_IN
			seen_fade_out = seen_fade_out or gate.phase == GATE_LOGIC.GatePhase.FADING_OUT
			seen_squeeze = seen_squeeze or gate.get_node("Sprite2D").scale.y < 0.95
		seen_warning = seen_warning or (gate.is_solid and gate.get_node("Sprite2D/Glow").visible)
		safe = safe and _gate_safe(gate) and gate.is_hidden == (gate.phase == GATE_LOGIC.GatePhase.HIDDEN)
	_check(transitions >= 4 and safe, "gate repeats fade cycles without any invisible or translucent blocking frame")
	_check(seen_fade_in and seen_fade_out and seen_squeeze, "both transitions visibly fade and squeeze the sprite")
	_check(seen_warning, "solid gate gives visible glow warning before disappearing")
	await _dispose(course)

	# Khi vừa bắt đầu mờ ra, collider phải tắt trước khi alpha giảm; bóng vẫn xuyên được.
	course = _course()
	gate = GATE.instantiate()
	gate.visible_duration = 0.1
	gate.hidden_duration = 5
	gate.fade_duration = 0.3
	course.add_child(gate)
	_check(await _until_phase(gate, GATE_LOGIC.GatePhase.FADING_OUT), "visible hold expires into fade-out")
	_check(gate.get_node("CollisionShape2D").disabled and not gate.is_solid, "fade-out disables collider before changing opacity")
	var fading_through := _ball(course, Vector2(0, -10), Vector2(0, 60))
	var outgoing_safe := true
	for _i in range(20):
		await _ticks(1)
		outgoing_safe = outgoing_safe and _gate_safe(gate)
	_check(outgoing_safe and fading_through.position.y > 7 and absf(fading_through.linear_velocity.y - 60) < 0.01, "ball passes through fading gate without invisible bounce")
	await _dispose(course)

	# Bóng vào trong lúc cửa đang hiện: phải đảo mờ ra, không được đóng kẹp bóng.
	course = _course()
	gate = GATE.instantiate()
	gate.fade_duration = 0.3
	gate.hidden_duration = 0.1
	course.add_child(gate)
	for _i in range(30):
		await _ticks(1)
		var alpha: float = gate.get_node("Sprite2D").modulate.a
		if gate.phase == GATE_LOGIC.GatePhase.FADING_IN and alpha > 0.2 and alpha < 0.8:
			break
	var incoming := _ball(course, Vector2.ZERO, Vector2(0, 60))
	var reopened := false
	var no_trap := true
	for _i in range(28):
		await _ticks(1)
		reopened = reopened or gate.phase == GATE_LOGIC.GatePhase.FADING_OUT
		no_trap = no_trap and _gate_safe(gate) and absf(incoming.linear_velocity.y - 60) < 0.01
		if absf(incoming.position.y) < 7:
			no_trap = no_trap and not gate.is_solid
	_check(reopened and no_trap and incoming.position.y > 20, "entering during fade-in reverses fade and never traps the ball")
	_check(await _until_phase(gate, GATE_LOGIC.GatePhase.SOLID), "interrupted gate can close normally once ball leaves")
	await _dispose(course)

	# Start Delay kéo dài pha ổn định đầu tiên, không rút ngắn hay bỏ qua hiệu ứng.
	course = _course()
	gate = GATE.instantiate()
	gate.start_hidden = true
	gate.hidden_duration = 0.1
	gate.start_delay = 0.2
	course.add_child(gate)
	await _ticks(12)
	_check(gate.is_hidden and _gate_safe(gate), "start-hidden delay keeps gate completely open before first fade")
	_check(await _until_phase(gate, GATE_LOGIC.GatePhase.SOLID), "start-hidden delay eventually allows full fade-in")
	await _dispose(course)
	course = _course()
	gate = GATE.instantiate()
	gate.visible_duration = 0.1
	gate.start_delay = 0.2
	course.add_child(gate)
	await _until_phase(gate, GATE_LOGIC.GatePhase.SOLID)
	await _ticks(12)
	_check(gate.is_solid and _gate_safe(gate), "start-visible delay extends first fully visible hold")
	await _dispose(course)
	# Kết quả cuối và mã thoát dành cho người chạy test hoặc công cụ tự động.
	print("OBSTACLES_RESULT passed=", passed, " failed=", failed)
	quit(0 if failed == 0 else 1)
