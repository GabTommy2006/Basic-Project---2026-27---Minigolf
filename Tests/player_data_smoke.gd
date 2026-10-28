extends SceneTree

const Store = preload("res://Game/progress_store.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", text)

func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(text)
	file.close()

func _run() -> void:
	var base := "res://tmp/save-check/%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var store := Store.new()
	store.save_path = base + "player.cfg"
	store.load_progress()
	check(store.load_status == "new" and store.unlocked == 1, "Missing save starts a fresh profile")
	store.save()
	check(store.save_error == OK and store.backup_error == OK, "First save creates its data folder")
	check(FileAccess.file_exists(store.save_path) and FileAccess.file_exists(store.save_path + ".bak"), "Primary and backup exist")
	store.record(1, 2, 3)
	store.record(1, 5, 1)
	store.begin_course(2)
	store.music_volume = 0.32
	store.sound_volume = 0.68
	store.save()
	var reloaded := Store.new()
	reloaded.save_path = store.save_path
	reloaded.load_progress()
	check(reloaded.load_status == "loaded", "Versioned save passes checksum")
	check(reloaded.best.get(1) == 2 and reloaded.earned_stars.get(1) == 3, "Best score and stars never regress")
	check(reloaded.unlocked == 2 and reloaded.last_course == 2 and reloaded.has_started, "Unlock and Continue survive reload")
	check(is_equal_approx(reloaded.music_volume, 0.32) and is_equal_approx(reloaded.sound_volume, 0.68), "Settings survive reload")
	var config := ConfigFile.new()
	config.load(store.save_path)
	config.set_value("best", "1", 99)
	config.save(store.save_path)
	reloaded.load_progress()
	check(reloaded.load_status == "recovered" and reloaded.best.get(1) == 2, "Damaged primary recovers newest backup")
	check(reloaded._read(reloaded.save_path).has("payload"), "Recovery repairs primary")
	# A crash after writing a newer verified temp file must not discard the new record.
	var previous := FileAccess.get_file_as_string(store.save_path)
	reloaded.record(2, 3, 3)
	var newer := FileAccess.get_file_as_string(store.save_path)
	write_text(store.save_path, previous)
	write_text(store.save_path + ".bak", previous)
	write_text(store.save_path + ".tmp", newer)
	reloaded.load_progress()
	check(reloaded.load_status == "recovered" and reloaded.best.get(2) == 3, "Interrupted write recovers the newest verified revision")
	check(not FileAccess.file_exists(store.save_path + ".tmp"), "Recovered temp is committed")
	var before_reset := FileAccess.get_file_as_string(store.save_path)
	check(reloaded.reset_progress(), "New Game resets successfully")
	check(reloaded.best.is_empty() and reloaded.earned_stars.is_empty() and reloaded.unlocked == 1, "New Game clears progress, records and stars")
	check(is_equal_approx(reloaded.music_volume, 0.32) and is_equal_approx(reloaded.sound_volume, 0.68), "New Game preserves settings")
	write_text(store.save_path + ".tmp", before_reset)
	reloaded.load_progress()
	check(reloaded.best.is_empty() and reloaded.unlocked == 1, "Stale temp cannot resurrect pre-reset progress")
	config.load(store.save_path)
	config.set_value("progress", "unlocked", 8)
	config.save(store.save_path)
	reloaded.load_progress()
	check(reloaded.best.is_empty() and reloaded.unlocked == 1, "Reset also replaces recovery backup")
	# Invalid legacy values must not crash Variant casts; valid records are migrated.
	var legacy_path := base + "legacy.cfg"
	config = ConfigFile.new()
	config.set_value("progress", "unlocked", [1, 2])
	config.set_value("best", "2", 3)
	config.set_value("best", "3", {"invalid": true})
	config.set_value("stars", "2", "invalid")
	config.set_value("settings", "music", "not-a-volume")
	config.set_value("settings", "sound", NAN)
	config.set_value("settings", "fullscreen", [])
	config.save(legacy_path)
	var legacy := Store.new()
	legacy.save_path = legacy_path
	legacy.load_progress()
	check(legacy.load_status == "migrated", "Legacy format migrates")
	check(legacy.best.get(2) == 3 and not legacy.best.has(3), "Legacy valid records survive invalid values")
	check(legacy.unlocked >= 3 and legacy.earned_stars.get(2) == 3, "Legacy unlocks and missing stars repaired")
	check(legacy.last_course == legacy.unlocked, "Legacy Continue points to the unlocked course")
	check(is_equal_approx(legacy.music_volume, 0.45) and is_equal_approx(legacy.sound_volume, 0.7) and not legacy.fullscreen, "Invalid settings fall back safely")
	# Fully damaged files are preserved, rather than silently overwritten by auto-save.
	var damage := ConfigFile.new()
	damage.set_value("meta", "version", 1)
	damage.set_value("meta", "checksum", "broken")
	damage.set_value("progress", "unlocked", 8)
	damage.save(base + "broken.cfg")
	damage.save(base + "broken.cfg.bak")
	var broken := Store.new()
	broken.save_path = base + "broken.cfg"
	var original := FileAccess.get_file_as_string(broken.save_path)
	broken.load_progress()
	broken.record(1, 1, 3)
	check(broken.read_only and broken.load_status == "damaged" and broken.save_error != OK, "Unrecoverable save reports failure")
	check(FileAccess.get_file_as_string(broken.save_path) == original, "Damaged source is not overwritten")
	check(broken.reset_progress(), "Explicit New Game can replace a damaged profile")
	var future := Store.new()
	future.save_path = base + "future.cfg"
	config = ConfigFile.new()
	config.set_value("meta", "version", 999)
	config.set_value("progress", "unlocked", 9)
	config.save(future.save_path)
	original = FileAccess.get_file_as_string(future.save_path)
	future.load_progress()
	future.save()
	check(future.read_only and future.load_status == "unsupported" and FileAccess.get_file_as_string(future.save_path) == original,
		"Newer save formats are never downgraded or overwritten")
	write_text(base + "blocker", "keep")
	reloaded.best[1] = 2
	reloaded.earned_stars[1] = 3
	reloaded.unlocked = 2
	reloaded.save_path = base + "blocker/player.cfg"
	check(not reloaded.reset_progress(), "Failed reset reports I/O failure")
	check(reloaded.best.get(1) == 2 and reloaded.unlocked == 2, "Failed reset restores in-memory progress")
	check(FileAccess.get_file_as_string(base + "blocker") == "keep", "Failed save does not overwrite unrelated file")
	reloaded.save_path = base + "missing.cfg"
	reloaded.load_progress()
	check(reloaded.best.is_empty() and reloaded.unlocked == 1, "Reload does not retain stale in-memory data")
	print("PLAYER_DATA_RESULT checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
