# Run in separate Godot processes. Uses a QA-only profile, never the player's real save.
extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 2 or (args.size() == 3 and args[2] == "project"))
	var phase := args[0]
	var name := args[1]
	assert(name.begins_with("qa_profile_") and name.ends_with(".cfg") and not name.contains("/") and not name.contains("\\"))
	var app = load("res://UI/Main.tscn").instantiate()
	app.progress.save_path = "user://" + name
	if args.size() == 3:
		app.progress.save_path = "res://tmp/ui-check/" + name
	root.add_child(app)
	if phase == "write":
		assert(app.progress.save_error == OK)
		app._music_changed(0.32)
		app._sound_changed(0.68)
		app.start_course(1)
		var hole = app.course.get_node("Hole")
		var distance: float = app.ball.global_position.distance_to(hole.global_position)
		var speed := sqrt(2.0 * float(app.ball.rolling_deceleration) * distance + 35.0 * 35.0)
		app.ball._pending_shot = app.ball.global_position.direction_to(hole.global_position) * speed
		for tick in 300:
			await physics_frame
			if app.ball.is_sunk:
				break
		await create_timer(0.5).timeout
		assert(app.modal_kind == "result" and app.progress.best.get(1) == 1)
		assert(app.progress.earned_stars.get(1) == 3 and app.progress.unlocked == 2)
		assert(app.progress.save_error == OK and app.progress.backup_error == OK)
	elif phase == "read":
		assert(app.progress.load_status == "loaded")
		assert(app.progress.best.get(1) == 1 and app.progress.earned_stars.get(1) == 3)
		assert(app.progress.unlocked == 2 and app.progress.last_course == 2)
		app._continue_game()
		assert(app.current_course == 2)
	elif phase in ["close", "close-pause", "close-result"]:
		assert(app.progress.best.get(1) == 1)
		if phase == "close-pause":
			app._continue_game()
			app._show_pause()
		elif phase == "close-result":
			app.start_course(1)
			app.ball.stroke_count = 1
			app._course_completed()
		print("PROFILE_RESTART_OK phase=", phase)
		await app._quit_game()
		return
	elif phase == "reset":
		assert(app.progress.best.get(1) == 1)
		app._confirm_new_game()
		app._close_modal()
		assert(app.progress.best.get(1) == 1)
		app._confirm_new_game()
		app._new_game()
		assert(app.current_course == 1 and app.progress.best.is_empty())
		assert(app.progress.unlocked == 1 and app.progress.earned_stars.is_empty())
	elif phase == "read-reset":
		assert(app.progress.load_status == "loaded")
		assert(app.progress.best.is_empty() and app.progress.earned_stars.is_empty())
		assert(app.progress.unlocked == 1 and app.progress.last_course == 1)
		app._continue_game()
		assert(app.current_course == 1)
	else:
		assert(false, "Unknown QA phase")
	assert(is_equal_approx(app.progress.music_volume, 0.32))
	assert(is_equal_approx(app.progress.sound_volume, 0.68))
	print("PROFILE_RESTART_OK phase=", phase, " data_dir=", OS.get_user_data_dir())
	app.audio.shutdown()
	await create_timer(0.2).timeout
	app.free()
	paused = false
	await create_timer(0.25).timeout
	quit()
