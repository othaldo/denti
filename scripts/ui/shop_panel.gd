class_name ShopPanel
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")
const RELOAD_ICON: Texture2D = preload("res://assets/ui/reload_light.svg")
const UPGRADE_ICON: Texture2D = preload("res://assets/ui/upgrade_ready.svg")
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
var offer_buttons: Array[Button] = []
var reroll_button: Button
var continue_button: Button
var inventory_label: Label
var inventory_row: Control
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
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	$Root/Dim.color = DentiUIStyle.BACKGROUND
	DentiUIStyle.style_dialog($Root/Center/Panel)
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	rows.add_theme_constant_override("separation", 12)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	rows.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	title_label = ShopDetails._label(titles, "Zahnklinik", 27)
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var wallet_box := VBoxContainer.new()
	wallet_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	story_timeline = StoryTimeline.new()
	rows.add_child(story_timeline)
	story_timeline.visible = false
	main_scroll = ScrollContainer.new()
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(main_scroll)
	main_scroll.resized.connect(_size_offer_grid)
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
	offers_header = header
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
	inventory_row = Control.new()
	inventory_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	details.evolution_requested.connect(func(id: StringName) -> void: evolution_requested.emit(selected_index, id))
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
	detail_buy_button = _button(detail_actions, "Kaufen", true)
	detail_buy_button.icon = ICONS.hud(2)
	detail_buy_button.add_theme_constant_override("icon_max_width", 23)
	detail_buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_buy_button.pressed.connect(func() -> void: buy_requested.emit(selected_index))
	detail_pin_button = _button(detail_actions, "")
	detail_pin_button.add_theme_constant_override("icon_max_width", 23)
	detail_pin_button.pressed.connect(func() -> void: reservation_requested.emit(selected_index))
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
	left_scroll.resized.connect(_layout_inventory)
	inventory_scroll.resized.connect(_layout_inventory)
	_build_night_layout()
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
		amalgam_chip.tooltip_text = "Amalgamkern\n" + player.items.armor_damage_explanation()

func _update_layout() -> void:
	if offer_scroll == null:
		return
	var extent: Vector2 = $Root.size
	var wide := extent.x >= 1000 and extent.y >= 560
	compact = not wide
	var narrow := extent.x < 600
	var short := extent.y < 700
	rows.add_theme_constant_override("separation", 8 if short else 12)
	build_portrait.custom_minimum_size = Vector2(40, 40) if short else Vector2(56, 56)
	for chip in stat_chips:
		chip.custom_minimum_size.y = 30 if short else 34
	amalgam_chip.custom_minimum_size.y = 30 if short else 34
	flow.vertical = compact
	shop_actions.vertical = narrow and extent.y >= 480
	detail_actions.vertical = narrow and extent.y >= 480
	_refresh_header()
	details.heading.add_theme_font_size_override("font_size", 17 if narrow else 21)
	details.icon.custom_minimum_size = Vector2(48, 48) if narrow else Vector2(64, 64)
	left_scroll.custom_minimum_size.x = 0 if compact else 280
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	left_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	offer_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if compact else ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	offer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	offers_grid.columns = 4 if wide else (2 if extent.x >= 600 else 1)
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
	items_scroll.custom_minimum_size.y = 52
	reroll_button.custom_minimum_size = Vector2(72, 40)
	reroll_button.add_theme_font_size_override("font_size", 14)
	continue_button.custom_minimum_size = Vector2(148, 44)
	continue_button.add_theme_font_size_override("font_size", 14)
	for button in [details.merge_button, details.sell_button, details.confirm_button, details.cancel_button, detail_buy_button, detail_pin_button]:
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 15)
		DentiUIMotion.bind_action(button)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for card in offer_buttons:
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.set_catalog_layout(true, wide and extent.y < 700, compact)
		if wide and extent.x >= 1500:
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
	if offers_grid == null:
		return
	if compact:
		offers_grid.custom_minimum_size.y = 0
		return
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
	offers_grid.custom_minimum_size.y = minf(560, maxf($Root.size.y - 24 - required, 0))


