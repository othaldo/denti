extends "res://tests/support/test_runtime.gd"

var game: Node2D
var ui: ShopPanel


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 12:
		await process_frame


func _check_widgets(extent: Vector2i, context: String) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(extent))
	var panel: Control = ui.get_node("Root/Center/Panel")
	check(bounds.encloses(panel.get_global_rect()), "panel exceeds viewport: " + context)
	for control in [ui.main_scroll, ui.shop_actions, ui.coins_label, ui.reroll_button, ui.continue_button, ui.items_scroll]:
		check(panel.get_global_rect().encloses(control.get_global_rect()), "widget exceeds panel: %s %s" % [control, context])
	var reroll := ui.reroll_button
	var price_width := reroll.get_theme_font("font").get_string_size(reroll.text, HORIZONTAL_ALIGNMENT_LEFT, -1, reroll.get_theme_font_size("font_size")).x
	var icon_width := minf(reroll.icon.get_width(), reroll.get_theme_constant("icon_max_width"))
	var content_width := reroll.size.x - reroll.get_theme_stylebox("normal").get_minimum_size().x - icon_width - reroll.get_theme_constant("h_separation")
	check(reroll.text == str(game.shop.reroll_cost) and price_width <= content_width, "shop reroll price is clipped at %s: %s" % [extent, reroll.text])
	if not ui.flow.vertical:
		_check_column(ui.left_scroll, ui.stat_grid, "stats exceed desktop build area: " + context)
		_check_column(ui.offer_scroll, ui.offers_grid, "offers exceed desktop offer area: " + context)
	for card in ui.offer_buttons:
		for control in [card.icon_rect, card.name_label, card.category_label, card.summary_row, card.effect_label, card.buy_button, card.reserve_button, card.info_badge]:
			if control.is_visible_in_tree():
				check(card.get_global_rect().encloses(control.get_global_rect()), "card widget exceeds its slot: %s %s" % [control, context])
		if card.info_badge.is_visible_in_tree():
			check(not card.name_label.get_global_rect().intersects(card.info_badge.get_global_rect()), "details icon covers the offer name: " + context)
		for label in [card.name_label, card.category_label, card.effect_label]:
			if label.is_visible_in_tree() and not label.text.is_empty():
				check(label.size.y >= label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")), "card text lost its visible height: %s %s" % [label, context])
		if card.effect_label.is_visible_in_tree():
			check(card.effect_label.get_visible_line_count() == card.effect_label.get_line_count(), "shop cuts off its effect summary: " + context)


func _check_column(scroll: ScrollContainer, content: Control, message: String) -> void:
	var area := scroll.get_global_rect().grow(1)
	var bar := scroll.get_v_scroll_bar()
	area.position.y -= scroll.scroll_vertical
	area.size.y += maxf(0, bar.max_value - bar.page)
	check(area.encloses(content.get_global_rect()), message)


func _capture(extent: Vector2i, stage: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var path := "res://.godot/layout_debug/%s_%dx%d.png" % [stage, extent.x, extent.y]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_shop_layout_stability.json"
	session.resume_requested = false
	session.reduced_ui_motion = true
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game._open_shop()
	ui = game.shop_panel
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(1920, 1080), Vector2i(720, 1280), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(extent)
		game.coins = 100000
		game.shop.reroll_cost = 107
		game.items.owned.clear()
		game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}])
		game.shop.offers.assign([ShopController.by_id(&"uv_lamp"), ShopController.by_id(&"mint_essence"), ShopController.by_id(&"metal_crown"), ShopController.by_id(&"amalgam_core")])
		game._update_shop_panel()
		await _settle()
		var panel: Control = ui.get_node("Root/Center/Panel")
		_check_widgets(extent, "empty inventory")
		var offers_viewport := (ui.main_scroll if ui.flow.vertical else ui.offer_scroll).get_global_rect()
		check(offers_viewport.encloses(ui.offer_buttons[0].name_label.get_global_rect()) and offers_viewport.encloses(ui.offer_buttons[0].price_label.get_global_rect()), "shop opens before its first offer is readable at %s" % extent)
		await _capture(extent, "before")
		var before := panel.get_global_rect()
		var footer := ui.shop_actions.get_global_rect()
		var main := ui.main_scroll.get_global_rect()
		var purchase := ui.offer_buttons[0].buy_button.get_global_rect()
		for index in [1, 2, 3]:
			ui.offer_buttons[index].buy_button.pressed.emit()
			check(game.shop.offers[index] == null, "purchase fixture did not buy the offer")
			for frame in 12:
				await process_frame
				check(panel.get_global_rect().is_equal_approx(before), "purchase changed shop bounds at %s: %s -> %s" % [extent, before, panel.get_global_rect()])
				check(ui.shop_actions.get_global_rect().is_equal_approx(footer), "purchase changed footer bounds at %s" % extent)
				check(ui.main_scroll.get_global_rect().is_equal_approx(main), "purchase changed main viewport at %s" % extent)
				if extent.x >= 1000:
					var current := ui.offer_buttons[0].buy_button.get_global_rect()
					check(current.is_equal_approx(purchase), "purchase moved a neighboring buy button at %s: %s to %s" % [extent, purchase, current])
			check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(panel.get_global_rect()), "shop escaped viewport after purchase at %s" % extent)
			check(footer.encloses(ui.continue_button.get_global_rect()) and footer.encloses(ui.items_scroll.get_global_rect()), "footer contents escaped their slot at %s" % extent)
		_check_widgets(extent, "after purchases")
		await _capture(extent, "after")
		# Buying/fusing equipment changes the root grid contents, not its allotted area.
		game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}, {"id": "uv_lamp", "tier": 1}])
		game._update_shop_panel()
		await _settle()
		var inventory := ui.inventory_scroll.get_global_rect()
		game._on_shop_merge(0)
		await _settle()
		check(ui.inventory_scroll.get_global_rect().is_equal_approx(inventory), "fusion changed equipment slot bounds at %s" % extent)
		check(panel.get_global_rect().is_equal_approx(before), "fusion changed shop bounds at %s" % extent)
		game._on_shop_sell(0)
		await _settle()
		check(panel.get_global_rect().is_equal_approx(before), "sale changed shop bounds at %s" % extent)
		ui.close_details()
	# Story progress shares the same viewport budget as equipment and offers.
	game.story.start()
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(720, 1280)]:
		root.content_scale_size = extent
		root.size = extent
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(extent)
		game.shop.offers.assign([ShopController.by_id(&"uv_lamp"), ShopController.by_id(&"mint_essence"), ShopController.by_id(&"metal_crown"), ShopController.by_id(&"amalgam_core")])
		game._update_shop_panel()
		await _settle()
		_check_widgets(extent, "story timeline at " + str(extent))
		check(ui.offers_grid.columns == (4 if extent.x >= 1000 else 2), "short story layout discarded available width")
		await _capture(extent, "story")
	game.story.enabled = false
	# Richer contents and long numbers may consume their own slot, never the viewport.
	for item in ItemCatalog.ALL:
		game.items.acquire(item)
	game.coins = 123456789
	game.shop.reroll_cost = 12345678
	game.wave.current_wave = 123456789
	game.player.stats.damage_bonus = 12345678
	game.player.stats.luck = 1234567
	for extent in [Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1720, 960), Vector2i(720, 1280), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(extent)
		game._update_shop_panel()
		await _settle()
		_check_widgets(extent, "full inventory and large values at " + str(extent))
		for template in ShopController.CATALOG:
			ui.offer_buttons[0].show_offer(template, game.coins)
			if template.weapon_data != null:
				ui.offer_buttons[0].show_weapon_values(template.weapon_data, template.weapon_tier, game.player)
			await _settle()
			_check_widgets(extent, "%s at %s" % [template.id, extent])
	session.clear_run()
	print("Denti shop layout stability test passed" if failures.is_empty() else "%d layout failures" % failures.size())
	finish_checks()
