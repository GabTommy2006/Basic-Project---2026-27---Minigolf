extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var app = load("res://UI/Main.tscn").instantiate()
	app.progress.save_path = "res://tmp/ui-check/framing-qa.cfg"
	root.add_child(app)
	app.progress.unlocked = 10
	for window_size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1920, 800), Vector2i(1024, 768), Vector2i(720, 1280)]:
		root.size = window_size
		await process_frame
		await process_frame
		app._resize()
		for number in range(1, 11):
			app.start_course(number)
			app.ball.freeze = true
			await process_frame
			await process_frame
			var camera = app.course.get_node("Camera2D")
			camera.set_process(false)
			camera._refresh_view()
			var viewport_rect := Rect2(Vector2.ZERO, Vector2(app.course_viewport.size))
			var root_size: Vector2 = root.get_visible_rect().size
			check(absf(app.course_container.position.x) < 0.1 and absf(viewport_rect.size.x - root_size.x) < 1.1,
				"Full-width gameplay without side gutters, map %d at %s" % [number, window_size])
			var top_rect: Rect2 = app._hud_top_panel.get_global_rect()
			var bottom_rect: Rect2 = app._hud_bottom_panel.get_global_rect()
			check(top_rect.end.y <= app.course_container.position.y + 0.1, "Top HUD stays above course")
			check(bottom_rect.position.y >= app.course_container.position.y + app.course_container.size.y - 0.1, "Bottom HUD stays below course")
			check(absf(top_rect.position.x - 8.0 * app.ui.scale.x) < 0.1 and absf(top_rect.end.x - (root_size.x - 8.0 * app.ui.scale.x)) < 0.1,
				"HUD spans window and stays anchored on resize")
			var bounds: Rect2 = camera._course_bounds
			var framed: Rect2 = bounds.grow(8.0)
			var initial_zoom: Vector2 = camera.zoom
			var expected_zoom := minf(viewport_rect.size.x / framed.size.x, viewport_rect.size.y / framed.size.y)
			check(is_equal_approx(camera.zoom.x, expected_zoom) and is_equal_approx(camera.zoom.x, camera.zoom.y),
				"Largest undistorted zoom that shows the whole course")
			var destinations: Array[Vector2] = []
			for point in [bounds.position + Vector2.ONE * 8.0, bounds.end - Vector2.ONE * 8.0, bounds.get_center()]:
				app.ball.global_position = point
				destinations.append(camera._destination())
				var previous: Vector2 = camera.global_position
				for frame in 35:
					camera._process(1.0 / 60.0)
					camera.force_update_scroll()
					var half_view: Vector2 = viewport_rect.size / camera.zoom * 0.5
					var visible := Rect2(camera.get_screen_center_position() - half_view, half_view * 2.0)
					check(visible.grow(0.1).encloses(framed), "Every playable edge remains visible while camera follows: map %d" % number)
					check(camera.zoom.is_equal_approx(initial_zoom), "Zoom stays steady during shots")
					check(camera.global_position.distance_to(camera._destination()) <= previous.distance_to(camera._destination()) + 0.01,
						"Smooth follow without reverse jitter")
					previous = camera.global_position
			var spare: Vector2 = viewport_rect.size / camera.zoom - framed.size
			if maxf(spare.x, spare.y) > 1.0:
				check(destinations[0].distance_to(destinations[1]) > 0.1, "Camera follows ball within spare view space")
			check(viewport_rect.has_point(app.course.get_node("Hole").get_global_transform_with_canvas().origin), "Hole remains visible")
		print("Framing checked all 10 maps at ", window_size)
	print("GAMEPLAY_FRAMING_RESULT checks=", checks, " failures=", failures)
	await app._quit_game()