func _layout_inventory() -> void:
	if inventory_row == null:
		return
	var columns := 6 if compact and left_scroll.size.x >= 420 else 2
	var width := maxf(inventory_scroll.size.x, 180)
	var gap := 5.0
	var unit := floorf((width - gap * (columns - 1)) / columns)
	var slot_height := 44.0 if $Root.size.y < 700 else 56.0
	var occupied: Array[bool] = []
	occupied.resize(WeaponLoadout.CAPACITY)
	occupied.fill(false)
	for slot in inventory_row.get_children():
		var button: Button = slot.get_child(0)
		var roots := int(button.get_meta("hands", 1))
		var position_index := 0
		while position_index < occupied.size():
			if position_index % columns + roots <= columns and not occupied[position_index] and (roots == 1 or not occupied[position_index + 1]):
				break
			position_index += 1
		for offset in roots:
			occupied[position_index + offset] = true
		slot.position = Vector2((position_index % columns) * (unit + gap), (position_index / columns) * (slot_height + gap))
		var desired := Vector2(unit * roots + gap * (roots - 1), slot_height)
		button.custom_minimum_size = desired
		slot.size = desired
	var height := ceili(float(WeaponLoadout.CAPACITY) / columns) * (slot_height + gap) - gap
	inventory_row.custom_minimum_size = Vector2(0, height)
	inventory_scroll.custom_minimum_size.y = height + 4


func show_shop(wave_number: int, coins: int, reroll_cost: int, new_offers: Array[ShopOfferData], new_equipment: Array[Dictionary] = [], used_slots: int = 0, capacity: int = 6, buyable: Array[bool] = [], luck: float = 0.0, collected: Array[Dictionary] = [], counts: Dictionary = {}, offer_dps: Array[float] = [], reserved: Array[bool] = []) -> void:
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
	luck_label.text = "%d %s" % [roundi(luck), DentiAttributes.name_for(DentiAttributes.Type.LUCK)]
	for index in offer_buttons.size():
		var offer := offers[index]
		var count := int(counts.get(str(offer.id), 0)) if offer != null else 0
		offer_buttons[index].show_offer(offer, coins, buyable.is_empty() or buyable[index], count, offer_dps[index] if index < offer_dps.size() else 0.0)
		offer_buttons[index].show_reservation(index < reserved.size() and reserved[index])
		if offer != null and offer.weapon_data != null:
			offer_buttons[index].show_weapon_values(offer.weapon_data, offer.weapon_tier, player)
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
			if data != null and data.evolution_kind != &"":
				DentiUIStyle.style_rarity_panel(details_panel, tier, WeaponPresentation.EVOLUTION_COLOR)
				details_panel.tooltip_text = "Spezialwaffe · Mk V"
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
		if player != null:
			details.show_evolutions(player.loadout.ready_evolutions(selected_index, player.items))
		details.sell_button.visible = true
		details.sell_button.text = "Verkaufen · +%d Münzen" % int(entry.refund)
		details.merge_button.visible = true
		details.merge_button.disabled = not bool(entry.mergeable)
		details.merge_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if details.merge_button.disabled else Control.CURSOR_POINTING_HAND
		details.merge_button.text = "Maximale Stufe IV" if tier == 4 else "Fusionieren · Stufe %s" % ["I", "II", "III", "IV"][tier]
		if data.evolution_kind != &"":
			details.merge_button.text = "Maximale Stufe V"
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
	var fusion := false
	for entry in equipment:
		var data: WeaponData = entry.get("data")
		if data != null and offer.weapon_data != null and data.id == offer.weapon_data.id and int(entry.tier) == offer.weapon_tier and offer.weapon_tier < 4:
			fusion = player != null and player.loadout.used_slots() + offer.weapon_data.hands > WeaponLoadout.CAPACITY
	offer_buttons[selected_index].buy_button.tooltip_text = "Kaufen & fusionieren" if fusion and can_buy and wallet >= offer.price else offer_buttons[selected_index].buy_button.tooltip_text
	details.action_hint.text = "Es fehlen %d Münzen" % (offer.price - wallet) if wallet < offer.price else (("Alle Wurzeln belegt" if offer.weapon_data != null else "Stapellimit erreicht") if not can_buy else ("Kauf fusioniert zu Stufe %s" % ["I", "II", "III", "IV"][offer.weapon_tier] if fusion else ""))
	details.action_hint.visible = not details.action_hint.text.is_empty()
	details.action_hint.add_theme_color_override("font_color", DentiUIStyle.CORAL if detail_buy_button.disabled else DentiUIStyle.MINT)
	_highlight_equipment()
	_queue_popup_layout()

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
	_clear(inventory_row)
	for index in entries.size():
		var entry := entries[index]
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_stretch_ratio = float(entry.get("hands", 1))
		inventory_row.add_child(slot)
		var data: WeaponData = entry.get("data")
		var tier := WeaponPresentation.tier_text(data, int(entry.tier))
		var color := WeaponPresentation.tier_color(data, int(entry.tier))
		var button := _button(slot, "")
		DentiUIStyle.style_card(button, int(entry.tier), WeaponPresentation.special_color(data))
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
		tier_label.add_theme_font_size_override("font_size", 12)
		tier_label.add_theme_color_override("font_color", DentiUIStyle.GOLD_INK if data != null and data.evolution_kind != &"" else DentiUIStyle.INK)
		var tier_badge := StyleBoxFlat.new()
		tier_badge.bg_color = color if data != null and data.evolution_kind != &"" else DentiUIStyle.PANEL.lerp(color, 0.16)
		tier_badge.border_color = color
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
		tier_label.offset_left = -51
		tier_label.offset_top = -27
		tier_label.offset_right = -5
		tier_label.offset_bottom = -3
		button.tooltip_text = "%s · %s\n%s\n%s\n%s\nca. %.1f DPS pro Ziel\nAntippen: Details, verkaufen oder fusionieren" % [entry.name, tier, entry.description, entry.combat, entry.stats, entry.dps]
		button.tooltip_text += "\n" + ("Spezialwaffe" if data != null and data.evolution_kind != &"" else "Seltenheit: " + DentiRarity.name_for(int(entry.tier)))
		var evolution_ready := player != null and not player.loadout.ready_evolutions(index, player.items).is_empty()
		if bool(entry.get("mergeable", false)) or evolution_ready:
			var indicator := PanelContainer.new()
			indicator.name = "UpgradeReady"
			indicator.custom_minimum_size = Vector2(28, 28)
			var badge := DentiUIStyle._box(DentiUIStyle.MINT, DentiUIStyle.MINT, 7, 0)
			badge.content_margin_left = 4
			badge.content_margin_right = 4
			badge.content_margin_top = 4
			badge.content_margin_bottom = 4
			indicator.add_theme_stylebox_override("panel", badge)
			indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(indicator)
			indicator.position = Vector2(5, 3)
			var arrow := TextureRect.new()
			arrow.texture = UPGRADE_ICON
			arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			indicator.add_child(arrow)
			button.tooltip_text += "\n" + ("Evolution zu Mk V möglich" if evolution_ready else "Fusion zur nächsten Stufe möglich")
		button.pressed.connect(_select.bind("equipment", index))
		button.gui_input.connect(_on_inventory_input.bind(index))
	for index in maxi(capacity - used_slots, 0):
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_row.add_child(slot)
		var empty := _button(slot, "Freie\nWurzel")
		empty.disabled = true
		empty.add_theme_font_size_override("font_size", 12)
		empty.tooltip_text = "Freie Wurzel"
	_layout_inventory()

