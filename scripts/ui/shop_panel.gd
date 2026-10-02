class_name ShopPanel
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")
const RELOAD_ICON: Texture2D = preload("res://assets/ui/reload.svg")
signal buy_requested(index: int)
signal sell_requested(index: int)
signal merge_requested(index: int)
signal reroll_requested
signal reservation_requested(index: int)
signal continue_requested

@onready var rows: VBoxContainer = $Root/Center/Panel/Margin/Rows
var title_label: Label
var coins_label: Label
var luck_label: Label
var offer_buttons: Array[Button] = []
var reroll_button: Button
var continue_button: Button
var inventory_label: Label
var inventory_row: HBoxContainer
var inventory_scroll: ScrollContainer
var items_label: Label
var items_scroll: ScrollContainer
var items_row: HBoxContainer
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

func _ready() -> void:
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	$Root/Dim.color = Color(0.12, 0.06, 0.13, 0.78)
	DentiUIStyle.style_dialog($Root/Center/Panel)
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	rows.add_theme_constant_override("separation", 5)
	var header := HBoxContainer.new()
	rows.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	title_label = ShopDetails._label(titles, "Zahnklinik", 27)
	var wallet_box := VBoxContainer.new()
	header.add_child(wallet_box)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_END
	wallet_box.add_child(coin_row)
	coins_label = ShopDetails._label(coin_row, "", 18)
	var coin_icon := TextureRect.new()
	coin_icon.texture = ICONS.hud(2)
	coin_icon.custom_minimum_size = Vector2(24, 24)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(coin_icon)
	luck_label = ShopDetails._label(wallet_box, "", 15)
	luck_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	luck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	main_scroll = ScrollContainer.new()
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(main_scroll)
	flow = BoxContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("separation", 10)
	main_scroll.add_child(flow)
	left_scroll = ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	flow.add_child(left_scroll)
	var left := VBoxContainer.new()
	build_column = left
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	left_scroll.add_child(left)
	offers_section = VBoxContainer.new()
	offers_section.add_theme_constant_override("separation", 4)
	left.add_child(offers_section)
	offers_header = HBoxContainer.new()
	offers_section.add_child(offers_header)
	var offers_label := ShopDetails._label(offers_header, "Angebote", 16)
	offers_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offers_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reroll_button = _button(offers_header, "2")
	reroll_button.icon = RELOAD_ICON
	reroll_button.add_theme_constant_override("icon_max_width", 20)
	reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	offers_grid = GridContainer.new()
	offers_grid.columns = 2
	offers_grid.add_theme_constant_override("h_separation", 9)
	offers_section.add_child(offers_grid)
	for index in ShopController.OFFER_COUNT:
		var card := OfferCard.new()
		card.selection_only = true
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		offers_grid.add_child(card)
		offer_buttons.append(card)
		card.pressed.connect(_select.bind("offer", index))
		card.purchase_requested.connect(func() -> void: buy_requested.emit(index))
		card.reservation_requested.connect(func() -> void: reservation_requested.emit(index))
	inventory_label = ShopDetails._label(left, "", 17)
	inventory_scroll = ScrollContainer.new()
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_scroll.custom_minimum_size.y = 76
	left.add_child(inventory_scroll)
	inventory_row = HBoxContainer.new()
	inventory_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	inventory_row.add_theme_constant_override("separation", 5)
	inventory_scroll.add_child(inventory_row)
	stats_label = ShopDetails._label(left, "", 16)
	details_panel = PanelContainer.new()
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_chip(details_panel, Color(0.96, 0.93, 0.85))
	details_scroll = ScrollContainer.new()
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_column = VBoxContainer.new()
	detail_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flow.add_child(detail_column)
	detail_column.add_child(details_scroll)
	details_scroll.add_child(details_panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 8)
	details_panel.add_child(margin)
	details = ShopDetails.new()
	margin.add_child(details)
	details.merge_button.pressed.connect(func() -> void: merge_requested.emit(selected_index))
	details.sell_button.pressed.connect(_confirm_sale)
	details.confirm_button.pressed.connect(func() -> void: sell_requested.emit(selected_index))
	details.cancel_button.pressed.connect(_render_selection)
	details.compare.item_selected.connect(_compare)
	detail_actions = BoxContainer.new()
	detail_column.add_child(detail_actions)
	for button in [details.merge_button, details.sell_button, details.confirm_button, details.cancel_button]:
		button.reparent(detail_actions)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
	var actions := BoxContainer.new()
	shop_actions = actions
	rows.add_child(actions)
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	items_column = VBoxContainer.new()
	items_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_column.add_theme_constant_override("separation", 3)
	actions.add_child(items_column)
	items_label = ShopDetails._label(items_column, "Gesammelt · Keine Items", 13)
	items_scroll = ScrollContainer.new()
	items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	items_column.add_child(items_scroll)
	items_row = HBoxContainer.new()
	items_row.add_theme_constant_override("separation", 5)
	items_scroll.add_child(items_row)
	continue_button = _button(actions, "Weiter", true)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_button.size_flags_vertical = Control.SIZE_SHRINK_END
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	get_viewport().size_changed.connect(_update_layout)
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

