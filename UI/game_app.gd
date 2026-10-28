extends Node

const Assets = preload("res://UI/ui_assets.gd")
const Catalog = preload("res://Game/course_catalog.gd")
const Progress = preload("res://Game/progress_store.gd")
const Audio = preload("res://Game/audio_director.gd")
const CourseCamera = preload("res://Maps/course_follow_camera.gd")
const DESIGN_SIZE := Vector2(640, 360)

var catalog := Catalog.new()
var progress := Progress.new()
var ui: Control
var page: Control
var modal: Control
var course_container: SubViewportContainer
var course_viewport: SubViewport
var course: Node2D
var ball: RigidBody2D
var current_course := 0
var screen := "menu"
var modal_kind := ""
var strokes_label: Label
var status_label: Label
var power: TextureProgressBar
var result_strokes := 0
var result_stars := 0
var result_best := 0
var _attempt_id := 0
var audio: Node
var _completion_pending := false
var _quitting := false
var _completion_timer: Timer
var _star_timer: Timer
var _pending_result_attempt := -1
var _star_attempt := -1
var _remaining_star_sounds := 0
var _hud_top: Control
var _hud_bottom: Control
var _hud_top_panel: Panel
var _hud_bottom_panel: Panel
var _hud_target: Label
var _hud_restart: Button
var _hud_pause: Button
var _hud_power_label: Label
var _quit_previous_modal := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	progress.load_progress()
	if progress.load_status == "new":
		progress.save()
	get_tree().auto_accept_quit = false
	_completion_timer = Timer.new()
	_completion_timer.name = "CourseResultDelay"
	_completion_timer.wait_time = 0.4
	_completion_timer.one_shot = true
	_completion_timer.timeout.connect(_finish_course_result)
	add_child(_completion_timer)
	_star_timer = Timer.new()
	_star_timer.name = "StarRewardSequence"
	_star_timer.wait_time = 0.18
	_star_timer.timeout.connect(_play_result_star)
	add_child(_star_timer)
	_apply_volumes()
	audio = Audio.new()
	audio.name = "AudioDirector"
	add_child(audio)
	_apply_fullscreen()
	course_container = SubViewportContainer.new()
	course_container.name = "CourseView"
	course_container.stretch = true
	course_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	course_container.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(course_container)
	course_viewport = SubViewport.new()
	course_viewport.name = "CourseViewport"
	course_viewport.handle_input_locally = true
	course_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	course_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	course_container.add_child(course_viewport)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui = Control.new()
	ui.name = "Interface"
	ui.size = DESIGN_SIZE
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ui.theme = Assets.theme()
	layer.add_child(ui)
	get_viewport().size_changed.connect(_resize)
	_resize()
	show_menu()
	if progress.load_status in ["recovered", "damaged", "unsupported"] or progress.save_error != OK:
		_show_save_notice.call_deferred()


func _resize() -> void:
	if ui == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	ui.scale = Vector2.ONE * factor
	ui.position = ((viewport_size - DESIGN_SIZE * factor) * 0.5).floor()
	# Fill the window between the HUD bands. Each course camera fits this actual
	# viewport instead of shrinking the game into a second 16:9 frame.
	course_container.position = Vector2(0, 44.0 * factor).floor()
	course_container.size = Vector2(viewport_size.x, viewport_size.y - 84.0 * factor).floor()
	_resize_hud()
	if is_instance_valid(modal):
		var shade := modal.get_node_or_null("ScreenShade") as ColorRect
		if shade != null:
			shade.position = -ui.position / factor
			shade.size = viewport_size / factor


