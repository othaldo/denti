class_name OfferCard
extends Button

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

var content: HBoxContainer
var icon_rect: TextureRect
var name_label: Label
var rarity_label: Label
var effect_label: Label
var price_label: Label
var hover_tween: Tween


func _ready() -> void:
	custom_minimum_size.y = 100.0
	_build_content()
	DentiUIStyle.style_card(self)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func show_offer(offer: ShopOfferData, coins: int, available: bool = true) -> void:
	if offer == null:
		content.visible = false
		text = "Ausverkauft"
		disabled = true
		tooltip_text = ""
		return
	content.visible = true
	text = ""
	icon_rect.texture = offer.icon_texture if offer.icon_texture != null else ICONS.item(offer.icon_index)
	name_label.text = offer.display_name.to_upper()
	rarity_label.text = offer.rarity
	rarity_label.add_theme_color_override("font_color", DentiUIStyle.VIOLET if offer.rarity == "Selten" else DentiUIStyle.MINT.darkened(0.52))
	effect_label.text = offer.description
	price_label.text = "%d" % offer.price
	disabled = coins < offer.price or not available
	tooltip_text = "Ausrüstung voll: erst eine Waffe verkaufen" if not available else offer.description
	DentiUIStyle.style_card(self, offer.rarity == "Selten")


func _build_content() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(78, 78)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 1)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(details)
	name_label = Label.new()
	name_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(name_label)
	rarity_label = Label.new()
	rarity_label.add_theme_font_size_override("font_size", 15)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(rarity_label)
	effect_label = Label.new()
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	effect_label.add_theme_font_size_override("font_size", 15)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(effect_label)
	var price_chip := PanelContainer.new()
	price_chip.custom_minimum_size.x = 76.0
	price_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DentiUIStyle.style_chip(price_chip)
	content.add_child(price_chip)
	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 3)
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_chip.add_child(price_row)
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


func _on_hover(hovered: bool) -> void:
	if disabled:
		return
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE * (1.015 if hovered else 1.0), 0.11)