func _update_layout() -> void:
	var extent: Vector2 = $Root.size
	var offer_row := extent.x >= 1000 and extent.y >= 560
	compact = not offer_row
	var narrow := extent.x < 600
	shop_actions.vertical = narrow and extent.y >= 480
	detail_actions.vertical = narrow and extent.y >= 480
	items_label.visible = true
	title_label.add_theme_font_size_override("font_size", 21 if extent.y < 480 else 27)
	details.heading.add_theme_font_size_override("font_size", 17 if narrow else 21)
	details.icon.custom_minimum_size = Vector2(40, 40) if narrow else Vector2(56, 56)
	flow.vertical = compact
	# Use the full dialog width for offers; build and comparison stay below.
	var offer_parent: Node = rows if offer_row else build_column
	if offers_section.get_parent() != offer_parent:
		offers_section.reparent(offer_parent)
	if offer_row:
		rows.move_child(offers_section, 1)
	else:
		build_column.move_child(offers_section, 0)
	offers_grid.columns = 4 if offer_row else (2 if extent.x >= 760 else 1)
	detail_column.custom_minimum_size.x = 0 if compact else 380
	var action_parent: Node = rows if compact else detail_column
	if detail_actions.get_parent() != action_parent:
		detail_actions.reparent(action_parent)
	if compact:
		rows.move_child(detail_actions, main_scroll.get_index() + 1)
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if compact else ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact else ScrollContainer.SCROLL_MODE_AUTO
	details_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact else ScrollContainer.SCROLL_MODE_AUTO
	$Root/Center/Panel.custom_minimum_size = Vector2(minf(extent.x - 24, 1180), extent.y - 24)
	for edge in ["left", "right"]:
		$Root/Center/Panel/Margin.add_theme_constant_override("margin_" + edge, 12)
	items_scroll.custom_minimum_size.y = 52 if extent.y < 480 else 58
	reroll_button.custom_minimum_size = Vector2(68, 40)
	reroll_button.add_theme_font_size_override("font_size", 14)
	continue_button.custom_minimum_size = Vector2(148, 44)
	continue_button.add_theme_font_size_override("font_size", 14)
	for button in [details.merge_button, details.sell_button, details.confirm_button, details.cancel_button]:
		button.custom_minimum_size.y = 48 if narrow or extent.y < 480 else (64 if compact else 54)
		button.add_theme_font_size_override("font_size", 15 if narrow else 16)
	for chip in items_row.get_children():
		chip.custom_minimum_size = Vector2(48, 44)
	for card in offer_buttons:
		card.set_catalog_layout(offer_row or extent.x >= 760 or narrow, offer_row)
	_layout_inventory()

func _layout_inventory() -> void:
	var extent: Vector2 = $Root.size
	var slot_width := 64.0 if compact else 80.0
	var slot_height := (72.0 if extent.y >= 480 else 64.0) if compact else 80.0
	inventory_scroll.custom_minimum_size.y = slot_height + 12.0
	for slot in inventory_row.get_children():
		var button: Button = slot.get_child(0)
		var hands := int(button.get_meta("hands", 1))
		button.custom_minimum_size = Vector2(slot_width * hands + 5.0 * (hands - 1), slot_height)