func _resize_hud() -> void:
	if not is_instance_valid(_hud_top) or not is_instance_valid(_hud_bottom):
		return
	var factor := ui.scale.x
	var screen_size := get_viewport().get_visible_rect().size / factor
	_hud_top.position = -ui.position / factor
	_hud_bottom.position = _hud_top.position + Vector2(0, screen_size.y - 40.0)
	_hud_top_panel.size.x = screen_size.x - 16.0
	_hud_bottom_panel.size.x = screen_size.x - 16.0
	_hud_target.size.x = screen_size.x - 432.0
	_hud_restart.position.x = screen_size.x - 96.0
	_hud_pause.position.x = screen_size.x - 56.0
	_hud_power_label.position.x = screen_size.x - 228.0
	power.position.x = screen_size.x - 166.0
	status_label.size.x = screen_size.x - 270.0


func _new_page(id: String) -> void:
	if is_instance_valid(page):
		# Button callbacks run inside GUI input dispatch. Deleting their owner
		# synchronously can leave Godot using the just-freed control on release.
		page.hide()
		page.queue_free()
	page = Control.new()
	page.name = id
	page.size = DESIGN_SIZE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(page)
	screen = id


func _clear_course() -> void:
	_attempt_id += 1
	_completion_pending = false
	_completion_timer.stop()
	_star_timer.stop()
	audio.stop_gameplay_sounds()
	get_tree().paused = false
	_close_modal()
	if is_instance_valid(course):
		course.hide()
		course.process_mode = Node.PROCESS_MODE_DISABLED
		course.queue_free()
	course = null
	ball = null
	course_container.hide()
	current_course = 0


func _rect(node: Control, bounds: Rect2, parent: Node) -> void:
	node.position = bounds.position
	node.size = bounds.size
	parent.add_child(node)


func _image(id: String, bounds: Rect2, parent: Node) -> TextureRect:
	var image := TextureRect.new()
	image.texture = Assets.texture(id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect(image, bounds, parent)
	return image


func _label(text: String, bounds: Rect2, parent: Node, font_size: int = 14, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect(label, bounds, parent)
	return label


func _panel(bounds: Rect2, parent: Node, style_id: String = "panel") -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", Assets.style(style_id))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect(panel, bounds, parent)
	return panel


func _button(text: String, bounds: Rect2, parent: Node, action: Callable, primary: bool = false, cue: String = "menu_click") -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, Assets.style("button_primary_" + state))
		button.add_theme_stylebox_override("focus", Assets.style("button_primary_hover"))
	button.pressed.connect(func(): audio.play_cue(cue, false))
	button.pressed.connect(action)
	_rect(button, bounds, parent)
	return button


func _icon(id: String, bounds: Rect2, parent: Node, hint: String, action: Callable) -> Button:
	var button := _button("", bounds, parent, action, false,
		"menu_back" if id in ["back", "home", "close"] else "menu_click")
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, Assets.style("button_icon_" + state))
	button.add_theme_stylebox_override("focus", Assets.style("button_icon_hover"))
	button.tooltip_text = hint
	_image("icons_" + id, Rect2(Vector2.ZERO, bounds.size), button)
	button.accessibility_name = hint
	return button


func _background() -> void:
	_image("menu_background", Rect2(Vector2.ZERO, DESIGN_SIZE), page)


func _stars(count: int, position: Vector2, parent: Node, large: bool = false) -> void:
	var width := 32.0 if large else 24.0
	for index in 3:
		var id := "star_large_" if large else "star_small_"
		id += "full" if index < count else "empty"
		_image(id, Rect2(position + Vector2(index * width, 0), Vector2.ONE * width), parent)


func show_menu() -> void:
	_clear_course()
	audio.set_context("menu")
	_new_page("menu")
	_background()
	_image("logo", Rect2(208, 34, 224, 64), page)
	_label("TEN COURSES. ONE PERFECT SHOT.", Rect2(128, 104, 384, 20), page, 11, true)
	var play := _button("CONTINUE" if progress.has_started else "PLAY", Rect2(224, 130, 192, 32), page, _continue_game, true)
	_button("NEW GAME", Rect2(224, 166, 192, 32), page, _confirm_new_game)
	_button("SELECT COURSE", Rect2(224, 202, 192, 32), page, show_levels)
	_button("SETTINGS", Rect2(224, 238, 192, 32), page, _show_settings)
	_button("HOW TO PLAY", Rect2(224, 274, 192, 32), page, _show_help)
	_panel(Rect2(248, 308, 144, 24), page)
	_label("%d / 30 STARS" % progress.total_stars(), Rect2(248, 310, 144, 20), page, 11, true)
	_icon("close", Rect2(578, 18, 32, 32), page, "Quit game", _confirm_quit)
	play.grab_focus()


