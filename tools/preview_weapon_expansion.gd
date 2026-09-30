extends SceneTree

# Reproducible visual check with an isolated save; never touches the normal run.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_expansion_preview.json"
	session.resume_requested = false
	session.clear_run()
	session.show_fps = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.coins = 150
	game.player.loadout.restore([
		{"id": "fluoride_sprayer", "tier": 2},
		{"id": "fluoride_rocket", "tier": 2},
		{"id": "prophylaxis_polisher", "tier": 2},
		{"id": "toothpick_spear", "tier": 2},
	])
	for index in 18:
		var offset := Vector2.RIGHT.rotated(TAU * float(index) / 18.0) * (80.0 + float(index % 3) * 85.0)
		game._create_enemy(WaveController.SUGAR, game.player.global_position + offset)
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 2000.0
		enemy.max_health = 2000.0
		enemy.set_physics_process(false)
	for frame in 12:
		await physics_frame
	paused = true
	await _capture("weapon_expansion_combat.png")
	game._clear_arena(false)
	game._open_shop()
	for batch in 4:
		game.shop.offers.clear()
		for offset in 3:
			var index := 8 + batch * 3 + offset
			game.shop.offers.append(ShopController.weapon_offer(ShopController.by_id(WeaponCatalog.ALL[index].id), 1) if index < WeaponCatalog.ALL.size() else null)
		game._update_shop_panel()
		await _capture("weapon_expansion_shop_%d.png" % (batch + 1))
	session.clear_run()
	quit()


func _capture(file_name: String) -> void:
	for frame in 4:
		await process_frame
	var screenshot := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://docs/screenshots/" + file_name)
	if screenshot.save_png(path) != OK:
		push_error("Could not save weapon preview: " + path)
	else:
		print("Weapon preview: " + path)
