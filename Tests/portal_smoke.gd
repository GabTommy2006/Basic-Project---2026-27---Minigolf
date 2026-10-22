# Harness chạy bằng Godot --headless --script, dùng Ball và hai scene cổng thật.
# Mọi sân thử được tạo trong bộ nhớ rồi xóa; không sửa map hoặc tài nguyên của người dùng.
extends SceneTree

const BALL = preload("res://Objects/Ball/Ball.tscn")
const ORANGE = preload("res://Objects/Portal/PortalOrange.tscn")
const BLUE = preload("res://Objects/Portal/PortalBlue.tscn")
const PORTAL_PAIR = preload("res://Objects/Portal/PortalPair.tscn")
const COURSE_TILESET = preload("res://Assets/TileSetSummer.tres")

var passes := 0
var failures: Array[String] = []

## Chờ SceneTree sẵn sàng trước khi tạo các node kiểm tra.
func _initialize() -> void:
	call_deferred("_run")

## Ghi từng kết quả và giữ lỗi để tiến trình trả exit code khác 0 nếu có mục thất bại.
func _check(condition: bool, text: String) -> void:
	if condition:
		passes += 1
		print("PASS: ", text)
	else:
		failures.append(text)
		printerr("FAIL: ", text)

## Đợi các bước vật lý thật, thay vì gọi tay hàm tích phân của RigidBody2D.
func _ticks(count: int) -> void:
	for _index in range(count):
		await physics_frame

## Tạo hai cổng nối đích rõ ràng và bóng không giảm tốc để đo chính xác vận tốc qua cổng.
func _make_pair(position: Vector2 = Vector2(-20, 0), redirect: bool = false) -> Dictionary:
	var stage := Node2D.new()
	var orange = ORANGE.instantiate()
	var blue = BLUE.instantiate()
	orange.destination = NodePath("../PortalBlue")
	blue.destination = NodePath("../PortalOrange")
	orange.redirect_exit_direction = redirect
	blue.position = Vector2(100, 0)
	if redirect:
		blue.rotation = PI * 0.5
	stage.add_child(orange)
	stage.add_child(blue)
	var ball = BALL.instantiate()
	ball.position = position
	ball.rolling_deceleration = 0.0
	ball.can_sleep = false
	stage.add_child(ball)
	root.add_child(stage)
	return {"root": stage, "orange": orange, "blue": blue, "ball": ball}

## Đợi thêm vài bước cho Area2D và các node bị queue_free dọn dữ liệu tiếp xúc.
func _dispose(pair: Dictionary) -> void:
	pair.root.queue_free()
	await _ticks(3)

## Giới hạn thời gian chờ; x > 80 là đã rời nguồn x = 0 tới vùng cổng đích x >= 100.
func _wait_travel(ball) -> bool:
	for _index in range(90):
		await _ticks(1)
		if ball.global_position.x > 80.0:
			return true
	return false

## Chiều ngược lại: bóng bắt đầu bên phải cổng xanh, cần thực sự tới bên trái cổng cam.
func _wait_reverse_travel(ball) -> bool:
	for _index in range(120):
		await _ticks(1)
		if ball.global_position.x < 0.0:
			return true
	return false

