class_name OfferCard
extends Button

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")
const PIN_ICON: Texture2D = preload("res://assets/ui/pin.svg")
const PIN_LIGHT: Texture2D = preload("res://assets/ui/pin_light.svg")
const INFO_ICON: Texture2D = preload("res://assets/ui/info.svg")

signal purchase_requested
signal reservation_requested

var buy_button: Button
var reserve_button: Button
var selection_only := false
var content: BoxContainer
var catalog_header: HBoxContainer
var info_box: VBoxContainer
var action_box: BoxContainer
var action_spacer: Control
var card_margin: MarginContainer
var icon_rect: TextureRect
var name_label: Label
var rarity_label: Label
var effect_label: Label
var price_label: Label
var buy_caption: Label
var info_badge: TextureRect
var hover_tween: Tween
var catalog_minimum_height := 100.0
var summary_row: GridContainer
var category_label: Label
var stat_font_size := 17
var secondary_font_size := 14
var compact_catalog := false
var fit_queued := false

func set_catalog_layout(vertical: bool, dense: bool = false, compact_grid: bool = false) -> void:
	compact_catalog = compact_grid
	content.vertical = vertical
	action_box.vertical = not vertical
	action_spacer.visible = vertical
	action_box.size_flags_vertical = Control.SIZE_SHRINK_END
	info_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	catalog_header.visible = false
	var action_height := 44.0
	buy_button.custom_minimum_size = Vector2(80, action_height)
	reserve_button.custom_minimum_size = Vector2(action_height, action_height)
	buy_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reserve_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_END
	reserve_button.size_flags_vertical = Control.SIZE_SHRINK_END
	catalog_minimum_height = 272.0 if compact_grid else (356.0 if dense else 436.0)
	custom_minimum_size.y = catalog_minimum_height
	icon_rect.custom_minimum_size = Vector2(88, 88) if dense or compact_grid else Vector2(112, 112)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_label.add_theme_font_size_override("font_size", 18 if compact_grid else (17 if dense else 20))
	effect_label.add_theme_font_size_override("font_size", 13 if dense else 14)
	stat_font_size = 14 if dense else 17
	secondary_font_size = 13 if dense else 14
	category_label.custom_minimum_size.y = ceilf(category_label.get_theme_font("font").get_height(category_label.get_theme_font_size("font_size")))
	if summary_row != null:
		for cell in summary_row.get_children():
			for child in cell.get_children():
				if child is Label:
					child.add_theme_font_size_override("font_size", stat_font_size if bool(cell.get_meta("primary", true)) else secondary_font_size)
	# Desktop cards reserve common text slots; compact rows remove empty fields.
	name_label.custom_minimum_size.y = 2.0 * ceilf(name_label.get_theme_font("font").get_height(name_label.get_theme_font_size("font_size")))
	effect_label.custom_minimum_size.y = (2.0 if dense else 3.0) * ceilf(effect_label.get_theme_font("font").get_height(effect_label.get_theme_font_size("font_size")))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	catalog_header.custom_minimum_size.y = name_label.custom_minimum_size.y if dense else 0.0
	effect_label.max_lines_visible = 2 if dense else 3
	info_box.add_theme_constant_override("separation", 6 if compact_grid else 8)
	content.add_theme_constant_override("separation", 6 if compact_grid else 8)
	action_box.add_theme_constant_override("separation", 4)
	if summary_row != null:
		summary_row.custom_minimum_size.y = 56 if dense else 60
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for edge in ["left", "right"]:
		card_margin.add_theme_constant_override("margin_" + edge, 10 if dense else 14)
	for edge in ["top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + edge, 10 if dense or compact_grid else 16)
	_sync_catalog_slots()



func _ready() -> void:
	custom_minimum_size.y = 100.0
	_build_content()
	DentiUIStyle.style_card(self)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	resized.connect(_queue_fit)
	card_margin.minimum_size_changed.connect(_queue_fit)
	name_label.resized.connect(_queue_fit)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func show_offer(offer: ShopOfferData, coins: int, available: bool = true, _owned_count: int = 0, dps: float = 0.0) -> void:
	if offer == null:
		content.visible = false
		info_badge.visible = false
		text = "Ausverkauft"
		disabled = true
		tooltip_text = ""
		DentiUIStyle.style_button(self)
		return
	content.visible = true
	info_badge.visible = selection_only
	text = ""
	icon_rect.texture = offer.weapon_data.sprite if offer.weapon_data != null else (offer.icon_texture if offer.icon_texture != null else ICONS.item(offer.icon_index))
	name_label.text = offer.display_name
	rarity_label.text = "%s" % DentiRarity.name_for(offer.rarity_tier)
	if offer.weapon_data != null:
		rarity_label.text += " · %s\n%s" % [["I", "II", "III", "IV"][offer.weapon_tier - 1], offer.weapon_data.damage_type_label().to_upper()]
	rarity_label.visible = false
	category_label.visible = selection_only
	category_label.text = "%s · %s · %s" % [offer.weapon_data.damage_type_label(), ["I", "II", "III", "IV"][offer.weapon_tier - 1], offer.weapon_data.roots_text()] if offer.weapon_data != null else ""
	category_label.tooltip_text = rarity_label.text + " · " + category_label.text
	effect_label.text = offer.weapon_data.stats_text(offer.weapon_tier) if offer.weapon_data != null else offer.effect_text()
	_show_summary(offer)
	price_label.text = "%d" % offer.price
	buy_button.disabled = coins < offer.price or not available
	buy_button.get_child(0).modulate = Color.WHITE
	buy_caption.text = "Zu teuer" if coins < offer.price else (("Belegt" if offer.weapon_data != null else "Limit") if not available else "Kaufen")
	var price_color := DentiUIStyle.CORAL if coins < offer.price else (DentiUIStyle.MUTED if not available else DentiUIStyle.GOLD_INK)
	price_label.add_theme_color_override("font_color", price_color)
	buy_caption.add_theme_color_override("font_color", price_color)
	buy_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if buy_button.disabled else Control.CURSOR_POINTING_HAND
	if buy_button.disabled:
		DentiUIMotion.reset(buy_button)
		buy_button.set_meta("denti_action_hovered", false)
	buy_button.tooltip_text = "Es fehlen %d Münzen" % (offer.price - coins) if coins < offer.price else (("Alle Wurzeln belegt" if offer.weapon_data != null else "Stapellimit erreicht") if not available else "Kaufen")
	var blocked := buy_button.get_theme_stylebox("disabled") as StyleBoxFlat
	blocked.border_color = DentiUIStyle.CORAL if coins < offer.price else DentiUIStyle.LINE
	reserve_button.disabled = false
	reserve_button.visible = selection_only
	disabled = (coins < offer.price or not available) and not selection_only
	if offer.weapon_data != null:
		tooltip_text = "%s\n%s\n%s\n%s\nca. %.1f DPS pro Ziel" % [offer.display_name, offer.description, offer.weapon_data.combat_text(), offer.weapon_data.stats_text(offer.weapon_tier), dps]
		if not available:
			tooltip_text += "\nAusrüstung voll: Platz schaffen oder passende Waffe verschmelzen"
	else:
		tooltip_text = "%s\n%s\n%s" % [offer.display_name, offer.effect_text(), offer.limit_text()]
		if not available:
			tooltip_text += "\nLimit erreicht"
	tooltip_text += "\nSeltenheit: " + DentiRarity.name_for(offer.rarity_tier)
	DentiUIStyle.style_card(self, offer.rarity_tier)
	_queue_fit()


func show_reservation(reserved: bool) -> void:
	reserve_button.text = ""
	reserve_button.icon = PIN_ICON if reserved else PIN_LIGHT
	reserve_button.tooltip_text = "Gemerkt · Angebot freigeben" if reserved else "Merken · Kostenlos für später merken; der Preis bleibt gleich."
	reserve_button.visible = selection_only
	DentiUIStyle.style_button(reserve_button, reserved)
	reserve_button.add_theme_font_size_override("font_size", 13)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := reserve_button.get_theme_stylebox(state)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6


func _queue_fit() -> void:
	if fit_queued:
		return
	fit_queued = true
	call_deferred("_fit_content")


func _fit_content() -> void:
	fit_queued = false
	if selection_only:
		if compact_catalog:
			# Clipped labels report no automatic height. Reserve exactly their
			# visible wrapped lines rather than a blank two-line slot on each item.
			var line_height := ceilf(name_label.get_theme_font("font").get_height(name_label.get_theme_font_size("font_size")))
			name_label.custom_minimum_size.y = line_height * clampi(name_label.get_line_count(), 1, 2)
		var height := maxf(catalog_minimum_height, card_margin.get_combined_minimum_size().y)
		if not is_equal_approx(custom_minimum_size.y, height):
			custom_minimum_size.y = height


func _sync_catalog_slots() -> void:
	if not selection_only:
		return
	# Desktop columns share text baselines. Compact rows use only the fields
	# present on the offer; empty metadata/stats must not create vertical gaps.
	category_label.visible = not compact_catalog or not category_label.text.is_empty()
	effect_label.visible = not compact_catalog or not effect_label.text.is_empty()
	if compact_catalog:
		name_label.custom_minimum_size.y = ceilf(name_label.get_theme_font("font").get_height(name_label.get_theme_font_size("font_size")))
		category_label.custom_minimum_size.y = 0
		effect_label.custom_minimum_size.y = 0
		effect_label.max_lines_visible = 2
	if summary_row != null:
		summary_row.visible = not compact_catalog or summary_row.get_child_count() > 0
		if compact_catalog:
			summary_row.custom_minimum_size.y = 0


func set_compact(compact: bool) -> void:
	custom_minimum_size.y = 80.0 if compact else 100.0
	icon_rect.custom_minimum_size = Vector2(58, 58) if compact else Vector2(78, 78)
	card_margin.add_theme_constant_override("margin_top", 6 if compact else 9)
	card_margin.add_theme_constant_override("margin_bottom", 6 if compact else 9)


func _build_content() -> void:
	var info := TextureRect.new()
	info_badge = info
	info.visible = selection_only
	info.texture = INFO_ICON
	info.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)
	info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	info.offset_left = -32
	info.offset_right = -12
	info.offset_top = 10
	info.offset_bottom = 30
	card_margin = MarginContainer.new()
	card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_margin.add_theme_constant_override("margin_left", 13)
	card_margin.add_theme_constant_override("margin_right", 13)
	card_margin.add_theme_constant_override("margin_top", 4)
	card_margin.add_theme_constant_override("margin_bottom", 4)
	card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_margin)
	content = BoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_margin.add_child(content)
	catalog_header = HBoxContainer.new()
	catalog_header.add_theme_constant_override("separation", 6)
	catalog_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalog_header.visible = false
	content.add_child(catalog_header)
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(78, 78)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)
	var details := VBoxContainer.new()
	info_box = details
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 1)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(details)
	name_label = Label.new()
	name_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.max_lines_visible = 2
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(name_label)
	rarity_label = Label.new()
	rarity_label.add_theme_font_size_override("font_size", 13)
	rarity_label.clip_text = true
	rarity_label.size_flags_horizontal = Control.SIZE_FILL
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(rarity_label)
	category_label = Label.new()
	category_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	category_label.add_theme_font_size_override("font_size", 13)
	category_label.clip_text = true
	category_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(category_label)
	effect_label = Label.new()
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_color_override("font_color", DentiUIStyle.TEXT)
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(effect_label)
	var price_chip := Button.new()
	buy_button = price_chip
	buy_button.pressed.connect(func() -> void: purchase_requested.emit())
	price_chip.custom_minimum_size.x = 76.0
	price_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_chip.custom_minimum_size.y = 48
	DentiUIStyle.style_button(price_chip, true)
	DentiUIMotion.bind_action(price_chip)
	var actions := BoxContainer.new()
	action_box = actions
	actions.vertical = true
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(actions)
	actions.add_child(price_chip)
	action_spacer = Control.new()
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_spacer.visible = false
	actions.add_child(action_spacer)
	reserve_button = Button.new()
	reserve_button.custom_minimum_size = Vector2(86, 36)
	reserve_button.icon = PIN_ICON
	reserve_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reserve_button.expand_icon = true
	reserve_button.add_theme_constant_override("icon_max_width", 18)
	reserve_button.pressed.connect(func() -> void: reservation_requested.emit())
	actions.add_child(reserve_button)
	reserve_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	DentiUIMotion.bind_action(reserve_button)
	show_reservation(false)
	var buy_content := VBoxContainer.new()
	buy_content.alignment = BoxContainer.ALIGNMENT_CENTER
	buy_content.add_theme_constant_override("separation", 0)
	buy_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_chip.add_child(buy_content)
	buy_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy_caption = Label.new()
	buy_caption.text = "Kaufen"
	buy_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_caption.add_theme_font_size_override("font_size", 12)
	buy_caption.add_theme_color_override("font_color", DentiUIStyle.GOLD_INK)
	buy_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy_content.add_child(buy_caption)
	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 3)
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy_content.add_child(price_row)
	var coin_icon := TextureRect.new()
	coin_icon.custom_minimum_size = Vector2(22, 22)
	coin_icon.texture = ICONS.hud(2)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_child(coin_icon)
	price_label = Label.new()
	price_label.add_theme_color_override("font_color", DentiUIStyle.GOLD)
	price_label.add_theme_font_size_override("font_size", 19)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_child(price_label)
	price_row.move_child(price_label, 0)


