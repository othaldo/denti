class_name SessionSettings
extends RefCounted

var master_volume_percent: int = 100
var music_volume_percent: int = 100
var sfx_volume_percent: int = 100
var show_fps: bool = false
var ui_sounds: bool = true
var reduced_ui_motion: bool = false
var graphics_mode: int = 0
var code_entry_unlocked: bool = false
var fullscreen: bool = false


func load_from(path: String) -> void:
	var config := ConfigFile.new()
	if config.load(path) == OK:
		master_volume_percent = clampi(int(config.get_value("audio", "master", config.get_value("audio", "volume", 100))), 0, 100)
		music_volume_percent = clampi(int(config.get_value("audio", "music", 100)), 0, 100)
		sfx_volume_percent = clampi(int(config.get_value("audio", "sfx", 100)), 0, 100)
		show_fps = bool(config.get_value("display", "show_fps", false))
		ui_sounds = bool(config.get_value("ui", "sounds", true))
		reduced_ui_motion = bool(config.get_value("ui", "reduced_motion", false))
		graphics_mode = clampi(int(config.get_value("display", "graphics_mode", 0)), 0, 2)
		code_entry_unlocked = bool(config.get_value("debug", "code_entry_unlocked", false))
		fullscreen = bool(config.get_value("display", "fullscreen", false))


func save_to(path: String, fullscreen: bool) -> Error:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume_percent)
	config.set_value("audio", "music", music_volume_percent)
	config.set_value("audio", "sfx", sfx_volume_percent)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "show_fps", show_fps)
	config.set_value("display", "graphics_mode", graphics_mode)
	config.set_value("ui", "sounds", ui_sounds)
	config.set_value("ui", "reduced_motion", reduced_ui_motion)
	config.set_value("debug", "code_entry_unlocked", code_entry_unlocked)
	return config.save(path)
