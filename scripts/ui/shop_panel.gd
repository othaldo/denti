class_name ShopPanel
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")
signal buy_requested(index: int)
signal sell_requested(index: int)
signal merge_requested(index: int)
signal reroll_requested
signal continue_requested

@onready var rows: VBoxContainer = $Root/Center/Panel/Margin/Rows
var title_label: Label
var coins_label: Label
var luck_label: Label
var preview_label: Label
var offer_buttons: Array[Button] = []
var reroll_button: Button
var continue_button: Button
var inventory_label: Label
var inventory_row: HBoxContainer
var items_label: Label
var items_scroll: ScrollContainer
var items_row: HBoxContainer
var details: ShopDetails
var main_scroll: ScrollContainer
var flow: BoxContainer
var offers_grid: GridContainer
var details_panel: PanelContainer
var left_scroll: ScrollContainer
var details_scroll: ScrollContainer
var detail_column: VBoxContainer
var detail_actions: HBoxContainer
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
	preview_label = ShopDetails._label(titles, "", 15)
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
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	left_scroll.add_child(left)
	ShopDetails._label(left, "Angebote", 16)
	offers_grid = GridContainer.new()
	offers_grid.columns = 3
	offers_grid.add_theme_constant_override("h_separation", 9)
	left.add_child(offers_grid)
	for index in 3:
		var card := OfferCard.new()
		card.selection_only = true
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		offers_grid.add_child(card)
		offer_buttons.append(card)
		card.pressed.connect(_select.bind("offer", index))
		card.purchase_requested.connect(func() -> void: buy_requested.emit(index))
	inventory_label = ShopDetails._label(left, "", 17)
	inventory_row = HBoxContainer.new()
	inventory_row.add_theme_constant_override("separation", 5)
	left.add_child(inventory_row)
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
	detail_actions = HBoxContainer.new()
	detail_column.add_child(detail_actions)
	for button in [details.merge_button, details.sell_button, details.confirm_button, details.cancel_button]:
		button.reparent(detail_actions)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
	var actions := HBoxContainer.new()
	rows.add_child(actions)
	reroll_button = _button(actions, "Neu würfeln")
	continue_button = _button(actions, "Weiter", true)
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	items_label = ShopDetails._label(rows, "Items & Relikte", 15)
	items_scroll = ScrollContainer.new()
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(items_scroll)
	items_row = HBoxContainer.new()
	items_row.add_theme_constant_override("separation", 5)
	items_scroll.add_child(items_row)
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()

func set_build_context(context: Player) -> void:
	player = context

func _update_layout() -> void:
	var extent: Vector2 = $Root.size
	compact = extent.x < 1000 or extent.y <= 620
	flow.vertical = compact
	offers_grid.columns = 1 if compact else 3
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
	items_scroll.custom_minimum_size.y = 64 if compact else 58
	for button in [reroll_button, continue_button, details.merge_button, details.sell_button, details.confirm_button, details.cancel_button]:
		button.custom_minimum_size.y = 64 if compact else 54
	for chip in items_row.get_children():
		chip.custom_minimum_size = Vector2(64, 60) if compact else Vector2(56, 52)
	for card in offer_buttons:
		card.set_catalog_layout(not compact)