func _on_hover(hovered: bool) -> void:
	if disabled:
		return
	DentiUIMotion.hover_art(icon_rect, hovered)


func _show_summary(offer: ShopOfferData) -> void:
	if summary_row == null:
		summary_row = GridContainer.new()
		summary_row.columns = 2
		summary_row.add_theme_constant_override("h_separation", 5)
		summary_row.add_theme_constant_override("v_separation", 3)
		summary_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(summary_row)
		info_box.move_child(summary_row, effect_label.get_index())
	for child in summary_row.get_children():
		summary_row.remove_child(child)
		child.queue_free()
	effect_label.visible = true
	if offer.weapon_data != null:
		show_weapon_values(offer.weapon_data, offer.weapon_tier, null)
		return
	for key: StringName in offer.stat_changes:
		var type := DentiAttributes.from_key(key)
		if type < 0:
			continue
		var value := float(offer.stat_changes[key])
		var row := _stat_cell(ICONS.stat(DentiAttributes.ICONS[type]), DentiAttributes.bonus_text(type, value).trim_suffix(" " + DentiAttributes.NAMES[type]), DentiAttributes.NAMES[type], true)
		var number: Label = row.get_child(1)
		number.add_theme_color_override("font_color", DentiUIStyle.CORAL if value < 0 else DentiUIStyle.INK)
	effect_label.text = offer.card_effect_text()
	_sync_catalog_slots()


