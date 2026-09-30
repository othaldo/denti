extends Node

signal fps_display_changed(enabled: bool)

const SAVE_VERSION := 1

var save_path: String = "user://run_save.json"
var report_dir: String = "user://run_reports"
var settings_path: String = "user://settings.cfg"
var progression_path: String = "user://progression.cfg"
var resume_requested: bool = false
var selected_difficulty_id: StringName = &"normal"
var hell_unlocked: bool = false
var master_volume_percent: int = 100
var music_volume_percent: int = 100
var sfx_volume_percent: int = 100
var show_fps: bool = false


func _ready() -> void:
	load_progression()
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		master_volume_percent = clampi(int(config.get_value("audio", "master", config.get_value("audio", "volume", 100))), 0, 100)
		music_volume_percent = clampi(int(config.get_value("audio", "music", 100)), 0, 100)
		sfx_volume_percent = clampi(int(config.get_value("audio", "sfx", 100)), 0, 100)
		show_fps = bool(config.get_value("display", "show_fps", false))
		if bool(config.get_value("display", "fullscreen", false)):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	apply_volume()
	fps_display_changed.emit(show_fps)


func has_run() -> bool:
	return load_run() != {}


func load_run() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("version", -1) != SAVE_VERSION:
		return {}
	if not parsed.has("wave") or not parsed.has("player"):
		return {}
	return parsed


func save_run(data: Dictionary) -> void:
	data["version"] = SAVE_VERSION
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))


func clear_run() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func load_progression() -> void:
	var config := ConfigFile.new()
	hell_unlocked = config.load(progression_path) == OK and bool(config.get_value("difficulty", "hell_unlocked", false))


func can_select_difficulty(id: StringName) -> bool:
	return DifficultyCatalog.by_id(id).id == id and (id != &"hell" or hell_unlocked)


func select_difficulty(id: StringName) -> bool:
	if not can_select_difficulty(id):
		return false
	selected_difficulty_id = id
	return true


func unlock_hell() -> bool:
	if hell_unlocked:
		return false
	hell_unlocked = true
	var config := ConfigFile.new()
	config.set_value("difficulty", "hell_unlocked", true)
	if config.save(progression_path) != OK:
		push_warning("Hell-Freischaltung konnte nicht gespeichert werden: %s" % progression_path)
	return true


func save_run_report(report: Dictionary) -> String:
	var directory := ProjectSettings.globalize_path(report_dir)
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_warning("Run-Bericht konnte nicht gespeichert werden: %s" % directory)
		return ""
	var path := "%s/run_%d_%d.json" % [report_dir, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Run-Bericht konnte nicht gespeichert werden: %s" % path)
		return ""
	file.store_string(JSON.stringify(report, "\t"))
	return path


func set_master_volume(value: int) -> void:
	master_volume_percent = clampi(value, 0, 100)
	apply_volume()
	_save_settings()


func set_music_volume(value: int) -> void:
	music_volume_percent = clampi(value, 0, 100)
	apply_volume()
	_save_settings()


func set_sfx_volume(value: int) -> void:
	sfx_volume_percent = clampi(value, 0, 100)
	apply_volume()
	_save_settings()


func apply_volume() -> void:
	for bus_name in [&"Master", &"Music", &"SFX"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var percent := master_volume_percent if bus_name == &"Master" else music_volume_percent if bus_name == &"Music" else sfx_volume_percent
		AudioServer.set_bus_volume_linear(bus_index, float(percent) / 100.0)


func set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func set_show_fps(enabled: bool) -> void:
	if show_fps == enabled:
		return
	show_fps = enabled
	fps_display_changed.emit(enabled)
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume_percent)
	config.set_value("audio", "music", music_volume_percent)
	config.set_value("audio", "sfx", sfx_volume_percent)
	config.set_value("display", "fullscreen", is_fullscreen())
	config.set_value("display", "show_fps", show_fps)
	config.save(settings_path)
