extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://shop_workbench_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 150
	game.player.loadout.restore([{"id": "fluoride_sprayer", "tier": 2}, {"id": "water_jet", "tier": 1}, {"id": "prophylaxis_polisher", "tier": 1}, {"id": "prophylaxis_polisher", "tier": 1}])
	for id in [&"metal_crown", &"floss_reel", &"polish_paste", &"conductive_varnish", &"mint_essence", &"fluoride_gel"]:
		game.items.acquire(ShopController.by_id(id))
	game.items.acquire(ShopController.by_id(&"metal_crown"))
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"uv_lamp"), ShopController.by_id(&"fluoride_rocket"), ShopController.by_id(&"polish_paste"), ShopController.by_id(&"floss_reel")])
	for index in game.shop.offers.size():
		game.shop.offers[index] = game.shop.offers[index].duplicate()
		game.shop.offers[index].price = EconomyRules.shop_price(game.shop.offers[index].price, game.wave.current_wave)
	game._update_shop_panel()
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(1040, 600)]:
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		root.size = extent
		for frame in 8:
			await process_frame
		game.shop_panel._select("offer", 0)
		game.shop_panel.main_scroll.scroll_vertical = 0
		await _capture("shop_workbench_%dx%d.png" % [extent.x, extent.y])
		game.shop_panel._select("equipment", 2)
		await _capture("shop_fusion_%dx%d.png" % [extent.x, extent.y])
		game.game_menu.visible = true
		game.game_menu._show_stats()
		await _capture("build_stats_%dx%d.png" % [extent.x, extent.y])
		game.game_menu._show_items()
		await _capture("build_items_%dx%d.png" % [extent.x, extent.y])
		game.game_menu.visible = false
	session.clear_run()
	quit()

func _capture(filename: String) -> void:
	var pointer := InputEventMouseMotion.new()
	pointer.position = Vector2(2, 2)
	root.push_input(pointer, true)
	for frame in 8:
		await process_frame
	var path := ProjectSettings.globalize_path("res://docs/screenshots/" + filename)
	root.get_texture().get_image().save_png(path)
	print(path)