func show_weapon_values(data: WeaponData, tier: int, player: Player) -> void:
	effect_label.text = WeaponPresentation.card_effect(data, tier)
	for child in summary_row.get_children():
		summary_row.remove_child(child)
		child.queue_free()
	var values := WeaponPresentation.values(data, tier, player)
	for entry in [[ICONS.stat(0), "%.1f" % values.damage, "Trefferschaden"], [ICONS.hud(5), "%.2f s" % values.pause, "Angriffspause"]]:
		_stat_cell(entry[0], entry[1], entry[2], true)
	_stat_cell(ICONS.stat(4), "%d %%" % roundi(values.crit * 100), "Krit-Chance", false)
	_stat_cell(ICONS.RANGE, "%d" % roundi(values.range), "Reichweite", false)
	_sync_catalog_slots()


func _stat_cell(texture: Texture2D, value: String, meaning: String, primary: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.set_meta("primary", primary)
	row.add_theme_constant_override("separation", 3)
	row.tooltip_text = meaning + " · " + value
	summary_row.add_child(row)
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = Vector2(22, 22)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(image)
	var number := ShopDetails._label(row, value, stat_font_size if primary else secondary_font_size)
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _make_custom_tooltip(for_text: String) -> Object:
	var label := Label.new()
	label.text = for_text
	label.custom_minimum_size.x = minf(400, get_viewport_rect().size.x - 40)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	return label
