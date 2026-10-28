extends RefCounted

const FORMAT_VERSION := 1
const Catalog = preload("res://Game/course_catalog.gd")

var save_path := "user://summer_golf.cfg"
var unlocked := 1
var last_course := 1
var has_started := false
var best: Dictionary = {}
var earned_stars: Dictionary = {}
var music_volume := 0.45
var sound_volume := 0.7
var fullscreen := false
var save_error := OK
var backup_error := OK
var load_status := "new"
var read_only := false
var _revision := 0


func load_progress() -> void:
	_apply(_defaults())
	_revision = 0
	read_only = false
	save_error = OK
	load_status = "new"
	var selected: Dictionary = {}
	var any_file := false
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = save_path + suffix
		any_file = any_file or FileAccess.file_exists(path)
		var candidate := _read(path)
		if suffix == "" and candidate.get("future", false):
			read_only = true
			load_status = "unsupported"
			save_error = ERR_UNAVAILABLE
			return
		if not candidate.has("payload"):
			continue
		if selected.is_empty() or int(candidate.revision) > int(selected.revision):
			selected = candidate
			selected["suffix"] = suffix
	if selected.is_empty():
		load_status = "damaged" if any_file else "new"
		read_only = any_file
		if any_file:
			save_error = ERR_FILE_CORRUPT
		return
	_apply(selected.payload)
	_revision = int(selected.revision)
	var catalog := Catalog.new()
	for number in best:
		earned_stars[number] = maxi(int(earned_stars.get(number, 0)), catalog.stars(number, best[number]))
		unlocked = maxi(unlocked, mini(int(number) + 1, 10))
	last_course = clampi(last_course, 1, unlocked)
	if int(selected.version) == 0 and not selected.get("has_last_course", false):
		last_course = unlocked
	has_started = has_started or not best.is_empty()
	load_status = "loaded"
	if selected.suffix != "":
		load_status = "recovered"
		save()
	elif int(selected.version) == 0:
		load_status = "migrated"
		save()


func record(number: int, strokes: int, stars: int) -> void:
	if number < 1 or number > 10 or strokes < 1 or strokes > 100000:
		return
	best[number] = mini(int(best.get(number, strokes)), strokes)
	earned_stars[number] = maxi(int(earned_stars.get(number, 0)), clampi(stars, 1, 3))
	unlocked = maxi(unlocked, mini(number + 1, 10))
	last_course = mini(number + 1, 10)
	has_started = true
	save()


func begin_course(number: int) -> void:
	if number < 1 or number > unlocked:
		return
	last_course = number
	has_started = true
	save()


func reset_progress() -> bool:
	var previous := _payload()
	var was_read_only := read_only
	best.clear()
	earned_stars.clear()
	unlocked = 1
	last_course = 1
	has_started = false
	read_only = false
	save()
	if save_error != OK:
		var pending := _read(save_path + ".tmp")
		if pending.has("payload") and pending.payload == _payload():
			DirAccess.remove_absolute(save_path + ".tmp")
		_apply(previous)
		read_only = was_read_only
		return false
	if backup_error != OK and FileAccess.file_exists(save_path + ".bak"):
		# An explicitly reset game must never resurrect a stale pre-reset backup.
		DirAccess.remove_absolute(save_path + ".bak")
	load_status = "loaded"
	return true


