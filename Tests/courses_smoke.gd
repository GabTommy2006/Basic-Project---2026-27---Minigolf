# Kiểm tra bộ mười sân đã lưu, không tạo lại chúng và không sửa scene của người dùng.
# Ngoài bố cục tĩnh, chạy cú đánh thật ở màn 1 và lượt dịch chuyển thật ở màn 9.
extends SceneTree

const TILE_SIZE := 16.0
const CARDINALS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var passes := 0
var failures: Array[String] = []

## Đợi SceneTree có viewport/vật lý trước khi đưa sân đầu tiên vào cây.
func _initialize() -> void:
	_run.call_deferred()

## Ghi rõ màn và điều kiện lỗi; trả mã tiến trình khác 0 nếu bất kỳ mục nào thất bại.
func _check(condition: bool, message: String) -> void:
	if condition:
		passes += 1
		print("PASS: ", message)
	else:
		failures.append(message)
		printerr("FAIL: ", message)

## Dùng nhịp vật lý thật để va chạm, cửa và RigidBody2D được xử lý như lúc chơi.
func _ticks(count: int) -> void:
	for _index in range(count):
		await physics_frame

## Đổi điểm thế giới về ô sân; không giả định TileMap luôn giữ transform mặc định.
func _cell(map: TileMap, point: Vector2) -> Vector2i:
	return map.local_to_map(map.to_local(point))

## Đọc tài nguyên đã lưu thay vì dùng JSON đầu vào để quyết định sân thực tế có gì.
func _kind(map: TileMap, cell: Vector2i) -> String:
	var data := map.get_cell_tile_data(0, cell)
	if data == null:
		return "void"
	if data.get_collision_polygons_count(0) > 0:
		return "wall"
	var surface := str(data.get_custom_data("surface_layer"))
	if surface == "water" or surface == "sand":
		return surface
	if not str(data.get_custom_data("arrow_direction")).is_empty():
		return "arrow"
	return "grass"

## Cỏ, cát và mũi tên đều cho bóng đứng/lăn; nước chỉ dùng làm vùng nguy hiểm.
func _is_dry(kind: String) -> bool:
	return kind == "grass" or kind == "sand" or kind == "arrow"

## Chỉ lấy các vật thể gameplay đặt trực tiếp trên sân, không nhầm node con trang trí.
func _objects(course: Node, kind: String = "") -> Array[Node2D]:
	var found: Array[Node2D] = []
	for child in course.get_children():
		if child is Node2D and child.has_meta("course_object_type"):
			if kind.is_empty() or str(child.get_meta("course_object_type")) == kind:
				found.append(child)
	return found

## Thuật toán tìm đường độc lập với recommended_route; tùy chọn thêm cạnh nối hai cổng.
func _connected(course: Node, start: Vector2i, goal: Vector2i, use_portals: bool) -> bool:
	var map: TileMap = course.get_node("TileMap")
	var portal_edges: Dictionary = {}
	if use_portals:
		for portal in _objects(course):
			if not str(portal.get_meta("course_object_type")).begins_with("portal_"):
				continue
			var target = portal._get_destination()
			if target != null:
				portal_edges[_cell(map, portal.global_position)] = _cell(map, target.global_position)
	var frontier: Array[Vector2i] = [start]
	var visited := {start: true}
	var index := 0
	while index < frontier.size():
		var current := frontier[index]
		index += 1
		if current == goal:
			return true
		var neighbors: Array[Vector2i] = []
		for direction in CARDINALS:
			neighbors.append(current + direction)
		if portal_edges.has(current):
			neighbors.append(portal_edges[current])
		for next in neighbors:
			if not visited.has(next) and _is_dry(_kind(map, next)):
				visited[next] = true
				frontier.append(next)
	return false

## Chỉ bỏ qua đoạn nhảy đúng giữa hai cổng nối thật; không cho phép bỏ qua đoạn nước khác.
func _is_portal_hop(course: Node, from: Vector2, to: Vector2) -> bool:
	if int(course.course_number) != 9:
		return false
	for portal in _objects(course):
		if not str(portal.get_meta("course_object_type")).begins_with("portal_"):
			continue
		var target = portal._get_destination()
		if target != null and from.distance_to(portal.global_position) < 0.1 and to.distance_to(target.global_position) < 0.1:
			return true
	return false

