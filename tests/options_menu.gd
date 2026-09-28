extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	var session: Node = root.get_node("GameSession")
	session.settings_path = "user://test_options_settings.cfg"
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._show_options()
	await process_frame
	await process_frame
	if menu.rows.get_child_count() != 6:
		_fail("options page has duplicate controls")
		return
	var volume_before: int = session.volume_percent
	var volume_button: Button = menu.volume_button
	for click in 3:
		volume_button.pressed.emit()
		await process_frame
		if menu.page != &"options" or menu.rows.get_child_count() != 6 or menu.volume_button != volume_button or volume_button.text != "Lautstärke: %d%%" % session.volume_percent:
			_fail("volume option duplicated or failed to update")
			return
	if session.volume_percent == volume_before:
		_fail("volume did not change")
		return
	var fullscreen_button: Button = menu.fullscreen_button
	fullscreen_button.pressed.emit()
	await process_frame
	if menu.rows.get_child_count() != 6 or menu.fullscreen_button != fullscreen_button:
		_fail("fullscreen option duplicated controls")
		return
	var back_button: Button = menu.rows.get_child(5)
	back_button.pressed.emit()
	await process_frame
	if menu.page != &"home" or menu.rows.get_child_count() != 8:
		_fail("options back button failed")
		return
	var options_button: Button = menu.rows.get_child(5)
	options_button.pressed.emit()
	await process_frame
	if menu.page != &"options" or menu.rows.get_child_count() != 6:
		_fail("opening options again duplicated controls")
		return
	session.save_path = "user://test_options_run.json"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	menu.queue_free()
	game.wave.active = false
	game.game_menu.open_pause()
	if not paused or game.game_menu.rows.get_child_count() != 7:
		_fail("pause menu did not open")
		return
	var pause_options_button: Button = game.game_menu.rows.get_child(5)
	pause_options_button.pressed.emit()
	await process_frame
	if game.game_menu.page != &"options" or game.game_menu.rows.get_child_count() != 6:
		_fail("pause options did not open cleanly")
		return
	var pause_volume_button: Button = game.game_menu.volume_button
	pause_volume_button.pressed.emit()
	await process_frame
	if game.game_menu.rows.get_child_count() != 6 or game.game_menu.volume_button != pause_volume_button:
		_fail("pause options duplicated controls")
		return
	(game.game_menu.rows.get_child(5) as Button).pressed.emit()
	await process_frame
	if game.game_menu.page != &"home" or game.game_menu.rows.get_child_count() != 7:
		_fail("pause options back button failed")
		return
	game.game_menu.close_pause()
	if paused:
		_fail("pause menu did not resume")
		return
	session.clear_run()
	session.set_volume(volume_before)
	session.set_fullscreen(false)
	if FileAccess.file_exists(session.settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(session.settings_path))
	print("Denti options menu test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
