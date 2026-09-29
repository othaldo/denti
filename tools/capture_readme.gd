extends SceneTree

const SCREENSHOT_DIR := "res://docs/screenshots"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://readme_capture_run.json"
	session.clear_run()
	session.resume_requested = false
	session.show_fps = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	var master_bus := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(master_bus, true)

	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _capture("hauptmenue.png")
	menu.queue_free()
	await process_frame

	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.current_wave = 4
	game.wave.remaining = 29.0
	game.player.stats.health = 84.0
	game.level = 4
	game.xp = 9
	game.xp_goal = 17
	game.coins = 27
	game.player.loadout.acquire(WeaponCatalog.by_id(&"turbo_drill"))
	game.player.loadout.acquire(WeaponCatalog.by_id(&"water_jet"))
	var enemy_types: Array[EnemyData] = [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER]
	for index in 20:
		if index in [14, 15, 16]:
			continue
		var angle := TAU * float(index) / 20.0
		var distance := 200.0 + float(index % 3) * 55.0
		var at: Vector2 = game.player.global_position + Vector2.RIGHT.rotated(angle) * distance
		game._create_enemy(enemy_types[index % enemy_types.size()], at)
	for frame in 15:
		await physics_frame
	game._spawn_loot(game.player.global_position + Vector2(-135.0, 35.0), &"xp", 2)
	game._spawn_loot(game.player.global_position + Vector2(145.0, -75.0), &"coin", 1)
	paused = true
	game._refresh_hud()
	await _capture("kampf.png")

	game._clear_arena(false)
	game.wave.current_wave = 5
	game.wave.remaining = 32.0
	game.player.global_position = Vector2(game.arena.arena_size.x * 0.5, 190.0)
	game._create_enemy(WaveController.BOSS, game.player.global_position + Vector2(235.0, 175.0))
	var boss_mobs: Array[EnemyData] = [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER]
	for index in boss_mobs.size():
		game._create_enemy(boss_mobs[index], game.player.global_position + Vector2(-325.0 + float(index) * 105.0, 135.0 + float(index % 2) * 115.0))
	paused = false
	for frame in 6:
		await physics_frame
	paused = true
	game._refresh_hud()
	await _capture("bosskampf.png")

	game.level = 5
	var upgrades: Array[UpgradeData] = [game.UPGRADES[0] as UpgradeData, game.UPGRADES[2] as UpgradeData, game.UPGRADES[3] as UpgradeData]
	game.choice_panel.show_upgrades(upgrades)
	game._refresh_hud()
	await _capture("levelaufstieg.png")

	game.choice_panel.visible = false
	game._clear_arena(false)
	game.wave.current_wave = 4
	game.coins = 45
	game._open_shop()
	game.shop.offers.clear()
	for offer_index in [11, 0, 13]:
		game.shop.offers.append(ShopController.CATALOG[offer_index])
	game._update_shop_panel()
	await _capture("shop.png")

	session.clear_run()
	quit()


func _capture(file_name: String) -> void:
	for frame in 4:
		await process_frame
	var screenshot: Image = root.get_texture().get_image()
	if screenshot == null or screenshot.is_empty():
		push_error("Screenshot konnte nicht aufgenommen werden: " + file_name)
		return
	var path := ProjectSettings.globalize_path(SCREENSHOT_DIR.path_join(file_name))
	var result := screenshot.save_png(path)
	if result != OK:
		push_error("Screenshot konnte nicht gespeichert werden: " + path)
	else:
		print("Screenshot: ", path)
