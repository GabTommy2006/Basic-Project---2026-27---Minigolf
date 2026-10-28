# Kiểm thử bumper bằng chính scene bóng và các hình vật cản đang dùng trong game.
# Phần đầu kiểm tra hướng/lực bật và hình va chạm; phần sau chạy va chạm vật lý thật.
# Script chỉ tạo một sân tạm trong bộ nhớ, không đổi map, TileSet hay thông số đã lưu.
extends SceneTree

# Tái sử dụng scene thực để phát hiện cả lỗi cấu hình node, không chỉ kiểm tra công thức.
const ROUND = preload("res://Objects/Bumpers/RoundBumper.tscn")
const TRIANGLE = preload("res://Objects/Bumpers/TriangleBumper.tscn")
const BALL = preload("res://Objects/Ball/Ball.tscn")

var passed := 0
var failed := 0

## Chờ SceneTree sẵn sàng rồi mới thêm các node kiểm thử.
func _initialize() -> void:
	_run.call_deferred()

## Ghi kết quả từng tình huống; kết thúc với exit code khác 0 nếu có lỗi.
func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		push_error("FAIL: " + description)
## So vector với sai số nhỏ vì hệ vật lý dùng số thực.
func near_vector(actual: Vector2, expected: Vector2) -> bool:
	return actual.distance_to(expected) < 0.01