## Kiểm tra tuyến tham khảo mỗi 4 pixel, gồm điểm đầu/cuối và mọi khúc cua.
func _route_is_clear(course: Node, route: PackedVector2Array) -> bool:
	var map: TileMap = course.get_node("TileMap")
	if route.size() < 2:
		return false
	if route[0].distance_to(course.get_node("Ball").global_position) > 0.1:
		return false
	if route[-1].distance_to(course.get_node("Hole").global_position) > 0.1:
		return false
	for index in range(1, route.size()):
		var from := route[index - 1]
		var to := route[index]
		if _is_portal_hop(course, from, to):
			continue
		var samples := maxi(1, ceili(from.distance_to(to) / 4.0))
		for sample in range(samples + 1):
			var point := from.lerp(to, float(sample) / float(samples))
			if not _is_dry(_kind(map, _cell(map, point))):
				return false
	return true

## Một tile tường cần kín toàn ô, tránh ảnh nhìn kín nhưng collider chỉ chặn một phần.
func _wall_fills_tile(data: TileData) -> bool:
	for index in range(data.get_collision_polygons_count(0)):
		var polygon := data.get_collision_polygon_points(0, index)
		if polygon.is_empty() or not Geometry2D.is_point_in_polygon(Vector2.ZERO, polygon):
			continue
		var bounds := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon:
			bounds = bounds.expand(point)
		if bounds.position.x <= -7.9 and bounds.position.y <= -7.9 and bounds.end.x >= 7.9 and bounds.end.y >= 7.9:
			return true
	return false

## Hỏi PhysicsServer để phát hiện cả tường TileMap và vật cản thật tại điểm xuất phát/lỗ.
func _position_has_room(course: Node2D, position: Vector2) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = [course.get_node("Ball").get_rid()]
	return course.get_world_2d().direct_space_state.intersect_shape(query).is_empty()

## Kiểm tra hình học chung: sân kín, tường có va chạm, tuyến đi và điểm đặt đều sử dụng được.
func _check_geometry(course: Node2D, number: int) -> void:
	var prefix := "Map%02d " % number
	var map: TileMap = course.get_node("TileMap")
	var ball: RigidBody2D = course.get_node("Ball")
	var hole: Area2D = course.get_node("Hole")
	var bounded := true
	var solid_walls := true
	var walls := 0
	for cell in map.get_used_cells(0):
		var kind := _kind(map, cell)
		if kind == "wall":
			walls += 1
			solid_walls = solid_walls and _wall_fills_tile(map.get_cell_tile_data(0, cell))
		elif _is_dry(kind):
			for direction in CARDINALS:
				bounded = bounded and _kind(map, cell + direction) != "void"
	_check(bounded, prefix + "walkable ground has no opening into exterior void")
	_check(walls > 0 and solid_walls, prefix + "visible wall tiles have full solid collision")
	_check(_kind(map, _cell(map, ball.global_position)) == "grass", prefix + "ball starts on grass")
	_check(_kind(map, _cell(map, hole.global_position)) == "grass", prefix + "hole is on grass")
	_check(_position_has_room(course, ball.global_position), prefix + "ball starts clear of walls and obstacle bodies")
	_check(_position_has_room(course, hole.global_position), prefix + "hole mouth is clear of obstacle bodies")
	var route = course.get_meta("recommended_route", PackedVector2Array())
	_check(route is PackedVector2Array and _route_is_clear(course, route), prefix + "reference route avoids walls, water and void")
	var connected := _connected(course, _cell(map, ball.global_position), _cell(map, hole.global_position), false)
	if number == 9:
		_check(not connected, prefix + "islands require the portal rather than a dry shortcut")
		_check(_connected(course, _cell(map, ball.global_position), _cell(map, hole.global_position), true), prefix + "linked portals connect both dry islands")
	else:
		_check(connected, prefix + "has a continuous dry route from ball to hole")
	for portal in _objects(course):
		if str(portal.get_meta("course_object_type")).begins_with("portal_"):
			var target = portal._get_destination()
			_check(target != null and target._get_destination() == portal, prefix + "portal Destination is reciprocal: " + str(portal.name))