func show_shop(wave_number: int, coins: int, reroll_cost: int, new_offers: Array[ShopOfferData], new_equipment: Array[Dictionary] = [], used_slots: int = 0, capacity: int = 6, buyable: Array[bool] = [], luck: float = 0.0, collected: Array[Dictionary] = [], counts: Dictionary = {}, offer_dps: Array[float] = [], reserved: Array[bool] = []) -> void:
	offers = new_offers
	equipment = new_equipment
	owned_items = collected
	available = buyable
	wallet = coins
	title_label.text = "Zahnklinik · Welle %d" % wave_number
	coins_label.text = str(coins)
	luck_label.text = "%d %s" % [roundi(luck), DentiAttributes.name_for(DentiAttributes.Type.LUCK)]
	for index in offer_buttons.size():
		var offer := offers[index]
		var count := int(counts.get(str(offer.id), 0)) if offer != null else 0
		offer_buttons[index].show_offer(offer, coins, buyable.is_empty() or buyable[index], count, offer_dps[index] if index < offer_dps.size() else 0.0)
		offer_buttons[index].show_reservation(index < reserved.size() and reserved[index])
		if offer != null and offer.weapon_data != null:
			offer_buttons[index].effect_label.text = WeaponPresentation.quick_text(offer.weapon_data, offer.weapon_tier, player)
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
	_render_selection()
	visible = true

func _select(kind: String, index: int) -> void:
	selected_kind = kind
	selected_index = index
	selected_uid = int(equipment[index].get("uid", 0)) if kind == "equipment" else 0
	_render_selection()
	if compact:
		call_deferred("_scroll_to_details")
	else:
		details_scroll.scroll_vertical = 0

func _scroll_to_details() -> void:
	main_scroll.scroll_vertical = roundi(detail_column.position.y)

func _render_selection() -> void:
	details.clear_actions()
	detail_actions.visible = selected_kind == "equipment"
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
		var tier := int(entry.tier)
		details.show_weapon(data, tier, player, true, equipment)
		details.sell_button.visible = true
		details.sell_button.text = "Verkaufen · +%d Münzen" % int(entry.refund)
		details.merge_button.visible = true
		details.merge_button.disabled = not bool(entry.mergeable)
		details.merge_button.text = "Maximale Stufe IV" if tier == 4 else "Fusionieren · Stufe %s" % ["I", "II", "III", "IV"][tier]
		if bool(entry.mergeable):
			details.action_hint.text = "%s frei\n%s" % [data.roots_text(), WeaponPresentation.comparison(data, tier + 1, data, tier, player)]
		else:
			details.action_hint.text = "Kein Fusionspartner" if tier < 4 else ""
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
			details.compare.add_item("Vergleichen: %s · %s" % [entry.name, ["I", "II", "III", "IV"][int(entry.tier)-1]])
		_compare(0)
	else:
		details.show_item({"name": offer.display_name, "description": offer.effect_text() + "\n" + offer.limit_text(), "icon": offer.icon_texture if offer.icon_texture != null else ICONS.item(offer.icon_index)}, false)
	var can_buy := available.is_empty() or available[selected_index]
	var fusion := false
	for entry in equipment:
		var data: WeaponData = entry.get("data")
		if data != null and offer.weapon_data != null and data.id == offer.weapon_data.id and int(entry.tier) == offer.weapon_tier and offer.weapon_tier < 4:
			fusion = player != null and player.loadout.used_slots() + offer.weapon_data.hands > WeaponLoadout.CAPACITY
	offer_buttons[selected_index].buy_button.tooltip_text = "Kaufen & fusionieren" if fusion and can_buy and wallet >= offer.price else offer_buttons[selected_index].buy_button.tooltip_text
	details.action_hint.text = "Zu wenig Münzen" if wallet < offer.price else (("Alle Wurzeln belegt" if offer.weapon_data != null else "Stapellimit erreicht") if not can_buy else ("Kauf fusioniert zu Stufe %s" % ["I", "II", "III", "IV"][offer.weapon_tier] if fusion else ""))
	details.action_hint.visible = not details.action_hint.text.is_empty()
	_highlight_equipment()

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

