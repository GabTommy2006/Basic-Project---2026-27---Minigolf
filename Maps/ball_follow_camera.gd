# Camera căn giữa bóng và lỗ; biên và zoom được tính từ sân khi chạy scene.
extends Camera2D

@export var target: Node2D
## Khi gán lỗ golf, camera theo trung điểm để thấy cả bóng và đích đến.
@export var hole: Node2D
@export var tile_map: TileMap
## Vùng sân nhìn thấy ở màn hình 16:9, tính bằng pixel thế giới.
## Giảm kích thước này để nhìn gần hơn; tăng để thấy nhiều sân hơn.
@export var view_size := Vector2(256.0, 144.0)
## Tự mở rộng khung hình để giữ cả bóng và lỗ, có chừa khoảng trống quanh hai bên.
@export var frame_ball_and_hole: bool = false
@export var framing_margin: float = 32.0
## Chừa góc nhìn lên phần sân phía trên khi camera theo bóng và lỗ.
@export var keep_upper_course_visible: bool = false
## Tọa độ Y thế giới của mép trên khu vực chơi cần giữ trong hình.
@export var upper_course_y: float = -16.0
## Khi bật, giữ cả dải sân trên-dưới và chỉ cho camera di chuyển trong phần dư.
@export var keep_course_height_visible: bool = false
@export var course_vertical_range := Vector2(-16.0, 208.0)


func _ready() -> void:
	_refresh_view()
	if frame_ball_and_hole and keep_course_height_visible:
		_follow_course(0.0, true)
	else:
		_follow_targets()
	make_current()
	reset_smoothing()
	force_update_scroll()
	get_viewport().size_changed.connect(_refresh_view)


func _physics_process(_delta: float) -> void:
	if frame_ball_and_hole and keep_course_height_visible:
		return
	_follow_targets()
	if frame_ball_and_hole:
		_frame_pair()


func _process(delta: float) -> void:
	if frame_ball_and_hole and keep_course_height_visible:
		_follow_course(delta)


## Một lần cập nhật mỗi khung vẽ; không đổi zoom hoặc reset smoothing khi bóng lăn.
func _follow_course(delta: float, snap: bool = false) -> void:
	if not is_instance_valid(target):
		return
	var half_view := get_viewport_rect().size / zoom * 0.5
	var min_center := Vector2(limit_left, limit_top) + half_view
	var max_center := Vector2(limit_right, limit_bottom) - half_view
	var course_top := minf(course_vertical_range.x, course_vertical_range.y)
	var course_bottom := maxf(course_vertical_range.x, course_vertical_range.y)
	min_center.y = maxf(min_center.y, course_bottom - half_view.y)
	max_center.y = minf(max_center.y, course_top + half_view.y)
	# Chống sai số tại trục vừa khít map và cửa sổ có tỷ lệ hẹp hơn sân.
	if min_center.x > max_center.x:
		min_center.x = (limit_left + limit_right) * 0.5
		max_center.x = min_center.x
	if min_center.y > max_center.y:
		min_center.y = (course_top + course_bottom) * 0.5
		max_center.y = min_center.y
	var destination := target.global_position.clamp(min_center, max_center)
	var weight := 1.0 if snap else 1.0 - exp(-maxf(position_smoothing_speed, 0.0) * delta)
	global_position = global_position.lerp(destination, weight).clamp(min_center, max_center)


func _follow_targets() -> void:
	if is_instance_valid(target):
		global_position = target.global_position
		if is_instance_valid(hole):
			global_position = (target.global_position + hole.global_position) * 0.5
			if frame_ball_and_hole and keep_upper_course_visible:
				var top := minf(minf(target.global_position.y, hole.global_position.y), upper_course_y)
				var bottom := maxf(target.global_position.y, hole.global_position.y)
				global_position.y = (top + bottom) * 0.5


