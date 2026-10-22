# Kiểm thử hình ảnh cổng bằng scene Ball/Portal/Hole thật, không thay map hay ảnh gốc.
# Hình cổng và bóng phải chạy hiệu ứng, nhưng vận tốc, số gậy và vị trí vật lý vẫn đúng.
# Mỗi tình huống tạo sân riêng trong bộ nhớ; nước/lỗ cũng dùng cơ chế thật để bắt lỗi tranh tween.
extends SceneTree

const BALL = preload("res://Objects/Ball/Ball.tscn")
const ORANGE = preload("res://Objects/Portal/PortalOrange.tscn")
const BLUE = preload("res://Objects/Portal/PortalBlue.tscn")
const HOLE = preload("res://Objects/Hole/Hole.tscn")
const COURSE_TILESET = preload("res://Assets/TileSetSummer.tres")

var passes := 0
var failures: Array[String] = []

## Đợi SceneTree sẵn sàng rồi mới thêm các sân thử và node vật lý.
func _initialize() -> void:
	_run.call_deferred()

## Giữ tên tình huống lỗi để tiến trình trả mã khác 0 nếu bất kỳ mục nào thất bại.
func _check(condition: bool, description: String) -> void:
	if condition:
		passes += 1
		print("PASS: ", description)
	else:
		failures.append(description)
		printerr("FAIL: ", description)

## Tween hình ảnh chạy theo process; thân bóng chạy theo physics, nên chờ đủ cả hai nhịp.
func _frames(count: int) -> void:
	for _index in range(count):
		await physics_frame
		await process_frame

## Chờ điều kiện với giới hạn thời gian, tránh giả định hiệu ứng bắt đầu ở một frame cố định.
func _wait_until(condition: Callable, maximum_frames: int = 120) -> bool:
	for _index in range(maximum_frames):
		if bool(condition.call()):
			return true
		await _frames(1)
	return bool(condition.call())

## Tạo cặp nối hai chiều, bóng không giảm tốc và Sprite có baseline khác mặc định.
## Parent có thể xoay/scale để xác nhận ảnh dư dùng transform nguồn trong thế giới.
func _make_pair(reverse: bool = false, transformed: bool = false) -> Dictionary:
	var stage := Node2D.new()
	if transformed:
		stage.position = Vector2(300, 200)
		stage.rotation = 0.4
		stage.scale = Vector2(1.25, 1.25)
	var orange = ORANGE.instantiate()
	var blue = BLUE.instantiate()
	orange.destination = NodePath("../PortalBlue")
	blue.destination = NodePath("../PortalOrange")
	blue.position = Vector2(100, 0)
	stage.add_child(orange)
	stage.add_child(blue)
	var ball = BALL.instantiate()
	ball.position = Vector2(120, 0) if reverse else Vector2(-20, 0)
	ball.rolling_deceleration = 0.0
	ball.can_sleep = false
	# Kéo dài cửa sổ quan sát một chút; không dùng frame index hay tốc độ render để quyết định PASS.
	ball.portal_effect_duration = 0.24
	var sprite: Sprite2D = ball.get_node("Sprite2D")
	sprite.scale = Vector2(1.2, 0.9)
	sprite.position = Vector2(0.25, -0.5)
	sprite.modulate = Color(0.9, 0.85, 1.0, 0.95)
	stage.add_child(ball)
	root.add_child(stage)
	return {"root": stage, "orange": orange, "blue": blue, "ball": ball,
		"sprite": sprite, "rest_scale": sprite.scale, "rest_position": sprite.position,
		"rest_modulate": sprite.modulate, "source": blue if reverse else orange,
		"target": orange if reverse else blue,
		"direction": stage.global_transform.x.normalized() * (-1.0 if reverse else 1.0)}

## Thả một cú đánh thật qua hàng chờ của Ball; qua cổng không được tính thêm gậy.
func _shoot(pair: Dictionary) -> void:
	pair.ball._pending_shot = pair.direction * 60.0
	pair.ball.sleeping = false

## Khoảng cách nguồn–đích lớn hơn 100 pixel; rời nguồn hơn 80 pixel nghĩa là đã teleport.
func _travelled(pair: Dictionary) -> bool:
	return pair.ball.global_position.distance_to(pair.source.global_position) > 80.0

