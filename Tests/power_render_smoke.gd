# External QA scene for a copy of the Release EXE; see Docs/ExportWindows.md.
extends Node

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("POWER_FAIL: ", message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not args[0].is_absolute_path():
		get_tree().quit(2)
		return
	var folder := args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var app = load("res://UI/Main.tscn").instantiate()
	app.progress.save_path = folder.path_join("qa_power.cfg")
	get_tree().root.add_child(app)
	app.start_course(1)
	app.ball.freeze = true
	for frame in 3:
		await get_tree().process_frame
	var camera = app.course.get_node("Camera2D")
	var origin: Vector2 = app.course_container.position + app.ball.get_global_transform_with_canvas().origin
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = origin
	get_tree().root.push_input(press, true)
	check(app.ball._is_dragging, "Real mouse press starts aiming")
	var yellow_counts: Array[int] = []
	for amount in [0.0, 0.25, 0.5, 1.0]:
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.position = origin + Vector2(app.ball.max_drag_distance * camera.zoom.x * amount, 0)
		get_tree().root.push_input(motion, true)
		for frame in 2:
			await get_tree().process_frame
		check(absf(app.power.value - amount) < 0.01, "Power value follows actual drag: %s" % amount)
		await RenderingServer.frame_post_draw
		var image := get_tree().root.get_texture().get_image()
		image.save_png(folder.path_join("power-%03d.png" % roundi(amount * 100)))
		var rect: Rect2 = app.power.get_global_rect()
		var scale := Vector2(image.get_size()) / get_viewport().get_visible_rect().size
		var pixels := Rect2i((rect.position * scale).ceil(), (rect.size * scale).floor())
		var yellow := 0
		for y in range(pixels.position.y, pixels.end.y):
			for x in range(pixels.position.x, pixels.end.x):
				var color := image.get_pixel(x, y)
				if color.r > 0.7 and color.g > 0.6 and color.b < 0.35:
					yellow += 1
		yellow_counts.append(yellow)
	check(yellow_counts[0] == 0, "Empty meter before dragging")
	check(yellow_counts[1] > 0 and yellow_counts[2] > yellow_counts[1] and yellow_counts[3] > yellow_counts[2],
		"Visible yellow fill grows at 25/50/100 percent")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = origin + Vector2(app.ball.max_drag_distance * camera.zoom.x, 0)
	get_tree().root.push_input(release, true)
	for frame in 2:
		await get_tree().process_frame
	check(is_zero_approx(app.power.value) and (app.ball._pending_shot.length() > 0.0 or app.ball.stroke_count == 1), "Release shoots and resets meter")
	print("POWER_RENDER_RESULT failures=", failures, " yellow_pixels=", yellow_counts)
	await app._quit_game()
