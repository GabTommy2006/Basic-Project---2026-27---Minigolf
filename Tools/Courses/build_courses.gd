# Công cụ dựng scene một lần từ bản bố cục dạng ô, không sinh map khi người chơi chạy game.
# Mỗi kết quả là TileMap và các scene vật thể thật, mở được để kéo/vẽ tiếp trong Godot.
# Chạy: Godot --headless --path . --script res://Tools/Courses/build_courses.gd
# Chỉ dùng -- --rebuild khi muốn GHI ĐÈ các Map01..Map10 đã chỉnh bằng tay.
extends SceneTree

# Ba nhóm bố cục độc lập để xem lại ý tưởng; không phải dữ liệu cần đọc lúc chơi.
const LAYOUT_FILES := [
	"res://Tools/Courses/layouts_01_04.json",
	"res://Tools/Courses/layouts_05_07.json",
	"res://Tools/Courses/layouts_08_10.json",
]
const TILESET = preload("res://Assets/TileSetSummer.tres")
const COURSE_SCRIPT = preload("res://Maps/Courses/course.gd")
const BALL_SCENE = preload("res://Objects/Ball/Ball.tscn")
const HOLE_SCENE = preload("res://Objects/Hole/Hole.tscn")
# Các vật thể được lấy nguyên từ bộ scene đã kiểm tra, không viết lại cơ chế riêng cho map.
const OBJECT_SCENES := {
	"rotator": preload("res://Objects/Obstacles/RotatingBar.tscn"),
	"gate": preload("res://Objects/Obstacles/BlinkingGate.tscn"),
	"moving": preload("res://Objects/Obstacles/MovingObstacle.tscn"),
	"round_bumper": preload("res://Objects/Bumpers/RoundBumper.tscn"),
	"triangle_tl": preload("res://Objects/Bumpers/TriangleTopLeft.tscn"),
	"triangle_tr": preload("res://Objects/Bumpers/TriangleTopRight.tscn"),
	"triangle_bl": preload("res://Objects/Bumpers/TriangleBottomLeft.tscn"),
	"triangle_br": preload("res://Objects/Bumpers/TriangleBottomRight.tscn"),
	"portal_orange": preload("res://Objects/Portal/PortalOrange.tscn"),
	"portal_blue": preload("res://Objects/Portal/PortalBlue.tscn"),
}
# Kích thước tile gốc SummerTile và khung sân thống nhất, không phóng to collider/vật thể.
const TILE_SIZE := 16.0
const WIDTH := 24
const HEIGHT := 14

## Hoãn tới khi SceneTree sẵn sàng; các node chỉ được đóng gói, không cần chạy hoạt ảnh.
func _initialize() -> void:
	_build_all.call_deferred()

## Kiểm tra đủ mười bản trước khi ghi; mặc định không ghi đè sân người dùng đã chỉnh.
func _build_all() -> void:
	var layouts: Array = []
	for path in LAYOUT_FILES:
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Array:
			_fail("Không đọc được bố cục: " + path)
			return
		layouts.append_array(data)
	if layouts.size() != 10:
		_fail("Cần đúng 10 bố cục trước khi dựng scene.")
		return
	layouts.sort_custom(func(a, b): return int(a.number) < int(b.number))
	var rebuild := "--rebuild" in OS.get_cmdline_user_args()
	for index in range(layouts.size()):
		var layout: Dictionary = layouts[index]
		if int(layout.number) != index + 1 or not _valid_grid(layout):
			_fail("Số màn hoặc lưới không hợp lệ: " + str(layout.get("number")))
			return
		var path := "res://Maps/Courses/Map%02d.tscn" % int(layout.number)
		if FileAccess.file_exists(path) and not rebuild:
			_fail("Đã có " + path + ". Dừng để giữ bản đã sửa; --rebuild mới cho phép ghi đè.")
			return
	for layout in layouts:
		var scene := _make_course(layout)
		var packed := PackedScene.new()
		var error := packed.pack(scene)
		if error == OK:
			error = ResourceSaver.save(packed, "res://Maps/Courses/Map%02d.tscn" % int(layout.number))
		scene.free()
		if error != OK:
			_fail("Không lưu được màn " + str(layout.number) + ": " + str(error))
			return
		print("CREATED Map%02d: %s" % [int(layout.number), str(layout.title)])
	quit(0)

## Mỗi hàng đúng 24 ô; chặn ký hiệu lạ để tránh tạo lỗ hổng không nhìn thấy trên sân.
func _valid_grid(layout: Dictionary) -> bool:
	var grid: Array = layout.get("grid", [])
	if grid.size() != HEIGHT:
		return false
	for row in grid:
		if not row is String or row.length() != WIDTH:
			return false
		for index in range(WIDTH):
			if not row[index] in "#.s~ <>^v":
				return false
	return true

## Tọa độ trong JSON tính theo ô; cộng 8 pixel để luôn đặt vật thể ở tâm ô đó.
func _center(cell: Array) -> Vector2:
	return Vector2(float(cell[0]), float(cell[1])) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 0.5

