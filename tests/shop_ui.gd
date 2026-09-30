extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_shop_ui_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game._open_shop()
	game.items.acquire(ShopController.by_id(&"metal_crown"))
	game.relics.acquire(&"tidal_seal")
	game.shop.offers[0] = ShopController.by_id(&"turbo_drill")
	game._update_shop_panel()
	await process_frame
	await process_frame
	var panel: PanelContainer = game.shop_panel.get_node("Root/Center/Panel")
	if panel.get_global_rect().position.y < 0.0 or panel.get_global_rect().end.y > 720.0:
		_fail("shop panel exceeds the 720 px viewport: %s" % panel.get_global_rect())
		return
	if game.shop_panel.items_row.get_child_count() != 2 or game.shop_panel.items_label.text.contains("Metallkrone"):
		_fail("shop did not render purchased items and relics as icons")
		return
	for chip: PanelContainer in game.shop_panel.items_row.get_children():
		var icon: TextureRect = chip.get_child(0).get_child(0)
		if icon.texture == null or chip.tooltip_text.is_empty():
			_fail("shop item icon or tooltip missing")
			return
	var weapon_button: Button = game.shop_panel.inventory_row.get_child(0).get_child(0)
	var offer_card: OfferCard = game.shop_panel.offer_buttons[0]
	var rarity_font := offer_card.rarity_label.get_theme_font("font")
	var rarity_width := rarity_font.get_string_size(offer_card.rarity_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, offer_card.rarity_label.get_theme_font_size("font_size")).x
	if offer_card.rarity_label.size.x < rarity_width + 12.0:
		_fail("rarity and damage type are visually clipped")
		return
	if not weapon_button.tooltip_text.contains("DPS") or not weapon_button.tooltip_text.contains("Basis-Schaden") or not offer_card.tooltip_text.contains("DPS") or not offer_card.tooltip_text.contains("Nahkampf"):
		_fail("weapon hover lacks DPS or effect information")
		return
	if not weapon_button.tooltip_text.contains("Schadensart: Schmelz") or not offer_card.rarity_label.text.contains("BOHRUNG") or not offer_card.tooltip_text.contains("Schadensart: Bohrung"):
		_fail("weapon damage types are missing from cards or tooltips")
		return
	var starter: WeaponData = game.player.loadout.equipped()[0].data
	game.player.loadout.acquire(starter)
	game._update_shop_panel()
	await process_frame
	game.shop_panel.inventory_row.get_child(0).get_child(0).pressed.emit()
	var merge_button: Button = game.shop_panel.details.merge_button
	if merge_button.disabled or not merge_button.visible or not _inside(panel.get_global_rect(), Vector2(1280, 720)):
		_fail("touch merge button or shop layout missing: %s / %s" % [merge_button.text, panel.get_global_rect()])
		return
	merge_button.pressed.emit()
	if game.player.loadout.equipped().size() != 1 or game.player.loadout.equipped()[0].tier != 2:
		_fail("touch merge button did not fuse matching weapons")
		return
	var many_items: Array[Dictionary] = []
	for template: ShopOfferData in ShopController.CATALOG:
		if template.weapon_data == null:
			many_items.append({"name": template.display_name, "count": 1, "description": template.description, "icon": template.icon_texture if template.icon_texture != null else DentiUIIcons.item(template.icon_index)})
	game.shop_panel._show_items(many_items)
	await process_frame
	if panel.get_global_rect().position.y < 0.0 or panel.get_global_rect().end.y > 720.0 or game.shop_panel.items_scroll.get_h_scroll_bar().max_value <= game.shop_panel.items_scroll.size.x:
		_fail("large item collection does not scroll within the viewport")
		return
	paused = false
	session.clear_run()
	print("Denti shop UI test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)


func _inside(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y
