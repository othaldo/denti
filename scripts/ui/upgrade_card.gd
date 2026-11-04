class_name UpgradeCard
extends Button

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

var content: VBoxContainer
var icon_rect: TextureRect
var name_label: Label
var rarity_label: Label
var effect_label: Label
var upgrade_tier: int = 1
var upgrade_description: String = ""
var content_margin: MarginContainer
var progress_bar: ProgressBar
var keep_label: Label
var chest_name: String = ""
var chest_effect: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(235, 186)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_content()
	DentiUIStyle.style_card(self)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func show_upgrade(upgrade: UpgradeData, stats: PlayerStats = null) -> void:
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
	if stats != null and attribute >= 0:
		var preview := DentiAttributes.upgrade_preview_text(stats, attribute, upgrade.amount)
		upgrade_description += "\n" + preview
		effect_label.text = upgrade_description
		tooltip_text += "\n" + preview
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
	# All starters are tier I; use the badge for the relevant build stat.
	rarity_label.text = weapon.scaling_label()
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


func show_affix(option: Dictionary, comparison: String, detail_text: String = "") -> void:
	_restore_standard_content()
	text = ""
	content.visible = true
	var data := WeaponAffixes.by_id(StringName(str(option.id)))
	icon_rect.texture = ICONS.item(data.icon_index) if data != null else ICONS.hud(4)
	name_label.text = data.display_name if data != null else "Mehr Platz"
	name_label.add_theme_color_override("font_color", data.color if data != null else DentiUIStyle.INK)
	rarity_label.text = DentiRarity.name_for(int(option.rarity)).to_upper()
	DentiUIStyle.style_affix_rarity_label(rarity_label, int(option.rarity))
	upgrade_description = comparison
	effect_label.text = comparison
	tooltip_text = (detail_text if not detail_text.is_empty() else comparison) + "\nJede passende Verzauberung bringt Fortschritt. Höhere Seltenheit: direktes Upgrade.\nZusatzschaden gilt pro Treffer und vor Gegnerresistenzen."
	disabled = false
	DentiUIStyle.style_card(self, int(option.rarity))


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
	set_meta("controller_action_label", action_name)
	disabled = false
	scale = Vector2.ONE
	DentiUIStyle.style_button(self, accent)


func _restore_standard_content() -> void:
	if has_meta("controller_action_label"): remove_meta("controller_action_label")
	progress_bar.hide()
	content.move_child(keep_label, -1)
	icon = null
	focus_neighbor_top = NodePath()
	focus_neighbor_bottom = NodePath()


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
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.hide()
	DentiUIStyle.style_progress(progress_bar, DentiUIStyle.MINT)
	content.add_child(progress_bar)
	keep_label = Label.new()
	keep_label.text = "Behalten"
	keep_label.visible = false
	keep_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	keep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(keep_label)


func _on_hover(hovered: bool) -> void:
	DentiUIMotion.hover_art(icon_rect, hovered)
