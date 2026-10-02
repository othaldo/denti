extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://attribute_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.content_scale_size = Vector2i(1040, 600)
	await _capture("attribute_starters_landscape", Vector2i(896, 414))
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 1000
	game._open_shop()
	game.shop.offers[0] = ShopController.by_id(&"health_2").duplicate()
	game._update_shop_panel()
	game.shop_panel.offer_buttons[0].buy_button.pressed.emit()
	game.shop_panel._select("item", 0)
	root.content_scale_size = Vector2i(1280, 720)
	await _capture("attribute_shop_after_purchase", Vector2i(1280, 720))
	game.shop_panel.visible = false
	var upgrades: Array[UpgradeData] = []
	for id in ["haerte", "schmelz", "putzeifer", "glanz"]:
		upgrades.append((load("res://data/upgrades/%s.tres" % id) as UpgradeData).with_tier(2))
	game.choice_panel.show_upgrades(upgrades)
	game.choice_panel.update_level_reroll(game.coins, 3, 5)
	root.content_scale_size = Vector2i(360, 640)
	await _capture("attribute_levelup_mobile", Vector2i(360, 640))
	session.clear_run()
	quit()

func _capture(label: String, extent: Vector2i) -> void:
	root.size = extent
	DisplayServer.window_set_size(extent)
	for frame in 12:
		await process_frame
	var path := "res://docs/screenshots/%s.png" % label
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print(path)
