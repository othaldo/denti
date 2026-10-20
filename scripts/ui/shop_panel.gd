class_name ShopPanel
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")
const RELOAD_ICON: Texture2D = preload("res://assets/ui/reload_light.svg")
const FOOTER_ICONS_HEIGHT := 52.0
const DESKTOP_MIN_BODY_HEIGHT := 380.0
const DENSE_BODY_HEIGHT := 460.0
const MAX_OFFER_HEIGHT := 560.0
signal buy_requested(index: int)
signal sell_requested(index: int)
signal merge_requested(index: int)
signal evolution_requested(index: int, recipe_id: StringName)
signal reroll_requested
signal reservation_requested(index: int)
signal continue_requested
signal pause_requested

@onready var rows: VBoxContainer = $Root/Center/Panel/Margin/Rows
var title_label: Label
var coins_label: Label
var luck_label: Label
var offer_buttons: Array[OfferCard] = []
var reroll_button: Button
var continue_button: Button
var inventory_label: Label
var inventory_row: EquipmentSlots
var inventory_scroll: ScrollContainer
var items_label: Label
var items_scroll: ScrollContainer
var items_row: CollectedItems
var items_column: VBoxContainer
var details: ShopDetails
var main_scroll: ScrollContainer
var flow: BoxContainer
var offers_grid: GridContainer
var offers_section: VBoxContainer
var offers_header: HBoxContainer
var build_column: VBoxContainer
var details_panel: PanelContainer
var left_scroll: ScrollContainer
var details_scroll: ScrollContainer
var detail_column: VBoxContainer
var detail_actions: BoxContainer
var shop_actions: BoxContainer
var stats_label: Label
var player: Player
var offers: Array[ShopOfferData] = []
var equipment: Array[Dictionary] = []
var owned_items: Array[Dictionary] = []
var available: Array[bool] = []
var wallet: int
var selected_kind := "offer"
var selected_index := 0
var selected_uid: int = 0
var compact := false
var dense_layout := false
var layout_queued := false
var card_layout_profile := Vector3i(-1, -1, -1)
var offer_column: VBoxContainer
var offer_scroll: ScrollContainer
var stat_grid: GridContainer
var stat_chips: Array[Button] = []
var amalgam_chip: Button
var expanded := false
var detail_buy_button: Button
var detail_pin_button: Button
var build_portrait: TextureRect
var detail_overlay: Control
var detail_popup: PanelContainer
var popup_layout_queued := false
var story_timeline: StoryTimeline
var displayed_wave: int = 0

func _ready() -> void:
	ShopLayout.build(self)
	_update_layout()


func set_build_context(context: Player) -> void:
	if player != context:
		if is_instance_valid(player) and player.stats.changed.is_connected(_refresh_stats):
			player.stats.changed.disconnect(_refresh_stats)
		if context != null and not context.stats.changed.is_connected(_refresh_stats):
			context.stats.changed.connect(_refresh_stats)
	player = context
	_refresh_stats()


func _refresh_stats() -> void:
	if not is_instance_valid(player) or stats_label == null:
		return
	stats_label.text = DentiAttributes.shop_text(player.stats)
	luck_label.text = "%s %s" % [DentiAttributes.value_text(player.stats, DentiAttributes.Type.LUCK), DentiAttributes.name_for(DentiAttributes.Type.LUCK)]
	var meanings: PackedStringArray = []
	for type in DentiAttributes.ACTIVE:
		meanings.append("%s: %s" % [DentiAttributes.name_for(type), DentiAttributes.meaning_for(type)])
	stats_label.tooltip_text = "\n".join(meanings)
	for index in stat_chips.size():
		var type: DentiAttributes.Type = DentiAttributes.ACTIVE[index]
		stat_chips[index].text = DentiAttributes.compact_value_text(player.stats, type)
		stat_chips[index].tooltip_text = "%s · %s\n%s" % [DentiAttributes.name_for(type), DentiAttributes.value_text(player.stats, type), DentiAttributes.meaning_for(type)]
	if amalgam_chip != null:
		amalgam_chip.visible = player.items.count(&"amalgam_core") > 0
		amalgam_chip.text = "+%s %%" % ("%.1f" % player.items.armor_damage_bonus()).trim_suffix(".0")
		amalgam_chip.tooltip_text = "Amalgamkern\n" + BuildPresentation.armor_explanation(player.items)

