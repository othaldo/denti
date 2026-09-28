extends Node

const SAVE_VERSION := 1

var save_path: String = "user://run_save.json"
var settings_path: String = "user://settings.cfg"
var resume_requested: bool = false
var volume_percent: int = 100


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		volume_percent = clampi(int(config.get_value("audio", "volume", 100)), 0, 100)
		if bool(config.get_value("display", "fullscreen", false)):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	apply_volume()


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


func set_volume(value: int) -> void:
	volume_percent = clampi(value, 0, 100)
	apply_volume()
	_save_settings()


func apply_volume() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_volume_linear(master, float(volume_percent) / 100.0)


func set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume_percent)
	config.set_value("display", "fullscreen", is_fullscreen())
	config.save(settings_path)
