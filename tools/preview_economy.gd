extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_economy.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots/economy"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	paused = true
	game._clear_arena(false)
	game.wave.current_wave = 4
	game.coins = 59
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "turbo_drill", "tier": 1}, {"id": "water_jet", "tier": 1}])
	for id in [&"gold_probe", &"gold_filling", &"lucky_molar", &"mint_essence"]:
		game.items.acquire(ShopController.by_id(id))
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"gold_probe"), ShopController.by_id(&"gold_extractor"), ShopController.by_id(&"gold_filling"), ShopController.by_id(&"interest_tooth")])
	for index in game.shop.offers.size():
		game.shop.offers[index] = game.shop.offers[index].duplicate()
		game.shop.offers[index].price = EconomyRules.shop_price(game.shop.offers[index].price, 4)
	game._update_shop_panel()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		game.choice_panel.visible = false
		game.shop_panel.visible = true
		game.shop_panel._select("offer", 0)
		await _capture("economy_shop_%dx%d.png" % [extent.x, extent.y])
		game.shop_panel.visible = false
		game.in_shop = false
		game.level = 10
		game.rewards.pending_levels = 2
		game.rewards.level_rerolls = 1
		game.rewards.step = PostWaveRewards.Step.LEVELS
		game._show_level_choice()
		game._refresh_hud()
		await _capture("economy_levelup_%dx%d.png" % [extent.x, extent.y])
	session.clear_run()
	quit(0)

func _capture(filename: String) -> void:
	var pointer := InputEventMouseMotion.new()
	pointer.position = Vector2(2, 2)
	root.push_input(pointer, true)
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://docs/screenshots/economy/" + filename)
	root.get_texture().get_image().save_png(path)
	print(path)
