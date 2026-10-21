extends Node

signal fps_display_changed(enabled: bool)
signal graphics_changed

const SAVE_VERSION := RunStore.VERSION
const ADAPTIVE_GRAPHICS: Script = preload("res://scripts/systems/adaptive_graphics.gd")
const BOSS_PROJECTILE_WARMUP: Script = preload("res://scripts/enemies/boss_projectile_warmup.gd")
enum GraphicsMode { AUTOMATIC, ECONOMY, FULL }

var settings_data := SessionSettings.new()
var progression_data := ProgressionStore.new()

var save_path: String = "user://run_save.json"
var report_dir: String = "user://run_reports"
var settings_path: String = "user://settings.cfg"
var progression_path: String = "user://progression.cfg"
var resume_requested: bool = false
var pending_start_weapon_id: StringName = &""
var setup_requested := false
var selected_difficulty_id: StringName = &"normal"
var selected_story_mode: bool = false
var hell_unlocked: bool:
	get: return progression_data.hell_unlocked
	set(value): progression_data.hell_unlocked = value
var discovered_fusions: Array[String]:
	get: return progression_data.discovered_fusions
	set(value): progression_data.discovered_fusions = value
var master_volume_percent: int:
	get: return settings_data.master_volume_percent
	set(value): settings_data.master_volume_percent = value
var music_volume_percent: int:
	get: return settings_data.music_volume_percent
	set(value): settings_data.music_volume_percent = value
var sfx_volume_percent: int:
	get: return settings_data.sfx_volume_percent
	set(value): settings_data.sfx_volume_percent = value
var show_fps: bool:
	get: return settings_data.show_fps
	set(value): settings_data.show_fps = value
var ui_sounds: bool:
	get: return settings_data.ui_sounds
	set(value): settings_data.ui_sounds = value
var reduced_ui_motion: bool:
	get: return settings_data.reduced_ui_motion
	set(value): settings_data.reduced_ui_motion = value
var graphics_mode: GraphicsMode:
	get: return settings_data.graphics_mode
	set(value): settings_data.graphics_mode = value
var adaptive_graphics: AdaptiveGraphics = ADAPTIVE_GRAPHICS.new()
var graphics_sample_us: int = -1
var application_focused: bool = true
var ui_voice: AudioStreamPlayer
var last_ui_cue_ms: int = -1000
var code_entry_unlocked: bool:
	get: return settings_data.code_entry_unlocked
	set(value): settings_data.code_entry_unlocked = value
var settings_visit_streak: int = 0
var test_scenario_id: StringName = &""
var test_save_path: String = "user://test_arena_run.json"
var protected_run_context: Dictionary = {}


func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		_update_mobile_scale()
		get_tree().root.size_changed.connect(_update_mobile_scale)
	load_progression()
	settings_data.load_from(settings_path)
	if settings_data.fullscreen:
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


func visit_settings_for_code_entry() -> void:
	if code_entry_unlocked:
		return
	settings_visit_streak += 1
	if settings_visit_streak >= 7:
		code_entry_unlocked = true
		_save_settings()


func begin_test_run(id: StringName) -> bool:
	if not code_entry_unlocked or TestArenaCatalog.by_id(id) == null:
		return false
	end_test_run()
	protected_run_context = {"save_path": save_path, "difficulty": selected_difficulty_id, "story": selected_story_mode}
	test_scenario_id = id
	save_path = test_save_path
	clear_run()
	selected_difficulty_id = &"normal"
	selected_story_mode = false
	resume_requested = false
	return true


func end_test_run() -> void:
	if test_scenario_id == &"":
		return
	clear_run()
	save_path = protected_run_context["save_path"]
	selected_difficulty_id = protected_run_context["difficulty"]
	selected_story_mode = protected_run_context["story"]
	test_scenario_id = &""
	protected_run_context.clear()
	resume_requested = false


func load_run() -> Dictionary:
	return RunStore.load_run(save_path)


func save_run(data: Dictionary) -> Error:
	data["version"] = SAVE_VERSION
	var error := RunStore.save_run(save_path, data)
	if error != OK:
		push_warning("Spielstand konnte nicht gespeichert werden: %s" % save_path)
	return error


func clear_run() -> void:
	RunStore.clear(save_path)

func load_progression() -> void:
	progression_data.load_from(progression_path)

func discover_fusion(id: StringName) -> void:
	if test_scenario_id != &"" or WeaponEvolutions.by_id(id) == null or discovered_fusions.has(str(id)):
		return
	discovered_fusions.append(str(id))
	_save_progression()


func _save_progression() -> void:
	progression_data.save_to(progression_path)

func can_select_difficulty(id: StringName) -> bool:
	return DifficultyCatalog.by_id(id).id == id and (id != &"hell" or hell_unlocked)


func select_difficulty(id: StringName) -> bool:
	if not can_select_difficulty(id):
		return false
	selected_difficulty_id = id
	return true


func unlock_hell() -> bool:
	if test_scenario_id != &"" or hell_unlocked:
		return false
	hell_unlocked = true
	_save_progression()
	return true


func save_run_report(report: Dictionary) -> String:
	if test_scenario_id != &"":
		return ""
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
	if settings_data.save_to(settings_path, is_fullscreen()) != OK:
		push_warning("Einstellungen konnten nicht gespeichert werden: %s" % settings_path)

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
