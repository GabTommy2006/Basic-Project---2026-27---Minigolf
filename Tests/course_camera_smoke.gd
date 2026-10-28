extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)


func _run() -> void:
	for number in [4, 5, 6, 7, 8, 9, 10]:
		var scene := load("res://Maps/Courses/Map%d.tscn" % number) as PackedScene
		_check(scene != null, "Scene loads")
		if scene == null:
			continue
		var map := scene.instantiate()
		root.add_child(map)
		var camera = map.get_node("Camera2D")
		var ball = map.get_node("Ball")
		ball.freeze = true
		camera.set_process(false)
		_check(camera.target == ball, "Camera target binding")
		_check(not camera.position_smoothing_enabled, "Only one smoothing implementation")
		var endpoints: Array[Vector2] = []
		for window_size in [Vector2i(1280, 720), Vector2i(1152, 648), Vector2i(720, 1280)]:
			root.size = window_size
			camera._refresh_view()
			var initial_zoom: Vector2 = camera.zoom
			var course: Rect2 = camera._course_bounds
			var corners := [course.position, Vector2(course.end.x, course.position.y),
				course.end, Vector2(course.position.x, course.end.y)]
			for fps in [30, 60, 144]:
				ball.global_position = course.position + Vector2.ONE * 8.0
				camera._refresh_view()
				ball.global_position = course.end - Vector2.ONE * 8.0
				var start: Vector2 = camera.global_position
				var previous := start
				for frame in fps:
					camera._process(1.0 / fps)
					var current: Vector2 = camera.global_position
					_check(current.distance_to(previous) <= start.distance_to(camera._destination()) * 0.25 + 0.01,
						"A target jump must be spread over multiple rendered frames")
					_check(current.distance_to(camera._destination()) <= previous.distance_to(camera._destination()) + 0.01,
						"No reverse jitter or overshoot while approaching target")
					_check(camera.zoom.is_equal_approx(initial_zoom), "Stable zoom during motion")
					camera.force_update_scroll()
					var visible_half: Vector2 = camera.get_viewport_rect().size / camera.zoom * 0.5
					var visible := Rect2(camera.get_screen_center_position() - visible_half, visible_half * 2.0)
					var map_bounds: Rect2 = camera._map_bounds
					_check(map_bounds.grow(0.1).encloses(visible), "Viewport must never extend outside map")
					if visible.size.x >= course.size.x + 16.0 and visible.size.y >= course.size.y + 16.0:
						for corner in corners:
							_check(visible.grow(0.1).has_point(corner), "Whole course visible when it fits")
					previous = current
				_check(camera.global_position.distance_to(start) > 1.0, "Camera actually follows ball")
				endpoints.append(camera.global_position)
				camera.force_update_scroll()
				var screen := Rect2(Vector2.ZERO, camera.get_viewport_rect().size)
				_check(screen.has_point(ball.get_global_transform_with_canvas().origin), "Camera catches up to ball")
				var hole := map.get_node_or_null("Hole") as Node2D
				if hole != null and window_size.x > window_size.y:
					_check(screen.has_point(hole.get_global_transform_with_canvas().origin), "Hole and ball visible together")
			_check(endpoints[-1].distance_to(endpoints[-3]) < 0.02, "Follow independent of frame rate")
		print("Checked map ", number, ": strict map bounds, moving follow, 3 window sizes, 30/60/144 FPS")
		map.queue_free()
		await process_frame
	print("COURSE_CAMERA_RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