func _highlight_equipment() -> void:
	for index in equipment.size():
		var button: Button = inventory_row.get_child(index).get_child(0)
		var partner := false
		if expanded and selected_kind == "equipment" and selected_index >= 0 and selected_index < equipment.size():
			var a: WeaponData = equipment[selected_index].get("data")
			var b: WeaponData = equipment[index].get("data")
			partner = a != null and b != null and a.id == b.id and equipment[index].tier == equipment[selected_index].tier and int(equipment[index].tier) < 4
		DentiUIStyle.style_card(button, int(equipment[index].tier), WeaponPresentation.special_color(equipment[index].get("data")))
		var selected := expanded and selected_kind == "equipment" and selected_index == index
		DentiUIStyle.mark_card(button, DentiUIStyle.INK if selected else (DentiUIStyle.MINT if partner else Color.TRANSPARENT))
	for index in items_row.get_child_count():
		DentiUIStyle.mark_card(items_row.get_child(index), DentiUIStyle.INK if expanded and selected_kind == "item" and selected_index == index else Color.TRANSPARENT)

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
		var tier := int(entry.get("tier", 4 if bool(entry.get("relic", false)) else 1))
		chip.tooltip_text += "\nSeltenheit: " + DentiRarity.name_for(tier)
		DentiUIStyle.style_rarity_panel(chip, tier)
		var chip_style := chip.get_theme_stylebox("panel")
		chip_style.content_margin_left = 6
		chip_style.content_margin_right = 6
		chip_style.content_margin_top = 3
		chip_style.content_margin_bottom = 3
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
		count.add_theme_color_override("font_outline_color", DentiUIStyle.PANEL)
		count.add_theme_constant_override("outline_size", 4)
		count.add_theme_font_size_override("font_size", 14)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	items_label.text = "Gesammelt · %d Items · %d Relikte" % [total, relic_count] if total + relic_count > 0 else "Gesammelt · Keine Items"
	items_scroll.visible = total + relic_count > 0