## Lần lượt chạy các tình huống độc lập, rồi xóa toàn bộ node đã tạo.
func _run() -> void:
	var round_bumper = ROUND.instantiate()
	var triangle_bumper = TRIANGLE.instantiate()
	root.add_child(round_bumper)
	root.add_child(triangle_bumper)
	triangle_bumper.position = Vector2(1000, 0)
	# Xác nhận đúng hình từ SummerTile và đúng group để script bóng nhận ra bumper.
	check(round_bumper.is_in_group("golf_bumpers") and triangle_bumper.is_in_group("golf_bumpers"), "both shapes expose bumper contact group")
	check(round_bumper.get_node("Sprite2D").region_rect == Rect2(224, 32, 16, 16), "round uses purple SummerTile region")
	check(triangle_bumper.get_node("Sprite2D").region_rect == Rect2(176, 32, 16, 16), "triangle uses striped SummerTile region")
	# Bao gồm bóng chậm, bóng đã được solver phản xạ, góc chéo và giới hạn lực bật.
	check(near_vector(round_bumper.get_bounce_velocity(Vector2(100, 0), Vector2.LEFT), Vector2(-180, 0)), "slow direct impact reflects outward with minimum kick")
	var already_outgoing := Vector2(-80, 30)
	check(near_vector(round_bumper.get_bounce_velocity(already_outgoing, Vector2.LEFT), already_outgoing.normalized() * 180.0), "already reflected solver velocity is not reflected into object again")
	check(near_vector(round_bumper.get_bounce_velocity(Vector2(100, 100), Vector2.LEFT), Vector2(-165, 165)), "oblique hit preserves reflected angle while multiplying speed")
	check(is_equal_approx(round_bumper.get_bounce_velocity(Vector2(2000, 0), Vector2.LEFT).length(), 300.0), "maximum kick speed caps repeated amplification")
	check(near_vector(round_bumper.get_bounce_velocity(Vector2.ZERO, Vector2.UP), Vector2(0, -180)), "zero speed impact exits along surface normal")
	check(near_vector(round_bumper.get_bounce_velocity(Vector2(100, 0), Vector2.ZERO), Vector2(-180, 0)), "missing normal has safe reverse direction")
	# Các giá trị chỉnh không hợp lệ trong Inspector cũng không được vượt trần vận tốc.
	round_bumper.maximum_bounce_speed = 100.0
	round_bumper.minimum_bounce_speed = 200.0
	check(is_equal_approx(round_bumper.get_bounce_velocity(Vector2(50, 0), Vector2.LEFT).length(), 100.0), "invalid floor above cap still respects cap")
	round_bumper.maximum_bounce_speed = 300.0
	round_bumper.minimum_bounce_speed = 0.0
	round_bumper.speed_multiplier = 0.0
	check(round_bumper.get_bounce_velocity(Vector2(100, 0), Vector2.LEFT) == Vector2.ZERO, "zero multiplier and floor disable added kick")
	round_bumper.minimum_bounce_speed = 180.0
	round_bumper.speed_multiplier = 1.65
	# Tam giác chỉ chắn phần có hình; nửa trong suốt còn lại không được thành vật chắn vô hình.
	var triangle_polygon: PackedVector2Array = triangle_bumper.get_node("CollisionPolygon2D").polygon
	check(Geometry2D.is_point_in_polygon(Vector2(-4, -4), triangle_polygon) and not Geometry2D.is_point_in_polygon(Vector2(5, 5), triangle_polygon), "triangle collider fills painted half and excludes transparent half")
	round_bumper.play_hit_effect()
	check(round_bumper.get_node("Sprite2D").modulate.r > 1.0, "impact feedback brightens only sprite")
	await create_timer(0.25).timeout
	check(round_bumper.get_node("Sprite2D").modulate == Color.WHITE, "impact feedback restores base sprite color")
	# Ba đường bóng tách nhau 1000 pixel để không vô tình va nhau khi đang chạy test.
	var ball = make_ball(Vector2(-36, 0), Vector2(120, 0))
	check(ball.contact_monitor and ball.max_contacts_reported > 0, "ball reports contacts needed by bumper integration")
	var diagonal_ball = make_ball(Vector2(1036, 36), Vector2(-120, -120))
	var flat_triangle = TRIANGLE.instantiate()
	root.add_child(flat_triangle)
	flat_triangle.position = Vector2(2000, 0)
	var flat_ball = make_ball(Vector2(1964, -4), Vector2(120, 0))
	var round_hit := false
	var diagonal_hit := false
	var flat_hit := false
	for tick in range(55):
		await physics_frame
		if ball.linear_velocity.x < -100.0:
			round_hit = true
		if diagonal_ball.linear_velocity.x > 100.0 and diagonal_ball.linear_velocity.y > 100.0:
			diagonal_hit = true
		if flat_ball.linear_velocity.x < -100.0:
			flat_hit = true
	check(round_hit and absf(ball.linear_velocity.length() - 198.0) < 0.1, "live round impact kicks outward once at incoming 120 times 1.65")
	check(diagonal_hit and absf(diagonal_ball.linear_velocity.length() - Vector2(120, 120).length() * 1.65) < 0.1, "live triangle diagonal edge reflects outward and amplifies speed")
	check(flat_hit and absf(flat_ball.linear_velocity.length() - 198.0) < 0.1, "live triangle flat edge uses matching outward normal")
	check(ball.stroke_count == 0 and diagonal_ball.stroke_count == 0 and flat_ball.stroke_count == 0, "bumper impacts do not add strokes")
	# Regression: chạm khi đang đứng yên chưa phải là một cú bật đã kích hoạt.
	# Sau khi bóng đứng tựa vài bước vật lý, cú đánh mới vào bumper vẫn phải được tăng lực.
	var resting_bumper = ROUND.instantiate()
	resting_bumper.position = Vector2(3000, 0)
	root.add_child(resting_bumper)
	var resting_ball = make_ball(Vector2(2989.6, 0), Vector2.ZERO)
	resting_ball.can_sleep = false
	for tick in range(8):
		await physics_frame
	check(resting_ball.get_colliding_bodies().has(resting_bumper) and resting_ball.linear_velocity.length() < 0.01, "stationary ball is already touching bumper before new shot")
	# Mô phỏng đúng vận tốc cú đánh mà thao tác thả chuột gửi vào bước vật lý kế tiếp.
	resting_ball._pending_shot = Vector2(120, 0)
	for tick in range(6):
		await physics_frame
	check(resting_ball.linear_velocity.x < -160.0 and absf(resting_ball.linear_velocity.length() - 198.0) < 0.1 and resting_ball.stroke_count == 1, "new shot from resting contact still receives exactly one bumper boost")
	for body in [ball, diagonal_ball, flat_ball, round_bumper, triangle_bumper, flat_triangle, resting_bumper, resting_ball]:
		body.free()
	# Bốn góc có ảnh và collider riêng, nên cần kiểm tra cả pháp tuyến lẫn bóng đi thực tế.
	await _test_triangle_variants()
	print("BUMPER_RESULT passed=", passed, " failed=", failed)
	quit(1 if failed else 0)

