extends "res://tests/support/test_runtime.gd"
## Native visual inspection with isolated APPDATA; writes only .godot captures.

func _initialize() -> void:
	call_deferred("_run")

func _capture(name: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/" + name + ".png")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_poison.json"
	session.clear_run()
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.coins = 80
	game._open_shop()
	game.shop.offers.assign([ItemCatalog.by_id(&"poison_depot"), ItemCatalog.by_id(&"nerve_probe"), ShopController.by_id(&"turbo_drill"), ItemCatalog.by_id(&"mint_essence")])
	for extent in [Vector2i(1280, 720), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		game._update_shop_panel()
		for frame in 12: await process_frame
		if extent.x < 600:
			game.shop_panel.main_scroll.scroll_vertical += roundi(game.shop_panel.offers_grid.global_position.y - game.shop_panel.main_scroll.global_position.y)
		await _capture("poison_shop_%dx%d" % [extent.x, extent.y])
		game.shop_panel._select("offer", 0)
		await _capture("poison_details_%dx%d" % [extent.x, extent.y])
		game.shop_panel.close_details()
		game.shop_panel.hide()
		var options: Array[RelicData] = [RelicCatalog.by_id(&"venom_fang"), RelicCatalog.by_id(&"pilgrim_compass"), RelicCatalog.by_id(&"blood_moon_tooth")]
		game.choice_panel.show_relics(options)
		await _capture("poison_relic_%dx%d" % [extent.x, extent.y])
		game.choice_panel.hide()
		game.shop_panel.show()
	# Actual combat/status markers, with no additional decorative overlays.
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	game.shop_panel.hide()
	game.in_shop = false
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game._refresh_hud()
	game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
	game.items.acquire(ItemCatalog.by_id(&"nerve_probe"))
	game.relics.acquire(&"venom_fang")
	for offset in [Vector2(80, 0), Vector2(160, -30), Vector2(210, 80)]:
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 1000
		game.items._process(0.61)
		WeaponAttackShapes.hit(enemy, WeaponCatalog.by_id(&"turbo_drill"), 1, 1, false, game.items, Vector2.RIGHT)
		enemy._process(0.15)
	await _capture("poison_combat_1280x720")
	session.clear_run()
	finish()
