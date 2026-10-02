extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://item_families_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 350
	game.wave.current_wave = 12
	game._open_shop()
	for entry in [
		{"name": "health", "ids": [&"health_1", &"health_2", &"ceramic_shell", &"health_4"]},
		{"name": "mythic", "ids": [&"mythic_heart", &"mythic_armor", &"mythic_crit", &"mythic_tempo"]},
	]:
		for index in 4:
			game.shop.offers[index] = ShopController.by_id(entry.ids[index]).duplicate()
			game.shop.offers[index].price = EconomyRules.shop_price(game.shop.offers[index].price, game.wave.current_wave)
		game._update_shop_panel()
		game.shop_panel._select("offer", 3)
		for extent in [Vector2i(1280, 720), Vector2i(360, 640)]:
			root.content_scale_size = extent
			root.size = extent
			DisplayServer.window_set_size(extent)
			game.shop_panel.main_scroll.scroll_vertical = 0
			for frame in 12:
				await process_frame
			var path := "res://docs/screenshots/item_family_%s_%dx%d.png" % [entry.name, extent.x, extent.y]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			print(path)
	session.clear_run()
	quit()
