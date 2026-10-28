# Attach to an external QA scene via override.cfg beside a copy of the exported EXE.
# No real player save is touched. Release templates do not support --script.
extends Node

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("BUILD_FAIL: ", message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] not in ["write", "read-reset"] or not args[1].is_absolute_path():
		get_tree().quit(2)
		return
	var folder := args[1]
	var phase := args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	check(OS.has_feature("template") and OS.has_feature("release") and not OS.is_debug_build(), "Real standalone release binary")
	check(not FileAccess.file_exists("res://project.godot"), "Uses packed project.binary")
	check(not ResourceLoader.exists("res://Tests/game_ui_smoke.gd"), "Tests excluded from shipping pack")
	check(FileAccess.file_exists("res://Game/courses.json"), "Star configuration included")
	var scene = load("res://UI/Main.tscn")
	if scene == null:
		check(false, "Packed main scene loads")
		get_tree().quit(1)
		return
	var app = scene.instantiate()
	app.progress.save_path = folder.path_join("qa_export_profile.cfg")
	get_tree().root.add_child(app)
	check(app.screen == "menu" and app.catalog.courses.size() == 10, "Menu and course catalog")
	check(app.audio.streams.size() == 12 and app.audio.music.stream != null, "Packed audio available")
	if phase == "write":
		app.progress.unlocked = 10
		if DisplayServer.get_name() != "headless":
			app.progress.fullscreen = true
			app._apply_fullscreen()
			for frame in 3:
				await get_tree().process_frame
		for number in range(1, 11):
			app.start_course(number)
			await get_tree().physics_frame
			await get_tree().process_frame
			check(is_instance_valid(app.ball) and app.course.get_node_or_null("Hole") != null, "Packed course %d loads" % number)
			var camera = app.course.get_node("Camera2D")
			camera.force_update_scroll()
			var half_view: Vector2 = Vector2(app.course_viewport.size) / camera.zoom * 0.5
			var visible := Rect2(camera.get_screen_center_position() - half_view, half_view * 2.0)
			check(camera.frame_entire_course and visible.grow(0.1).encloses(camera._course_bounds.grow(8.0)), "Whole packed course remains visible: %d" % number)
			check(absf(app.course_container.size.x - get_viewport().get_visible_rect().size.x) < 1.1, "Gameplay fills fullscreen width")
			if DisplayServer.get_name() != "headless" and number in [3, 8]:
				await RenderingServer.frame_post_draw
				get_tree().root.get_texture().get_image().save_png(folder.path_join("fullscreen-course-%02d.png" % number))
		if DisplayServer.get_name() != "headless":
			app.progress.fullscreen = false
			app._apply_fullscreen()
			for frame in 3:
				await get_tree().process_frame
		app.start_course(1)
		var hole = app.course.get_node("Hole")
		var distance: float = app.ball.global_position.distance_to(hole.global_position)
		var speed := sqrt(2.0 * float(app.ball.rolling_deceleration) * distance + 35.0 * 35.0)
		app.ball._pending_shot = app.ball.global_position.direction_to(hole.global_position) * speed
		for tick in 300:
			await get_tree().physics_frame
			if app.ball.is_sunk:
				break
		await get_tree().create_timer(0.7).timeout
		check(app.modal_kind == "result" and app.progress.best.get(1) == 1, "Actual course completion saves record")
		check(app.progress.earned_stars.get(1) == 3 and app.progress.save_error == OK, "Actual course stars saved")
		app.show_menu()
	else:
		check(app.progress.load_status == "loaded" and app.progress.best.get(1) == 1, "EXE reloads previous process record")
		check(app.progress.earned_stars.get(1) == 3, "EXE reloads stars")
		app._confirm_new_game()
		app._close_modal()
		check(app.progress.best.get(1) == 1, "Cancel keeps record")
		app._new_game()
		check(app.progress.best.is_empty() and app.progress.unlocked == 1 and app.current_course == 1, "New Game resets and starts course 1")
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		check(get_tree().root.get_texture().get_image().save_png(folder.path_join("export-" + phase + ".png")) == OK, "Standalone screenshot")
	print("EXPORT_BUILD_RESULT phase=", phase, " failures=", failures)
	if failures > 0:
		app.audio.shutdown()
		await get_tree().create_timer(0.3).timeout
		get_tree().quit(1)
	else:
		await app._quit_game()