func _queue_layout() -> void:
	if layout_queued:
		return
	layout_queued = true
	call_deferred("_update_layout")


func _update_layout() -> void:
	layout_queued = false
	if offer_scroll == null:
		return
	var extent: Vector2 = $Root.size
	var narrow := extent.x < 600
	var short := extent.y < 700
	rows.add_theme_constant_override("separation", 8 if short else 12)
	shop_actions.vertical = narrow and extent.y >= 480
	detail_actions.vertical = narrow and extent.y >= 480
	reroll_button.custom_minimum_size = Vector2(72, 40)
	reroll_button.add_theme_font_size_override("font_size", 14)
	continue_button.custom_minimum_size = Vector2(148, 44)
	continue_button.add_theme_font_size_override("font_size", 14)
	_refresh_header()
	var body_height := _available_body_height()
	var side_by_side := extent.x >= 1000
	var wide := side_by_side and extent.y >= 560 and body_height >= DESKTOP_MIN_BODY_HEIGHT
	compact = not wide
	dense_layout = side_by_side and (short or body_height < DENSE_BODY_HEIGHT)
	build_portrait.custom_minimum_size = Vector2(40, 40) if short or dense_layout else Vector2(56, 56)
	for chip in stat_chips:
		chip.custom_minimum_size.y = 30 if short or dense_layout else 34
	amalgam_chip.custom_minimum_size.y = 30 if short or dense_layout else 34
	flow.vertical = not side_by_side
	details.heading.add_theme_font_size_override("font_size", 17 if narrow else 21)
	details.icon.custom_minimum_size = Vector2(48, 48) if narrow else Vector2(64, 64)
	left_scroll.custom_minimum_size.x = 280 if side_by_side else 0
	left_scroll.size_flags_horizontal = Control.SIZE_FILL if side_by_side else Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	offer_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if compact else ScrollContainer.SCROLL_MODE_SHOW_NEVER
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if wide else ScrollContainer.SCROLL_MODE_DISABLED
	offer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	offers_grid.columns = 4 if side_by_side else (2 if extent.x >= 600 else 1)
	offers_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	offers_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stat_grid.columns = 3 if extent.x >= 600 else 2
	_sync_detail_layout()
	detail_column.custom_minimum_size.x = 0
	detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_queue_popup_layout()
	$Root/Center/Panel.custom_minimum_size = Vector2(minf(extent.x - 24, 1720), extent.y - 24)
	for edge in ["left", "right"]:
		$Root/Center/Panel/Margin.add_theme_constant_override("margin_" + edge, 12)
	items_scroll.custom_minimum_size.y = FOOTER_ICONS_HEIGHT
	for button in [details.merge_button, details.sell_button, details.confirm_button, details.cancel_button, detail_buy_button, detail_pin_button]:
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 15)
		DentiUIMotion.bind_action(button)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var large_icons := wide and not dense_layout and extent.x >= 1500
	var profile := Vector3i(int(dense_layout), int(not side_by_side), int(large_icons))
	# Unchanged profiles must preserve fitted text slots across purchases/rerolls.
	if profile != card_layout_profile:
		card_layout_profile = profile
		for card in offer_buttons:
			card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			card.set_catalog_layout(true, dense_layout, not side_by_side)
			if large_icons:
				card.icon_rect.custom_minimum_size = Vector2(152, 152)
	_layout_inventory()
	call_deferred("_size_offer_grid")

func _refresh_header() -> void:
	var extent: Vector2 = $Root.size
	var narrow := extent.x < 600
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.text = ("Klinik · %d" if narrow else "Zahnklinik · Welle %d") % displayed_wave
	title_label.add_theme_font_size_override("font_size", 18 if narrow else (21 if extent.y < 480 else 27))


func _size_offer_grid() -> void:
	if offers_grid != null:
		offers_grid.custom_minimum_size.y = 0.0 if compact else minf(MAX_OFFER_HEIGHT, _available_body_height())


