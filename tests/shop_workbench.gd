extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_shop_workbench.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 150
	game._open_shop()
	game.player.loadout.restore([{"id": "prophylaxis_polisher", "tier": 1}, {"id": "prophylaxis_polisher", "tier": 1}, {"id": "water_jet", "tier": 1}])
	game.items.acquire(ShopController.by_id(&"metal_crown"))
	game.items.acquire(ShopController.by_id(&"metal_crown"))
	game.shop.offers[0] = ShopController.by_id(&"fluoride_rocket")
	game._update_shop_panel()
	var ui: ShopPanel = game.shop_panel
	var balance: int = game.coins
	ui.offer_buttons[0].pressed.emit()
	if game.coins != balance or not ui.offer_buttons[0].buy_button.visible or not ui.details.heading.text.contains("Rakete"):
		_fail("offer inspection changed the run or omitted purchase details")
		return
	ui.inventory_row.get_child(0).get_child(0).pressed.emit()
	if not ui.details.merge_button.visible or ui.details.merge_button.disabled or not ui.details.action_hint.text.contains("Wurzel frei"):
		_fail("equipped weapon lacks fusion and freed-hand preview")
		return
	for character in ui.details.compare_text.text + ui.details.action_hint.text:
		if character != "\n" and not DentiUIStyle.FONT.has_char(character.unicode_at(0)):
			_fail("weapon comparison contains a glyph missing from the bundled font: %s" % character)
			return
	ui.details.sell_button.pressed.emit()
	if game.coins != balance or not ui.details.confirm_button.visible:
		_fail("sale lacked confirmation")
		return
	ui.details.cancel_button.pressed.emit()
	if game.player.loadout.equipped().size() != 3 or ui.details.confirm_button.visible:
		_fail("cancelled sale changed equipment")
		return
	ui.details.merge_button.pressed.emit()
	if game.player.loadout.equipped().size() != 2 or game.player.loadout.equipped()[0].tier != 2 or game.coins != balance:
		_fail("detail fusion did not combine matching weapons")
		return
	ui.inventory_row.get_child(0).get_child(0).pressed.emit()
	if not ui.details.merge_button.disabled:
		_fail("fusion without a partner remained enabled")
		return
	var refund: int = game.player.loadout.refund_for(0)
	ui.details.sell_button.pressed.emit()
	ui.details.confirm_button.pressed.emit()
	if game.coins != balance + refund or game.player.loadout.equipped().size() != 1:
		_fail("confirmed sale did not update coins and hands")
		return
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	ui.items_row.get_child(0).gui_input.emit(touch)
	if not ui.details.heading.text.contains("Metallkrone") or not ui.details.subtitle.text.contains("×2") or ui.details.effect.text.is_empty():
		_fail("touch inspection lacks owned item count and effect")
		return
	var crown_chip: PanelContainer = ui.items_row.get_child(0)
	if not crown_chip.tooltip_text.contains("×2") or crown_chip.get_node("Icon/StackCount").text != "×2":
		_fail("item icon lacks count badge or hover effect")
		return
	game.coins = 0
	game._update_shop_panel()
	ui.offer_buttons[0].pressed.emit()
	if ui.offer_buttons[0].disabled or not ui.offer_buttons[0].buy_button.disabled:
		_fail("unaffordable offer cannot be inspected or remains buyable")
		return
	game.coins = 150
	game._update_shop_panel()
	game.player.stats.damage_bonus += 100
	ui._select("offer", 0)
	var values := WeaponPresentation.values(game.shop.offers[0].weapon_data, 1, game.player)
	if not ui.details.values_grid.get_child(1).text.contains("%.1f" % values.damage):
		_fail("weapon details ignore current build stats")
		return
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(1040, 600)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 5:
			await process_frame
		ui._select("equipment", 0)
		for frame in 3:
			await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(extent))
		var panel: PanelContainer = ui.get_node("Root/Center/Panel")
		if not bounds.encloses(panel.get_global_rect()) or not bounds.encloses(ui.items_scroll.get_global_rect()) or not bounds.encloses(ui.continue_button.get_global_rect()):
			_fail("shop or persistent controls exceed viewport %s" % extent)
			return
		if extent.x < 1000 or extent.y < 560:
			if not ui.compact or ui.offers_grid.columns != (2 if extent.x >= 760 else 1) or not ui.main_scroll.get_global_rect().encloses(ui.details.heading.get_global_rect()):
				_fail("mobile selection did not open reachable stacked details")
				return
	ui._select("offer", 0)
	var price: int = game.shop.offers[0].price
	var before: int = game.coins
	ui._select("equipment", 0)
	for frame in 3:
		await process_frame
	ui.main_scroll.scroll_vertical = 0
	for frame in 3:
		await process_frame
	var direct_button: Button = ui.offer_buttons[0].buy_button
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = direct_button.get_global_rect().get_center()
		root.push_input(click, true)
		await process_frame
	if game.coins != before - price or game.shop.offers[0] != null:
		_fail("explicit buy did not complete purchase")
		return
	game._save_run()
	var saved: Dictionary = session.load_run()
	if saved.get("weapons", []).size() != game.player.loadout.equipped().size():
		_fail("shop operations were not saved")
		return
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}, {"id": "fluoride_rocket", "tier": 1}])
	game.shop.offers[0] = ShopController.by_id(&"magic_toothbrush")
	game._update_shop_panel()
	ui._select("offer", 0)
	if not ui.offer_buttons[0].buy_button.tooltip_text.contains("fusionieren") or ui.offer_buttons[0].buy_button.disabled:
		_fail("matching purchase at full capacity lacks automatic fusion")
		return
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}])
	game._update_shop_panel()
	ui._select("equipment", 0)
	if not ui.details.merge_button.disabled or not ui.details.merge_button.text.contains("IV"):
		_fail("maximum-tier weapon still offers fusion")
		return
	for frame in 3:
		await process_frame
	for button in [ui.details.merge_button, ui.details.sell_button]:
		if not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()):
			_fail("mobile equipment actions cannot be reached without scrolling")
			return
	paused = false
	session.clear_run()
	print("Denti shop workbench test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