## So sánh đủ các baseline, không mặc định mọi sprite đều scale1 hoặc màu trắng.
func _sprite_at_rest(pair: Dictionary) -> bool:
	return (pair.sprite.scale.is_equal_approx(pair.rest_scale)
		and pair.sprite.position.is_equal_approx(pair.rest_position)
		and pair.sprite.modulate.is_equal_approx(pair.rest_modulate))

## Hỏi node quản lý thay vì suy ra hiệu ứng còn chạy chỉ từ alpha tại một frame.
func _effect_is_playing(pair: Dictionary) -> bool:
	var effect: Node = pair.ball.get_node_or_null("PortalEffect")
	return effect != null and bool(effect.call("is_playing"))

## Xóa sân giữa các tình huống; ảnh dư là con của sân nên phải được dọn cùng nhau.
func _dispose(pair: Dictionary) -> void:
	pair.root.queue_free()
	await _frames(4)

## Hai chiều phải cùng có burst nguồn/đích, ảnh dư tại nguồn và bóng thật hiện dần ở đích.
func _test_direction(reverse: bool) -> void:
	var pair := _make_pair(reverse)
	var label := "blue-to-orange" if reverse else "orange-to-blue"
	_shoot(pair)
	_check(await _wait_until(func(): return _travelled(pair)), label + " actually teleports")
	_check(await _wait_until(func(): return _effect_is_playing(pair), 20), label + " starts ball arrival effect")
	_check(not _sprite_at_rest(pair), label + " changes the real ball sprite during arrival")
	var source_visual: Node = pair.source.get_node("PortalVisual")
	var target_visual: Node = pair.target.get_node("PortalVisual")
	_check(bool(source_visual.get("_travel_active")) and not bool(source_visual.get("_travel_is_arrival")), label + " source plays departure burst")
	_check(bool(target_visual.get("_travel_active")) and bool(target_visual.get("_travel_is_arrival")), label + " target plays arrival burst")
	var echoes := get_nodes_in_group("portal_ball_echoes")
	_check(not echoes.is_empty(), label + " creates source afterimage")
	if not echoes.is_empty():
		var echo := echoes[0] as Sprite2D
		_check(echo != null and echo.global_position.distance_to(pair.source.global_position) < 16.0
			and echo.global_position.distance_to(pair.target.global_position) > 70.0,
			label + " source afterimage stays at source instead of following teleported body")
		_check(echo.texture == pair.sprite.texture and echo.get_script() == null,
			label + " afterimage reuses ball art without a second physics body")
	# Scale đang grow không được làm các chấm lăn quay nhanh sai vì phép đổi tọa độ bị thu nhỏ.
	var roll: Node = pair.ball.get_node("Sprite2D/RollMarks")
	var roll_before: Quaternion = roll.get("_orientation")
	await _frames(2)
	var roll_during: Quaternion = roll.get("_orientation")
	_check(absf(roll_before.dot(roll_during)) > 0.99999, label + " growing sprite does not corrupt rolling orientation")
	_check(pair.ball.linear_velocity.is_equal_approx(pair.direction * 60.0) and pair.ball.stroke_count == 1,
		label + " visual effect preserves physical speed and stroke count")
	var exit_position: Vector2 = pair.ball.global_position
	_check(await _wait_until(func(): return not _effect_is_playing(pair)), label + " ball arrival effect finishes")
	_check(_sprite_at_rest(pair), label + " restores custom scale color and local position")
	_check(pair.ball.global_position.distance_to(exit_position) > 2.0, label + " body continues rolling while sprite animates")
	await _frames(3)
	var roll_after: Quaternion = roll.get("_orientation")
	_check(absf(roll_during.dot(roll_after)) < 0.9999, label + " normal rolling resumes after arrival effect")
	_check(await _wait_until(func(): return get_nodes_in_group("portal_ball_echoes").is_empty()), label + " source afterimage cleans itself up")
	_check(await _wait_until(func(): return not bool(source_visual.get("_travel_active")) and not bool(target_visual.get("_travel_active"))), label + " both portal bursts finish cleanly")
	await _dispose(pair)

