extends Node

signal cue_played(cue: String)

const ROOT := "res://Assets/Audio/"
# Small gain offsets keep mechanical cues quieter than the shot and completion feedback.
const CUES := {
	"menu_click": -12.0, "menu_back": -12.0,
	"golf_shot": -6.0, "wall_contact": -14.0, "bumper_hit": -11.0,
	"arrow_boost": -14.0, "portal_travel": -12.0, "gate_switch": -22.0,
	"water_splash": -12.0, "hole_capture": -9.0,
	"star_reward": -15.0, "course_complete": -12.0,
}
const COOLDOWN := {"wall_contact": 0.10, "bumper_hit": 0.10, "arrow_boost": 0.10,
	"gate_switch": 0.25, "menu_click": 0.04, "menu_back": 0.04}

var music: AudioStreamPlayer
var players: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var context := "menu"
var _last_played: Dictionary = {}
var _music_fade: Tween
var _gameplay_paused := false
var _shutting_down := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	for cue in CUES:
		streams[cue] = load(ROOT + cue + ".ogg") as AudioStream
	for index in 12:
		var player := AudioStreamPlayer.new()
		player.name = "Effect%02d" % index
		player.bus = "SFX"
		add_child(player)
		players.append(player)
	music = AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	music.bus = "Music"
	var loop := (load(ROOT + "music_sherwood.ogg") as AudioStreamOggVorbis).duplicate() as AudioStreamOggVorbis
	loop.loop = true
	music.stream = loop
	music.volume_db = -40.0
	add_child(music)
	music.play()


func play_cue(cue: String, gameplay: bool = true) -> void:
	if _shutting_down or not streams.has(cue) or (_gameplay_paused and gameplay):
		return
	var now := Time.get_ticks_msec()
	var cooldown_ms := int(float(COOLDOWN.get(cue, 0.0)) * 1000.0)
	if _last_played.has(cue) and now - int(_last_played[cue]) < cooldown_ms:
		return
	var available: AudioStreamPlayer = null
	for player in players:
		if not player.playing:
			available = player
			break
	# Dense collisions cannot stack unlimited voices or interrupt an existing cue.
	if available == null:
		return
	_last_played[cue] = now
	available.stream = streams[cue]
	available.volume_db = float(CUES[cue])
	available.stream_paused = false
	available.set_meta("gameplay", gameplay)
	available.set_meta("cue", cue)
	available.play()
	cue_played.emit(cue)


func set_context(value: String) -> void:
	if _shutting_down:
		return
	context = value
	_gameplay_paused = value == "paused" or value == "result"
	for player in players:
		if bool(player.get_meta("gameplay", false)):
			player.stream_paused = _gameplay_paused
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	var volume := -18.0 if value == "menu" else -22.0
	if _gameplay_paused:
		volume = -28.0
	_music_fade = create_tween()
	_music_fade.tween_property(music, "volume_db", volume, 0.35)


func stop_gameplay_sounds() -> void:
	for player in players:
		if bool(player.get_meta("gameplay", false)) or player.get_meta("cue", "") in ["course_complete", "star_reward"]:
			player.stop()
	_gameplay_paused = false


func _exit_tree() -> void:
	shutdown()


func shutdown() -> void:
	if _shutting_down:
		return
	_shutting_down = true
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	for player in players:
		player.stop()
		player.stream = null
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	streams.clear()
	_music_fade = null
