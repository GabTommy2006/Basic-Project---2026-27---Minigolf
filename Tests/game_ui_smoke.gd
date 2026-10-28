extends SceneTree

const STORE = preload("res://Game/progress_store.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/ui-check")
	var app = load("res://UI/Main.tscn").instantiate()
	app.progress.save_path = "res://tmp/ui-check/ui-smoke-save.cfg"
	root.add_child(app)
	app.progress.unlocked = 1
	app.progress.best.clear()
	app.progress.earned_stars.clear()
	app.show_menu()
	check(app.screen == "menu", "Menu boots")
	app.show_levels()
	check(app.screen == "levels", "Level select opens")
	app.start_course(2)
	check(app.current_course == 0, "Locked course cannot start")
	app.start_course(1)
	await process_frame
	check(app.current_course == 1 and app.ball != null, "First course starts")
	check(app.course_viewport.size.y < root.get_visible_rect().size.y, "HUD has dedicated screen area")
	var p: Vector2 = app.course_container.position
	var s: Vector2 = app.course_container.size
	check(p.y > 0.0 and p.y + s.y < root.get_visible_rect().size.y, "Top and bottom HUD never cover course viewport")
	# Feed an actual drag into the gameplay viewport to verify input coordinate routing.
	app.ball.freeze = true
	await process_frame
	var screen_ball: Vector2 = app.ball.get_global_transform_with_canvas().origin
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = app.course_container.position + screen_ball
	root.push_input(press, true)
	check(app.ball._is_dragging, "Viewport mouse press reaches ball")
	for amount in [0.25, 0.5, 1.0]:
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.position = press.position + Vector2(app.ball.max_drag_distance * app.course.get_node("Camera2D").zoom.x * amount, 0)
		root.push_input(motion, true)
		app._process(0.0)
		check(absf(app.power.value - amount) < 0.01, "HUD power follows real drag: %s" % amount)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = app.course_container.position + screen_ball + Vector2(40, 0)
	root.push_input(release, true)
	check(app.ball._pending_shot.length() > 0.0, "Viewport drag queues a real shot")
	app._process(0.0)
	check(is_zero_approx(app.power.value), "HUD power resets after release")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	check(paused and app.modal_kind == "pause", "Pause stops gameplay")
	check(not app.ball.can_process(), "Ball physics pauses")
	check(app.can_process(), "UI continues while paused")
	root.push_input(press, true)
	check(not app.ball._is_dragging, "Pause overlay blocks gameplay clicks")
	root.push_input(release, true)
	app._show_settings()
	check(app.modal_kind == "settings", "Settings work during pause")
	app._music_changed(0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music slider mute works")
	app._settings_back()
	check(app.modal_kind == "pause", "Settings return to pause")
	root.push_input(escape, true)
	check(not paused and app.modal == null, "Resume restores gameplay")
	app.ball.stroke_count = 2
	app._update_strokes(2)
	check(app.strokes_label.text == "STROKES 2", "HUD shows shot count")
	app.ball.sink_into_hole(app.course.get_node("Hole").global_position)
	app.course.get_node("Hole").completed.emit()
	var completed_revision: int = app.progress._revision
	app._course_completed()
	check(app.progress._revision == completed_revision, "Duplicate completion does not save or award twice")
	await create_timer(0.5).timeout
	check(app.modal_kind == "result" and paused, "Completion animation then results")
	check(app.progress.unlocked >= 2 and app.progress.best[1] == 2, "Win saves score and unlocks next course")
	check(app.progress.earned_stars[1] == 3, "Per-course star threshold works")
	check(app.progress.save_error == OK, "Progress saved successfully")
	app._next_course()
	check(app.current_course == 2 and not paused, "Next course starts")
	app._confirm_restart()
	app._restart()
	check(app.current_course == 2 and app.ball.stroke_count == 0, "Restart resets current attempt")
	var store := STORE.new()
	store.save_path = app.progress.save_path
	store.load_progress()
	check(store.best.get(1) == 2 and store.unlocked >= 2, "Progress survives reload")
	store.record(1, 9, 1)
	check(store.best[1] == 2 and store.earned_stars[1] == 3, "Worse attempts preserve best score and stars")
	app.ball.stroke_count = 4
	app._course_completed()
	app._restart()
	await create_timer(0.5).timeout
	check(app.modal == null and not paused, "Delayed old result cannot interrupt a new attempt")
	# Isolated session data: user progress is never touched by this test.
	app.progress.unlocked = 10
	for number in range(1, 11):
		app.start_course(number)
		check(app.course.get_node_or_null("Ball") != null and app.course.get_node_or_null("Hole") != null,
			"Course %d has playable scene bindings" % number)
		check(app.catalog.stars(number, app.catalog.target(number)) == 3, "3-star boundary")
		check(app.catalog.stars(number, app.catalog.target(number) + 2) == 2, "2-star boundary")
		check(app.catalog.stars(number, app.catalog.target(number) + 3) == 1, "1-star boundary")
		await process_frame
		var camera := app.course.get_node("Camera2D") as Camera2D
		camera.force_update_scroll()
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(app.course_viewport.size))
		check(viewport_rect.has_point(app.ball.get_global_transform_with_canvas().origin), "Ball visible in actual HUD viewport: %d" % number)
		check(viewport_rect.has_point(app.course.get_node("Hole").get_global_transform_with_canvas().origin), "Hole visible in actual HUD viewport: %d" % number)
	app.ball.stroke_count = 8
	app._course_completed()
	await create_timer(0.5).timeout
	check(app.current_course == 10 and app.modal_kind == "result", "Course 10 has final result screen")
	app.show_menu()
	check(not paused and app.course == null, "Menu removes gameplay and pause state")
	app._show_help()
	app._close_modal()
	app._show_settings()
	app._settings_back()
	check(app.modal == null, "Menu help/settings close safely")
	var original_unlocked: int = app.progress.unlocked
	app._confirm_new_game()
	check(app.modal_kind == "new_game", "New Game asks for confirmation")
	app._close_modal()
	check(app.progress.unlocked == original_unlocked and not app.progress.best.is_empty(), "Cancelling New Game keeps progress")
	app._confirm_new_game()
	app._new_game()
	check(app.current_course == 1 and app.progress.unlocked == 1 and app.progress.best.is_empty() and app.progress.earned_stars.is_empty(),
		"Confirmed New Game starts course 1 with clean progress")
	app.show_menu()
	app._continue_game()
	check(app.current_course == 1, "Continue uses the stored last course")
	app.queue_free()
	await process_frame
	# Let the audio server release queued playback references before engine shutdown.
	await create_timer(0.25).timeout
	print("GAME_UI_RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