func _continue_game() -> void:
	start_course(clampi(progress.last_course, 1, progress.unlocked))


func _confirm_new_game() -> void:
	var panel := _begin_modal("new_game", Rect2(132, 78, 376, 204), "START A NEW GAME?")
	_label("Reset all course progress, stars and records?", Rect2(12, 54, 352, 24), panel, 11, true)
	_label("Your audio and display settings will be kept.", Rect2(12, 82, 352, 24), panel, 10, true)
	_button("NEW GAME", Rect2(28, 140, 152, 32), panel, _new_game, true)
	_button("CANCEL", Rect2(196, 140, 152, 32), panel, _close_modal).grab_focus()


func _new_game() -> void:
	if not progress.reset_progress():
		var panel := _begin_modal("save_error", Rect2(132, 92, 376, 176), "COULD NOT RESET SAVE")
		_label("Your previous progress has not been reset.", Rect2(12, 54, 352, 24), panel, 11, true)
		_button("BACK", Rect2(92, 116, 192, 32), panel, _close_modal, true)
		return
	start_course(1)


func _show_save_notice() -> void:
	var panel := _begin_modal("save_notice", Rect2(112, 78, 416, 204), "PLAYER DATA")
	var message := "Progress restored from the recovery copy."
	if progress.load_status == "unsupported":
		message = "This save needs a newer version of the game."
	elif progress.load_status == "damaged":
		message = "The save is damaged. New Game can reset it."
	elif progress.save_error != OK:
		message = "Save unavailable. Progress is kept this session."
	_label(message, Rect2(12, 62, 392, 28), panel, 11, true)
	var detail := "A recovery copy is kept automatically when saving."
	if progress.read_only:
		detail = "The unreadable file is kept until you confirm New Game."
	_label(detail, Rect2(12, 96, 392, 20), panel, 9, true)
	_button("OK", Rect2(112, 144, 192, 32), panel, _close_modal, true)


func show_levels() -> void:
	_clear_course()
	audio.set_context("menu")
	_new_page("levels")
	_background()
	_panel(Rect2(34, 26, 572, 308), page)
	_icon("back", Rect2(46, 38, 32, 32), page, "Back to menu", show_menu)
	_label("SELECT COURSE", Rect2(168, 38, 304, 32), page, 18, true)
	_label("%d / 30 STARS" % progress.total_stars(), Rect2(224, 298, 192, 20), page, 12, true)
	for index in 10:
		var number := index + 1
		var position := Vector2(52 + (index % 5) * 108, 88 + (index / 5) * 100)
		var unlocked := number <= progress.unlocked
		var card := _button("", Rect2(position, Vector2(104, 92)), page, start_course.bind(number))
		for state in ["normal", "hover", "pressed"]:
			card.add_theme_stylebox_override(state, Assets.style("level_card_" + state))
		card.add_theme_stylebox_override("disabled", Assets.style("level_card_locked"))
		card.add_theme_stylebox_override("focus", Assets.style("level_card_hover"))
		card.disabled = not unlocked
		card.tooltip_text = "Course %02d - 3 stars: %d strokes" % [number, catalog.target(number)] if unlocked else "Complete course %02d to unlock" % (number - 1)
		_label("%02d" % number, Rect2(8, 6, 88, 24), card, 18, true)
		if unlocked:
			_stars(int(progress.earned_stars.get(number, 0)), Vector2(16, 32), card)
			var best := "BEST %d" % int(progress.best[number]) if progress.best.has(number) else "%d FOR 3 STARS" % catalog.target(number)
			_label(best, Rect2(4, 66, 96, 16), card, 9, true)
		else:
			_image("lock", Rect2(36, 34, 32, 32), card)