## Màn đầu phải là một phòng chữ nhật cỏ trống, không có tường trong hoặc cơ chế phụ.
func _check_beginner_course(course: Node2D) -> void:
	var map: TileMap = course.get_node("TileMap")
	var grass_cells: Array[Vector2i] = []
	var only_grass_and_wall := true
	for cell in map.get_used_cells(0):
		var kind := _kind(map, cell)
		only_grass_and_wall = only_grass_and_wall and (kind == "grass" or kind == "wall")
		if kind == "grass":
			grass_cells.append(cell)
	var rectangular := not grass_cells.is_empty()
	if rectangular:
		var bounds := Rect2i(grass_cells[0], Vector2i.ONE)
		for cell in grass_cells:
			bounds = bounds.expand(cell)
		for y in range(bounds.position.y, bounds.end.y):
			for x in range(bounds.position.x, bounds.end.x):
				rectangular = rectangular and _kind(map, Vector2i(x, y)) == "grass"
	_check(only_grass_and_wall and rectangular and _objects(course).is_empty(), "Map01 is an empty grass rectangle for a basic putt")
	var ball = course.get_node("Ball")
	var hole = course.get_node("Hole")
	var result := {"count": 0, "number": 0, "strokes": 0}
	course.course_completed.connect(func(number: int, strokes: int):
		result.count += 1
		result.number = number
		result.strokes = strokes)
	var distance: float = ball.global_position.distance_to(hole.global_position)
	# Chọn lực để tới miệng lỗ còn khoảng 35 px/s, dưới ngưỡng nhận bóng nhưng vẫn dư quãng lăn.
	var speed := sqrt(2.0 * float(ball.rolling_deceleration) * distance + 35.0 * 35.0)
	_check(speed <= float(ball.max_shot_speed), "Map01 hole is reachable with one legal shot")
	ball._pending_shot = ball.global_position.direction_to(hole.global_position) * speed
	ball.sleeping = false
	for _index in range(240):
		await _ticks(1)
		if ball.is_sunk:
			break
	_check(ball.is_sunk and ball.stroke_count == 1 and not ball.is_in_water, "Map01 real physics putt reaches hole in one stroke")
	await _ticks(24)
	_check(result.count == 1 and result.number == 1 and result.strokes == 1, "Map01 reports completion exactly once with the real score")
	_check(is_instance_valid(course) and course.is_inside_tree() and current_scene == course, "Map01 completion leaves this course open without auto advancement")

## Cửa đặt đúng khe một tile; hai tile trên/dưới kín để người chơi không lách cạnh cửa.
func _check_gate_doorways(course: Node2D) -> void:
	var map: TileMap = course.get_node("TileMap")
	for gate in _objects(course, "gate"):
		var shape: RectangleShape2D = gate.get_node("CollisionShape2D").shape
		var cell := _cell(map, gate.global_position)
		var fits := absf(absf(sin(gate.rotation)) - 1.0) < 0.001 and is_equal_approx(shape.size.x, TILE_SIZE)
		fits = fits and _kind(map, cell + Vector2i.UP) == "wall" and _kind(map, cell + Vector2i.DOWN) == "wall"
		fits = fits and _is_dry(_kind(map, cell + Vector2i.LEFT)) and _is_dry(_kind(map, cell + Vector2i.RIGHT))
		_check(fits, "Map%02d gate seals the one-tile doorway: %s" % [course.course_number, gate.name])

## EndPoint phải còn trong PackedScene; chờ chuyển động thật để bắt lỗi mất override khi đóng gói.
func _check_moving_obstacles(course: Node2D) -> void:
	var movers := _objects(course, "moving")
	var starts: Array[Vector2] = []
	for mover in movers:
		var end_point: Marker2D = mover.get_node("EndPoint")
		_check(end_point.position.is_equal_approx(Vector2(48, 0)), "Map07 saved EndPoint retains the 3-tile horizontal patrol: " + str(mover.name))
		starts.append(mover.get_node("Body").position)
	await _ticks(72)
	for index in range(movers.size()):
		var body: AnimatableBody2D = movers[index].get_node("Body")
		_check(body.position.distance_to(starts[index]) > 4.0 and absf(body.position.y) < 0.01, "Map07 obstacle physically moves along its saved route: " + str(movers[index].name))

