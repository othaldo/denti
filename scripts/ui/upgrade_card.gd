class_name UpgradeCard
extends Button

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

var content: VBoxContainer
var icon_rect: TextureRect
var name_label: Label
var rarity_label: Label
var effect_label: Label
var hover_tween: Tween
var upgrade_tier: int = 1
var upgrade_description: String = ""
var content_margin: MarginContainer
var chest_row: HBoxContainer
var keep_label: Label
var chest_name: String = ""
var chest_effect: String = ""
var chest_layout: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(235, 186)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_content()
	DentiUIStyle.style_card(self)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func show_upgrade(upgrade: UpgradeData) -> void:
	_restore_standard_content()
	upgrade_tier = upgrade.tier
	upgrade_description = upgrade.effect_text()
	custom_minimum_size.y = 186.0
	text = ""
	content.visible = true
	icon_rect.texture = ICONS.stat(upgrade.attribute_icon())
	name_label.text = upgrade.attribute_name().to_upper()
	rarity_label.text = "STUFE %d · %s" % [upgrade.tier, DentiRarity.name_for(upgrade.tier).to_upper()]
	DentiUIStyle.style_rarity_label(rarity_label, upgrade.tier)
	effect_label.text = upgrade_description
	var attribute := DentiAttributes.from_key(upgrade.stat)
	tooltip_text = upgrade_description + ("\n" + DentiAttributes.meaning_for(attribute) if attribute >= 0 else "")
	disabled = false
	DentiUIStyle.style_card(self, upgrade.tier)


func show_weapon(weapon: WeaponData) -> void:
	_restore_standard_content()
	# Weapon cards carry a description plus three stat lines. Godot 4.7's
	# Fredoka metrics need a little more room than the compact upgrade cards.
	custom_minimum_size.y = 250.0
	text = ""
	content.visible = true
	icon_rect.texture = weapon.sprite
	name_label.text = weapon.display_name.to_upper()
	# All starters are tier I; keep the badge short enough for landscape cards.
	rarity_label.text = "%s · %s" % [DentiRarity.name_for(1).to_upper(), weapon.damage_type_label().to_upper()]
	DentiUIStyle.style_rarity_label(rarity_label, 1)
	effect_label.text = "%s\n%d Schaden · %.2f s\n%d Reichweite" % [weapon.description, roundi(weapon.damage_at_tier(1)), weapon.interval_at_tier(1), roundi(weapon.attack_range)]
	tooltip_text = "%s\n%s" % [weapon.description, weapon.combat_text()]
	disabled = false
	DentiUIStyle.style_card(self)


func show_item(item: ShopOfferData) -> void:
	_restore_standard_content()
	custom_minimum_size.y = 210.0
	text = ""
	content.visible = true
	icon_rect.texture = item.icon_texture if item.icon_texture != null else ICONS.item(item.icon_index)
	name_label.text = item.display_name.to_upper()
	rarity_label.text = "STUFE %d · %s" % [item.rarity_tier, DentiRarity.name_for(item.rarity_tier).to_upper()]
	DentiUIStyle.style_rarity_label(rarity_label, item.rarity_tier)
	effect_label.text = "BEHALTEN\n%s" % item.effect_text()
	chest_name = item.display_name
	chest_effect = item.effect_text()
	tooltip_text = "%s\n%s\nBehalten" % [item.display_name, chest_effect]
	disabled = false
	DentiUIStyle.style_card(self, item.rarity_tier)


func show_relic(relic: RelicData) -> void:
	_restore_standard_content()
	custom_minimum_size.y = 230.0
	text = ""
	content.visible = true
	icon_rect.texture = ICONS.relic(relic.icon_index)
	name_label.text = relic.display_name.to_upper()
	rarity_label.text = "GÖTTLICHES RELIKT"
	DentiUIStyle.style_rarity_label(rarity_label, 4)
	effect_label.text = DentiAttributes.resolve_text(relic.description)
	disabled = false
	DentiUIStyle.style_card(self, 4)


func show_action(action_name: String, accent: bool = false) -> void:
	_restore_standard_content()
	custom_minimum_size.y = 60.0
	content.visible = false
	text = action_name
	disabled = false
	scale = Vector2.ONE
	DentiUIStyle.style_button(self, accent)


func set_mobile_text(enabled: bool) -> void:
	name_label.add_theme_font_size_override("font_size", 21 if enabled else 19)
	effect_label.add_theme_font_size_override("font_size", 17 if enabled else 14)