func show_shop(wave_number: int, coins: int, reroll_cost: int, new_offers: Array[ShopOfferData], preview: String = "", new_equipment: Array[Dictionary] = [], used_slots: int = 0, capacity: int = 6, buyable: Array[bool] = [], luck: float = 0.0, collected: Array[Dictionary] = [], counts: Dictionary = {}, offer_dps: Array[float] = []) -> void:
	offers = new_offers
	equipment = new_equipment
	owned_items = collected
	available = buyable
	wallet = coins
	title_label.text = "Zahnklinik · Welle %d" % wave_number
	coins_label.text = str(coins)
	luck_label.text = "%d Glück" % roundi(luck)
	preview_label.text = preview
	for index in offer_buttons.size():
		var offer := offers[index]
		var count := int(counts.get(str(offer.id), 0)) if offer != null else 0
		offer_buttons[index].show_offer(offer, coins, buyable.is_empty() or buyable[index], count, offer_dps[index] if index < offer_dps.size() else 0.0)
		if offer != null and offer.weapon_data != null:
			offer_buttons[index].effect_label.text = WeaponPresentation.quick_text(offer.weapon_data, offer.weapon_tier, player)
	_show_inventory(equipment, used_slots, capacity)
	_show_items(owned_items)
	if player != null:
		var s := player.stats
		stats_label.text = "Bisskraft %.0f · Härte %.0f · Schmelz %.0f HP\nPutzeifer %.2f s · Glanz %d %% Crit · Speichel %.1f/s\nBewegung %.0f · Zahnglück %.0f" % [s.damage, s.armor, s.max_health, s.attack_interval, roundi(s.crit_chance * 100), s.regen, s.move_speed, s.luck]
	reroll_button.text = "Neu würfeln · %d" % reroll_cost
	reroll_button.disabled = coins < reroll_cost
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
			details.action_hint.text = "%d %s frei\n%s" % [data.hands, "Hand" if data.hands == 1 else "Hände", WeaponPresentation.comparison(data, tier + 1, data, tier, player)]
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
		details.show_item({"name": offer.display_name, "description": offer.description, "icon": offer.icon_texture if offer.icon_texture != null else ICONS.item(offer.icon_index)}, false)
	var can_buy := available.is_empty() or available[selected_index]
	var fusion := false
	for entry in equipment:
		var data: WeaponData = entry.get("data")
		if data != null and offer.weapon_data != null and data.id == offer.weapon_data.id and int(entry.tier) == offer.weapon_tier and offer.weapon_tier < 4:
			fusion = player != null and player.loadout.used_slots() + offer.weapon_data.hands > WeaponLoadout.CAPACITY
	offer_buttons[selected_index].buy_button.tooltip_text = "Kaufen & fusionieren" if fusion and can_buy and wallet >= offer.price else offer_buttons[selected_index].buy_button.tooltip_text
	details.action_hint.text = "Zu wenig Münzen" if wallet < offer.price else (("Hände voll" if offer.weapon_data != null else "Stapellimit erreicht") if not can_buy else ("Kauf fusioniert zu Stufe %s" % ["I", "II", "III", "IV"][offer.weapon_tier] if fusion else ""))
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
	inventory_label.text = "Hände · %d/%d" % [used_slots, capacity]
	_clear(inventory_row)
	for index in entries.size():
		var entry := entries[index]
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_stretch_ratio = float(entry.get("hands", 1))
		inventory_row.add_child(slot)
		var button := _button(slot, ["I", "II", "III", "IV"][int(entry.tier)-1])
		button.custom_minimum_size = Vector2(50, 64)
		button.icon = entry.get("icon")
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 42)
		button.tooltip_text = "%s\n%s\n%s\n≈ %.1f DPS pro Ziel\nAntippen: Details, verkaufen oder fusionieren" % [entry.description, entry.combat, entry.stats, entry.dps]
		button.pressed.connect(_select.bind("equipment", index))
		button.gui_input.connect(_on_inventory_input.bind(index))
	for index in maxi(capacity - used_slots, 0):
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_row.add_child(slot)
		var empty := _button(slot, "＋")
		empty.disabled = true
		empty.custom_minimum_size = Vector2(40, 64)
		empty.tooltip_text = "Freie Hand"

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
	for index in entries.size():
		var entry := entries[index]
		var copies := int(entry.count)
		total += copies
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(64, 60) if compact else Vector2(56, 52)
		chip.focus_mode = Control.FOCUS_ALL
		chip.tooltip_text = "%s ×%d\n%s" % [entry.name, copies, entry.description]
		DentiUIStyle.style_chip(chip, Color(0.91, 0.84, 0.97) if bool(entry.get("relic", false)) else Color(0.96, 0.91, 0.78))
		items_row.add_child(chip)
		chip.gui_input.connect(_on_item_input.bind(index))
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(40, 40)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(holder)
		var icon := TextureRect.new()
		icon.texture = entry.icon
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(icon)
		var count := Label.new()
		count.text = "×%d" % copies
		count.add_theme_color_override("font_color", DentiUIStyle.INK)
		count.add_theme_color_override("font_outline_color", Color.WHITE)
		count.add_theme_constant_override("outline_size", 4)
		count.add_theme_font_size_override("font_size", 14)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	items_label.text = "Items & Relikte · %d" % total
	items_scroll.visible = total > 0

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