## Tắt hiệu ứng bóng hoặc lớp cổng đều không được làm mất chức năng dịch chuyển vật lý.
func _test_toggles() -> void:
	var ball_off := _make_pair()
	ball_off.ball.portal_effects_enabled = false
	_shoot(ball_off)
	_check(await _wait_until(func(): return _travelled(ball_off)), "disabled ball effects still allow teleport")
	await _frames(2)
	_check(not _effect_is_playing(ball_off) and _sprite_at_rest(ball_off), "disabled ball effects leave sprite at its baseline")
	_check(get_nodes_in_group("portal_ball_echoes").is_empty(), "disabled ball effects create no source ghost")
	_check(ball_off.ball.linear_velocity.is_equal_approx(Vector2(60, 0)), "disabled ball effects preserve speed")
	await _dispose(ball_off)
	var visual_off := _make_pair()
	for portal in [visual_off.orange, visual_off.blue]:
		portal.get_node("PortalVisual").effects_enabled = false
	_shoot(visual_off)
	_check(await _wait_until(func(): return _travelled(visual_off)), "disabled portal visuals still allow teleport")
	_check(not bool(visual_off.orange.get_node("PortalVisual").get("_travel_active"))
		and not bool(visual_off.blue.get_node("PortalVisual").get("_travel_active")), "disabled portal visuals do not start bursts")
	_check(visual_off.ball.linear_velocity.is_equal_approx(Vector2(60, 0)) and visual_off.ball.stroke_count == 1,
		"disabled portal visuals do not change speed or strokes")
	await _dispose(visual_off)
	var ambient_off := _make_pair()
	for portal in [ambient_off.orange, ambient_off.blue]:
		portal.get_node("PortalVisual").ambient_enabled = false
	_check(not ambient_off.orange.get_node("PortalVisual").is_processing(), "disabled ambient has no idle update loop")
	_shoot(ambient_off)
	_check(await _wait_until(func(): return _travelled(ambient_off)), "ambient-only toggle preserves teleport")
	_check(bool(ambient_off.orange.get_node("PortalVisual").get("_travel_active")), "disabled ambient still allows a travel burst")
	_check(await _wait_until(func(): return not ambient_off.orange.get_node("PortalVisual").is_processing()), "ambient-off portal stops updating after burst ends")
	await _dispose(ambient_off)

## Khi parent xoay/scale, ảnh dư phải ở nguồn đúng hướng, không mang tọa độ local sang thế giới.
func _test_parent_transform() -> void:
	var pair := _make_pair(false, true)
	var original_rotation: float = pair.sprite.global_rotation
	var original_scale: Vector2 = pair.sprite.global_scale
	_shoot(pair)
	_check(await _wait_until(func(): return _travelled(pair)), "rotated scaled parent still transports the ball")
	_check(await _wait_until(func(): return not get_nodes_in_group("portal_ball_echoes").is_empty(), 20), "transformed parent creates source echo")
	var echoes := get_nodes_in_group("portal_ball_echoes")
	if not echoes.is_empty():
		var echo := echoes[0] as Sprite2D
		_check(echo.global_position.distance_to(pair.source.global_position) < 16.0
			and echo.global_position.distance_to(pair.target.global_position) > 90.0,
			"transformed echo uses source world position")
		_check(absf(angle_difference(echo.global_rotation, original_rotation)) < 0.001
			and echo.global_scale.x <= original_scale.x + 0.01 and echo.global_scale.y <= original_scale.y + 0.01,
			"transformed echo keeps source rotation and scale while shrinking")
	_check(pair.ball.linear_velocity.is_equal_approx(pair.direction * 60.0), "transformed VFX preserve world velocity")
	_check(await _wait_until(func(): return not _effect_is_playing(pair)), "transformed arrival tween finishes")
	_check(_sprite_at_rest(pair), "transformed parent restores local sprite baselines")
	await _dispose(pair)