func start_course(number: int) -> void:
	if number < 1 or number > Catalog.COUNT or number > progress.unlocked:
		return
	_clear_course()
	current_course = number
	progress.begin_course(number)
	var packed := load(catalog.path(number)) as PackedScene
	if packed == null:
		show_levels()
		return
	course = packed.instantiate() as Node2D
	# The UI needs one consistent framing policy, including the old fixed camera
	# in course 3. Keep authored F6 cameras and every map asset unchanged.
	var authored_camera := course.get_node("Camera2D") as Camera2D
	if authored_camera.get_script() != CourseCamera:
		course.remove_child(authored_camera)
		authored_camera.free()
		authored_camera = CourseCamera.new()
		authored_camera.name = "Camera2D"
		course.add_child(authored_camera)
	authored_camera.target = course.get_node("Ball")
	authored_camera.tile_map = course.get_node("TileMap")
	authored_camera.frame_entire_course = true
	course_viewport.add_child(course)
	ball = course.get_node("Ball") as RigidBody2D
	ball.stroke_count_changed.connect(_update_strokes)
	course.get_node("Hole").completed.connect(_course_completed)
	# The host owns restart/results. Standalone scenes keep their original R shortcut.
	course.get_node("Hole").set_process_unhandled_key_input(false)
	_bind_course_audio(course)
	audio.set_context("playing")
	course_container.show()
	_new_page("playing")
	_build_hud()
	_update_strokes(ball.stroke_count)


func _bind_course_audio(node: Node) -> void:
	if node.has_signal("sound_requested"):
		node.connect("sound_requested", _course_sound.bind(node))
	for child in node.get_children():
		_bind_course_audio(child)


func _course_sound(cue: String, source: Node) -> void:
	if get_tree().paused or screen != "playing":
		return
	# Gates switch repeatedly: distant gates should not distract from the shot.
	if cue == "gate_switch" and source is Node2D and is_instance_valid(ball):
		if source.global_position.distance_to(ball.global_position) > 128.0:
			return
	audio.play_cue(cue)


func _build_hud() -> void:
	_hud_top = Control.new()
	_hud_top.name = "HUDTop"
	_hud_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(_hud_top)
	_hud_bottom = Control.new()
	_hud_bottom.name = "HUDBottom"
	_hud_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(_hud_bottom)
	_hud_top_panel = _panel(Rect2(8, 6, 624, 32), _hud_top)
	_panel(Rect2(8, 6, 260, 32), _hud_top, "hud_panel")
	_label("COURSE %02d / 10" % current_course, Rect2(20, 12, 132, 20), _hud_top, 12)
	strokes_label = _label("STROKES 0", Rect2(160, 12, 100, 20), _hud_top, 12)
	_hud_target = _label("3 STARS: %d STROKES" % catalog.target(current_course), Rect2(282, 12, 208, 20), _hud_top, 11)
	_hud_restart = _icon("restart", Rect2(544, 6, 32, 32), _hud_top, "Restart course (R)", _confirm_restart)
	_hud_pause = _icon("pause", Rect2(584, 6, 32, 32), _hud_top, "Pause (Esc)", _show_pause)
	_hud_bottom_panel = _panel(Rect2(8, 6, 624, 28), _hud_bottom)
	status_label = _label("Click the ball, drag back, release.", Rect2(18, 10, 370, 20), _hud_bottom, 10)
	_hud_power_label = _label("POWER", Rect2(412, 12, 58, 16), _hud_bottom, 10)
	power = TextureProgressBar.new()
	power.texture_under = Assets.texture("power_frame")
	power.texture_progress = Assets.texture("power_fill")
	# The frame includes an opaque trough. Keep it underneath the yellow fill;
	# using it as texture_over hides the meter at every power level.
	power.nine_patch_stretch = true
	power.stretch_margin_left = 2
	power.stretch_margin_right = 2
	power.stretch_margin_top = 2
	power.stretch_margin_bottom = 2
	power.max_value = 1.0
	power.step = 0.001
	power.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect(power, Rect2(474, 10, 146, 20), _hud_bottom)
	_resize_hud()