## Kiểm tra bốn tam giác lấy đúng vùng ảnh và chỉ chắn phần có hình trong từng ô.
func _test_triangle_variants() -> void:
	# empty_direction chỉ về nửa trong suốt; đó cũng là pháp tuyến ra khỏi cạnh chéo.
	# Mỗi góc dùng một sân riêng, tránh các bóng của những tình huống khác va vào nhau.
	var samples := [
		{"scene": preload("res://Objects/Bumpers/TriangleTopLeft.tscn"),
			"region": Rect2(176, 32, 16, 16), "empty_direction": Vector2(1, 1), "name": "top-left"},
		{"scene": preload("res://Objects/Bumpers/TriangleTopRight.tscn"),
			"region": Rect2(192, 32, 16, 16), "empty_direction": Vector2(-1, 1), "name": "top-right"},
		{"scene": preload("res://Objects/Bumpers/TriangleBottomLeft.tscn"),
			"region": Rect2(176, 48, 16, 16), "empty_direction": Vector2(1, -1), "name": "bottom-left"},
		{"scene": preload("res://Objects/Bumpers/TriangleBottomRight.tscn"),
			"region": Rect2(192, 48, 16, 16), "empty_direction": Vector2(-1, -1), "name": "bottom-right"},
	]
	for index in range(samples.size()):
		var sample: Dictionary = samples[index]
		var bumper = sample["scene"].instantiate()
		bumper.position = Vector2(5000 + index * 1000, 1000)
		root.add_child(bumper)
		sample["bumper"] = bumper
		check(bumper.get_node("Sprite2D").region_rect == sample["region"],
			sample["name"] + " uses its original SummerTile corner region")
	# Chờ các collider được đăng ký vào không gian vật lý trước khi bắn tia kiểm tra.
	await physics_frame
	await physics_frame
	for sample in samples:
		var bumper = sample["bumper"]
		var origin: Vector2 = bumper.global_position
		var empty_direction: Vector2 = sample["empty_direction"]
		var space = bumper.get_world_2d().direct_space_state
		# Tia đi từ phần trống vào phần có hình phải chạm cạnh chéo với normal đúng góc.
		var diagonal_query := PhysicsRayQueryParameters2D.create(
			origin + empty_direction * 5.0, origin - empty_direction * 5.0, 1)
		diagonal_query.collide_with_areas = false
		var diagonal_hit: Dictionary = space.intersect_ray(diagonal_query)
		var hit_normal: Vector2 = diagonal_hit.get("normal", Vector2.ZERO)
		check(diagonal_hit.get("collider") == bumper
			and hit_normal.dot(empty_direction.normalized()) > 0.999,
			sample["name"] + " diagonal collider reports outward normal toward transparent half")
		# Tia nằm hoàn toàn trong nửa trong suốt không được gặp một hình vuông chặn vô hình.
		var clear_query := PhysicsRayQueryParameters2D.create(
			origin + empty_direction * 4.0, origin + empty_direction * 6.0, 1)
		clear_query.collide_with_areas = false
		check(space.intersect_ray(clear_query).is_empty(),
			sample["name"] + " transparent half contains no blocking collider")
		sample["hit_ball"] = make_ball(origin + empty_direction * 36.0,
			-empty_direction * 120.0)
	# Bóng đi vào cạnh chéo, bật lại và rời hẳn. Đo sau nhiều frame cũng bắt được lỗi tăng lực lặp.
	for tick in range(55):
		await physics_frame
	for sample in samples:
		var hit_ball = sample["hit_ball"]
		var empty_direction: Vector2 = sample["empty_direction"]
		check(near_vector(hit_ball.linear_velocity, empty_direction * 198.0)
			and hit_ball.stroke_count == 0,
			sample["name"] + " live diagonal hit reflects once with exact boosted speed and no stroke")
		hit_ball.free()
		# Cho một bóng khác đi qua phần trống, cách cạnh chéo đủ xa cả bán kính 3 pixel.
		# Không có va chạm thật thì không được xuất hiện cú boost dù bóng đang trong ô ảnh.
		var origin: Vector2 = sample["bumper"].global_position
		sample["clear_ball"] = make_ball(origin + empty_direction * 5.0, empty_direction * 40.0)
	for tick in range(12):
		await physics_frame
	for sample in samples:
		var clear_ball = sample["clear_ball"]
		var empty_direction: Vector2 = sample["empty_direction"]
		check(near_vector(clear_ball.linear_velocity, empty_direction * 40.0)
			and clear_ball.stroke_count == 0,
			sample["name"] + " ball crosses transparent half without collision or extra kick")
		clear_ball.free()
		sample["bumper"].free()

## Tạo bóng thật với mặt sân trống và bỏ giảm tốc để đo riêng kết quả của bumper.
func make_ball(location: Vector2, velocity: Vector2):
	var ball = BALL.instantiate()
	ball.position = location
	ball.rolling_deceleration = 0.0
	ball.sand_deceleration = 0.0
	ball.linear_velocity = velocity
	root.add_child(ball)
	return ball
