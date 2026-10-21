extends "res://tests/support/test_runtime.gd"

var game: Node2D
var ui: ShopPanel
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _settle() -> void:
	for frame in 12:
		await process_frame


func _check_widgets(extent: Vector2i, context: String) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(extent))
	var panel: Control = ui.get_node("Root/Center/Panel")
	_check(bounds.encloses(panel.get_global_rect()), "panel exceeds viewport: " + context)
	for control in [ui.main_scroll, ui.shop_actions, ui.coins_label, ui.reroll_button, ui.continue_button, ui.items_scroll]:
		_check(panel.get_global_rect().encloses(control.get_global_rect()), "widget exceeds panel: %s %s" % [control, context])
	if not ui.compact:
		_check(ui.left_scroll.get_global_rect().encloses(ui.stat_grid.get_global_rect()), "stats exceed desktop build area: " + context)
		_check(ui.main_scroll.get_global_rect().encloses(ui.offers_grid.get_global_rect()), "offers exceed desktop body: " + context)
	for card in ui.offer_buttons:
		for control in [card.icon_rect, card.name_label, card.category_label, card.summary_row, card.effect_label, card.buy_button, card.reserve_button]:
			if control.is_visible_in_tree():
				_check(card.get_global_rect().encloses(control.get_global_rect()), "card widget exceeds its slot: %s %s" % [control, context])
		for label in [card.name_label, card.category_label, card.effect_label]:
			if label.is_visible_in_tree() and not label.text.is_empty():
				_check(label.size.y >= label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")), "card text lost its visible height: %s %s" % [label, context])


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
		game.items.owned.clear()
		game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}])
		game.shop.offers.assign([ShopController.by_id(&"uv_lamp"), ShopController.by_id(&"mint_essence"), ShopController.by_id(&"metal_crown"), ShopController.by_id(&"amalgam_core")])
		game._update_shop_panel()
		await _settle()
		var panel: Control = ui.get_node("Root/Center/Panel")
		_check_widgets(extent, "empty inventory")
		await _capture(extent, "before")
		var before := panel.get_global_rect()
		var footer := ui.shop_actions.get_global_rect()
		var main := ui.main_scroll.get_global_rect()
		for index in [1, 2, 3]:
			ui.offer_buttons[index].buy_button.pressed.emit()
			_check(game.shop.offers[index] == null, "purchase fixture did not buy the offer")
			for frame in 12:
				await process_frame
				_check(panel.get_global_rect().is_equal_approx(before), "purchase changed shop bounds at %s: %s -> %s" % [extent, before, panel.get_global_rect()])
				_check(ui.shop_actions.get_global_rect().is_equal_approx(footer), "purchase changed footer bounds at %s" % extent)
				_check(ui.main_scroll.get_global_rect().is_equal_approx(main), "purchase changed main viewport at %s" % extent)
			_check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(panel.get_global_rect()), "shop escaped viewport after purchase at %s" % extent)
			_check(footer.encloses(ui.continue_button.get_global_rect()) and footer.encloses(ui.items_scroll.get_global_rect()), "footer contents escaped their slot at %s" % extent)
		_check_widgets(extent, "after purchases")
		await _capture(extent, "after")
		# Buying/fusing equipment changes the root grid contents, not its allotted area.
		game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}, {"id": "uv_lamp", "tier": 1}])
		game._update_shop_panel()
		await _settle()
		var inventory := ui.inventory_scroll.get_global_rect()
		game._on_shop_merge(0)
		await _settle()
		_check(ui.inventory_scroll.get_global_rect().is_equal_approx(inventory), "fusion changed equipment slot bounds at %s" % extent)
		_check(panel.get_global_rect().is_equal_approx(before), "fusion changed shop bounds at %s" % extent)
		game._on_shop_sell(0)
		await _settle()
		_check(panel.get_global_rect().is_equal_approx(before), "sale changed shop bounds at %s" % extent)
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
		_check(ui.offers_grid.columns == (4 if extent.x >= 1000 else 2), "short story layout discarded available width")
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
	finish(0 if failures.is_empty() else 1)