func _update_strokes(count: int) -> void:
	if is_instance_valid(strokes_label):
		strokes_label.text = "STROKES %d" % count


func _process(_delta: float) -> void:
	if screen != "playing" or not is_instance_valid(ball) or not is_instance_valid(power):
		return
	power.value = ball._drag_offset.length() / maxf(ball.max_drag_distance, 1.0)
	if ball.is_in_water:
		status_label.text = "Water! Returning to your last shot."
	elif ball.is_sunk:
		status_label.text = "Nice shot!"
	elif ball._is_dragging:
		status_label.text = "Release to shoot. Drag farther for more power."
	elif ball.linear_velocity.length() > 1.0:
		status_label.text = "Ball rolling..."
	else:
		status_label.text = "Click the ball, drag back, release."


func _begin_modal(kind: String, bounds: Rect2, title: String) -> Panel:
	_close_modal()
	modal_kind = kind
	modal = Control.new()
	modal.name = kind
	modal.size = DESIGN_SIZE
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(modal)
	var shade := ColorRect.new()
	shade.name = "ScreenShade"
	shade.color = Color(0.04, 0.07, 0.08, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_rect(shade, Rect2(-ui.position / ui.scale.x, get_viewport().get_visible_rect().size / ui.scale.x), modal)
	var panel := _panel(bounds, modal)
	_label(title, Rect2(16, 12, bounds.size.x - 32, 32), panel, 18, true)
	return panel


func _close_modal() -> void:
	if is_instance_valid(modal):
		modal.hide()
		modal.queue_free()
	modal = null
	modal_kind = ""


func _pause_game() -> void:
	if is_instance_valid(ball):
		ball._cancel_drag()
	get_tree().paused = true
	audio.set_context("paused")


func _resume() -> void:
	_close_modal()
	get_tree().paused = false
	audio.set_context("playing")


func _show_pause() -> void:
	if screen != "playing" or modal_kind == "result":
		return
	_pause_game()
	var panel := _begin_modal("pause", Rect2(188, 46, 264, 268), "PAUSED")
	var resume := _button("RESUME", Rect2(36, 62, 192, 32), panel, _resume, true)
	_button("RESTART", Rect2(36, 104, 192, 32), panel, _confirm_restart)
	_button("SETTINGS", Rect2(36, 146, 192, 32), panel, _show_settings)
	_button("SELECT COURSE", Rect2(36, 188, 192, 32), panel, show_levels)
	_label("ESC TO RESUME", Rect2(36, 230, 192, 18), panel, 10, true)
	resume.grab_focus()


func _confirm_restart() -> void:
	_pause_game()
	var panel := _begin_modal("restart", Rect2(160, 102, 320, 156), "RESTART COURSE?")
	_label("This attempt will be reset.", Rect2(16, 48, 288, 24), panel, 12, true)
	_button("RESTART", Rect2(16, 96, 136, 32), panel, _restart, true)
	_button("CANCEL", Rect2(168, 96, 136, 32), panel, _show_pause).grab_focus()


func _restart() -> void:
	var number := current_course
	start_course(number)


func _course_completed() -> void:
	if screen != "playing" or modal_kind == "result" or _completion_pending:
		return
	_completion_pending = true
	result_strokes = ball.stroke_count
	result_stars = catalog.stars(current_course, result_strokes)
	result_best = mini(int(progress.best.get(current_course, result_strokes)), result_strokes)
	progress.record(current_course, result_strokes, result_stars)
	_pending_result_attempt = _attempt_id
	_completion_timer.start()


func _finish_course_result() -> void:
	if screen != "playing" or not is_instance_valid(ball) or _pending_result_attempt != _attempt_id:
		return
	if modal_kind == "quit":
		# Keep the user's quit decision visible. Cancel restores the finished result.
		return
	_show_result()


func _show_result(play_rewards: bool = true) -> void:
	_pause_game()
	audio.set_context("result")
	if play_rewards:
		audio.play_cue("course_complete", false)
		_star_attempt = _attempt_id
		_remaining_star_sounds = result_stars
		if _remaining_star_sounds > 0:
			_star_timer.start()
	var final_course := current_course == Catalog.COUNT
	var panel := _begin_modal("result", Rect2(156, 26, 328, 308), "COURSE COMPLETE!" if not final_course else "ALL COURSES COMPLETE!")
	_stars(result_stars, Vector2(116, 52), panel, true)
	_label("STROKES  %d     BEST  %d" % [result_strokes, result_best], Rect2(16, 92, 296, 26), panel, 14, true)
	var target_text := "3 STARS: %d STROKES OR LESS" % catalog.target(current_course)
	_label(target_text, Rect2(16, 120, 296, 20), panel, 10, true)
	if progress.save_error != OK:
		_label("Save failed. Progress kept for this session.", Rect2(8, 143, 312, 18), panel, 9, true)
	elif final_course:
		_label("%d / 30 STARS - THANKS FOR PLAYING!" % progress.total_stars(), Rect2(8, 143, 312, 18), panel, 10, true)
	var next := _button("NEXT COURSE" if not final_course else "SELECT COURSE", Rect2(68, 172, 192, 32), panel, _next_course if not final_course else show_levels, true)
	_button("PLAY AGAIN", Rect2(68, 214, 192, 32), panel, _restart)
	_icon("home", Rect2(280, 260, 32, 32), panel, "Main menu", show_menu)
	_icon("back", Rect2(16, 260, 32, 32), panel, "Select course", show_levels)
	next.grab_focus()


func _play_result_star() -> void:
	if _star_attempt != _attempt_id or modal_kind != "result" or _remaining_star_sounds <= 0:
		_star_timer.stop()
		return
	audio.play_cue("star_reward", false)
	_remaining_star_sounds -= 1
	if _remaining_star_sounds == 0:
		_star_timer.stop()


func _next_course() -> void:
	start_course(current_course + 1)


func _show_settings() -> void:
	var in_game := screen == "playing"
	if in_game:
		_pause_game()
	var panel := _begin_modal("settings", Rect2(124, 38, 392, 284), "SETTINGS")
	_image("audio_icons_music_on", Rect2(28, 64, 32, 32), panel)
	_label("MUSIC", Rect2(72, 66, 116, 28), panel, 13)
	_slider(Rect2(204, 66, 156, 28), panel, progress.music_volume, _music_changed)
	_image("audio_icons_sound_on", Rect2(28, 112, 32, 32), panel)
	_label("SOUND", Rect2(72, 114, 116, 28), panel, 13)
	_slider(Rect2(204, 114, 156, 28), panel, progress.sound_volume, _sound_changed)
	var toggle := _button("FULLSCREEN: ON" if progress.fullscreen else "FULLSCREEN: OFF", Rect2(72, 170, 248, 32), panel, func():
		progress.fullscreen = not progress.fullscreen
		_apply_fullscreen()
		progress.save()
		_show_settings())
	toggle.tooltip_text = "Toggle fullscreen display"
	_button("BACK", Rect2(100, 224, 192, 32), panel, _settings_back, true)
	if progress.save_error != OK:
		_label("Save unavailable. Progress is kept this session.", Rect2(12, 146, 368, 18), panel, 9, true)


func _slider(bounds: Rect2, parent: Node, value: float, changed: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.value_changed.connect(changed)
	_rect(slider, bounds, parent)
	return slider


func _music_changed(value: float) -> void:
	progress.music_volume = value
	_apply_volumes()
	progress.save()


func _sound_changed(value: float) -> void:
	progress.sound_volume = value
	_apply_volumes()
	progress.save()


func _apply_volumes() -> void:
	for entry in [["Music", progress.music_volume], ["SFX", progress.sound_volume]]:
		var index := AudioServer.get_bus_index(entry[0])
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, entry[0])
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(float(entry[1]), 0.001)))
		AudioServer.set_bus_mute(index, float(entry[1]) <= 0.0)


