extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	var session: Node = root.get_node("GameSession")
	session.settings_path = "user://test_options_settings.cfg"
	var previous_master: int = session.master_volume_percent
	var previous_music: int = session.music_volume_percent
	var previous_sfx: int = session.sfx_volume_percent
	var previous_show_fps: bool = session.show_fps
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._show_options()
	await process_frame
	await process_frame
	if menu.rows.get_child_count() != 9:
		_fail("options page has duplicate controls")
		return
	var master_bus := AudioServer.get_bus_index("Master")
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if master_bus < 0 or music_bus < 0 or sfx_bus < 0:
		_fail("music or sound effects have no separate audio bus")
		return
	var master_slider: HSlider = menu.master_slider
	var music_slider: HSlider = menu.music_slider
	var sfx_slider: HSlider = menu.sfx_slider
	var track: StyleBox = master_slider.get_theme_stylebox("slider")
	var fill: StyleBox = master_slider.get_theme_stylebox("grabber_area")
	if track.get_minimum_size().y < 10.0 or fill.get_minimum_size().y < 10.0:
		_fail("audio sliders have no visible track")
		return
	var fps_toggle: CheckButton = menu.fps_toggle
	var selected_fps: bool = not session.show_fps
	fps_toggle.button_pressed = selected_fps
	master_slider.value = 37.0
	music_slider.value = 62.0
	sfx_slider.value = 15.0
	await process_frame
	if menu.rows.get_child_count() != 9 or menu.fps_toggle != fps_toggle or menu.master_slider != master_slider or menu.music_slider != music_slider or menu.sfx_slider != sfx_slider:
		_fail("moving sliders duplicated options")
		return
	if session.show_fps != selected_fps:
		_fail("FPS toggle did not change the setting")
		return
	if session.master_volume_percent != 37 or session.music_volume_percent != 62 or session.sfx_volume_percent != 15:
		_fail("sliders did not update independent volume settings")
		return
	if not is_equal_approx(AudioServer.get_bus_volume_linear(master_bus), 0.37) or not is_equal_approx(AudioServer.get_bus_volume_linear(music_bus), 0.62) or not is_equal_approx(AudioServer.get_bus_volume_linear(sfx_bus), 0.15):
		_fail("audio bus levels do not match the sliders")
		return
	if master_slider.get_parent().get_child(2).text != "37%" or music_slider.get_parent().get_child(2).text != "62%" or sfx_slider.get_parent().get_child(2).text != "15%":
		_fail("slider percentages did not update")
		return
	var saved_settings := ConfigFile.new()
	if saved_settings.load(session.settings_path) != OK or int(saved_settings.get_value("audio", "master", -1)) != 37 or int(saved_settings.get_value("audio", "music", -1)) != 62 or int(saved_settings.get_value("audio", "sfx", -1)) != 15 or bool(saved_settings.get_value("display", "show_fps", not selected_fps)) != selected_fps:
		_fail("options settings were not saved")
		return
	var options_panel: PanelContainer = menu.rows.get_parent().get_parent()
	if options_panel.get_global_rect().end.y > 720.0:
		_fail("options panel exceeds the viewport")
		return
	var fullscreen_button: Button = menu.fullscreen_button
	fullscreen_button.pressed.emit()
	await process_frame
	if menu.rows.get_child_count() != 9 or menu.fullscreen_button != fullscreen_button:
		_fail("fullscreen option duplicated controls")
		return
	var back_button: Button = menu.rows.get_child(8)
	back_button.pressed.emit()
	await process_frame
	if menu.page != &"home" or menu.rows.get_child_count() != 8:
		_fail("options back button failed")
		return
	var options_button: Button = menu.rows.get_child(5)
	options_button.pressed.emit()
	await process_frame
	if menu.page != &"options" or menu.rows.get_child_count() != 9 or menu.fps_toggle.button_pressed != selected_fps or int(menu.master_slider.value) != 37 or int(menu.music_slider.value) != 62 or int(menu.sfx_slider.value) != 15:
		_fail("opening options again duplicated controls")
		return
	session.master_volume_percent = 100
	session.music_volume_percent = 100
	session.sfx_volume_percent = 100
	session.show_fps = not selected_fps
	session._ready()
	if session.master_volume_percent != 37 or session.music_volume_percent != 62 or session.sfx_volume_percent != 15 or session.show_fps != selected_fps:
		_fail("options settings did not load after a restart")
		return
	session.save_path = "user://test_options_run.json"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	menu.queue_free()
	if game.hud.fps_panel.visible != selected_fps:
		_fail("HUD did not apply saved FPS visibility")
		return
	if game.music.bus != &"Music":
		_fail("background music is not routed to Music")
		return
	for voice: AudioStreamPlayer in game.sound.voices:
		if voice.bus != &"SFX":
			_fail("sound effect is not routed to SFX")
			return
	game.wave.active = false
	game.game_menu.open_pause()
	if not paused or game.game_menu.rows.get_child_count() != 8:
		_fail("pause menu did not open")
		return
	var pause_options_button: Button = game.game_menu.rows.get_child(6)
	pause_options_button.pressed.emit()
	await process_frame
	if game.game_menu.page != &"options" or game.game_menu.rows.get_child_count() != 9:
		_fail("pause options did not open cleanly")
		return
	var pause_music_slider: HSlider = game.game_menu.music_slider
	game.game_menu.fps_toggle.button_pressed = not selected_fps
	if session.show_fps == selected_fps or game.hud.fps_panel.visible == selected_fps:
		_fail("FPS display did not update while paused")
		return
	game.game_menu.fps_toggle.button_pressed = true
	await process_frame
	if not game.hud.fps_panel.visible or game.hud.fps_label.text == "FPS --":
		_fail("FPS counter did not refresh while paused")
		return
	game.game_menu.fps_toggle.button_pressed = false
	if game.hud.fps_panel.visible:
		_fail("FPS counter stayed visible after switching it off")
		return
	pause_music_slider.value = 23.0
	await process_frame
	if game.game_menu.rows.get_child_count() != 9 or game.game_menu.music_slider != pause_music_slider or session.music_volume_percent != 23:
		_fail("pause options duplicated controls")
		return
	(game.game_menu.rows.get_child(8) as Button).pressed.emit()
	await process_frame
	if game.game_menu.page != &"home" or game.game_menu.rows.get_child_count() != 8:
		_fail("pause options back button failed")
		return
	game.game_menu.close_pause()
	if paused:
		_fail("pause menu did not resume")
		return
	var legacy_path := "user://test_options_legacy.cfg"
	var legacy_settings := ConfigFile.new()
	legacy_settings.set_value("audio", "volume", 42)
	legacy_settings.save(legacy_path)
	session.settings_path = legacy_path
	session.master_volume_percent = 100
	session.music_volume_percent = 100
	session.sfx_volume_percent = 100
	session._ready()
	if session.master_volume_percent != 42 or session.music_volume_percent != 100 or session.sfx_volume_percent != 100:
		_fail("old volume setting was not migrated to Gesamt")
		return
	session.settings_path = "user://test_options_settings.cfg"
	session.clear_run()
	session.set_master_volume(previous_master)
	session.set_music_volume(previous_music)
	session.set_sfx_volume(previous_sfx)
	session.set_show_fps(previous_show_fps)
	session.set_fullscreen(false)
	if FileAccess.file_exists(session.settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(session.settings_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
	print("Denti options menu test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