func set_upgrade_layout(narrow: bool, compact: bool) -> void:
	_restore_standard_content()
	custom_minimum_size = Vector2(0, 186 if narrow else (174 if compact else 186))
	icon_rect.custom_minimum_size.y = 40 if compact else 56
	icon_rect.custom_minimum_size.x = icon_rect.custom_minimum_size.y
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_label.custom_minimum_size.y = 34 if narrow else 26
	name_label.add_theme_font_size_override("font_size", 12 if narrow else 18)
	effect_label.add_theme_font_size_override("font_size", 15 if narrow else 17)
	effect_label.text = upgrade_description.replace(" (Waffenskalierung)", "") if compact or narrow else upgrade_description
	if narrow:
		effect_label.text = effect_label.text.replace(" (HP) + Heilung", " + Heilung")
	rarity_label.text = DentiRarity.name_for(upgrade_tier).to_upper()
	rarity_label.clip_text = true
	rarity_label.size_flags_horizontal = Control.SIZE_FILL
	rarity_label.add_theme_font_size_override("font_size", 10 if narrow else 12)
	content.add_theme_constant_override("separation", 3 if compact else 5)


func reset_card_layout() -> void:
	_restore_standard_content()
	custom_minimum_size.x = 235
	icon_rect.custom_minimum_size.y = 56
	name_label.custom_minimum_size.y = 48
	rarity_label.clip_text = false
	rarity_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_theme_constant_override("separation", 5)


func set_chest_layout(card_width: float, compact: bool) -> void:
	if not chest_layout:
		if chest_row == null:
			chest_row = HBoxContainer.new()
			chest_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chest_row.add_theme_constant_override("separation", 12)
			content_margin.add_child(chest_row)
		icon_rect.reparent(chest_row)
		content.reparent(chest_row)
		chest_layout = true
	chest_row.visible = true
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var art_size := 64.0 if compact else 80.0
	icon_rect.custom_minimum_size = Vector2(art_size, art_size)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var text_width := maxf(card_width - 28.0 - art_size - 12.0, 120.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size.y = 0
	name_label.max_lines_visible = -1
	name_label.add_theme_font_size_override("font_size", 18 if compact else 20)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rarity_label.clip_text = false
	rarity_label.size_flags_horizontal = Control.SIZE_FILL
	rarity_label.add_theme_font_size_override("font_size", 11 if compact else 12)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	effect_label.add_theme_font_size_override("font_size", 14 if compact else 16)
	# Button does not derive its minimum from child controls. Shape at the final
	# text width, then size the card from the complete effect rather than a fixed
	# height which lets wrapped descriptions escape below the card.
	_wrap_chest_text(name_label, chest_name, text_width)
	_wrap_chest_text(effect_label, chest_effect, text_width)
	keep_label.visible = true
	keep_label.add_theme_font_size_override("font_size", 14 if compact else 16)
	custom_minimum_size = Vector2(0, maxf(content.get_combined_minimum_size().y, art_size) + 20.0)


func _wrap_chest_text(label: Label, source: String, width: float) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var paragraph := TextParagraph.new()
	paragraph.width = width
	paragraph.add_string(source, label.get_theme_font("font"), label.get_theme_font_size("font_size"))
	var lines: PackedStringArray = []
	for index in paragraph.get_line_count():
		var span := paragraph.get_line_range(index)
		lines.append(source.substr(span.x, span.y - span.x).strip_edges())
	label.text = "\n".join(lines)


func _restore_standard_content() -> void:
	icon = null
	focus_neighbor_top = NodePath()
	focus_neighbor_bottom = NodePath()
	if not chest_layout:
		return
	content.reparent(content_margin)
	icon_rect.reparent(content)
	content.move_child(icon_rect, 0)
	chest_row.visible = false
	chest_layout = false
	keep_label.visible = false
	content.size_flags_horizontal = Control.SIZE_FILL
	icon_rect.custom_minimum_size = Vector2(0, 56)
	icon_rect.size_flags_horizontal = Control.SIZE_FILL
	icon_rect.size_flags_vertical = Control.SIZE_FILL
	for label in [name_label, rarity_label, effect_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.custom_minimum_size.y = 48
	rarity_label.remove_theme_font_size_override("font_size")
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _build_content() -> void:
	var margin := MarginContainer.new()
	content_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 5)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(0, 56)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.custom_minimum_size.y = 48.0
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)
	rarity_label = Label.new()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(rarity_label)
	effect_label = Label.new()
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_color_override("font_color", DentiUIStyle.TEXT)
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(effect_label)
	keep_label = Label.new()
	keep_label.text = "Behalten"
	keep_label.visible = false
	keep_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	keep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(keep_label)


func _on_hover(hovered: bool) -> void:
	DentiUIMotion.hover_art(icon_rect, hovered)