func _settings_back() -> void:
	if screen == "playing":
		_show_pause()
	else:
		_close_modal()


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if progress.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func _show_help() -> void:
	var panel := _begin_modal("help", Rect2(80, 28, 480, 304), "HOW TO PLAY")
	for index in 3:
		var id: String = ["press", "drag", "release"][index]
		_image("mouse_drag_hint_" + id, Rect2(46 + index * 140, 58, 96, 64), panel)
		_label(["CLICK BALL", "DRAG BACK", "RELEASE"][index], Rect2(24 + index * 140, 126, 140, 20), panel, 11, true)
	_label("Drag farther for more power. Wait for the ball to stop.", Rect2(20, 158, 440, 22), panel, 11, true)
	_label("Sand slows you. Water adds a penalty stroke.", Rect2(20, 184, 440, 22), panel, 11, true)
	_label("Arrows redirect and boost. Portals connect the course.", Rect2(20, 210, 440, 22), panel, 10, true)
	_button("GOT IT", Rect2(144, 250, 192, 32), panel, _close_modal, true).grab_focus()


func _confirm_quit() -> void:
	if modal_kind != "quit":
		_quit_previous_modal = modal_kind
	if screen == "playing":
		_pause_game()
	var panel := _begin_modal("quit", Rect2(160, 102, 320, 156), "QUIT GAME?")
	_label("Your completed courses are saved." if progress.save_error == OK else "Save failed. Quit without saving?", Rect2(12, 48, 296, 24), panel, 11, true)
	_button("QUIT", Rect2(16, 96, 136, 32), panel, _quit_game.bind(true), true)
	_button("CANCEL", Rect2(168, 96, 136, 32), panel, _cancel_quit).grab_focus()