## Đánh từ cỏ gần cổng cam vào vòng nhận thật; không gọi trực tiếp hàm dịch chuyển.
func _check_island_transport(course: Node2D) -> void:
	var ball = course.get_node("Ball")
	var orange: Area2D = _objects(course, "portal_orange")[0]
	var blue: Area2D = _objects(course, "portal_blue")[0]
	# Đổi transform trước khi bước vật lý bắt đầu nhận cú đánh; vị trí vẫn ở đảo trái.
	ball.global_position = orange.global_position - Vector2(24, 0)
	ball.reset_physics_interpolation()
	await _ticks(2)
	var shot_origin: Vector2 = ball.global_position
	ball._pending_shot = Vector2(60, 0)
	ball.sleeping = false
	var transported := false
	var saw_water := false
	for _index in range(120):
		await _ticks(1)
		saw_water = saw_water or ball.is_in_water
		if ball.global_position.x > blue.global_position.x + 10.0:
			transported = true
			break
	_check(transported and absf(ball.global_position.y - blue.global_position.y) < 0.5, "Map09 real entry travels from orange to the blue island")
	_check(ball.linear_velocity.x > 0.0 and ball.linear_velocity.length() < 60.0, "Map09 preserves rightward motion with normal grass deceleration")
	await _ticks(90)
	saw_water = saw_water or ball.is_in_water
	_check(not saw_water and ball.stroke_count == 1 and ball.global_position.x > blue.global_position.x, "Map09 arrival stays on grass without water penalty or reset")
	_check(ball._shot_start_position.distance_to(shot_origin) < 0.5, "Map09 portal retains the original shot return point")

## Lần lượt tải các scene đã lưu; mỗi sân được dọn khỏi PhysicsServer trước sân kế tiếp.
func _run() -> void:
	for number in range(1, 11):
		var path := "res://Maps/Courses/Map%02d.tscn" % number
		var packed := load(path) as PackedScene
		_check(packed != null, "Map%02d saved scene loads" % number)
		if packed == null:
			continue
		var course := packed.instantiate() as Node2D
		var balls := course.find_children("*", "RigidBody2D", true, false)
		var holes: Array[Node] = []
		for child in course.get_children():
			if child.has_signal("completed") and child.has_method("contains_ball_center"):
				holes.append(child)
		_check(int(course.course_number) == number and not str(course.course_title).is_empty(), "Map%02d has its own course number and title" % number)
		_check(balls.size() == 1 and holes.size() == 1 and course.has_node("Ball") and course.has_node("Hole"), "Map%02d has exactly one playable ball and one hole" % number)
		root.add_child(course)
		current_scene = course
		await _ticks(3)
		_check_geometry(course, number)
		if number == 1:
			await _check_beginner_course(course)
		if number == 5:
			_check(_objects(course, "rotator").size() == 1, "Map05 includes its central rotating obstacle")
		if number == 6:
			_check(_objects(course, "gate").size() == 2, "Map06 has two distinct timed gates")
		if number == 7:
			_check(_objects(course, "moving").size() == 2, "Map07 has patrols in both legs")
			await _check_moving_obstacles(course)
		if number == 8:
			var triangle_count := _objects(course, "triangle_tl").size() + _objects(course, "triangle_tr").size() + _objects(course, "triangle_bl").size() + _objects(course, "triangle_br").size()
			_check(_objects(course, "round_bumper").size() > 0 and triangle_count > 0, "Map08 includes round and triangular rebound obstacles")
		if number == 9:
			_check(_objects(course, "portal_orange").size() == 1 and _objects(course, "portal_blue").size() == 1, "Map09 contains one independent portal of each color")
			await _check_island_transport(course)
		_check_gate_doorways(course)
		current_scene = null
		course.queue_free()
		await _ticks(3)
	print("\nCOURSES: %d passed, %d failed" % [passes, failures.size()])
	quit(0 if failures.is_empty() else 1)
