extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _button(menu: GameMenu, title: String) -> Button:
	for child in menu.rows.get_children():
		if child is Button and child.text == title:
			return child
	return null

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/test_arena_protected_run.json"
	session.test_save_path = "res://.godot/test_arena_sandbox_run.json"
	session.settings_path = "res://.godot/test_arena_settings.cfg"
	session.progression_path = "res://.godot/test_arena_progression.cfg"
	session.report_dir = "res://.godot/test_arena_reports"
	session.code_entry_unlocked = false
	session.settings_visit_streak = 0
	session.selected_story_mode = false
	session.resume_requested = false
	session.hell_unlocked = false
	session.discovered_fusions.clear()
	var original_fps: bool = session.show_fps
	var original_graphics: int = session.graphics_mode
	var web_export := ConfigFile.new()
	web_export.load("res://export_presets.cfg")
	_check(bool(web_export.get_value("preset.0.options", "html/experimental_virtual_keyboard", false)), "web code entry cannot open the touchscreen keyboard")
	var normal: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(normal)
	current_scene = normal
	normal.choice_panel.buttons[0].pressed.emit()
	normal.coins = 37
	normal._save_run()
	var protected_bytes := FileAccess.get_file_as_string(session.save_path)
	var protected_path: String = session.save_path
	normal.free()
	paused = false
	session.selected_difficulty_id = &"hard"
	session.selected_story_mode = true
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	_check(_button(menu, "Code eingeben") == null and not session.begin_test_run(&"dense_combat"), "test entry was available before seven settings visits")
	for visit in 2:
		_button(menu, "Einstellungen").pressed.emit()
		_button(menu, "Zurück").pressed.emit()
	_button(menu, "Credits").pressed.emit()
	_button(menu, "Zurück").pressed.emit()
	_check(session.settings_visit_streak == 0, "another main-menu page did not reset the settings streak")
	for visit in 7:
		_button(menu, "Einstellungen").pressed.emit()
		menu._show_options() # Rebuilding the already-open page must not count twice.
		_button(menu, "Zurück").pressed.emit()
		_check(session.code_entry_unlocked == (visit == 6), "code entry unlocked before/after the seventh visit")
		await process_frame
	var settings := ConfigFile.new()
	settings.load(session.settings_path)
	_check(bool(settings.get_value("debug", "code_entry_unlocked", false)), "code-entry unlock did not persist")
	for size in [Vector2i(320, 568), Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(1040, 600)]:
		root.content_scale_size = size
		root.size = size
		menu._show_home()
		for frame in 10:
			await process_frame
		_check(_inside(menu.build_panel, size), "unlocked main menu overflows %s: %s" % [size, menu.build_panel.get_global_rect()])
		_button(menu, "Code eingeben").pressed.emit()
		for frame in 10:
			await process_frame
		_check(_inside(menu.build_panel, size) and _inside(menu.code_input, size), "code input overflows %s" % size)
		menu._show_home()
	_button(menu, "Code eingeben").pressed.emit()
	menu._activate_test_code("unknown test")
	_check(menu.page == &"code_entry" and not menu.code_error.text.is_empty() and session.test_scenario_id == &"", "unknown code changed the run")
	menu.code_input.text = "  DEBUG  MAP  "
	_button(menu, "Test starten").pressed.emit()
	await process_frame
	await process_frame
	var game: Node2D = current_scene
	_check(game.has_node("TestArena") and not paused and not game.choice_panel.visible, "test map opened the starter/reward menu")
	_check(session.test_scenario_id == &"dense_combat" and session.save_path != protected_path, "test map used the normal save path")
	_check(game.get_node("Enemies").get_child_count() == 110 and game.get_node("Loot").get_child_count() > 1100, "dense test map did not populate its enemies and loot")
	_check(game.player.loadout.equipped().size() == 3 and game.player.loadout.equipped()[0].data.id == &"trinity_brush", "dense test map did not configure the requested brush build")
	_check(not game.wave.is_processing() and game.wave.active and game.wave.current_wave == 17, "test wave can accidentally advance into rewards/shop")
	_check(game.hud.fps_panel.visible and session.show_fps == original_fps and session.graphics_mode == original_graphics, "test map changed persistent graphics/FPS settings")
	_check(not game.has_node("DebugCheatMenu"), "test map exposed the unrelated native cheat controls")
	game._save_run()
	_check(FileAccess.file_exists(session.test_save_path) and FileAccess.get_file_as_string(protected_path) == protected_bytes, "test autosave overwrote the normal run")
	_check(not session.unlock_hell() and not session.hell_unlocked, "test run unlocked a normal difficulty")
	session.discover_fusion(WeaponEvolutions.ALL[0].id)
	_check(session.discovered_fusions.is_empty() and session.save_run_report({}) == "", "test run changed discoveries or wrote a normal run report")
	game.game_menu.open_pause()
	_check(_button(game.game_menu, "Test neu starten") != null, "test pause menu has no restart control")
	_button(game.game_menu, "Test neu starten").pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	_check(game.has_node("TestArena") and game.get_node("Enemies").get_child_count() == 110 and not paused, "test restart did not recreate the preset")
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene
	_check(session.test_scenario_id == &"" and session.save_path == protected_path and session.has_run(), "leaving test mode did not restore the normal run")
	_check(session.selected_difficulty_id == &"hard" and session.selected_story_mode, "test mode lost the previous difficulty/story selection")
	_check(FileAccess.get_file_as_string(protected_path) == protected_bytes and not FileAccess.file_exists(session.test_save_path), "test exit changed the normal save or kept a disposable save")
	menu._show_code_entry()
	menu._activate_test_code("boss charge")
	await process_frame
	await process_frame
	game = current_scene
	_check(game.get_node("Enemies").get_child_count() == 1 and game.boss != null and game.boss.data == WaveController.CAVITY_KING, "boss code did not start the isolated charge scenario")
	_check(game.hud.boss_label.text.ends_with("· Test"), "boss test shows unreadable artificial health totals")
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene
	menu._show_code_entry()
	menu._activate_test_code("debug enemies")
	await process_frame
	await process_frame
	game = current_scene
	_check(session.test_scenario_id == &"enemies_only" and game.get_node("Enemies").get_child_count() == 110, "enemy comparison code did not retain full enemy density")
	_check(game.get_node("Loot").get_child_count() == 0 and game.player.loadout.equipped().is_empty() and game.items.owned.is_empty(), "enemy comparison includes loot, player weapons or item procs")
	await process_frame
	_check(game.get_node("TestArena").maximum_frame_ms > 0, "test arena does not measure individual frame spikes")
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene
	menu._show_code_entry()
	menu._activate_test_code("bacteria charge")
	await process_frame
	await process_frame
	game = current_scene
	_check(game.get_node("Enemies").get_child_count() == 60 and game.player.loadout.equipped().is_empty(), "bacteria test does not isolate the charge workload")
	for enemy: Enemy in game.get_node("Enemies").get_children():
		_check(enemy.data == WaveController.BACTERIA, "bacteria test includes another enemy role")
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene
	menu._continue_game()
	await process_frame
	await process_frame
	game = current_scene
	_check(not game.has_node("TestArena") and game.coins == 37 and game.wave.current_wave == 1, "normal Continue restored a test arena instead of the original run")
	session.clear_run()
	game.free()
	paused = false
	if failures.is_empty():
		print("Denti hidden test arenas regression test passed")
	quit(0 if failures.is_empty() else 1)

func _inside(control: Control, size: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= size.x + 1 and rect.end.y <= size.y + 1
