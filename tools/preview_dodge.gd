extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://dodge_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 1000
	game._open_shop()
	game.items.acquire(ShopController.by_id(&"dodge_2"))
	game.items.acquire(ShopController.by_id(&"mythic_dodge"))
	for index in 4:
		game.shop.offers[index] = ShopController.by_id(StringName("dodge_%d" % (index + 1))).duplicate()
	game._update_shop_panel()
	game.shop_panel._select("offer", 2)
	root.content_scale_size = Vector2i(1280, 720)
	await _capture("dodge_shop_desktop", Vector2i(1280, 720))
	root.content_scale_size = Vector2i(360, 640)
	await _capture("dodge_shop_mobile", Vector2i(360, 640))
	game.shop_panel.main_scroll.scroll_vertical = 100000
	await _capture("dodge_shop_mobile_stats", Vector2i(360, 640))
	game.shop_panel.visible = false
	var upgrades: Array[UpgradeData] = []
	for id in ["zahnflutsch", "haerte", "schmelz", "speichel"]:
		upgrades.append((load("res://data/upgrades/%s.tres" % id) as UpgradeData).with_tier(3))
	game.choice_panel.show_upgrades(upgrades)
	game.choice_panel.update_level_reroll(game.coins, 3, 5)
	await _capture("dodge_levelup_mobile", Vector2i(360, 640))
	game.free()
	paused = false
	session.clear_run()
	quit()

func _capture(label: String, extent: Vector2i) -> void:
	root.size = extent
	DisplayServer.window_set_size(extent)
	for frame in 12:
		await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/%s.png" % label))
