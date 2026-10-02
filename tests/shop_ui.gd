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
		var icon: TextureRect = chip.get_node("Icon/Texture")
		if icon.texture == null or chip.tooltip_text.is_empty():
			_fail("shop item icon or tooltip missing")
			return
		var entry: Dictionary = game.shop_panel.owned_items[chip.get_index()]
		if not _rarity_matches(chip.get_theme_stylebox("panel"), int(entry.tier)) or not chip.tooltip_text.contains("Seltenheit:"):
			_fail("owned item or relic loses its rarity surface")
			return
	var weapon_button: Button = game.shop_panel.inventory_row.get_child(0).get_child(0)
	var free_hand: Button = game.shop_panel.inventory_row.get_child(1).get_child(0)
	if weapon_button.get_meta("hands", 1) != 2 or absf(weapon_button.size.x - 2.0 * free_hand.size.x) > 6.0:
		_fail("two-handed weapon does not occupy two hand widths: weapon %s, free %s, hands %s" % [weapon_button.size, free_hand.size, weapon_button.get_meta("hands", 1)])
		return
	var offer_card: OfferCard = game.shop_panel.offer_buttons[0]
	var rarity_border := offer_card.get_theme_stylebox("normal") as StyleBoxFlat
	if offer_card.rarity_label.visible or rarity_border.border_width_left != 2 or rarity_border.border_color != DentiRarity.color_for(game.shop.offers[0].rarity_tier).lightened(0.20) or not offer_card.tooltip_text.contains("Seltenheit:"):
		_fail("shop rarity lacks a visible border or accessible name")
		return
	if not weapon_button.tooltip_text.contains("DPS") or not weapon_button.tooltip_text.contains("Basis-Schaden") or not offer_card.tooltip_text.contains("DPS") or not offer_card.tooltip_text.contains("Nahkampf"):
		_fail("weapon hover lacks DPS or effect information")
		return
	if not weapon_button.tooltip_text.contains("Schadensart: Schmelz") or not offer_card.rarity_label.text.contains("BOHRUNG") or not offer_card.tooltip_text.contains("Schadensart: Bohrung"):
		_fail("weapon damage types are missing from cards or tooltips")
		return
	var range_cell: HBoxContainer = offer_card.summary_row.get_child(3)
	if (range_cell.get_child(0) as TextureRect).texture != DentiUIIcons.RANGE or range_cell.get_child(1).text.contains("\n") or not range_cell.tooltip_text.begins_with("Reichweite"):
		_fail("range stat is not a single icon/value cell with its meaning on hover")
		return
	var screw := ShopController.by_id(&"damage_1")
	offer_card.show_offer(screw, 100, true, 2)
	if offer_card.name_label.text != screw.display_name or not offer_card.category_label.text.is_empty() or not offer_card.effect_label.text.is_empty() or offer_card.summary_row.get_child_count() != 2:
		_fail("purchase card shows owned count or repeats unconditional stat values")
		return
	for sample in [{"id": &"polish_paste", "mechanic": "35 % Trefferschaden (gesamt max. 80 %)"}, {"id": &"dodge_4", "mechanic": "Jedes 3. Ausweichen gewährt 1 Schildladung"}, {"id": &"damage_2", "mechanic": "Schaden gegen Bosse"}, {"id": &"fluoride_gel", "mechanic": "Schild"}, {"id": &"cavity_bounty", "mechanic": "Alle 12 Kills"}]:
		var item := ShopController.by_id(sample.id)
		offer_card.show_offer(item, 100, true, 2)
		if not offer_card.effect_label.text.contains(sample.mechanic) or not offer_card.tooltip_text.contains(item.effect_text()):
			_fail("compact card loses a special mechanic or its full hover description: %s" % sample.id)
			return
	game._update_shop_panel()
	await process_frame
	await process_frame
	# Hoverable stat cells must still forward purchase-card clicks to inspection.
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = offer_card.summary_row.get_child(0).get_global_rect().get_center()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)
	if not game.shop_panel.expanded or game.shop_panel.selected_kind != "offer":
		_fail("stat hover cells block clicks on the purchase card")
		return
	game.shop_panel.close_details()
	weapon_button = game.shop_panel.inventory_row.get_child(0).get_child(0)
	# Missing font glyphs appear as broken boxes even with correctly encoded UTF-8.
	for tooltip in [weapon_button.tooltip_text, offer_card.tooltip_text]:
		for index in tooltip.length():
			var code: int = tooltip.unicode_at(index)
			if code > 32 and not DentiUIStyle.FONT.has_char(code):
				_fail("shop tooltip uses an unsupported glyph: U+%04X" % code)
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
	var fused_button: Button = game.shop_panel.inventory_row.get_child(0).get_child(0)
	if not _rarity_matches(fused_button.get_theme_stylebox("normal"), 2) or not _rarity_matches(game.shop_panel.details_panel.get_theme_stylebox("panel"), 2):
		_fail("fusion did not update inventory and expanded detail rarity together")
		return
	game.shop_panel.close_details()
	if not _rarity_matches(fused_button.get_theme_stylebox("normal"), 2) or fused_button.get_meta("denti_rarity_marker", Color.TRANSPARENT).a > 0:
		_fail("closing selection clears rarity or leaves a selected inventory marker")
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


func _rarity_matches(style: StyleBoxFlat, tier: int) -> bool:
	var accent := DentiRarity.color_for(tier)
	return style.border_width_left == 2 and style.border_color == accent.lightened(0.20) and style.bg_color == DentiUIStyle.PANEL.lerp(accent, 0.16)