func _available_body_height() -> float:
	# Compute the available height from the viewport, not the previous layout's
	# main-scroll size: a large minimum must not prevent a smaller window reflow.
	var margins: MarginContainer = $Root/Center/Panel/Margin
	var required: float = $Root/Center/Panel.get_theme_stylebox("panel").get_minimum_size().y
	required += margins.get_theme_constant("margin_top") + margins.get_theme_constant("margin_bottom")
	var visible_rows := 0
	for child: Control in rows.get_children():
		if child.visible:
			visible_rows += 1
			if child != main_scroll:
				required += child.get_combined_minimum_size().y
	required += rows.get_theme_constant("separation") * maxi(visible_rows - 1, 0)
	return maxf($Root.size.y - 24 - required, 0)


func _layout_inventory() -> void:
	if inventory_row == null:
		return
	var columns := 6 if compact and left_scroll.size.x >= 420 else 2
	inventory_scroll.custom_minimum_size.y = inventory_row.layout_slots(maxf(inventory_scroll.size.x, 180), columns, 44.0 if dense_layout or $Root.size.y < 700 else 56.0)


func show_shop(wave_number: int, coins: int, reroll_cost: int, new_offers: Array[ShopOfferData], new_equipment: Array[Dictionary] = [], used_slots: int = 0, capacity: int = PlayerStats.DEFAULT_ROOT_CAPACITY, buyable: Array[bool] = [], luck: float = 0.0, collected: Array[Dictionary] = [], counts: Dictionary = {}, offer_dps: Array[float] = [], reserved: Array[bool] = []) -> void:
	var model := ShopViewData.new()
	model.wave_number = wave_number
	model.coins = coins
	model.reroll_cost = reroll_cost
	model.offers = new_offers
	model.equipment = new_equipment
	model.used_slots = used_slots
	model.capacity = capacity
	model.buyable = buyable
	model.luck = luck
	model.collected = collected
	model.counts = counts
	model.offer_dps = offer_dps
	model.reserved = reserved
	present(model)


func present(model: ShopViewData) -> void:
	var wave_number := model.wave_number
	var coins := model.coins
	var reroll_cost := model.reroll_cost
	var new_offers := model.offers
	var new_equipment := model.equipment
	var used_slots := model.used_slots
	var capacity := model.capacity
	var buyable := model.buyable
	var luck := model.luck
	var collected := model.collected
	var counts := model.counts
	var offer_dps := model.offer_dps
	var reserved := model.reserved
	displayed_wave = wave_number
	if not visible:
		close_details()
		main_scroll.scroll_vertical = 0
		offer_scroll.scroll_vertical = 0
	offers = new_offers
	equipment = new_equipment
	owned_items = collected
	available = buyable
	wallet = coins
	_refresh_header()
	coins_label.text = str(coins)
	coins_label.tooltip_text = "%d Münzen" % coins
	coins_label.custom_minimum_size.x = clampf(coins_label.get_theme_font("font").get_string_size(coins_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, coins_label.get_theme_font_size("font_size")).x, 40, 100)
	luck_label.text = "%d %s" % [roundi(luck), DentiAttributes.name_for(DentiAttributes.Type.LUCK)]
	for index in offer_buttons.size():
		var offer := offers[index]
		var count := int(counts.get(str(offer.id), 0)) if offer != null else 0
		offer_buttons[index].show_offer(offer, coins, buyable.is_empty() or buyable[index], count, offer_dps[index] if index < offer_dps.size() else 0.0)
		offer_buttons[index].show_reservation(index < reserved.size() and reserved[index])
		if offer != null and offer.weapon_data != null:
			offer_buttons[index].show_weapon_values(offer.weapon_data, offer.weapon_tier, player)
			if player != null and player.loadout.purchase_fusion_target(offer.weapon_data, offer.weapon_tier) != null:
				offer_buttons[index].buy_button.tooltip_text += "\nKaufen & fusionieren: je Attribut der bessere Wert. Verzauberungen bleiben erhalten."
	_show_inventory(equipment, used_slots, capacity)
	_show_items(owned_items)
	_refresh_stats()
	reroll_button.text = str(reroll_cost)
	reroll_button.disabled = coins < reroll_cost
	if reserved.size() == ShopController.OFFER_COUNT and reserved.all(func(value: bool) -> bool: return value):
		reroll_button.disabled = true
		reroll_button.tooltip_text = "Neu würfeln · %d Münzen\nAlle Angebote sind gemerkt. Gib zuerst eines frei." % reroll_cost
	else:
		reroll_button.tooltip_text = "Neu würfeln · %d Münzen\nGemerkte Angebote bleiben erhalten." % reroll_cost
	continue_button.text = "Welle %d starten" % (wave_number + 1)
	continue_button.tooltip_text = continue_button.text
	continue_button.disabled = equipment.is_empty()
	if selected_kind == "equipment":
		var found := -1
		for index in equipment.size():
			if int(equipment[index].get("uid", 0)) == selected_uid:
				found = index
		selected_index = found
		if found < 0:
			selected_kind = "offer"
			selected_index = 0
	if expanded and selected_kind == "offer" and selected_index < offers.size() and offers[selected_index] == null:
		close_details()
	if expanded:
		_render_selection()
		_queue_popup_layout()
	else:
		detail_column.visible = false
		detail_actions.visible = false
	if not visible:
		DentiUIMotion.reveal($Root/Center/Panel)
	visible = true
	_queue_layout()

