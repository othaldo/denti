extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_progression_run.json"
	session.clear_run()
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	if session.has_run() or menu.overlay:
		_fail("main menu started with an unexpected save")
		return
	if menu.menu_music.current_cue != &"main_menu" or menu.menu_music.bus != &"Music" or menu.menu_music.stream != MusicController.MAIN_MENU or not menu.menu_music.playing:
		_fail("main menu theme did not start")
		return
	menu.menu_music._process(MusicController.FADE_DURATION)
	menu.menu_music.seek(menu.menu_music.stream.get_length() - MusicController.FADE_DURATION * 0.5)
	menu.menu_music._process(0.01)
	if menu.menu_music.fade_state != MusicController.FadeState.FADING_OUT or menu.menu_music.queued_cue != &"main_menu":
		_fail("main menu theme did not prepare its next loop")
		return
	menu.menu_music._process(MusicController.FADE_DURATION)
	if menu.menu_music.current_cue != &"main_menu" or menu.menu_music.fade_state != MusicController.FadeState.FADING_IN:
		_fail("main menu theme did not restart with a fade")
		return
	if (menu.rows.get_child(3) as Button).text != "Neues Spiel" or not (menu.rows.get_child(3) as Button).has_focus():
		_fail("new game was not selected when no save exists")
		return
	menu._new_game()
	if menu.page != &"difficulty" or (menu.rows.get_child(4) as Button).text != "Normal":
		_fail("new game did not offer difficulty selection")
		return
	(menu.rows.get_child(4) as Button).pressed.emit()
	await process_frame
	await process_frame
	var game: Node2D = current_scene
	if game == null or game.name != "Game" or not session.has_run():
		_fail("new game did not start and save")
		return
	if not paused or game.choice_panel.mode != &"starter":
		_fail("new game did not offer starter weapons")
		return
	if not bool(session.load_run().get("starter_pending", false)):
		_fail("starter choice was not saved for continue")
		return
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.game_menu.open_pause()
	if not paused or not game.game_menu.visible:
		_fail("escape menu did not pause play")
		return
	game.game_menu._show_stats()
	if game.game_menu.page != &"stats":
		_fail("stats page did not open")
		return
	game.game_menu.close_pause()
	if paused:
		_fail("pause menu did not resume play")
		return
	game.player.stats.damage_bonus = 42.0
	game.coins = 17
	game.xp = 3
	game.wave.remaining = 23.0
	game.wave.active = true
	game.wave.current_wave = 4
	game.wave.duration = WaveController.duration_for_wave(4)
	game.wave.horde_waves.clear()
	game.wave.horde_waves.append(4)
	game.wave.horde_waves.append(8)
	game._spawn_enemy(WaveController.ACID_SPITTER)
	var acid_enemy: Enemy = game.get_node("Enemies").get_child(-1)
	acid_enemy.position = game.player.position + Vector2(200.0, 0.0)
	acid_enemy.special_timer = 0.0
	paused = true
	acid_enemy._physics_process(0.01)
	if acid_enemy.special_phase != Enemy.SpecialPhase.WARNING:
		_fail("acid enemy did not announce its shot")
		return
	acid_enemy._physics_process(acid_enemy.data.warning_time)
	if game.get_node("EnemyProjectiles").get_child_count() != 1:
		_fail("acid enemy did not fire a projectile")
		return
	var acid_projectile: AcidProjectile = game.get_node("EnemyProjectiles").get_child(0)
	var health_before: float = game.player.stats.health
	acid_projectile._physics_process(0.69)
	if game.player.stats.health >= health_before:
		_fail("acid projectile did not damage Denti")
		return
	paused = false
	game._save_run()
	var stored: Dictionary = session.load_run()
	if int(stored.get("coins", -1)) != 17 or int(stored.get("wave", -1)) != 4:
		_fail("run state was not written to disk")
		return
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene as GameMenu
	if menu == null or not session.has_run():
		_fail("main menu lost the run")
		return
	if (menu.rows.get_child(3) as Button).text != "Fortsetzen" or not (menu.rows.get_child(3) as Button).has_focus():
		_fail("continue was not the default action with a save")
		return
	menu._new_game()
	if menu.page != &"confirm_new_game" or not session.has_run() or (menu.rows.get_child(3) as Button).text != "Abbrechen" or not (menu.rows.get_child(3) as Button).has_focus():
		_fail("new game did not ask before deleting the save")
		return
	(menu.rows.get_child(3) as Button).pressed.emit()
	if menu.page != &"home" or not session.has_run():
		_fail("cancelling a new game did not preserve the save")
		return
	menu._continue_game()
	await process_frame
	await process_frame
	game = current_scene
	if game.coins != 17 or game.xp != 3 or game.wave.current_wave != 4 or not is_equal_approx(game.wave.duration, WaveController.duration_for_wave(4)) or absf(game.wave.remaining - 23.0) > 0.2 or game.player.stats.damage_bonus != 42.0:
		_fail("continue did not restore progression")
		return
	var restored_acid := false
	for restored_enemy: Enemy in game.get_node("Enemies").get_children():
		if restored_enemy.data == WaveController.ACID_SPITTER:
			restored_acid = true
	if not restored_acid:
		_fail("continue did not restore enemies")
		return
	for value in [1, 2, 3]:
		game.wave.current_wave = value
		game.wave.remaining = 20.0
		for attempt in 40:
			var enemy_data: EnemyData = game.wave._choose_enemy()
			if value < 4 and enemy_data == WaveController.ACID_SPITTER or value < 3 and enemy_data == WaveController.SUGAR or value < 2 and enemy_data == WaveController.BACTERIA:
				_fail("enemy type appeared too early")
				return
	game.wave.active = true
	game.wave.current_wave = 4
	game.wave.horde_waves.clear()
	game.wave.horde_waves.append(4)
	game.wave.horde_waves.append(8)
	game.wave.horde_spawned = false
	game.wave.remaining = game.wave.duration * (1.0 - WaveController.HORDE_TIME_FRACTION) + 0.1
	var enemies_before: int = game.get_node("Enemies").get_child_count()
	game.wave._process(0.2)
	if not game.wave.horde_spawned or game.get_node("Enemies").get_child_count() < enemies_before + 9:
		_fail("single-type horde did not spawn")
		return
	game._clear_arena(false)
	game._on_loot_collected(&"xp", game.xp_goal)
	if paused or game.choice_panel.visible or game.rewards.pending_levels != 1:
		_fail("XP interrupted active combat instead of queuing a level-up")
		return
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene as GameMenu
	menu._continue_game()
	await process_frame
	await process_frame
	game = current_scene
	if paused or game.choice_panel.visible or game.rewards.pending_levels != 1:
		_fail("continue lost the level-up earned during combat")
		return
	game.wave._process(game.wave.remaining)
	if not paused or not game.choice_panel.visible or game.choice_panel.current_upgrades.size() != 4:
		_fail("post-wave level-up choices did not open after loot collection")
		return
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene as GameMenu
	menu._continue_game()
	await process_frame
	await process_frame
	game = current_scene
	if not paused or game.rewards.pending_levels != 1 or not game.choice_panel.visible or game.choice_panel.current_upgrades.size() != 4:
		_fail("continue lost a post-wave level-up choice")
		return
	game.choice_panel._on_choice_pressed(0)
	if not paused or not game.shop_panel.visible:
		_fail("shop did not open before saving")
		return
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene as GameMenu
	menu._continue_game()
	await process_frame
	await process_frame
	game = current_scene
	if not paused or not game.in_shop or not game.shop_panel.visible or game.shop.offers.size() != 4:
		_fail("continue did not restore the shop")
		return
	game.game_menu._to_main_menu()
	await process_frame
	await process_frame
	menu = current_scene as GameMenu
	menu._new_game()
	(menu.rows.get_child(4) as Button).pressed.emit()
	if menu.page != &"difficulty":
		_fail("confirmed new game did not offer difficulty selection")
		return
	(menu.rows.get_child(4) as Button).pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	if not paused or game.choice_panel.mode != &"starter" or game.coins != 0 or game.in_shop or not session.has_run():
		_fail("confirmed new game did not replace the previous run")
		return
	session.clear_run()
	paused = false
	print("Denti progression and menu test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