func save() -> void:
	if read_only:
		save_error = ERR_UNAVAILABLE
		return
	var directory := ProjectSettings.globalize_path(save_path).get_base_dir()
	save_error = DirAccess.make_dir_recursive_absolute(directory)
	if save_error != OK:
		return
	var payload := _payload()
	var config := ConfigFile.new()
	config.set_value("meta", "version", FORMAT_VERSION)
	config.set_value("meta", "revision", _revision + 1)
	config.set_value("meta", "checksum", JSON.stringify(payload).sha256_text())
	for key in ["unlocked", "last_course", "has_started"]:
		config.set_value("progress", key, payload[key])
	for number in payload.best:
		config.set_value("best", number, payload.best[number])
	for number in payload.stars:
		config.set_value("stars", number, payload.stars[number])
	for key in ["music", "sound", "fullscreen"]:
		config.set_value("settings", key, payload[key])
	# Replace the profile only after writing and verifying a complete temporary file.
	save_error = config.save(save_path + ".tmp")
	if save_error != OK:
		return
	if not _read(save_path + ".tmp").has("payload"):
		save_error = ERR_FILE_CORRUPT
		return
	save_error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if save_error != OK:
		return
	_revision += 1
	# Keep the newest committed progress in the recovery copy as well.
	backup_error = DirAccess.copy_absolute(save_path, save_path + ".bak")


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var config := ConfigFile.new()
	if config.load(path) != OK or not config.has_section("progress"):
		return {}
	var raw_version = config.get_value("meta", "version", 0)
	if not raw_version is int or raw_version < 0:
		return {}
	var version := int(raw_version)
	if version > FORMAT_VERSION:
		return {"future": true}
	var data := _defaults()
	data.unlocked = _integer(config.get_value("progress", "unlocked", 1), 1, 1, 10)
	data.last_course = _integer(config.get_value("progress", "last_course", 1), 1, 1, 10)
	data.has_started = _boolean(config.get_value("progress", "has_started", false), false)
	for number in range(1, 11):
		var score := _integer(config.get_value("best", str(number), 0), 0, 0, 100000)
		if score > 0:
			data.best[str(number)] = score
		var stars := _integer(config.get_value("stars", str(number), 0), 0, 0, 3)
		if stars > 0:
			data.stars[str(number)] = stars
	data.music = _volume(config.get_value("settings", "music", 0.45), 0.45)
	data.sound = _volume(config.get_value("settings", "sound", 0.7), 0.7)
	data.fullscreen = _boolean(config.get_value("settings", "fullscreen", false), false)
	if version > 0:
		var checksum = config.get_value("meta", "checksum", "")
		if not checksum is String or checksum != JSON.stringify(data).sha256_text():
			return {}
	return {"payload": data, "revision": _integer(config.get_value("meta", "revision", 0), 0, 0, 2147483647),
		"version": version, "has_last_course": config.has_section_key("progress", "last_course")}


func _defaults() -> Dictionary:
	return {"unlocked": 1, "last_course": 1, "has_started": false,
		"best": {}, "stars": {}, "music": 0.45, "sound": 0.7, "fullscreen": false}


func _payload() -> Dictionary:
	var data := {"unlocked": unlocked, "last_course": last_course, "has_started": has_started,
		"best": {}, "stars": {}, "music": music_volume, "sound": sound_volume, "fullscreen": fullscreen}
	for number in best:
		data.best[str(number)] = int(best[number])
	for number in earned_stars:
		data.stars[str(number)] = int(earned_stars[number])
	return data


func _apply(data: Dictionary) -> void:
	unlocked = int(data.unlocked)
	last_course = int(data.last_course)
	has_started = bool(data.has_started)
	best.clear()
	earned_stars.clear()
	for number in data.best:
		best[int(number)] = int(data.best[number])
	for number in data.stars:
		earned_stars[int(number)] = int(data.stars[number])
	music_volume = float(data.music)
	sound_volume = float(data.sound)
	fullscreen = bool(data.fullscreen)


func _integer(value: Variant, fallback: int, low: int, high: int) -> int:
	if not value is int:
		return fallback
	return clampi(value, low, high)


func _volume(value: Variant, fallback: float) -> float:
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), 0.0, 1.0)
	return fallback


func _boolean(value: Variant, fallback: bool) -> bool:
	return value if value is bool else fallback


func total_stars() -> int:
	var total := 0
	for score in earned_stars.values():
		total += int(score)
	return total