func _frame_pair() -> void:
	if not is_instance_valid(target) or not is_instance_valid(hole):
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var separation := (target.global_position - hole.global_position).abs()
	if keep_upper_course_visible:
		separation.y = maxf(target.global_position.y, hole.global_position.y) \
			- minf(minf(target.global_position.y, hole.global_position.y), upper_course_y)
	var required := separation + Vector2.ONE * maxf(framing_margin, 0.0) * 2.0
	var size := Vector2(maxf(view_size.x, required.x), maxf(view_size.y, required.y))
	zoom = Vector2.ONE * minf(viewport_size.x / maxf(size.x, 1.0),
		viewport_size.y / maxf(size.y, 1.0))
	# Giới hạn mức zoom-out để khung nhìn luôn nằm trong hình chữ nhật của map.
	var map_size := Vector2(limit_right - limit_left, limit_bottom - limit_top)
	if map_size.x > 0.0 and map_size.y > 0.0:
		var minimum_zoom := maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y)
		zoom = Vector2.ONE * maxf(zoom.x, minimum_zoom)
		var half_view := viewport_size / zoom * 0.5
		global_position = Vector2(
			clampf(global_position.x, limit_left + half_view.x, limit_right - half_view.x),
			clampf(global_position.y, limit_top + half_view.y, limit_bottom - half_view.y))
	if keep_course_height_visible:
		var course_top := minf(course_vertical_range.x, course_vertical_range.y)
		var course_bottom := maxf(course_vertical_range.x, course_vertical_range.y)
		var height := maxf(course_bottom - course_top, 1.0)
		# Đủ cao để thấy cả sân; vẫn giữ giới hạn map ở tỷ lệ cửa sổ hiện tại.
		var fitted_zoom := minf(zoom.x, viewport_size.y / height)
		if map_size.x > 0.0 and map_size.y > 0.0:
			fitted_zoom = maxf(fitted_zoom,
				maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y))
		zoom = Vector2.ONE * fitted_zoom
		var half_view := viewport_size / zoom * 0.5
		var lowest_center := maxf(limit_top + half_view.y, course_bottom - half_view.y)
		var highest_center := minf(limit_bottom - half_view.y, course_top + half_view.y)
		if lowest_center <= highest_center:
			global_position.y = clampf(target.global_position.y, lowest_center, highest_center)
		global_position.x = clampf(target.global_position.x,
			limit_left + half_view.x, limit_right - half_view.x)
		# Đổi tâm/zoom không được để phần bám mượt cũ kéo mép sân ra khỏi hình.
		var actual_center := get_screen_center_position()
		if actual_center.y + half_view.y < course_bottom \
				or actual_center.y - half_view.y > course_top:
			reset_smoothing()
	# Nếu bóng di chuyển nhanh hơn phần bám mượt, kéo tâm về để không mất bóng hoặc lỗ.
	var visible_half := viewport_size / zoom * 0.5
	var center := get_screen_center_position()
	for point in [target.global_position, hole.global_position]:
		var offset: Vector2 = (point - center).abs()
		if offset.x > visible_half.x - 16.0 or offset.y > visible_half.y - 16.0:
			reset_smoothing()
			break


func _refresh_view() -> void:
	var viewport_size := get_viewport_rect().size
	if not viewport_size.x > 0.0 or not viewport_size.y > 0.0:
		return
	# Giữ cùng tỷ lệ hai trục để hình bóng không bị kéo méo khi đổi cửa sổ.
	var zoom_factor := minf(viewport_size.x / maxf(view_size.x, 1.0),
		viewport_size.y / maxf(view_size.y, 1.0))
	if is_instance_valid(tile_map) and tile_map.tile_set != null:
		var cells := tile_map.get_used_rect()
		if cells.has_area():
			var tile_size := Vector2(tile_map.tile_set.tile_size)
			var local_bounds := Rect2(Vector2(cells.position) * tile_size,
				Vector2(cells.size) * tile_size)
			var bounds := tile_map.global_transform * local_bounds
			limit_left = floori(bounds.position.x)
			limit_top = floori(bounds.position.y)
			limit_right = ceili(bounds.end.x)
			limit_bottom = ceili(bounds.end.y)
			# Cửa sổ rộng/cao cũng không nhìn vượt quá biên sân.
			zoom_factor = maxf(zoom_factor, maxf(viewport_size.x / bounds.size.x,
				viewport_size.y / bounds.size.y))
	zoom = Vector2.ONE * zoom_factor
	if frame_ball_and_hole and keep_course_height_visible:
		var height := maxf(absf(course_vertical_range.y - course_vertical_range.x), 1.0)
		var desired_zoom := minf(viewport_size.x / maxf(view_size.x, 1.0),
			minf(viewport_size.y / maxf(view_size.y, 1.0), viewport_size.y / height))
		var map_size := Vector2(limit_right - limit_left, limit_bottom - limit_top)
		if map_size.x > 0.0 and map_size.y > 0.0:
			desired_zoom = maxf(desired_zoom,
				maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y))
		zoom = Vector2.ONE * desired_zoom
		_follow_course(0.0, true)
	elif frame_ball_and_hole:
		_frame_pair()
	reset_smoothing()
	force_update_scroll()
