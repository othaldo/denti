class_name OfferCard
extends Button

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

signal purchase_requested
signal reservation_requested

var buy_button: Button
var reserve_button: Button
var selection_only := false
var content: BoxContainer
var catalog_header: HBoxContainer
var info_box: VBoxContainer
var card_margin: MarginContainer
var icon_rect: TextureRect
var name_label: Label
var rarity_label: Label
var effect_label: Label
var price_label: Label
var hover_tween: Tween
var dense_catalog := false

func set_catalog_layout(vertical: bool, dense: bool = false) -> void:
	dense_catalog = dense
	content.vertical = vertical
	catalog_header.visible = dense
	if dense:
		if icon_rect.get_parent() != catalog_header:
			icon_rect.reparent(catalog_header)
			name_label.reparent(catalog_header)
	else:
		if icon_rect.get_parent() != content:
			icon_rect.reparent(content)
			content.move_child(icon_rect, 1)
			name_label.reparent(info_box)
			info_box.move_child(name_label, 0)
	buy_button.custom_minimum_size.y = 40 if dense else (48 if vertical else 64)
	reserve_button.custom_minimum_size.y = 32 if dense else 36
	custom_minimum_size.y = 208 if dense else (210 if vertical else 96)
	icon_rect.custom_minimum_size = Vector2(40, 40) if dense else Vector2(48, 48)
	name_label.add_theme_font_size_override("font_size", 16 if dense else 18)
	effect_label.add_theme_font_size_override("font_size", 13 if dense else 14)
	effect_label.max_lines_visible = 2 if dense else -1
	effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if dense else TextServer.OVERRUN_NO_TRIMMING
	for edge in ["left", "right"]:
		card_margin.add_theme_constant_override("margin_" + edge, 9 if dense else 13)



func _ready() -> void:
	custom_minimum_size.y = 100.0
	_build_content()
	DentiUIStyle.style_card(self)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	resized.connect(func() -> void: call_deferred("_fit_content"))
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func show_offer(offer: ShopOfferData, coins: int, available: bool = true, owned_count: int = 0, dps: float = 0.0) -> void:
	if offer == null:
		content.visible = false
		text = "Ausverkauft"
		disabled = true
		tooltip_text = ""
		return
	content.visible = true
	text = ""
	icon_rect.texture = offer.weapon_data.sprite if offer.weapon_data != null else (offer.icon_texture if offer.icon_texture != null else ICONS.item(offer.icon_index))
	name_label.text = "%s MK %s" % [offer.display_name, ["I", "II", "III", "IV"][offer.weapon_tier - 1]] if offer.weapon_data != null else offer.display_name + (" · ×%d" % owned_count if owned_count > 0 else "")
	rarity_label.text = "%s" % DentiRarity.name_for(offer.rarity_tier)
	if offer.weapon_data != null:
		rarity_label.text += " · %s" % offer.weapon_data.damage_type.to_upper()
	DentiUIStyle.style_rarity_label(rarity_label, offer.rarity_tier)
	effect_label.text = offer.weapon_data.stats_text(offer.weapon_tier) if offer.weapon_data != null else offer.description
	price_label.text = "%d" % offer.price
	buy_button.disabled = coins < offer.price or not available
	buy_button.get_child(0).modulate = Color(1, 1, 1, 0.45) if buy_button.disabled else Color.WHITE
	buy_button.tooltip_text = "Zu wenig Münzen" if coins < offer.price else ("Nicht verfügbar" if not available else "Kaufen")
	reserve_button.disabled = false
	disabled = (coins < offer.price or not available) and not selection_only
	if offer.weapon_data != null:
		tooltip_text = "%s\n%s\n%s\n≈ %.1f DPS pro Ziel" % [offer.description, offer.weapon_data.combat_text(), effect_label.text, dps]
		if not available:
			tooltip_text += "\nAusrüstung voll: Platz schaffen oder passende Waffe verschmelzen"
	else:
		tooltip_text = "Limit erreicht: %d Stück" % offer.max_stacks if not available else effect_label.text
	DentiUIStyle.style_card(self, offer.rarity_tier)
	call_deferred("_fit_content")


func show_reservation(reserved: bool) -> void:
	reserve_button.text = "Gemerkt" if reserved else "Merken"
	reserve_button.tooltip_text = "Angebot freigeben" if reserved else "Kostenlos für später merken; der Preis bleibt gleich."
	reserve_button.visible = selection_only
	DentiUIStyle.style_button(reserve_button, reserved)
	reserve_button.add_theme_font_size_override("font_size", 13)


func _fit_content() -> void:
	if selection_only:
		custom_minimum_size.y = maxf(208.0 if dense_catalog else (96.0 if not content.vertical else 210.0), card_margin.get_combined_minimum_size().y + (8.0 if dense_catalog else 0.0))


func set_compact(compact: bool) -> void:
	custom_minimum_size.y = 80.0 if compact else 100.0
	icon_rect.custom_minimum_size = Vector2(58, 58) if compact else Vector2(78, 78)
	card_margin.add_theme_constant_override("margin_top", 6 if compact else 9)
	card_margin.add_theme_constant_override("margin_bottom", 6 if compact else 9)


func _build_content() -> void:
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
	effect_label = Label.new()
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
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
	var actions := VBoxContainer.new()
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(actions)
	actions.add_child(price_chip)
	reserve_button = Button.new()
	reserve_button.custom_minimum_size = Vector2(86, 36)
	reserve_button.pressed.connect(func() -> void: reservation_requested.emit())
	actions.add_child(reserve_button)
	show_reservation(false)
	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 3)
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_chip.add_child(price_row)
	price_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var coin_icon := TextureRect.new()
	coin_icon.custom_minimum_size = Vector2(22, 22)
	coin_icon.texture = ICONS.hud(2)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_child(coin_icon)
	price_label = Label.new()
	price_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	price_label.add_theme_font_size_override("font_size", 19)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_child(price_label)
	price_row.move_child(price_label, 0)


func _on_hover(hovered: bool) -> void:
	if disabled:
		return
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE * (1.015 if hovered else 1.0), 0.11)
