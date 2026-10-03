extends Node

signal fps_display_changed(enabled: bool)
signal graphics_changed

const SAVE_VERSION := 1
const ADAPTIVE_GRAPHICS: Script = preload("res://scripts/systems/adaptive_graphics.gd")
const BOSS_PROJECTILE_WARMUP: Script = preload("res://scripts/enemies/boss_projectile_warmup.gd")
enum GraphicsMode { AUTOMATIC, ECONOMY, FULL }

var save_path: String = "user://run_save.json"
var report_dir: String = "user://run_reports"
var settings_path: String = "user://settings.cfg"
var progression_path: String = "user://progression.cfg"
var resume_requested: bool = false
var selected_difficulty_id: StringName = &"normal"
var selected_story_mode: bool = false
var hell_unlocked: bool = false
var discovered_fusions: Array[String] = []
var master_volume_percent: int = 100
var music_volume_percent: int = 100
var sfx_volume_percent: int = 100
var show_fps: bool = false
var ui_sounds: bool = true
var reduced_ui_motion: bool = false
var graphics_mode: GraphicsMode = GraphicsMode.AUTOMATIC
var adaptive_graphics: AdaptiveGraphics = ADAPTIVE_GRAPHICS.new()
var graphics_sample_us: int = -1
var application_focused: bool = true
var ui_voice: AudioStreamPlayer
var last_ui_cue_ms: int = -1000


func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		_update_mobile_scale()
		get_tree().root.size_changed.connect(_update_mobile_scale)
	load_progression()
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		master_volume_percent = clampi(int(config.get_value("audio", "master", config.get_value("audio", "volume", 100))), 0, 100)
		music_volume_percent = clampi(int(config.get_value("audio", "music", 100)), 0, 100)
		sfx_volume_percent = clampi(int(config.get_value("audio", "sfx", 100)), 0, 100)
		show_fps = bool(config.get_value("display", "show_fps", false))
		ui_sounds = bool(config.get_value("ui", "sounds", true))
		reduced_ui_motion = bool(config.get_value("ui", "reduced_motion", false))
		graphics_mode = clampi(int(config.get_value("display", "graphics_mode", 0)), 0, 2) as GraphicsMode
		if bool(config.get_value("display", "fullscreen", false)):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	apply_volume()
	apply_graphics()
	if DisplayServer.get_name() != "headless":
		add_child(BOSS_PROJECTILE_WARMUP.new())
	fps_display_changed.emit(show_fps)
	if ui_voice == null:
		ui_voice = AudioStreamPlayer.new()
		ui_voice.process_mode = Node.PROCESS_MODE_ALWAYS
		ui_voice.bus = &"SFX"
		ui_voice.stream = preload("res://assets/audio/sfx/pickup.wav")
		ui_voice.volume_db = -22.0
		add_child(ui_voice)


func _update_mobile_scale() -> void:
	var target := mobile_base_size(DisplayServer.window_get_size())
	if get_tree().root.content_scale_size != target:
		get_tree().root.content_scale_size = target


static func mobile_base_size(window_size: Vector2i) -> Vector2i:
	return Vector2i(720, 1280) if window_size.y > window_size.x else Vector2i(1040, 600)


func economy_graphics() -> bool:
	return use_economy_graphics(graphics_mode, adaptive_graphics.economy)


static func use_economy_graphics(mode: int, automatic_economy: bool) -> bool:
	return mode == GraphicsMode.ECONOMY or mode == GraphicsMode.AUTOMATIC and automatic_economy


func begin_graphics_run() -> void:
	adaptive_graphics.reset()
	graphics_sample_us = -1
	apply_graphics()


func suspend_graphics_sampling() -> void:
	graphics_sample_us = -1
	adaptive_graphics.suspend()


func update_graphics_performance(combat_active: bool) -> void:
	if graphics_mode != GraphicsMode.AUTOMATIC or not combat_active or get_tree().paused or not application_focused:
		suspend_graphics_sampling()
		return
	var now := Time.get_ticks_usec()
	var previous := graphics_sample_us
	graphics_sample_us = now
	if previous >= 0 and adaptive_graphics.observe_frame(float(now - previous) / 1000000.0):
		apply_graphics()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		application_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		application_focused = true
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN]:
		suspend_graphics_sampling()


func set_graphics_mode(mode: int) -> void:
	graphics_mode = clampi(mode, 0, 2) as GraphicsMode
	begin_graphics_run()
	_save_settings()


func apply_graphics() -> void:
	# Viewport stretching caps 2D pixel work; logical UI/input dimensions stay intact.
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if economy_graphics() else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	graphics_changed.emit()


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
	var loaded := config.load(progression_path) == OK
	hell_unlocked = loaded and bool(config.get_value("difficulty", "hell_unlocked", false))
	discovered_fusions.clear()
	if loaded:
		for id in config.get_value("dentipedia", "fusions", []):
			if WeaponEvolutions.by_id(StringName(str(id))) != null and not discovered_fusions.has(str(id)):
				discovered_fusions.append(str(id))


func discover_fusion(id: StringName) -> void:
	if WeaponEvolutions.by_id(id) == null or discovered_fusions.has(str(id)):
		return
	discovered_fusions.append(str(id))
	_save_progression()


func _save_progression() -> void:
	var config := ConfigFile.new()
	config.load(progression_path)
	config.set_value("difficulty", "hell_unlocked", hell_unlocked)
	config.set_value("dentipedia", "fusions", discovered_fusions)
	if config.save(progression_path) != OK:
		push_warning("Fortschritt konnte nicht gespeichert werden: %s" % progression_path)


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
	_save_progression()
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
	config.set_value("display", "graphics_mode", graphics_mode)
	config.set_value("ui", "sounds", ui_sounds)
	config.set_value("ui", "reduced_motion", reduced_ui_motion)
	config.save(settings_path)


func set_ui_sounds(enabled: bool) -> void:
	ui_sounds = enabled
	_save_settings()


func set_reduced_ui_motion(enabled: bool) -> void:
	reduced_ui_motion = enabled
	if enabled:
		for control in get_tree().get_nodes_in_group("denti_ui_motion"):
			DentiUIMotion.reset(control)
	_save_settings()


func play_ui_cue(clicked: bool) -> void:
	if not ui_sounds or ui_voice == null or DisplayServer.get_name() == "headless":
		return
	var now := Time.get_ticks_msec()
	if now - last_ui_cue_ms < 90:
		return
	last_ui_cue_ms = now
	ui_voice.pitch_scale = 1.10 if clicked else 1.55
	ui_voice.play()
