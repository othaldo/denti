extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_mobile_shop_spacing.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 207
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}, {"id": "water_jet", "tier": 2}, {"id": "turbo_drill", "tier": 4}, {"id": "prophylaxis_polisher", "tier": 4}])
	for id in [&"fluoride_gel", &"radiant_filling", &"metal_crown", &"gold_probe"]:
		game.items.acquire(ShopController.by_id(id))
	game.relics.acquire(&"tidal_seal")
	game.wave.current_wave = 12
	game._open_shop()
	game.shop.offers.assign([load("res://data/items/mobility_3.tres"), ShopController.by_id(&"radiant_filling"), ShopController.by_id(&"fluoride_gel"), ShopController.by_id(&"gold_probe")])
	var ui: ShopPanel = game.shop_panel
	var capture := "--capture" in OS.get_cmdline_user_args()
	var path := ProjectSettings.globalize_path("res://.codex/mobile-ui-preview")
	if capture:
		DirAccess.make_dir_recursive_absolute(path)
	for extent in [Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1280, 720)]:
		root.content_scale_size = extent
		root.size = extent
		if capture:
			DisplayServer.window_set_size(extent)
		game._update_shop_panel()
		ui.close_details()
		ui.main_scroll.scroll_vertical = 0
		for frame in 12:
			await process_frame
		var row_baselines: Dictionary = {}
		for index in ui.offer_buttons.size():
			var card: OfferCard = ui.offer_buttons[index]
			if card.name_label.size.y < card.name_label.get_theme_font("font").get_height(card.name_label.get_theme_font_size("font_size")):
				_fail("compact offer title has no room to render")
				return
			if extent.x == 720 and (card.size.y > 300 or not ui.main_scroll.get_global_rect().encloses(card.get_global_rect())):
				_fail("portrait item cards waste height or need scrolling: %s / %s" % [card.get_global_rect(), ui.main_scroll.get_global_rect()])
				return
			for control in [card.icon_rect, card.name_label, card.summary_row, card.effect_label, card.buy_button, card.reserve_button]:
				if control.is_visible_in_tree() and not card.get_global_rect().encloses(control.get_global_rect()):
					_fail("offer content leaves its card at %s" % extent)
					return
			var row := index / ui.offers_grid.columns
			if row_baselines.has(row) and not is_equal_approx(card.buy_button.global_position.y, row_baselines[row]):
				_fail("prices lose their common row baseline")
				return
			row_baselines[row] = card.buy_button.global_position.y
			if card.buy_button.size.y < 44 or card.reserve_button.size.y < 44:
				_fail("compact spacing reduced action hit targets")
				return
		if extent.x == 720:
			for card: OfferCard in ui.offer_buttons:
				if card.category_label.visible:
					_fail("compact item offers reserve an empty category row")
					return
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(path + "/shop_%dx%d.png" % [extent.x, extent.y])
			print(path + "/shop_%dx%d.png" % [extent.x, extent.y])
			ui.visible = false
			game.choice_panel.show_chest(ShopController.by_id(&"dodge_2"), 5)
			for frame in 12:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(path + "/chest_%dx%d.png" % [extent.x, extent.y])
			print(path + "/chest_%dx%d.png" % [extent.x, extent.y])
			game.choice_panel.visible = false
			ui.visible = true
	# Pure stat items and mechanics without stats must not allocate empty fields.
	root.content_scale_size = Vector2i(720, 1280)
	root.size = Vector2i(720, 1280)
	game.shop.offers.assign([ShopController.by_id(&"damage_1"), ShopController.by_id(&"cavity_bounty"), ShopController.by_id(&"turbo_drill"), ShopController.by_id(&"water_jet")])
	game._update_shop_panel()
	for frame in 12:
		await process_frame
	if ui.offer_buttons[0].effect_label.visible or ui.offer_buttons[1].summary_row.visible:
		_fail("empty effect/stat blocks still create mobile spacing")
		return
	for card: OfferCard in ui.offer_buttons:
		for control in [card.icon_rect, card.name_label, card.summary_row, card.effect_label, card.buy_button, card.reserve_button]:
			if control.is_visible_in_tree() and not card.get_global_rect().encloses(control.get_global_rect()):
				_fail("compact weapons/items overflow after a reroll")
				return
	# Reflow all real offers, including long names and multi-row weapon stats.
	# Child text minima may change after the Button first resizes.
	for extent in [Vector2i(720, 1280), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		for template in ShopController.CATALOG:
			ui.offer_buttons[0].show_offer(template, 10000)
			for frame in 8:
				await process_frame
			var card: OfferCard = ui.offer_buttons[0]
			for control in [card.icon_rect, card.name_label, card.category_label, card.summary_row, card.effect_label, card.buy_button, card.reserve_button]:
				if control.is_visible_in_tree() and not card.get_global_rect().encloses(control.get_global_rect()):
					_fail("wrapped content overflows at %s for %s" % [extent, template.id])
					return
	paused = false
	session.clear_run()
	print("Denti mobile shop spacing test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
