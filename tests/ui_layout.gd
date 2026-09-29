extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	root.get_node("GameSession").save_path = "user://test_ui_layout_run.json"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	if not paused or game.choice_panel.mode != &"starter":
		_fail("starter choice did not fit on screen")
		return
	if not _starter_fits(game.choice_panel):
		_fail("starter card content exceeds its card or the 1280x720 viewport")
		return
	root.size = Vector2i(1024, 600)
	await process_frame
	await process_frame
	if not _starter_fits(game.choice_panel):
		_fail("starter choice exceeds the 1024x600 viewport")
		return
	root.size = Vector2i(1280, 720)
	await process_frame
	game.choice_panel.buttons[0].pressed.emit()
	game._on_loot_collected(&"xp", game.xp_goal)
	if paused or game.choice_panel.visible:
		_fail("XP opened the level-up overlay during combat")
		return
	game.wave._process(game.wave.remaining)
	await process_frame
	if not paused or not game.choice_panel.visible:
		_fail("level-up overlay did not appear")
		return
	var choice_panel: PanelContainer = game.choice_panel.dialog_panel
	if not _inside(choice_panel.get_global_rect(), Vector2(1280, 720)):
		_fail("level-up dialog exceeds 1280x720")
		return
	var previous_right := -1.0
	for button: Button in game.choice_panel.buttons:
		if not _inside(button.get_global_rect(), Vector2(1280, 720)) or button.position.x < previous_right:
			_fail("upgrade cards overlap or exceed viewport")
			return
		previous_right = button.position.x + button.size.x
		if button.get("icon_rect").texture == null or button.get("effect_label").text.is_empty():
			_fail("upgrade card is missing icon or effect")
			return
	game.choice_panel.buttons[0].pressed.emit()
	if not paused or game.choice_panel.visible or not game.shop_panel.visible:
		_fail("choosing a level-up card did not open the shop")
		return
	await process_frame
	if not paused or not game.shop_panel.visible:
		_fail("shop overlay did not appear")
		return
	var shop_panel: PanelContainer = game.shop_panel.get_node("Root/Center/Panel")
	if not _inside(shop_panel.get_global_rect(), Vector2(1280, 720)):
		_fail("shop dialog exceeds 1280x720")
		return
	for button: Button in game.shop_panel.offer_buttons:
		if not _inside(button.get_global_rect(), Vector2(1280, 720)):
			_fail("shop card exceeds viewport")
			return
		if button.get("icon_rect").texture == null or button.get("name_label").text.is_empty() or button.get("price_label").text.is_empty():
			_fail("shop card is missing item information")
			return
	var first_offer := game.shop_panel.offer_buttons[0] as OfferCard
	for template in ShopController.CATALOG:
		if template.weapon_data != null:
			continue
		first_offer.show_offer(template, 100)
		await process_frame
		if not _within(first_offer.effect_label.get_global_rect(), first_offer.get_global_rect()):
			_fail("item description exceeds shop card: " + str(template.id))
			return
	game._update_shop_panel()
	game.coins = 100
	game._update_shop_panel()
	var offer: ShopOfferData = game.shop.offers[0]
	var coins_before_purchase: int = game.coins
	game.shop_panel.offer_buttons[0].pressed.emit()
	if game.coins != coins_before_purchase - offer.price or game.shop.offers[0] != null or not game.shop_panel.offer_buttons[0].disabled:
		_fail("shop card did not complete a purchase and update")
		return
	for id in [&"turbo_drill", &"floss_whip", &"water_jet", &"enamel_mirror"]:
		game.player.loadout.acquire(WeaponCatalog.by_id(id))
	game._update_shop_panel()
	await process_frame
	for weapon_button: Button in game.shop_panel.inventory_row.get_children():
		if not _inside(weapon_button.get_global_rect(), Vector2(1280, 720)):
			_fail("equipped weapon row exceeds viewport")
			return
	game.choice_panel.show_chest(ShopController.by_id(&"metal_crown"), 3)
	root.size = Vector2i(1024, 600)
	await process_frame
	await process_frame
	var layout_size: Vector2 = game.choice_panel.get_node("Root").size
	if not _inside(game.choice_panel.dialog_panel.get_global_rect(), layout_size) or not _inside(game.choice_panel.buttons[0].get_global_rect(), layout_size) or not _inside(game.choice_panel.buttons[1].get_global_rect(), layout_size):
		_fail("chest decision exceeds the scaled 1024x600 viewport")
		return
	paused = false
	root.get_node("GameSession").clear_run()
	print("Denti UI layout test passed")
	quit(0)


func _inside(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y


func _within(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x and inner.position.y >= outer.position.y and inner.end.x <= outer.end.x and inner.end.y <= outer.end.y


func _starter_fits(panel: ChoicePanel) -> bool:
	var viewport_size: Vector2 = panel.get_node("Root").size
	if not _inside(panel.dialog_panel.get_global_rect(), viewport_size):
		return false
	for button: UpgradeCard in panel.buttons:
		var card_rect := button.get_global_rect()
		var effect_rect := button.effect_label.get_global_rect()
		if not _inside(card_rect, viewport_size) or effect_rect.position.y < card_rect.position.y or effect_rect.end.y > card_rect.end.y:
			return false
	return true


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
