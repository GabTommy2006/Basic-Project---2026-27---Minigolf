# Standalone listening room for comparing the approved source audio.
extends Control

const Assets = preload("res://UI/ui_assets.gd")
const ROOT := "res://ArtDrafts/AudioReview/"
var player: AudioStreamPlayer
var status: Label

func _ready() -> void:
	theme = Assets.theme()
	var background := TextureRect.new()
	background.texture = Assets.texture("menu_background")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 32)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var title := Label.new()
	title.text = "SUMMER MINIGOLF - AUDIO AUDITION"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	status = Label.new()
	status.text = "Click to preview an approved sound. Stop ends playback."
	column.add_child(status)
	var stop := Button.new()
	stop.text = "STOP"
	stop.custom_minimum_size.y = 36
	column.add_child(stop)
	player = AudioStreamPlayer.new()
	player.volume_db = -10.0
	add_child(player)
	stop.pressed.connect(player.stop)
	var volume := HSlider.new()
	volume.min_value = -35
	volume.max_value = 0
	volume.value = -10
	volume.custom_minimum_size.y = 30
	volume.value_changed.connect(func(value: float): player.volume_db = value)
	column.add_child(volume)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "selection.json"))
	if not manifest is Dictionary:
		status.text = "Audio files are not available. See Docs/AudioSelection.md."
		return
	for entry in manifest.candidates:
		var button := Button.new()
		button.text = entry.title + "  |  " + entry.creator + "  |  CC0"
		button.custom_minimum_size.y = 40
		button.pressed.connect(_play.bind(entry))
		list.add_child(button)

func _play(entry: Dictionary) -> void:
	player.stop()
	var path: String = ROOT + entry.file
	if path.get_extension() == "ogg":
		player.stream = AudioStreamOggVorbis.load_from_file(path)
	elif path.get_extension() == "wav":
		player.stream = AudioStreamWAV.load_from_file(path)
	else:
		return
	if player.stream != null:
		status.text = entry.title + "  -  " + entry.source
		player.play()