func _cancel_quit() -> void:
	if screen == "playing":
		if _completion_pending and (_quit_previous_modal == "result" or _completion_timer.is_stopped()):
			_show_result(false)
		else:
			_show_pause()
	else:
		match _quit_previous_modal:
			"settings": _show_settings()
			"help": _show_help()
			"new_game": _confirm_new_game()
			"save_notice": _show_save_notice()
			_: _close_modal()


func _quit_game(force: bool = false) -> void:
	if _quitting:
		return
	progress.save()
	if progress.save_error != OK and not force:
		_confirm_quit()
		return
	_quitting = true
	_clear_course()
	ui.hide()
	audio.shutdown()
	# AudioServer retires stopped playbacks asynchronously. Measure wall time: a
	# SceneTreeTimer created during startup can consume that frame's loading delta
	# and expire immediately, before the audio thread has released its references.
	var audio_deadline := Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < audio_deadline:
		await get_tree().process_frame
	get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	if _quitting:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if modal_kind == "quit":
			_cancel_quit()
		elif screen == "playing":
			if modal_kind == "pause":
				_resume()
			elif modal_kind == "":
				_show_pause()
			elif modal_kind != "result":
				_show_pause()
		elif is_instance_valid(modal):
			_close_modal()
		elif screen == "levels":
			show_menu()
	elif event.keycode == KEY_R and screen == "playing" and modal_kind == "":
		get_viewport().set_input_as_handled()
		_confirm_restart()


func _notification(what: int) -> void:
	if _quitting or not is_inside_tree():
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_game()
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "playing" and modal_kind == "":
		_show_pause()