## Tạo node có owner rõ ràng để tất cả phần tự dựng đều được lưu vào PackedScene.
func _own(parent: Node, child: Node, scene: Node) -> void:
	parent.add_child(child)
	child.owner = scene

## Dựng sẵn sân, camera, bóng, lỗ; runtime không cần JSON hoặc công cụ này.
func _make_course(layout: Dictionary) -> Node2D:
	var scene := Node2D.new()
	scene.name = "Map%02d" % int(layout.number)
	scene.set_script(COURSE_SCRIPT)
	scene.course_number = int(layout.number)
	scene.course_title = str(layout.title)
	scene.editor_description = "%02d — %s. F6 chơi sân này; R chơi lại. TileMap vẽ sửa trực tiếp, vật thể kéo riêng trong Scene Tree." % [int(layout.number), str(layout.title)]
	# Lưu đường tham khảo cho kiểm tra bố cục, không vẽ gợi ý lên gameplay.
	var route := PackedVector2Array()
	for cell in layout.route:
		route.append(_center(cell))
	scene.set_meta("recommended_route", route)
	# Nền tối nằm sau sân; phần ngoài tường không được hiểu là cỏ có thể đánh bóng.
	var backdrop := Polygon2D.new()
	backdrop.name = "Backdrop"
	backdrop.z_index = -2
	backdrop.color = Color("173a32")
	backdrop.polygon = PackedVector2Array([Vector2(-32, -24), Vector2(416, -24), Vector2(416, 248), Vector2(-32, 248)])
	_own(scene, backdrop, scene)
	var map := TileMap.new()
	map.name = "TileMap"
	map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.tile_set = TILESET
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var symbol: String = layout.grid[y][x]
			if symbol != " ":
				map.set_cell(0, Vector2i(x, y), 0, _atlas_cell(symbol, layout.grid, x, y))
	_own(scene, map, scene)
	# Khung 384x224 vừa toàn sân ở zoom 3 trên viewport 1280x720 đang dùng.
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(WIDTH, HEIGHT) * TILE_SIZE * 0.5
	camera.zoom = Vector2(3.0, 3.0)
	_own(scene, camera, scene)
	for definition in layout.get("objects", []):
		_add_object(scene, definition)
	var hole := HOLE_SCENE.instantiate()
	hole.name = "Hole"
	hole.position = _center(layout.hole)
	hole.z_index = 1
	_own(scene, hole, scene)
	var ball := BALL_SCENE.instantiate()
	ball.name = "Ball"
	ball.position = _center(layout.ball)
	ball.z_index = 2
	_own(scene, ball, scene)
	return scene

## Tile cát/nước lấy đúng nhãn Custom Data đang có; mũi tên cũng dùng tile đã lập trình.
func _atlas_cell(symbol: String, grid: Array, x: int, y: int) -> Vector2i:
	match symbol:
		"#": return Vector2i(8, 0)
		">": return Vector2i(8, 4)
		"<": return Vector2i(9, 4)
		"^": return Vector2i(9, 5)
		"v": return Vector2i(8, 5)
		"s", "~":
			# Bộ 3x3 tạo viền tiếp đất, dùng ô giữa nếu dải chỉ dày một tile.
			var left := _same(grid, x - 1, y, symbol)
			var right := _same(grid, x + 1, y, symbol)
			var above := _same(grid, x, y - 1, symbol)
			var below := _same(grid, x, y + 1, symbol)
			var dx := 1 if left == right else (0 if not left else 2)
			var dy := 1 if above == below else (0 if not above else 2)
			return Vector2i((3 if symbol == "s" else 6) + dx, 10 + dy)
	return Vector2i(1, 4)

## So sánh hàng xóm có cùng vật liệu, kể cả ô ngoài lưới luôn được coi là khác.
func _same(grid: Array, x: int, y: int, symbol: String) -> bool:
	return x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT and grid[y][x] == symbol

## Gắn instance scene thật và lưu các chỉnh riêng của mỗi màn, gồm cặp Destination hai chiều.
func _add_object(scene: Node2D, definition: Dictionary) -> void:
	var kind := str(definition.type)
	var object: Node2D = OBJECT_SCENES[kind].instantiate()
	object.name = str(definition.name)
	object.position = _center(definition.at)
	object.rotation_degrees = float(definition.get("rotation_degrees", 0.0))
	object.z_index = 1
	object.set_meta("course_object_type", kind)
	for property in definition.get("properties", {}):
		object.set(property, definition.properties[property])
	if definition.has("destination"):
		object.destination = NodePath("../" + str(definition.destination))
	_own(scene, object, scene)
	if kind == "moving":
		var offset: Array = definition.get("end_offset", [3, 0])
		object.get_node("EndPoint").position = Vector2(float(offset[0]), float(offset[1])) * TILE_SIZE
		# Cho phép kéo EndPoint trong editor mà không phải mở scene gốc của mọi vật cản.
		scene.set_editable_instance(object, true)

## In một lỗi rõ ràng và trả exit code khác 0 để không nhầm kết quả dựng sân đã thành công.
func _fail(message: String) -> void:
	printerr(message)
	quit(1)
