extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_nightclinic_run.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 500
	game._open_shop()
	game.player.loadout.restore([{"id": "water_jet", "tier": 2}, {"id": "uv_lamp", "tier": 2}, {"id": "floss_whip", "tier": 1}])
	game.shop.offers[2] = ShopController.by_id(&"conductive_varnish").duplicate()
	game._update_shop_panel()
	var ui: ShopPanel = game.shop_panel
	if ui.expanded or ui.detail_column.visible or ui.stat_chips.size() != DentiAttributes.ACTIVE.size():
		_fail("shop opens with filler details or omits active icon stats")
		return
	var panel: PanelContainer = ui.get_node("Root/Center/Panel")
	if (panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color != DentiUIStyle.BACKGROUND:
		_fail("shop does not use the opaque dark surface")
		return
	var pinned_price: int = game.shop.offers[2].price
	ui.offer_buttons[2].reserve_button.pressed.emit()
	ui.reroll_button.pressed.emit()
	if not game.shop.reserved[2] or game.shop.offers[2].price != pinned_price or not ui.offer_buttons[2].reserve_button.visible:
		_fail("item pin/reroll lost its reserved offer or price")
		return
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(720, 1280), Vector2i(568, 320), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 10:
			await process_frame
		for card: OfferCard in ui.offer_buttons:
			if not card.get_global_rect().encloses(card.buy_button.get_global_rect()) or not card.get_global_rect().encloses(card.reserve_button.get_global_rect()):
				_fail("shop card actions overlap the next card at %s: %s / %s" % [extent, card.get_global_rect(), card.buy_button.get_global_rect()])
				return
		var previous_end := -1.0
		var previous_y := -1.0
		for slot in ui.inventory_row.get_children():
			var button: Button = slot.get_child(0)
			var rect := button.get_global_rect()
			if is_equal_approx(rect.position.y, previous_y) and rect.position.x < previous_end - 1:
				_fail("root slots overlap at %s: %s" % [extent, rect])
				return
			previous_y = rect.position.y
			previous_end = rect.end.x
		if extent.x >= 1000 and extent.y >= 560:
			var bounds := Rect2(Vector2.ZERO, Vector2(extent))
			for scroll in [ui.main_scroll, ui.left_scroll, ui.offer_scroll, ui.inventory_scroll]:
				if scroll.get_h_scroll_bar().visible or scroll.get_v_scroll_bar().visible:
					_fail("desktop shows unnecessary shop scrollbars at %s" % extent)
					return
			if not ui.left_scroll.get_global_rect().encloses(ui.stat_grid.get_global_rect()) or not bounds.encloses(panel.get_global_rect()):
				_fail("desktop build was clipped instead of fitting its space")
				return
			ui._select("equipment", 0)
			for frame in 5:
				await process_frame
			if ui.offers_section.visible or not bounds.encloses(ui.details_panel.get_global_rect()):
				_fail("expanded desktop card does not use the free offer area")
				return
			if ui.details_panel.size.x > 640 or ui.detail_actions.get_parent() != ui.detail_column:
				_fail("desktop details stretch beyond the compact card or detach actions")
				return
			ui.close_details()
	# Settings must remain reachable during a mandatory shop pause, and returning
	# must keep that pause. Closing expanded details consumes ESC first.
	ui._select("equipment", 0)
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	root.push_input(escape, true)
	if ui.expanded or not paused:
		_fail("ESC did not close shop details without resuming gameplay")
		return
	root.push_input(escape, true)
	if not game.game_menu.visible or not paused:
		_fail("ESC failed to open pause from the shop")
		return
	game.game_menu.close_pause()
	if not paused or not ui.visible:
		_fail("returning from ESC incorrectly resumed a mandatory shop")
		return
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	for frame in 5:
		await process_frame
	# Every real catalog entry must remain inspectable without hiding long
	# effects or comparison text outside the desktop viewport.
	for template in ShopController.CATALOG:
		game.shop.offers[0] = template.duplicate()
		game._update_shop_panel()
		ui._select("offer", 0)
		for frame in 5:
			await process_frame
		if not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(panel.get_global_rect()):
			_fail("expanded desktop details exceed viewport for %s" % template.id)
			return
		var surface := ui.details_panel.get_theme_stylebox("panel") as StyleBoxFlat
		var offer_surface := ui.offer_buttons[0].get_theme_stylebox("normal") as StyleBoxFlat
		if surface.border_color != offer_surface.border_color or surface.bg_color != offer_surface.bg_color:
			_fail("expanded detail loses the offer rarity for %s" % template.id)
			return
	ui.close_details()
	ui.stat_chips[0].pressed.emit()
	var popup := ui.stat_chips[0].get_child(0) as PopupPanel
	if popup == null or not popup.visible or popup.get_child(0).get_child(0).get_child(1).text != DentiAttributes.NAMES[0]:
		_fail("stat icon does not open its authoritative Dentikon entry")
		return
	for frame in 5:
		await process_frame
	if popup.size.y > 220 or popup.size.x > 440:
		_fail("short Dentikon explanation stretches beyond its content: %s" % popup.size)
		return
	var body: Label = popup.get_child(0).get_child(1)
	if body.get_rect().end.y > popup.size.y:
		_fail("compact Dentikon clips its explanation")
		return
	popup.hide()
	await process_frame
	for extent in [Vector2i(1280, 720), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 5:
			await process_frame
		for term in DentiAttributes.NAMES + DentiDentikon.MECHANICS.keys():
			DentiDentikon.open_term(ui.stat_chips[0], term)
			var entry: PopupPanel = ui.stat_chips[0].get_child(0)
			for frame in 3:
				await process_frame
			var explanation: Label = entry.get_child(0).get_child(1)
			var expected: String = DentiAttributes.meaning_for(DentiAttributes.NAMES.find(term)) if DentiAttributes.NAMES.has(term) else DentiDentikon.MECHANICS[term]
			if entry.size.x > mini(440, extent.x - 32) or entry.size.y > 320 or explanation.text.replace("\n", " ") != expected:
				_fail("Dentikon sizing or wrapping loses text for %s at %s: %s" % [term, extent, entry.size])
				return
			entry.hide()
			await process_frame
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	for frame in 5:
		await process_frame
	# A purchase resolves immediately; visual feedback cannot delay the offer,
	# inventory or coin changes and must clean up while the shop stays paused.
	var previous_motion: bool = session.reduced_ui_motion
	session.reduced_ui_motion = false
	game.shop.offers[2] = ShopController.by_id(&"conductive_varnish").duplicate()
	game._update_shop_panel()
	var before_coins: int = game.coins
	var purchase_price: int = game.shop.offers[2].price
	ui._select("offer", 2)
	for frame in 5:
		await process_frame
	if not ui.detail_buy_button.is_visible_in_tree() or not ui.detail_pin_button.is_visible_in_tree():
		_fail("expanded card lost purchase or pin actions")
		return
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = ui.detail_buy_button.get_global_rect().get_center()
		root.push_input(click, true)
	if game.coins != before_coins - purchase_price or game.shop.offers[2] != null:
		_fail("purchase feedback delayed shop state changes")
		return
	await create_timer(0.6, true).timeout
	for control in get_nodes_in_group("denti_ui_motion"):
		if control.has_meta("denti_flying"):
			_fail("purchase animation left an orphaned icon in the paused shop")
			return
	session.reduced_ui_motion = previous_motion
	paused = false
	session.clear_run()
	print("Denti nightclinic UI test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
