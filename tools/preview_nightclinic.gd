extends SceneTree

# Actual game UI with an isolated run save. Never overwrites reference captures.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://nightclinic_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 146
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}, {"id": "amalgam_slingshot", "tier": 1}])
	for id in [&"conductive_varnish", &"forbidden_lollipop"]:
		game.items.acquire(ShopController.by_id(id))
	game.relics.acquire(&"tidal_seal")
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"uv_lamp"), ShopController.by_id(&"water_jet"), ShopController.by_id(&"conductive_varnish"), ShopController.by_id(&"forbidden_lollipop")])
	for index in game.shop.offers.size():
		game.shop.offers[index] = game.shop.offers[index].duplicate()
	game._update_shop_panel()
	for extent in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(720, 1280)]:
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		root.size = extent
		game.shop_panel.close_details()
		game.shop_panel.main_scroll.scroll_vertical = 0
		game.shop_panel.offer_scroll.scroll_vertical = 0
		await _capture("nightclinic_shop_%dx%d.png" % [extent.x, extent.y])
		game.shop_panel._select("equipment", 0)
		await _capture("nightclinic_details_%dx%d.png" % [extent.x, extent.y])
		if extent.x == 1920:
			DentiDentikon.open_attribute(game.shop_panel.details.close_button, DentiAttributes.Type.RANGED_DAMAGE)
			await _capture("nightclinic_dentikon.png")
			game.shop_panel.details.close_button.get_child(0).hide()
			await process_frame
	root.content_scale_size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	game.shop_panel.close_details()
	var previous_offers: Array[ShopOfferData] = game.shop.offers.duplicate()
	game.shop.offers.assign([ShopController.by_id(&"turbo_drill"), ShopController.by_id(&"damage_1"), ShopController.by_id(&"crit_1"), ShopController.by_id(&"cavity_bounty")])
	game._update_shop_panel()
	await _capture("nightclinic_shop_clean_cards.png")
	game.shop.offers.assign(previous_offers)
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}, {"id": "amalgam_slingshot", "tier": 2}, {"id": "turbo_drill", "tier": 1}])
	game._update_shop_panel()
	game.shop_panel.inventory_row.get_child(0).get_child(0).release_focus()
	await _capture("nightclinic_inventory_hover.png", game.shop_panel.inventory_row.get_child(2).get_child(0))
	game.game_menu.open_pause()
	game.game_menu._show_options()
	await _capture("nightclinic_settings.png")
	game.game_menu.close_pause()
	game.shop_panel.visible = false
	game.in_shop = false
	var upgrades: Array[UpgradeData] = [load("res://data/upgrades/bisskraft.tres"), load("res://data/upgrades/haerte.tres"), load("res://data/upgrades/glanz.tres"), load("res://data/upgrades/fernschaden.tres")]
	game.choice_panel.show_upgrades(upgrades)
	await _capture("nightclinic_upgrade.png")
	var rarity_options: Array[UpgradeData] = []
	for index in upgrades.size():
		rarity_options.append(upgrades[index].with_tier(index + 1))
	game.choice_panel.show_upgrades(rarity_options)
	game.choice_panel.buttons[1].grab_focus()
	await _capture("nightclinic_upgrade_rarities.png")
	game.choice_panel.visible = false
	game.shop_panel.visible = false
	game.game_menu.visible = false
	game.in_shop = false
	await _capture("nightclinic_hud.png")
	session.clear_run()
	game.queue_free()
	await process_frame
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	paused = false
	await _capture("nightclinic_menu.png")
	quit()


func _capture(filename: String, hovered: Control = null) -> void:
	if hovered != null:
		for frame in 5:
			await process_frame
	var pointer := InputEventMouseMotion.new()
	pointer.position = hovered.get_global_rect().get_center() if hovered != null else Vector2(2, 2)
	root.push_input(pointer, true)
	for frame in (12 if hovered != null else 30):
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://docs/screenshots/" + filename)
	root.get_texture().get_image().save_png(path)
	print(path)