func _select(kind: String, index: int) -> void:
	expanded = true
	details_scroll.scroll_vertical = 0
	detail_column.visible = true
	detail_overlay.visible = true
	details.close_button.visible = true
	selected_kind = kind
	selected_index = index
	selected_uid = int(equipment[index].get("uid", 0)) if kind == "equipment" else 0
	_render_selection()
	_sync_detail_layout()
	DentiUIMotion.reveal(detail_popup)
	details.close_button.grab_focus()

func _sync_detail_layout() -> void:
	# Inspection floats above the shop. Opening it never removes/reflows offers.
	offers_section.visible = true
	offer_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	detail_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_queue_popup_layout()


func _queue_popup_layout() -> void:
	if detail_popup == null or popup_layout_queued:
		return
	popup_layout_queued = true
	call_deferred("_size_detail_popup")


func _size_detail_popup() -> void:
	popup_layout_queued = false
	if not expanded:
		return
	var extent: Vector2 = $Root.size
	var width := minf(520, extent.x - 32)
	var icon_values := true
	for index in range(0, details.values_grid.get_child_count(), 2):
		if not details.values_grid.get_child(index) is TextureRect:
			icon_values = false
	details.values_grid.columns = 4 if width >= 480 and icon_values else 2
	var style_size := detail_popup.get_theme_stylebox("panel").get_minimum_size()
	var height := details_panel.get_combined_minimum_size().y + style_size.y
	if detail_actions.visible:
		height += detail_actions.get_combined_minimum_size().y + detail_column.get_theme_constant("separation")
	detail_popup.custom_minimum_size = Vector2(width, 0)
	detail_popup.size = Vector2(width, minf(height, extent.y - 32))
	detail_popup.position = (extent - detail_popup.size) * 0.5

