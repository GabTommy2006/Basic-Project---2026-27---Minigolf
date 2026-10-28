extends SceneTree

var failures := 0
var checks := 0
var cues: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func button_named(node: Node, caption: String) -> Button:
	if node is Button and (node.text == caption or node.tooltip_text == caption):
		return node
	for child in node.get_children():
		var found := button_named(child, caption)
		if found != null:
			return found
	return null

func click(button: Button) -> void:
	check(button != null, "Visible button exists")
	if button == null:
		return
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.position = point
	release.button_index = MOUSE_BUTTON_LEFT
	root.push_input(release, true)
	await process_frame

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)
	await process_frame

func _run() -> void:
	var folder := "res://tmp/ui-edge/%d/" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var app = load("res://UI/Main.tscn").instantiate()
	app.progress.save_path = folder + "qa.cfg"
	root.add_child(app)
	app.audio.cue_played.connect(func(cue: String): cues.append(cue))
	await process_frame
	await click(button_named(app.page, "SELECT COURSE"))
	check(app.screen == "levels", "Actual mouse button opens course selection")
	await escape()
	check(app.screen == "menu", "Esc returns to menu")
	await click(button_named(app.page, "SETTINGS"))
	check(app.modal_kind == "settings", "Actual mouse opens Settings")
	app._confirm_quit()
	await click(button_named(app.modal, "CANCEL"))
	check(app.modal_kind == "settings", "Cancel quit restores menu Settings")
	await escape()
	await click(button_named(app.page, "PLAY"))
	check(app.current_course == 1 and app.modal_kind == "", "Actual mouse starts playable course")
	await click(button_named(app.page, "Pause (Esc)"))
	check(paused and app.modal_kind == "pause", "Actual HUD icon pauses")
	await click(button_named(app.modal, "SETTINGS"))
	await click(button_named(app.modal, "BACK"))
	check(app.modal_kind == "pause", "Settings returns to pause")
	await click(button_named(app.modal, "RESTART"))
	await click(button_named(app.modal, "CANCEL"))
	check(app.modal_kind == "pause", "Cancel restart retains paused attempt")
	await click(button_named(app.modal, "RESUME"))
	check(not paused and app.modal_kind == "", "Actual mouse resumes")
	# Complete a real hole, then simulate a filesystem error when closing the window.
	app.ball.stroke_count = 2
	app.ball.sink_into_hole(app.course.get_node("Hole").global_position)
	app._course_completed()
	await create_timer(0.5).timeout
	check(app.modal_kind == "result", "Completed course has results")
	var file := FileAccess.open(folder + "blocker", FileAccess.WRITE)
	file.store_string("QA I/O blocker")
	file.close()
	var original_path: String = app.progress.save_path
	app.progress.save_path = folder + "blocker/player.cfg"
	app._quit_game()
	check(app.modal_kind == "quit" and not app._quitting, "Failed close offers a cancellable warning")
	var reward_count := cues.count("course_complete")
	await click(button_named(app.modal, "CANCEL"))
	check(app.modal_kind == "result" and paused and app.ball.is_sunk, "Cancel failed quit returns to results, never an unplayable sunk ball")
	check(cues.count("course_complete") == reward_count, "Restoring results does not replay completion reward")
	app._quit_game()
	await escape()
	check(app.modal_kind == "result", "Esc also cancels failed quit back to results")
	app.progress.save_path = original_path
	await click(button_named(app.modal, "NEXT COURSE"))
	check(app.current_course == 2 and not paused, "Next course still works after cancelled failed quit")
	# The result delay must not replace a pending quit confirmation.
	app.ball.stroke_count = 3
	app.ball.sink_into_hole(app.course.get_node("Hole").global_position)
	app._course_completed()
	app.progress.save_path = folder + "blocker/player.cfg"
	app._quit_game()
	await create_timer(0.5).timeout
	check(app.modal_kind == "quit", "Delayed results cannot overwrite a quit decision")
	await click(button_named(app.modal, "CANCEL"))
	check(app.modal_kind == "result", "Cancel pending quit restores the completed result")
	app.progress.save_path = original_path
	app.progress.unlocked = 10
	app.start_course(10)
	app.ball.stroke_count = 7
	app.ball.sink_into_hole(app.course.get_node("Hole").global_position)
	app._course_completed()
	await create_timer(0.5).timeout
	await click(button_named(app.modal, "SELECT COURSE"))
	check(app.screen == "levels" and not paused, "Final course navigates to level selection")
	var loaded = load("res://Game/progress_store.gd").new()
	loaded.save_path = original_path
	loaded.load_progress()
	check(loaded.best.get(10) == 7 and loaded.earned_stars.get(10) == 3, "Final-course record and stars survive reload")
	print("UI_EDGE_RESULT checks=", checks, " failures=", failures)
	await app._quit_game()