func _run() -> void:
	# Nhóm 1: liên kết, ảnh atlas và vật lý đi xuyên; qua cổng giữ vận tốc/gậy/điểm trước cú đánh.
	var normal := _make_pair()
	var normal_ball = normal.ball
	_check(normal.orange._get_destination() == normal.blue, "explicit destination resolves target portal")
	_check(normal.orange.collision_layer == 0 and normal.blue.collision_layer == 0, "portal is a nonblocking Area2D")
	_check(normal.orange.get_node("Sprite2D").texture.region == Rect2(224, 48, 16, 16), "orange atlas region is correct")
	_check(normal.blue.get_node("Sprite2D").texture.region == Rect2(240, 48, 16, 16), "blue atlas region is correct")
	normal_ball._pending_shot = Vector2(60, 0)
	normal_ball.sleeping = false
	_check(await _wait_travel(normal_ball), "moving ball travels from orange to explicit blue")
	_check(normal_ball.global_position.x >= 112.0 and absf(normal_ball.global_position.y) < 0.01, "exit lies beyond blue trigger circle")
	_check(normal_ball.linear_velocity.is_equal_approx(Vector2(60, 0)), "default travel preserves incoming direction and speed")
	_check(normal_ball.stroke_count == 1, "portal does not count another stroke")
	_check(normal_ball._shot_start_position.is_equal_approx(Vector2(-20, 0)), "portal preserves original shot return point")
	_check(normal.blue._is_ball_blocked(normal_ball), "destination is blocked before/after physics travel")
	await _ticks(20)
	_check(normal_ball.global_position.x > 112.0, "paired portals do not ping-pong the ball")
	_check(not normal.blue._is_ball_blocked(normal_ball), "outside exit releases block even without body_exited")
	await _dispose(normal)

	# Nhóm 2: tùy chọn đổi hướng theo cổng đích xoay 90 độ vẫn giữ nguyên độ lớn vận tốc.
	var redirected := _make_pair(Vector2(-20, 0), true)
	redirected.ball._pending_shot = Vector2(60, 0)
	redirected.ball.sleeping = false
	_check(await _wait_travel(redirected.ball), "redirecting portal travel completes")
	_check(redirected.ball.linear_velocity.is_equal_approx(Vector2(0, 60)), "optional redirect follows rotated destination X axis with same speed")
	_check(absf(redirected.ball.global_position.x - 100.0) < 0.01 and redirected.ball.global_position.y >= 12.0, "redirected exit uses matching safe outward direction")
	await _dispose(redirected)

	# Nhóm 3: mép bóng chỉ chạm Area chưa đủ; ngược lại bóng khởi tạo ngay trong cổng vẫn đi được.
	var edge := _make_pair(Vector2(-8, 0))
	await _ticks(8)
	_check(edge.ball.global_position.is_equal_approx(Vector2(-8, 0)), "touching outer edge alone does not trigger before center enters")
	await _dispose(edge)

	var stationary := _make_pair(Vector2.ZERO)
	stationary.orange.exit_distance = 0.0
	_check(await _wait_travel(stationary.ball), "ball initially inside portal can travel while stationary")
	_check(stationary.ball.linear_velocity == Vector2.ZERO, "stationary travel does not boost the ball")
	_check(stationary.ball.global_position.x >= 110.0, "small exit_distance is clamped beyond both radii")
	await _ticks(20)
	_check(stationary.ball.global_position.x >= 110.0 and stationary.ball.global_position.x < 120.0, "stationary ball stays at safe exit without a return loop")
	await _dispose(stationary)

	# Nhóm 4: khóa chỉ hết sau cả thời gian tối thiểu lẫn việc rời vòng nhận; xóa bóng không để rác.
	var locked := _make_pair(Vector2(100, 0))
	locked.blue.block_ball_until_exit(locked.ball)
	await _ticks(20)
	_check(locked.blue._is_ball_blocked(locked.ball), "block remains after cooldown while ball still overlaps portal")
	_check(locked.ball.global_position.is_equal_approx(Vector2(100, 0)), "blocked destination cannot instantly send ball back")
	var accepted: bool = locked.ball.queue_portal_travel(Vector2(130, 0), Vector2.ZERO, locked.orange, locked.blue)
	_check(accepted, "ball accepts later queued physics relocation out of blocked area")
	await _ticks(4)
	_check(not locked.blue._is_ball_blocked(locked.ball), "block clears once ball has actually left and guard elapsed")
	locked.blue.block_ball_until_exit(locked.ball)
	locked.ball.queue_free()
	await _ticks(4)
	_check(locked.blue._blocked_balls.is_empty(), "weak-reference lock is cleaned when ball is deleted")
	await _dispose(locked)

	# Nhóm 5: xóa đích giữa lúc xếp hàng và bước vật lý phải trả khóa cho nguồn còn sống.
	# Gọi cổng thật để tạo đủ hai khóa, rồi xóa ngay đích trước khi engine tích phân bóng.
	var deleted_target := _make_pair(Vector2.ZERO)
	deleted_target.orange._try_transport(deleted_target.ball)
	_check(deleted_target.ball._portal_travel_pending, "real portal queues request before the physics step")
	_check(deleted_target.orange._is_ball_blocked(deleted_target.ball), "source lock is present while queued request waits")
	deleted_target.blue.free()
	await _ticks(3)
	_check(not deleted_target.ball._portal_travel_pending, "deleted destination aborts pending travel")
	_check(deleted_target.ball.global_position == Vector2.ZERO and deleted_target.ball.linear_velocity == Vector2.ZERO, "aborted travel leaves ball at source unchanged")
	_check(not deleted_target.orange._is_ball_blocked(deleted_target.ball), "aborted travel unlocks surviving source portal")
	_check(deleted_target.orange.overlaps_body(deleted_target.ball), "aborted ball is still inside source without leaving its area")
	_check(deleted_target.ball._portal_source == null and deleted_target.ball._portal_destination == null, "aborted request clears both weak portal references")
	# Gắn một đích mới cùng tên: bóng vẫn đứng trong nguồn phải dùng được ngay, không cần đi ra vào lại.
	var replacement_blue = BLUE.instantiate()
	replacement_blue.name = "PortalBlue"
	replacement_blue.position = Vector2(160, 0)
	replacement_blue.destination = NodePath("../PortalOrange")
	deleted_target.root.add_child(replacement_blue)
	deleted_target["blue"] = replacement_blue
	_check(await _wait_travel(deleted_target.ball), "replacement destination works without leaving and reentering source")
	_check(deleted_target.ball.global_position.x >= 172.0 and deleted_target.ball.stroke_count == 0, "replacement travel uses new safe exit without extra strokes")
	await _dispose(deleted_target)

	# Nhóm 6: chưa nối đích, tự nối chính mình hoặc trỏ nhầm node đều bỏ qua an toàn.
	var disconnected := _make_pair(Vector2.ZERO)
	disconnected.orange.destination = NodePath("")
	await _ticks(5)
	_check(disconnected.ball.global_position == Vector2.ZERO, "disconnected portal safely ignores entry")
	_check(not disconnected.orange._get_configuration_warnings().is_empty(), "disconnected portal exposes editor configuration warning")
	disconnected.orange.destination = NodePath(".")
	_check(disconnected.orange._get_destination() == null, "self-target is rejected")
	disconnected.orange.destination = NodePath("../Ball")
	_check(disconnected.orange._get_destination() == null, "nonportal target is rejected")
	await _dispose(disconnected)

	# Nhóm 7: bóng đã vào lỗ/đang chìm từ chối yêu cầu, và cổng phải hoàn lại khóa vừa đặt ở đích.
	var sunk := _make_pair(Vector2.ZERO)
	sunk.ball.is_sunk = true
	await _ticks(5)
	_check(sunk.ball.global_position == Vector2.ZERO, "sunk ball cannot enter portal")
	_check(not sunk.blue._is_ball_blocked(sunk.ball), "rejected queue rolls back destination lock")
	await _dispose(sunk)
	var water := _make_pair(Vector2.ZERO)
	water.ball.is_in_water = true
	await _ticks(5)
	_check(water.ball.global_position == Vector2.ZERO, "ball running water effect cannot enter portal")
	_check(not water.blue._is_ball_blocked(water.ball), "water rejection also rolls back destination lock")
	await _dispose(water)

	# Nhóm 8: khoảng giữa hai cổng có mũi tên; dịch chuyển không được coi là đường lăn qua nó.
	# Đồng thời mốc hình lăn phải về đầu ra, không xoay mặt bóng theo đoạn nhảy hơn 100 pixel.
	var arrow_jump := _make_pair()
	var arrow_map := TileMap.new()
	arrow_map.name = "TileMap"
	arrow_map.tile_set = COURSE_TILESET
	arrow_map.set_cell(0, Vector2i(3, 0), 0, Vector2i(9, 5))
	arrow_jump.root.add_child(arrow_map)
	arrow_jump.ball.surface_tile_map = arrow_map
	arrow_jump.ball._pending_shot = Vector2(60, 0)
	arrow_jump.ball.sleeping = false
	_check(await _wait_travel(arrow_jump.ball), "portal jump crosses intervening arrow without physically visiting it")
	var roll_marks = arrow_jump.ball.get_node("Sprite2D/RollMarks")
	_check(roll_marks._previous_position.distance_to(arrow_jump.ball.global_position) < 2.0, "rolling visual sample resets at portal exit instead of including teleport distance")
	await _ticks(4)
	_check(arrow_jump.ball.linear_velocity.is_equal_approx(Vector2(60, 0)) and absf(arrow_jump.ball.global_position.y) < 0.01, "post-portal sweep does not apply distant arrow direction")
	await _dispose(arrow_jump)

	# Nhóm 9: điểm ra nằm trong nước thật phải chìm đúng một lần, rồi về trước cú đánh gốc.
	# Nước phủ 3x3 ô quanh đầu ra để đủ độ sâu 5 pixel, không giả lập cờ is_in_water.
	var exit_water := _make_pair()
	var water_map := TileMap.new()
	water_map.name = "TileMap"
	water_map.tile_set = COURSE_TILESET
	for cell_x in range(6, 9):
		for cell_y in range(-1, 2):
			water_map.set_cell(0, Vector2i(cell_x, cell_y), 0, Vector2i(7, 11))
	exit_water.root.add_child(water_map)
	exit_water.ball.surface_tile_map = water_map
	exit_water.ball.water_sink_duration = 0.1
	exit_water.ball._pending_shot = Vector2(60, 0)
	exit_water.ball.sleeping = false
	_check(await _wait_travel(exit_water.ball), "portal can exit into actual labeled water terrain")
	var saw_water_effect := false
	for _index in range(60):
		await _ticks(1)
		saw_water_effect = saw_water_effect or exit_water.ball.is_in_water
		if saw_water_effect and not exit_water.ball.is_in_water and exit_water.ball.global_position.distance_to(Vector2(-20, 0)) < 0.01:
			break
	_check(saw_water_effect, "water at portal exit starts the real sinking effect")
	_check(exit_water.ball.global_position.is_equal_approx(Vector2(-20, 0)) and exit_water.ball.linear_velocity == Vector2.ZERO, "portal-to-water respawn returns to original shot origin and stops")
	_check(exit_water.ball.stroke_count == 2, "portal-to-water route adds exactly one water penalty after one shot")
	await _ticks(20)
	_check(exit_water.ball.stroke_count == 2 and not exit_water.ball.is_in_water and exit_water.ball.global_position.is_equal_approx(Vector2(-20, 0)), "portal-to-water respawn has no repeat penalty or teleport ping-pong")
	await _dispose(exit_water)

	# Nhóm 10: thử riêng chiều xanh -> cam với giảm tốc cỏ thật, không chỉ thử chiều cam -> xanh.
	var reverse := _make_pair(Vector2(120, 0))
	reverse.ball.rolling_deceleration = 40.0
	reverse.ball.can_sleep = true
	reverse.ball._pending_shot = Vector2(-60, 0)
	reverse.ball.sleeping = false
	_check(await _wait_reverse_travel(reverse.ball), "blue-to-orange travel works with normal grass deceleration")
	_check(reverse.ball.linear_velocity.x < -40.0 and reverse.ball.linear_velocity.length() < 60.0 and absf(reverse.ball.linear_velocity.y) < 0.01, "reverse portal keeps incoming left direction and naturally reduced speed")
	_check(reverse.ball.stroke_count == 1 and reverse.ball._shot_start_position.is_equal_approx(Vector2(120, 0)), "reverse travel preserves stroke count and blue-side shot origin")
	await _dispose(reverse)

	# Nhóm 11: đi cam -> xanh, dừng trên cỏ, đặt ngủ rồi đánh ngược vào xanh để quay lại cam.
	# Lượt quay lại phải dùng được cả sau khóa Area2D lẫn cooldown của Ball đã hết.
	var round_trip := _make_pair()
	round_trip.ball.rolling_deceleration = 40.0
	round_trip.ball.can_sleep = true
	round_trip.ball._pending_shot = Vector2(60, 0)
	round_trip.ball.sleeping = false
	_check(await _wait_travel(round_trip.ball), "round-trip first orange-to-blue passage completes")
	await _ticks(150)
	_check(round_trip.ball.linear_velocity == Vector2.ZERO, "ball naturally decelerates to rest after first passage")
	_check(not round_trip.orange._is_ball_blocked(round_trip.ball) and not round_trip.blue._is_ball_blocked(round_trip.ball), "both portal locks release before the return shot")
	# Script tích phân có thể giữ thân thức khi gán vận tốc mỗi bước; tạo trạng thái ngủ rõ ràng
	# để kiểm tra thao tác đánh thức, thay vì phụ thuộc cơ chế tự ngủ của phiên bản engine.
	round_trip.ball.sleeping = true
	await _ticks(3)
	_check(round_trip.ball.sleeping, "resting ball is asleep before return-shot wake-up regression")
	round_trip.ball._pending_shot = Vector2(-60, 0)
	round_trip.ball.sleeping = false
	_check(await _wait_reverse_travel(round_trip.ball), "after prior travel and sleeping the blue portal sends ball back to orange")
	_check(round_trip.ball.linear_velocity.x < 0.0 and absf(round_trip.ball.linear_velocity.y) < 0.01, "return passage retains leftward movement instead of bouncing to blue")
	_check(round_trip.ball.stroke_count == 2, "round trip counts only the two real shots")
	await _ticks(20)
	_check(round_trip.ball.global_position.x < 0.0 and round_trip.ball.stroke_count == 2, "return exit has no automatic portal ping-pong")
	await _dispose(round_trip)

	# Nhóm 12: scene cặp cổng kéo-thả đã nối hai chiều, không gán Destination trong bài kiểm tra.
	# Dịch cả cặp đi 30 pixel cũng không làm hỏng các NodePath tương đối ở bên trong.
	var ready_stage := Node2D.new()
	var ready_pair = PORTAL_PAIR.instantiate()
	ready_pair.position = Vector2(30, 0)
	ready_stage.add_child(ready_pair)
	var ready_ball = BALL.instantiate()
	ready_ball.position = Vector2(10, 0)
	ready_stage.add_child(ready_ball)
	root.add_child(ready_stage)
	var ready_orange = ready_pair.get_node("PortalOrange")
	var ready_blue = ready_pair.get_node("PortalBlue")
	_check(ready_orange._get_destination() == ready_blue and ready_blue._get_destination() == ready_orange, "PortalPair prefab is already wired in both directions without setup")
	_check(ready_orange.position == Vector2.ZERO and ready_blue.position == Vector2(80, 0), "PortalPair prefab keeps orange origin and blue 80px spacing")
	_check(ready_orange._get_configuration_warnings().is_empty() and ready_blue._get_configuration_warnings().is_empty(), "prewired PortalPair has no missing destination warnings")
	ready_ball._pending_shot = Vector2(60, 0)
	ready_ball.sleeping = false
	_check(await _wait_travel(ready_ball), "one-drag PortalPair actually transports a ball without manual node links")
	_check(ready_ball.global_position.x >= 122.0 and ready_ball.linear_velocity.x > 0.0 and ready_ball.stroke_count == 1, "translated PortalPair exits at its own blue portal with normal shot count")
	await _dispose({"root": ready_stage})
	print("PORTAL_SMOKE_RESULT passes=", passes, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