func _render_selection() -> void:
	details.clear_actions()
	_highlight_equipment()
	var tier := 0
	if selected_kind == "equipment" and selected_index >= 0 and selected_index < equipment.size():
		tier = int(equipment[selected_index].tier)
	elif selected_kind == "item" and selected_index >= 0 and selected_index < owned_items.size():
		tier = int(owned_items[selected_index].get("tier", 1))
	elif selected_kind == "offer" and selected_index >= 0 and selected_index < offers.size() and offers[selected_index] != null:
		tier = offers[selected_index].rarity_tier
	if tier > 0:
		DentiUIStyle.style_rarity_panel(details_panel, tier)
		details_panel.tooltip_text = "Seltenheit: " + DentiRarity.name_for(tier)
		if selected_kind == "equipment":
			var data: WeaponData = equipment[selected_index].get("data")
			if data != null and (data.evolution_kind != &"" or int(data.chest_upgrades.get("mk", 0)) > 0):
				DentiUIStyle.style_rarity_panel(details_panel, tier, WeaponPresentation.special_color(data))
				details_panel.tooltip_text = ("Evolution · " if data.evolution_kind != &"" else "") + WeaponPresentation.tier_text(data, tier)
	else:
		DentiUIStyle.style_chip(details_panel)
		details_panel.tooltip_text = ""
	var inspect_offer := selected_kind == "offer" and selected_index >= 0 and selected_index < offers.size() and offers[selected_index] != null
	detail_actions.visible = selected_kind == "equipment" or inspect_offer
	detail_buy_button.visible = inspect_offer
	detail_pin_button.visible = inspect_offer
	if selected_kind == "item":
		if selected_index < owned_items.size():
			details.show_item(owned_items[selected_index], true)
		return
	if selected_kind == "equipment":
		if selected_index < 0 or selected_index >= equipment.size():
			return
		var entry := equipment[selected_index]
		var data: WeaponData = entry.get("data")
		if data == null:
			return
		tier = int(entry.tier)
		details.show_weapon(data, tier, player, true, equipment)
		if player != null and selected_index < player.loadout.equipped().size():
			details.show_affixes(player.loadout.equipped()[selected_index], player.stats, player.items)
		if player != null:
			details.show_evolutions(player.loadout.ready_evolutions(selected_index, player.items))
		details.sell_button.visible = true
		details.sell_button.text = "Verkaufen · +%d Münzen" % int(entry.refund)
		details.merge_button.visible = true
		details.merge_button.disabled = not bool(entry.mergeable)
		details.merge_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if details.merge_button.disabled else Control.CURSOR_POINTING_HAND
		details.merge_button.text = "Weitere Mk-Stufen aus Upgrade-Kapseln" if tier == 4 else "Fusionieren · Stufe %s" % ["I", "II", "III", "IV"][tier]
		if data.evolution_kind != &"":
			details.merge_button.text = "Weitere Mk-Stufen aus Upgrade-Kapseln"
		if bool(entry.mergeable):
			var primary := player.loadout.equipped()[selected_index]
			var partner := player.loadout.merge_partner(selected_index)
			var result := player.loadout.fusion_data(primary, partner.data, partner)
			details.action_hint.text = "%s frei · beste Werte\n%s" % [data.roots_text(), _fusion_comparison(result, tier + 1, data, tier)]
		else:
			details.action_hint.text = "Zu viele Verzauberungen für die vorhandenen Plätze" if player != null and player.loadout.merge_affix_conflict(selected_index) else ("Kein Fusionspartner" if tier < 4 else "Verzauberungen wachsen mit weiteren Upgrade-Kapseln.")
		details.action_hint.visible = not details.action_hint.text.is_empty()
		_highlight_equipment()
		return
	if selected_index >= offers.size() or offers[selected_index] == null:
		details.show_item({"name": "Ausverkauft"}, false)
		return
	var offer := offers[selected_index]
	if offer.weapon_data != null:
		details.show_weapon(offer.weapon_data, offer.weapon_tier, player, false, equipment)
		details.compare.clear()
		for entry in equipment:
			details.compare.add_item("Vergleichen: %s · %s" % [entry.name, WeaponPresentation.tier_text(entry.get("data"), int(entry.tier))])
		_compare(0)
	else:
		details.show_item({"name": offer.display_name, "description": offer.effect_text() + "\n" + offer.limit_text(), "icon": offer.icon_texture if offer.icon_texture != null else ICONS.item(offer.icon_index)}, false)
	var can_buy := available.is_empty() or available[selected_index]
	detail_buy_button.text = "Kaufen · %d" % offer.price
	detail_buy_button.disabled = wallet < offer.price or not can_buy
	detail_buy_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if detail_buy_button.disabled else Control.CURSOR_POINTING_HAND
	detail_buy_button.tooltip_text = offer_buttons[selected_index].buy_button.tooltip_text
	var pin: Button = offer_buttons[selected_index].reserve_button
	detail_pin_button.icon = pin.icon
	detail_pin_button.tooltip_text = pin.tooltip_text
	DentiUIStyle.style_button(detail_pin_button, pin.icon == OfferCard.PIN_ICON)
	var target: WeaponInstance
	if player != null and offer.weapon_data != null:
		target = player.loadout.purchase_fusion_target(offer.weapon_data, offer.weapon_tier)
	var fusion_hint := ""
	if target != null:
		details.compare.hide()
		details.compare_text.hide()
		var result := player.loadout.fusion_data(target, offer.weapon_data)
		fusion_hint = "Fusion zu %s · beste Werte\n%s" % [WeaponPresentation.tier_text(result, offer.weapon_tier + 1), _fusion_comparison(result, offer.weapon_tier + 1, target.data, target.tier)]
		detail_buy_button.tooltip_text += "\nFusionspartner: " + WeaponPresentation.weapon_name(target)
		detail_buy_button.text = "Fusion · %d" % offer.price
	details.action_hint.text = "Es fehlen %d Münzen" % (offer.price - wallet) if wallet < offer.price else (("Alle Wurzeln belegt" if offer.weapon_data != null else "Stapellimit erreicht") if not can_buy else fusion_hint)
	details.action_hint.visible = not details.action_hint.text.is_empty()
	details.action_hint.add_theme_color_override("font_color", DentiUIStyle.CORAL if detail_buy_button.disabled else DentiUIStyle.MINT)
	_highlight_equipment()
	_queue_popup_layout()

