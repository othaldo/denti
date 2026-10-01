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


func _ready() -> void:
	custom_minimum_size = Vector2(235, 186)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_content()
	DentiUIStyle.style_card(self)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func show_upgrade(upgrade: UpgradeData) -> void:
	upgrade_tier = upgrade.tier
	upgrade_description = upgrade.description
	custom_minimum_size.y = 186.0
	text = ""
	content.visible = true
	icon_rect.texture = ICONS.stat(upgrade.icon_index)
	name_label.text = upgrade.display_name.to_upper()
	rarity_label.text = "STUFE %d · %s" % [upgrade.tier, DentiRarity.name_for(upgrade.tier).to_upper()]
	DentiUIStyle.style_rarity_label(rarity_label, upgrade.tier)
	effect_label.text = upgrade.description
	tooltip_text = upgrade.description
	disabled = false
	DentiUIStyle.style_card(self, upgrade.tier)


func show_weapon(weapon: WeaponData) -> void:
	# Weapon cards carry a description plus three stat lines. Godot 4.7's
	# Fredoka metrics need a little more room than the compact upgrade cards.
	custom_minimum_size.y = 250.0
	text = ""
	content.visible = true
	icon_rect.texture = weapon.sprite
	name_label.text = weapon.display_name.to_upper()
	rarity_label.text = "STUFE I · GEWÖHNLICH · %s" % weapon.damage_type.to_upper()
	DentiUIStyle.style_rarity_label(rarity_label, 1)
	effect_label.text = "%s\n%d Schaden · %.2f s\n%d Reichweite" % [weapon.description, roundi(weapon.damage_at_tier(1)), weapon.interval_at_tier(1), roundi(weapon.attack_range)]
	tooltip_text = "%s\n%s" % [weapon.description, weapon.combat_text()]
	disabled = false
	DentiUIStyle.style_card(self)


func show_item(item: ShopOfferData) -> void:
	custom_minimum_size.y = 210.0
	text = ""
	content.visible = true
	icon_rect.texture = item.icon_texture if item.icon_texture != null else ICONS.item(item.icon_index)
	name_label.text = item.display_name.to_upper()
	rarity_label.text = "STUFE %d · %s" % [item.rarity_tier, DentiRarity.name_for(item.rarity_tier).to_upper()]
	DentiUIStyle.style_rarity_label(rarity_label, item.rarity_tier)
	effect_label.text = "BEHALTEN\n%s" % item.description
	disabled = false
	DentiUIStyle.style_card(self, item.rarity_tier)


func show_relic(relic: RelicData) -> void:
	custom_minimum_size.y = 230.0
	text = ""
	content.visible = true
	icon_rect.texture = ICONS.relic(relic.icon_index)
	name_label.text = relic.display_name.to_upper()
	rarity_label.text = "GÖTTLICHES RELIKT"
	DentiUIStyle.style_rarity_label(rarity_label, 4)
	effect_label.text = relic.description
	disabled = false
	DentiUIStyle.style_card(self, 4)


func show_action(action_name: String, accent: bool = false) -> void:
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
	custom_minimum_size = Vector2(0, 186 if narrow else (174 if compact else 186))
	icon_rect.custom_minimum_size.y = 40 if compact else 56
	name_label.custom_minimum_size.y = 34 if narrow else 26
	name_label.add_theme_font_size_override("font_size", 15 if narrow else 18)
	effect_label.add_theme_font_size_override("font_size", 15 if narrow else 17)
	effect_label.text = upgrade_description.replace(" (Waffenskalierung)", "").replace("maximales Leben und Heilung", "Leben + Heilung").replace("kritische Chance", "Crit") if compact or narrow else upgrade_description
	rarity_label.text = DentiRarity.name_for(upgrade_tier).to_upper()
	rarity_label.clip_text = true
	rarity_label.size_flags_horizontal = Control.SIZE_FILL
	rarity_label.add_theme_font_size_override("font_size", 10 if narrow else 12)
	content.add_theme_constant_override("separation", 3 if compact else 5)


func reset_card_layout() -> void:
	custom_minimum_size.x = 235
	icon_rect.custom_minimum_size.y = 56
	name_label.custom_minimum_size.y = 48
	rarity_label.clip_text = false
	rarity_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_theme_constant_override("separation", 5)


func _build_content() -> void:
	var margin := MarginContainer.new()
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
	effect_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(effect_label)


func _on_hover(hovered: bool) -> void:
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE * (1.025 if hovered else 1.0), 0.11)