func _build_night_layout() -> void:
	# The build occupies its own compact column; offers and expanded details share
	# a separate scroll area. Purchase/reservation signals remain authoritative.
	var build_panel := PanelContainer.new()
	build_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_chip(build_panel)
	left_scroll.add_child(build_panel)
	build_column.reparent(build_panel)
	var portrait := TextureRect.new()
	build_portrait = portrait
	portrait.texture = preload("res://assets/denti/denti_unarmed.png")
	portrait.custom_minimum_size = Vector2(56, 56)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 12)
	build_column.add_child(identity)
	build_column.move_child(identity, 0)
	identity.add_child(portrait)
	var name_label := ShopDetails._label(identity, "Denti", 19)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stat_grid = GridContainer.new()
	stat_grid.columns = 2
	stat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_grid.add_theme_constant_override("h_separation", 5)
	stat_grid.add_theme_constant_override("v_separation", 5)
	build_column.add_child(stat_grid)
	stats_label.visible = false
	luck_label.visible = false
	for type in DentiAttributes.ACTIVE:
		var chip := Button.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size = Vector2(0, 34)
		chip.icon = ICONS.stat(DentiAttributes.ICONS[type])
		chip.expand_icon = true
		chip.add_theme_constant_override("icon_max_width", 23)
		chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		DentiUIStyle.style_button(chip, false, true)
		chip.add_theme_font_size_override("font_size", 13)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var box := chip.get_theme_stylebox(state)
			box.content_margin_left = 5
			box.content_margin_right = 5
			box.content_margin_top = 3
			box.content_margin_bottom = 3
		stat_grid.add_child(chip)
		stat_chips.append(chip)
		chip.pressed.connect(func() -> void: DentiDentikon.open_attribute(chip, type))
	amalgam_chip = Button.new()
	amalgam_chip.visible = false
	amalgam_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amalgam_chip.custom_minimum_size.y = 34
	amalgam_chip.icon = ICONS.item(ShopController.by_id(&"amalgam_core").icon_index)
	amalgam_chip.expand_icon = true
	amalgam_chip.add_theme_constant_override("icon_max_width", 23)
	amalgam_chip.add_theme_font_size_override("font_size", 13)
	DentiUIStyle.style_button(amalgam_chip, false, true)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := amalgam_chip.get_theme_stylebox(state)
		box.content_margin_left = 5
		box.content_margin_right = 5
		box.content_margin_top = 3
		box.content_margin_bottom = 3
	stat_grid.add_child(amalgam_chip)
	amalgam_chip.pressed.connect(func() -> void:
		if is_instance_valid(player):
			DentiDentikon.open(amalgam_chip, "Amalgamkern", player.items.armor_damage_explanation(), amalgam_chip.icon)
	)
	offer_scroll = ScrollContainer.new()
	offer_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	flow.add_child(offer_scroll)
	offer_column = VBoxContainer.new()
	offer_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_column.add_theme_constant_override("separation", 12)
	offer_scroll.add_child(offer_column)
	offers_section.reparent(offer_column)
	detail_overlay = Control.new()
	detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(detail_overlay)
	var outside := ColorRect.new()
	outside.color = Color(0, 0, 0, 0.16)
	outside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_overlay.add_child(outside)
	outside.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			close_details()
			outside.accept_event()
		elif event is InputEventScreenTouch and event.pressed:
			close_details()
			outside.accept_event()
	)
	detail_popup = PanelContainer.new()
	DentiUIStyle.style_dialog(detail_popup)
	detail_overlay.add_child(detail_popup)
	detail_column.reparent(detail_popup)
	detail_actions.add_theme_constant_override("separation", 6)
	detail_column.add_theme_constant_override("separation", 8)
	details_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	details_panel.minimum_size_changed.connect(_queue_popup_layout)
	detail_actions.minimum_size_changed.connect(_queue_popup_layout)
	detail_overlay.visible = false
	details.close_button.pressed.connect(close_details)
	detail_column.visible = false
	detail_actions.visible = false


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
