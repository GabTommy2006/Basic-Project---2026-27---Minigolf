extends SceneTree

const Director = preload("res://Game/audio_director.gd")
var failures := 0
var heard: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", text)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/ui-check")
	var app = load("res://UI/Main.tscn").instantiate()
	app.progress.save_path = "res://tmp/ui-check/audio-smoke-save.cfg"
	root.add_child(app)
	app.progress.unlocked = 10
	app.audio.cue_played.connect(func(cue: String): heard.append(cue))
	check(app.audio.music.playing, "Background music starts in menu")
	check(app.audio.music.stream.loop, "Background music loops")
	check(app.audio.music.bus == "Music", "Background music has dedicated bus")
	for cue in Director.CUES:
		check(app.audio.streams[cue] != null and app.audio.streams[cue].get_length() > 0.0, "Audio asset loads: " + cue)
	app.audio.play_cue("menu_click", false)
	check(heard.has("menu_click"), "Menu sound plays")
	app.start_course(1)
	var music_position: float = app.audio.music.get_playback_position()
	app.ball._pending_shot = Vector2(80, 0)
	for tick in 5:
		await physics_frame
	check(heard.has("golf_shot"), "Actual physics shot emits audio")
	check(app.ball.stroke_count == 1, "Audio does not add strokes")
	check(app.audio.music.playing and app.audio.music.get_playback_position() >= music_position,
		"Starting a course does not restart background music")
	# Exercise the new wall-contact hook with a real collision in an isolated physics stage.
	var stage := Node2D.new()
	stage.position = Vector2(1000, 1000)
	root.add_child(stage)
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16, 48)
	shape.shape = rectangle
	wall.position = Vector2(16, 0)
	wall.add_child(shape)
	stage.add_child(wall)
	var test_ball = load("res://Objects/Ball/Ball.tscn").instantiate()
	test_ball.position = Vector2(50, 0)
	test_ball.rolling_deceleration = 0.0
	stage.add_child(test_ball)
	test_ball.sound_requested.connect(Callable(app.audio, "play_cue"))
	var previous_wall_count := heard.count("wall_contact")
	test_ball.linear_velocity = Vector2(-80, 0)
	for tick in 25:
		await physics_frame
	check(heard.count("wall_contact") > previous_wall_count, "Real wall impact emits contact audio")
	stage.queue_free()
	await create_timer(0.11).timeout
	var wall_count := heard.count("wall_contact")
	for attempt in 20:
		app.audio.play_cue("wall_contact")
	check(heard.count("wall_contact") == wall_count + 1, "Wall collision sounds are rate limited")
	app._show_pause()
	var before := heard.size()
	app.audio.play_cue("water_splash")
	check(heard.size() == before, "Gameplay audio cannot trigger during pause")
	check(app.audio.music.playing and not app.audio.music.stream_paused, "Music continues quietly during pause")
	app.audio.play_cue("menu_back", false)
	check(heard.back() == "menu_back", "Menu controls still sound during pause")
	app._resume()
	app.audio.play_cue("water_splash")
	check(heard.back() == "water_splash", "Gameplay audio resumes")
	app._music_changed(0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music slider mutes its bus")
	app._sound_changed(0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Sound slider mutes its bus")
	app._music_changed(0.45)
	app._sound_changed(0.7)
	app.start_course(6)
	var gate = app.course.get_node_or_null("BlinkingGate")
	if gate != null:
		app.ball.global_position = gate.global_position + Vector2(20, 0)
		gate.sound_requested.emit("gate_switch")
		check(heard.has("gate_switch"), "Gate sound is connected to host")
	app.ball.sink_into_hole(app.course.get_node("Hole").global_position)
	check(heard.has("hole_capture"), "Hole capture plays once")
	app.ball.stroke_count = 3
	app._course_completed()
	await create_timer(1.1).timeout
	check(heard.has("course_complete") and heard.has("star_reward"), "Results and stars play audio")
	check(app.audio.context == "result", "Result screen ducks music")
	app.show_menu()
	check(app.audio.context == "menu" and app.audio.music.playing, "Returning to menu keeps music alive")
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("GAME_AUDIO_RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