func _show_inventory(entries: Array[Dictionary], used_slots: int, capacity: int) -> void:
	inventory_label.text = "Wurzeln · %d/%d" % [used_slots, capacity]
	_clear(inventory_row)
	for index in entries.size():
		var entry := entries[index]
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_stretch_ratio = float(entry.get("hands", 1))
		inventory_row.add_child(slot)
		var tier: String = ["I", "II", "III", "IV"][int(entry.tier)-1]
		var button := _button(slot, "")
		button.set_meta("hands", int(entry.get("hands", 1)))
		var icon := TextureRect.new()
		icon.name = "WeaponIcon"
		icon.texture = entry.get("icon")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 6
		icon.offset_top = 6
		icon.offset_right = -6
		icon.offset_bottom = -6
		var tier_label := Label.new()
		tier_label.name = "WeaponTier"
		tier_label.text = tier
		tier_label.add_theme_font_size_override("font_size", 15)
		tier_label.add_theme_color_override("font_color", DentiUIStyle.INK)
		var tier_badge := StyleBoxFlat.new()
		tier_badge.bg_color = DentiUIStyle.GOLD.lightened(0.65)
		tier_badge.border_color = DentiUIStyle.MUTED
		tier_badge.set_border_width_all(1)
		tier_badge.set_corner_radius_all(4)
		tier_badge.content_margin_left = 3
		tier_badge.content_margin_right = 3
		tier_label.add_theme_stylebox_override("normal", tier_badge)
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(tier_label)
		tier_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		tier_label.offset_left = -33
		tier_label.offset_top = -27
		tier_label.offset_right = -5
		tier_label.offset_bottom = -3
		button.tooltip_text = "%s · Stufe %s\n%s\n%s\n%s\nca. %.1f DPS pro Ziel\nAntippen: Details, verkaufen oder fusionieren" % [entry.name, tier, entry.description, entry.combat, entry.stats, entry.dps]
		button.pressed.connect(_select.bind("equipment", index))
		button.gui_input.connect(_on_inventory_input.bind(index))
	for index in maxi(capacity - used_slots, 0):
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_row.add_child(slot)
		var empty := _button(slot, "+")
		empty.disabled = true
		empty.add_theme_font_size_override("font_size", 28)
		empty.tooltip_text = "Freie Wurzel"
	_layout_inventory()

func _highlight_equipment() -> void:
	for index in equipment.size():
		var button: Button = inventory_row.get_child(index).get_child(0)
		var partner := false
		if selected_kind == "equipment" and selected_index >= 0 and selected_index < equipment.size():
			var a: WeaponData = equipment[selected_index].get("data")
			var b: WeaponData = equipment[index].get("data")
			partner = a != null and b != null and a.id == b.id and equipment[index].tier == equipment[selected_index].tier and int(equipment[index].tier) < 4
		DentiUIStyle.style_button(button, partner or (selected_kind == "equipment" and selected_index == index))
	for index in offer_buttons.size():
		offer_buttons[index].modulate = Color.WHITE if selected_kind == "offer" and selected_index == index else Color(0.92, 0.92, 0.92)

func _show_items(entries: Array[Dictionary]) -> void:
	owned_items = entries
	_clear(items_row)
	var total := 0
	var relic_count := 0
	for index in entries.size():
		var entry := entries[index]
		var copies := int(entry.count)
		if bool(entry.get("relic", false)):
			relic_count += copies
		else:
			total += copies
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(48, 44)
		chip.focus_mode = Control.FOCUS_ALL
		chip.tooltip_text = "%s ×%d\n%s" % [entry.name, copies, entry.description]
		DentiUIStyle.style_chip(chip, Color(0.91, 0.84, 0.97) if bool(entry.get("relic", false)) else Color(0.96, 0.91, 0.78))
		var chip_style := chip.get_theme_stylebox("panel")
		chip_style.content_margin_left = 6
		chip_style.content_margin_right = 6
		items_row.add_child(chip)
		chip.gui_input.connect(_on_item_input.bind(index))
		var holder := Control.new()
		holder.name = "Icon"
		holder.custom_minimum_size = Vector2(36, 36)
		holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(holder)
		var icon := TextureRect.new()
		icon.name = "Texture"
		icon.texture = entry.icon
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(icon)
		var count := Label.new()
		count.name = "StackCount"
		count.text = "×%d" % copies
		count.add_theme_color_override("font_color", DentiUIStyle.INK)
		count.add_theme_color_override("font_outline_color", Color.WHITE)
		count.add_theme_constant_override("outline_size", 4)
		count.add_theme_font_size_override("font_size", 14)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	items_label.text = "Gesammelt · %d Items · %d Relikte" % [total, relic_count] if total + relic_count > 0 else "Gesammelt · Keine Items"
	items_scroll.visible = total + relic_count > 0

func _on_item_input(event: InputEvent, index: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("ui_accept"):
		_select("item", index)
		get_viewport().set_input_as_handled()

func _on_inventory_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		merge_requested.emit(index)
		get_viewport().set_input_as_handled()

func _button(parent: Node, text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 54
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_button(button, primary)
	parent.add_child(button)
	return button

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