func _fusion_comparison(result: WeaponData, tier: int, previous: WeaponData, previous_tier: int) -> String:
	var before := WeaponPresentation.values(previous, previous_tier, player)
	var after := WeaponPresentation.values(result, tier, player)
	return WeaponPresentation.comparison(result, tier, previous, previous_tier, player) + "\nCrit %.1f -> %.1f %%" % [before.crit * 100.0, after.crit * 100.0]


func _compare(index: int) -> void:
	if selected_kind != "offer" or equipment.is_empty() or offers[selected_index] == null or offers[selected_index].weapon_data == null:
		return
	var entry := equipment[index]
	var data: WeaponData = entry.get("data")
	if data != null:
		details.compare_text.text = WeaponPresentation.comparison(offers[selected_index].weapon_data, offers[selected_index].weapon_tier, data, int(entry.tier), player)

func _confirm_sale() -> void:
	details.sell_button.visible = false
	details.merge_button.visible = false
	details.confirm_button.visible = true
	details.cancel_button.visible = true
	details.action_hint.text = "Verkaufen? +%d Münzen" % int(equipment[selected_index].refund)
	details.action_hint.visible = true
	_queue_popup_layout()

func _show_inventory(entries: Array[Dictionary], used_slots: int, capacity: int) -> void:
	inventory_label.text = "Wurzeln · %d/%d" % [used_slots, capacity]
	inventory_row.show_entries(entries, player, used_slots, capacity)
	_layout_inventory()


func _highlight_equipment() -> void:
	inventory_row.highlight(equipment, selected_index if expanded and selected_kind == "equipment" else -1)
	items_row.highlight(selected_index if expanded and selected_kind == "item" else -1)


func _show_items(entries: Array[Dictionary]) -> void:
	owned_items = entries
	var counts := items_row.show_entries(entries)
	items_label.text = "Gesammelt · %d Items · %d Relikte" % [counts.x, counts.y] if counts.x + counts.y > 0 else "Gesammelt · Keine Items"
	items_label.tooltip_text = items_label.text


func close_details() -> void:
	var was_expanded := expanded
	expanded = false
	detail_overlay.visible = false
	detail_column.visible = false
	detail_actions.visible = false
	offer_scroll.scroll_vertical = 0
	_sync_detail_layout()
	if was_expanded:
		_highlight_equipment()
		if selected_kind == "offer" and selected_index >= 0 and selected_index < offer_buttons.size():
			offer_buttons[selected_index].grab_focus()
		elif selected_kind == "equipment" and selected_index >= 0 and selected_index < equipment.size():
			inventory_row.get_child(selected_index).get_child(0).grab_focus()
		elif selected_kind == "item" and selected_index >= 0 and selected_index < items_row.get_child_count():
			items_row.get_child(selected_index).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if expanded:
			close_details()
		else:
			pause_requested.emit()
		get_viewport().set_input_as_handled()


func animate_purchase(source: Rect2, offer: ShopOfferData) -> void:
	await get_tree().process_frame
	if not visible:
		return
	var target: Control = items_row
	if offer.weapon_data != null:
		for index in equipment.size():
			var data: WeaponData = equipment[index].get("data")
			if data != null and data.id == offer.weapon_data.id:
				target = inventory_row.get_child(index).get_child(0)
	else:
		for index in owned_items.size():
			if owned_items[index].name == offer.display_name:
				target = items_row.get_child(index)
	var image: Texture2D = offer.weapon_data.sprite if offer.weapon_data != null else (offer.icon_texture if offer.icon_texture != null else ICONS.item(offer.icon_index))
	DentiUIMotion.fly($Root, image, source, target.get_global_rect())
	DentiUIMotion.pulse(coins_label)


func animate_equipment(index: int) -> void:
	await get_tree().process_frame
	if visible and index >= 0 and index < equipment.size():
		DentiUIMotion.pulse(inventory_row.get_child(index).get_child(0))