## Nước nhận bóng giữa lúc hiện ra phải hủy tween cổng; tween cũ không được làm bóng hiện lại.
func _test_water_cancel() -> void:
	var pair := _make_pair()
	pair.ball.water_sink_duration = 0.65
	_shoot(pair)
	_check(await _wait_until(func(): return _travelled(pair) and _effect_is_playing(pair)), "water case begins during a real portal arrival effect")
	var water_map := TileMap.new()
	water_map.name = "TileMap"
	water_map.tile_set = COURSE_TILESET
	for cell_x in range(6, 9):
		for cell_y in range(-1, 2):
			water_map.set_cell(0, Vector2i(cell_x, cell_y), 0, Vector2i(7, 11))
	pair.root.add_child(water_map)
	pair.ball.surface_tile_map = water_map
	_check(await _wait_until(func(): return pair.ball.is_in_water), "actual water terrain takes over during portal animation")
	_check(not _effect_is_playing(pair), "water cancels portal arrival tween immediately")
	# Chờ qua thời điểm tween cổng cũ đáng lẽ kết thúc, nhưng vẫn ở giữa thời gian chìm.
	await create_timer(0.35).timeout
	_check(pair.ball.is_in_water and pair.sprite.scale.x < pair.rest_scale.x * 0.9
		and pair.sprite.modulate.a < pair.rest_modulate.a * 0.8,
		"expired portal tween does not restore sprite over the water sink tween")
	_check(await _wait_until(func(): return (not pair.ball.is_in_water
		and pair.ball.global_position.distance_to(Vector2(-20, 0)) < 0.01)), "water completes normal respawn after canceled portal effect")
	_check(_sprite_at_rest(pair) and pair.ball.stroke_count == 2, "water restores baseline only on respawn and counts one penalty")
	await _dispose(pair)

## Lỗ thật nhận bóng khi tween cổng đang chạy; sau đó hình bóng phải thu về 0 và giữ nguyên.
func _test_hole_cancel() -> void:
	var pair := _make_pair()
	_shoot(pair)
	_check(await _wait_until(func(): return _travelled(pair) and _effect_is_playing(pair)), "hole case begins during a real portal arrival effect")
	var hole = HOLE.instantiate()
	pair.root.add_child(hole)
	hole.global_position = pair.ball.global_position
	_check(await _wait_until(func(): return pair.ball.is_sunk), "actual hole captures ball during portal animation")
	_check(not _effect_is_playing(pair), "hole cancels portal arrival tween immediately")
	_check(await _wait_until(func(): return pair.sprite.scale.length() < 0.001), "hole sink shrinks sprite fully after portal cancellation")
	await create_timer(0.3).timeout
	_check(pair.ball.is_sunk and pair.sprite.scale.length() < 0.001 and pair.ball.stroke_count == 1,
		"old portal tween never regrows the completed ball or adds a stroke")
	await _dispose(pair)

## Xóa sân hoặc hủy yêu cầu chưa thực hiện không để ảnh dư mồ côi hoặc burst giả.
func _test_cleanup_and_abort() -> void:
	var freed := _make_pair()
	_shoot(freed)
	_check(await _wait_until(func(): return _effect_is_playing(freed)), "stage cleanup starts while arrival tween is active")
	_check(not get_nodes_in_group("portal_ball_echoes").is_empty(), "stage cleanup includes a living source echo")
	await _dispose(freed)
	_check(get_nodes_in_group("portal_ball_echoes").is_empty(), "freeing stage removes echo and its running tween")
	await _frames(20)
	_check(get_nodes_in_group("portal_ball_echoes").is_empty(), "freed stage leaves no delayed orphan echo")
	var aborted := _make_pair()
	# Đặt bóng ngay trong nguồn rồi gửi yêu cầu thật, xóa đích trước khi physics nhận yêu cầu.
	aborted.ball.global_position = aborted.orange.global_position
	aborted.orange._try_transport(aborted.ball)
	_check(aborted.ball._portal_travel_pending, "abort case queues a real portal request")
	aborted.blue.free()
	await _frames(4)
	_check(not aborted.ball._portal_travel_pending and not _effect_is_playing(aborted), "deleted destination cancels request without ball effect")
	_check(not bool(aborted.orange.get_node("PortalVisual").get("_travel_active"))
		and get_nodes_in_group("portal_ball_echoes").is_empty(), "aborted teleport creates neither portal burst nor source ghost")
	await _dispose(aborted)

## Chạy các nhóm riêng để lỗi VFX không bị che bởi các kiểm thử cơ chế cổng đã có.
func _run() -> void:
	await _test_direction(false)
	await _test_direction(true)
	await _test_toggles()
	await _test_parent_transform()
	await _test_water_cancel()
	await _test_hole_cancel()
	await _test_cleanup_and_abort()
	print("PORTAL_EFFECTS_RESULT passes=", passes, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
