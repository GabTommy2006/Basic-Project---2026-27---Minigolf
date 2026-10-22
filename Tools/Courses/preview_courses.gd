# Xuất ảnh tổng quan từ mười scene thật; đây là công cụ xem sân, không phải HUD trong game.
# Chạy PreviewCourses.tscn bằng F6 hoặc thêm -- --capture để lưu PNG rồi tự đóng.
extends Node

## Dùng viewport riêng lớn hơn cửa sổ để ảnh tổng quan vẫn rõ khi có mười sân.
func _ready() -> void:
	var preview := SubViewport.new()
	preview.size = Vector2i(1280, 1800)
	preview.world_2d = World2D.new()
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(preview)
	var background := ColorRect.new()
	background.size = Vector2(1280, 1800)
	background.color = Color("142923")
	preview.add_child(background)
	for number in range(1, 11):
		var course: Node2D = load("res://Maps/Courses/Map%02d.tscn" % number).instantiate()
		# Mọi sân cùng nằm trong ảnh tổng quan, không dùng camera riêng của từng sân ở đây.
		course.get_node("Camera2D").enabled = false
		var column := (number - 1) % 2
		var row := floori(float(number - 1) / 2.0)
		var origin := Vector2(48 + column * 624, 50 + row * 352)
		course.position = origin
		course.scale = Vector2(1.4, 1.4)
		preview.add_child(course)
		var label := Label.new()
		label.position = origin + Vector2(0, -34)
		label.add_theme_font_size_override("font_size", 22)
		label.modulate = Color("ffebba")
		label.text = "%02d — %s" % [number, course.course_title]
		preview.add_child(label)
	# Có một cửa sổ xem thu nhỏ để chạy F6; ảnh lưu vẫn giữ độ phân giải viewport gốc.
	var display := TextureRect.new()
	display.texture = preview.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.size = get_viewport().get_visible_rect().size
	add_child(display)
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	preview.get_texture().get_image().save_png("res://output/courses_overview.png")
	print("COURSES_PREVIEW saved res://output/courses_overview.png")
	if "--capture" in OS.get_cmdline_user_args():
		get_tree().quit()
