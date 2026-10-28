# Camera cho các sân lớn: bám bóng mượt, khung nhìn luôn nằm trong biên map.
extends Camera2D

@export var target: Node2D
@export var tile_map: TileMap
@export_range(8.0, 96.0, 1.0) var framing_padding: float = 8.0
@export_range(1.0, 30.0, 0.5) var follow_speed: float = 8.0
## Lùi nhẹ góc nhìn so với khung sát sân, không thay zoom trong lúc bóng lăn.
@export_range(0.5, 1.0, 0.05) var overview_scale: float = 0.9
## UI mode: keep every playable edge visible while following within spare screen space.
@export var frame_entire_course := false

var _course_bounds := Rect2()
var _map_bounds := Rect2()
var _minimum_center := Vector2.ZERO
var _maximum_center := Vector2.ZERO
var _hole: Node2D


func _ready() -> void:
	# Chỉ một lớp làm mượt; không dùng thêm smoothing của Camera2D.
	position_smoothing_enabled = false
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
	_measure_course()
	_refresh_view()
	make_current()
	force_update_scroll()
	get_viewport().size_changed.connect(_refresh_view)


func _measure_course() -> void:
	if not is_instance_valid(tile_map) or tile_map.tile_set == null:
		return
	var tile_size := Vector2(tile_map.tile_set.tile_size)
	var used := tile_map.get_used_rect()
	_map_bounds = tile_map.global_transform * Rect2(Vector2(used.position) * tile_size,
		Vector2(used.size) * tile_size)
	var found := false
	for layer in tile_map.get_layers_count():
		for cell in tile_map.get_used_cells(layer):
			var atlas := tile_map.get_cell_atlas_coords(layer, cell)
			# Chín tile đất viền SummerTile ở cột 7..9, hàng 0..2 là nền ngoài sân.
			# Vẫn tính chúng vào biên map, nhưng không lấy làm kích thước đường chơi.
			if tile_map.get_cell_source_id(layer, cell) == 0 \
					and atlas.x >= 7 and atlas.x <= 9 and atlas.y >= 0 and atlas.y <= 2:
				continue
			var local_rect := Rect2(tile_map.map_to_local(cell) - tile_size * 0.5, tile_size)
			var world_rect := tile_map.global_transform * local_rect
			_course_bounds = _course_bounds.merge(world_rect) if found else world_rect
			found = true
	if not found:
		_course_bounds = _map_bounds
	# Không để điểm xuất phát hoặc lỗ nằm ngoài khung nếu map còn đang được vẽ.
	if is_instance_valid(target):
		_course_bounds = _course_bounds.expand(target.global_position)
	_hole = get_parent().get_node_or_null("Hole") as Node2D
	if is_instance_valid(_hole):
		_course_bounds = _course_bounds.expand(_hole.global_position)


func _refresh_view() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or not _course_bounds.has_area():
		return
	var framed_size := _course_bounds.size + Vector2.ONE * maxf(framing_padding, 8.0) * 2.0
	if frame_entire_course:
		# Fit, rather than crop, for the actual gameplay aspect ratio. A tall course
		# cannot obey strict outer-map limits in a wide viewport and remain whole.
		zoom = Vector2.ONE * minf(viewport_size.x / framed_size.x, viewport_size.y / framed_size.y)
		var half_view := viewport_size / zoom * 0.5
		var framed := _course_bounds.grow(maxf(framing_padding, 8.0))
		_minimum_center = framed.end - half_view
		_maximum_center = framed.position + half_view
		for axis in 2:
			if _minimum_center[axis] > _maximum_center[axis]:
				_minimum_center[axis] = framed.get_center()[axis]
				_maximum_center[axis] = _minimum_center[axis]
		global_position = _destination()
		force_update_scroll()
		return
	var course_zoom := maxf(viewport_size.x / framed_size.x, viewport_size.y / framed_size.y) * overview_scale
	if is_instance_valid(_hole):
		# Tính một lần cho mọi vị trí bóng trên sân, tránh zoom nhấp nhô khi bóng di chuyển.
		var hole_position := _hole.global_position
		var separation := Vector2(
			maxf(absf(_course_bounds.position.x - hole_position.x), absf(_course_bounds.end.x - hole_position.x)),
			maxf(absf(_course_bounds.position.y - hole_position.y), absf(_course_bounds.end.y - hole_position.y)))
		var pair_size := separation + Vector2.ONE * 32.0
		course_zoom = minf(course_zoom, minf(viewport_size.x / pair_size.x, viewport_size.y / pair_size.y))
	# Cả chiều rộng và chiều cao khung nhìn phải nhỏ hơn hoặc bằng map.
	var minimum_zoom := maxf(viewport_size.x / _map_bounds.size.x, viewport_size.y / _map_bounds.size.y)
	zoom = Vector2.ONE * maxf(course_zoom, minimum_zoom)
	var half_view := viewport_size / zoom * 0.5
	_minimum_center = _map_bounds.position + half_view
	_maximum_center = _map_bounds.end - half_view
	# Giữ toàn đường chơi ở trục đủ rộng; trục còn lại cuộn theo bóng trong map.
	var safe_bounds := _course_bounds.grow(8.0)
	for axis in 2:
		if _minimum_center[axis] > _maximum_center[axis]:
			_minimum_center[axis] = _map_bounds.get_center()[axis]
			_maximum_center[axis] = _minimum_center[axis]
		var lower := maxf(_minimum_center[axis], safe_bounds.end[axis] - half_view[axis])
		var upper := minf(_maximum_center[axis], safe_bounds.position[axis] + half_view[axis])
		if lower <= upper:
			_minimum_center[axis] = lower
			_maximum_center[axis] = upper
	global_position = _destination()
	force_update_scroll()


func _destination() -> Vector2:
	var focus := target.global_position if is_instance_valid(target) else _course_bounds.get_center()
	var lower := _minimum_center
	var upper := _maximum_center
	if is_instance_valid(target) and is_instance_valid(_hole):
		var ball_position := target.global_position
		var hole_position := _hole.global_position
		focus = ball_position.lerp(hole_position, 0.35)
		var half_view := get_viewport_rect().size / zoom * 0.5 - Vector2.ONE * 8.0
		for axis in 2:
			var pair_lower := maxf(lower[axis], maxf(ball_position[axis], hole_position[axis]) - half_view[axis])
			var pair_upper := minf(upper[axis], minf(ball_position[axis], hole_position[axis]) + half_view[axis])
			if pair_lower <= pair_upper:
				lower[axis] = pair_lower
				upper[axis] = pair_upper
	return focus.clamp(lower, upper)


func _process(delta: float) -> void:
	if not _course_bounds.has_area():
		return
	# Zoom chỉ đổi khi resize. Không reset smoothing hay đổi tâm nhiều lần mỗi frame.
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(_destination(), weight).clamp(_minimum_center, _maximum_center)
