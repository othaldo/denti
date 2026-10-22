class_name RewardCard
extends UpgradeCard

# Reward presentation is separate from shop cards. The exposed UpgradeCard
# controls remain available to the reward coordinator and affix comparisons.
var detail_label: Label
var card_body: Control
var stat_header: HBoxContainer
var _kind: StringName = &"upgrade"
var _card_width := 260.0
var _compact := false
var _tall := true
var _name_source := ""
var _effect_source := ""
var _detail_source := ""
var _keep_source := ""
var _wrapped_name := ""
var _wrapped_effect := ""
var _wrapped_keep := ""
var _laying_out := false


func _ready() -> void:
	_ensure_content()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_surface()
	resized.connect(_layout_content)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	focus_entered.connect(_on_hover.bind(true))
	focus_exited.connect(func() -> void: _on_hover(is_hovered()))
	DentiUIMotion.bind_button(self)
	_layout_content()


func show_upgrade(upgrade: UpgradeData) -> void:
	_restore_standard_content()
	_kind = &"upgrade"
	upgrade_tier = upgrade.tier
	upgrade_description = upgrade.effect_text()
	icon_rect.texture = ICONS.stat(upgrade.attribute_icon())
	_name_source = upgrade.attribute_name()
	var attribute := DentiAttributes.from_key(upgrade.stat)
	if attribute >= 0:
		var value := upgrade.amount * 100.0 if DentiAttributes.is_fraction(attribute) else upgrade.amount
		_effect_source = DentiAttributes.number(value, true) + (" %" if DentiAttributes.is_percent(attribute) else "")
		match attribute:
			DentiAttributes.Type.MAX_HEALTH:
				_detail_source = "inkl. Heilung"
			DentiAttributes.Type.DASH_RECOVERY:
				_detail_source = "Ausdauer"
			DentiAttributes.Type.MELEE_DAMAGE, DentiAttributes.Type.RANGED_DAMAGE:
				_detail_source = "Waffenskalierung"
	else:
		_effect_source = upgrade_description
	tooltip_text = upgrade_description + ("\n" + DentiAttributes.meaning_for(attribute) if attribute >= 0 else "")
	_set_rarity(upgrade.tier)
	_finish_content()


func show_relic(relic: RelicData) -> void:
	_restore_standard_content()
	_kind = &"relic"
	icon_rect.texture = ICONS.relic(relic.icon_index)
	_name_source = relic.display_name
	_effect_source = DentiAttributes.resolve_text(relic.description)
	upgrade_description = _effect_source
	tooltip_text = _effect_source
	_set_rarity(4, "Göttliches Relikt")
	_finish_content()


func show_item(item: ShopOfferData) -> void:
	_restore_standard_content()
	_kind = &"item"
	icon_rect.texture = item.icon_texture if item.icon_texture != null else ICONS.item(item.icon_index)
	chest_name = item.display_name
	chest_effect = item.effect_text()
	_name_source = chest_name
	_effect_source = chest_effect
	_detail_source = item.limit_text()
	upgrade_description = chest_effect
	tooltip_text = "%s\n%s" % [chest_name, chest_effect]
	_set_rarity(item.rarity_tier)
	keep_label.text = "Behalten"
	keep_label.show()
	_finish_content()


func show_affix(option: Dictionary, comparison: String, detail_text: String = "") -> void:
	_restore_standard_content()
	_kind = &"affix"
	var data := WeaponAffixes.by_id(StringName(str(option.id)))
	icon_rect.texture = ICONS.item(data.icon_index) if data != null else ICONS.hud(4)
	_name_source = data.display_name if data != null else "Mehr Platz"
	_effect_source = comparison
	upgrade_description = comparison
	tooltip_text = detail_text if not detail_text.is_empty() else comparison
	_set_rarity(int(option.rarity))
	_finish_content()


func show_weapon(weapon: WeaponData) -> void:
	_restore_standard_content()
	_kind = &"weapon"
	icon_rect.texture = weapon.sprite
	_name_source = weapon.display_name
	_effect_source = "%s\n%d Schaden · %.2f s\n%d Reichweite" % [weapon.description, roundi(weapon.damage_at_tier(1)), weapon.interval_at_tier(1), roundi(weapon.attack_range)]
	upgrade_description = _effect_source
	tooltip_text = "%s\n%s" % [weapon.description, weapon.combat_text()]
	_set_rarity(1)
	_finish_content()


func show_action(action_name: String, accent: bool = false) -> void:
	_restore_standard_content()
	_kind = &"action"
	card_body.hide()
	text = action_name
	custom_minimum_size = Vector2(0, 48)
	MenuStyle.action(self, accent)


func configure_layout(width: float, compact: bool, tall: bool = true) -> void:
	_ensure_content()
	_card_width = maxf(width, 120)
	_compact = compact
	_tall = tall and not compact
	_layout_content()


func set_mobile_text(enabled: bool) -> void:
	configure_layout(_card_width, enabled, _tall)


func set_upgrade_layout(narrow: bool, compact: bool) -> void:
	configure_layout(_card_width, narrow or compact, not narrow and not compact)


func reset_card_layout() -> void:
	configure_layout(_card_width, false)


func set_chest_layout(card_width: float, compact: bool) -> void:
	configure_layout(card_width, compact, false)


func set_affix_header() -> void:
	# The card owns a single hierarchy in both layouts; callers never need to
	# move labels into the legacy UpgradeCard.affix_header container.
	pass


func _ensure_content() -> void:
	if content_margin != null:
		return
	content_margin = MarginContainer.new()
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "right", "top", "bottom"]:
		content_margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(content_margin)
	card_body = Control.new()
	card_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(card_body)
	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_body.add_child(icon_rect)
	content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	card_body.add_child(content)
	affix_header = HBoxContainer.new()
	affix_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	affix_header.add_theme_constant_override("separation", 10)
	content.add_child(affix_header)
	affix_header.hide()
	stat_header = HBoxContainer.new()
	stat_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_header.add_theme_constant_override("separation", 8)
	content.add_child(stat_header)
	stat_header.hide()
	name_label = _label(DentiUIStyle.INK)
	rarity_label = _label(DentiUIStyle.MUTED)
	effect_label = _label(DentiUIStyle.INK)
	detail_label = _label(DentiUIStyle.MUTED)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 6
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DentiUIStyle.style_progress(progress_bar, DentiUIStyle.MINT)
	content.add_child(progress_bar)
	progress_bar.hide()
	keep_label = _label(DentiUIStyle.MINT)
	keep_label.hide()


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.max_lines_visible = -1
	label.size_flags_horizontal = Control.SIZE_FILL
	content.add_child(label)
	return label


func _restore_standard_content() -> void:
	_ensure_content()
	if icon_rect.get_parent() != card_body:
		icon_rect.reparent(card_body)
	if name_label.get_parent() != content:
		name_label.reparent(content)
	if rarity_label.get_parent() != content:
		rarity_label.reparent(content)
	content.move_child(name_label, 2)
	content.move_child(rarity_label, 3)
	affix_header.hide()
	stat_header.hide()
	card_body.show()
	content.show()
	text = ""
	icon = null
	disabled = false
	progress_bar.hide()
	keep_label.hide()
	detail_label.hide()
	_detail_source = ""
	_keep_source = ""
	_wrapped_keep = ""
	_name_source = ""
	_effect_source = ""
	_wrapped_name = ""
	_wrapped_effect = ""
	name_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	effect_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	chest_layout = false
	scale = Vector2.ONE
	DentiUIMotion.reset(icon_rect)


func _set_rarity(tier: int, caption: String = "") -> void:
	upgrade_tier = tier
	rarity_label.text = caption if not caption.is_empty() else DentiRarity.name_for(tier)
	DentiUIStyle.style_rarity_label(rarity_label, tier)


func _finish_content() -> void:
	name_label.text = _name_source
	effect_label.text = _effect_source
	_wrapped_name = _name_source
	_wrapped_effect = _effect_source
	detail_label.text = _detail_source
	detail_label.visible = not _detail_source.is_empty()
	_style_surface()
	_layout_content()


func _style_surface() -> void:
	DentiUIStyle.style_card(self, upgrade_tier, Color.TRANSPARENT, 18)
	var outline := MenuStyle.box(Color.TRANSPARENT, DentiUIStyle.INK, 14, 2)
	outline.draw_center = false
	outline.set_expand_margin_all(-4)
	add_theme_stylebox_override("focus", outline)


func _layout_content() -> void:
	if card_body == null or _kind == &"action" or _laying_out:
		return
	_laying_out = true
	var padding := 12.0 if _compact else 16.0
	for edge in ["left", "right", "top", "bottom"]:
		content_margin.add_theme_constant_override("margin_" + edge, int(padding))
	var inner_width := maxf(_card_width - padding * 2, 88)
	var art_size := 56.0 if _compact else (104.0 if _tall else 80.0)
	if _kind == &"item": art_size = 80 if _compact else 144
	var gap := 10.0 if _compact else 18.0
	var text_width := inner_width if _tall else maxf(inner_width - art_size - gap, 38)
	if _kind == &"affix":
		text_width = inner_width
	var centered := _tall
	name_label.add_theme_font_size_override("font_size", 18 if _compact else 22)
	if _kind == &"item" and not _compact: name_label.add_theme_font_size_override("font_size", 26)
	rarity_label.add_theme_font_size_override("font_size", 12 if _compact else 13)
	effect_label.add_theme_font_size_override("font_size", (26 if _compact else 36) if _kind == &"upgrade" else 16)
	if _kind == &"item" and not _compact: effect_label.add_theme_font_size_override("font_size", 18)
	detail_label.add_theme_font_size_override("font_size", 12 if _compact else 14)
	keep_label.add_theme_font_size_override("font_size", 14)
	content.add_theme_constant_override("separation", 2 if _compact else 7)
	var compact_stat := _kind == &"upgrade" and _compact
	if compact_stat:
		if name_label.get_parent() != stat_header:
			name_label.reparent(stat_header)
			rarity_label.reparent(stat_header)
		stat_header.show()
	else:
		if _kind != &"affix" and name_label.get_parent() != content:
			name_label.reparent(content)
		if rarity_label.get_parent() != content:
			rarity_label.reparent(content)
		if name_label.get_parent() == content:
			content.move_child(name_label, 2)
		content.move_child(rarity_label, 3)
		stat_header.hide()
	# External capsule updates may change the title/action after show_affix.
	# Keep original paragraphs independently of the measured line breaks so a
	# second, wider layout always unwraps correctly.
	if name_label.text != _wrapped_name:
		_name_source = name_label.text.replace("\n", " ")
	if effect_label.text != _wrapped_effect:
		_effect_source = effect_label.text
	if keep_label.text != _wrapped_keep:
		_keep_source = keep_label.text.replace("\n", " ")
	for label in [name_label, rarity_label, effect_label, detail_label, keep_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
		label.size_flags_horizontal = Control.SIZE_FILL
		label.custom_minimum_size = Vector2.ZERO
		label.max_lines_visible = -1
		label.clip_text = false
	var name_width := text_width - 44 if _kind == &"affix" else text_width
	if compact_stat:
		var rarity_width := rarity_label.get_theme_font("font").get_string_size(rarity_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, rarity_label.get_theme_font_size("font_size")).x
		name_width = maxf(40, text_width - rarity_width - 8)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rarity_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_wrap_chest_text(name_label, _name_source, name_width)
	_wrap_chest_text(effect_label, _effect_source, text_width)
	_wrap_chest_text(detail_label, _detail_source, text_width)
	_wrap_chest_text(keep_label, _keep_source, text_width)
	_wrapped_name = name_label.text
	_wrapped_effect = effect_label.text
	_wrapped_keep = keep_label.text
	if _kind == &"affix":
		_layout_affix(inner_width)
		_laying_out = false
		return
	var text_height := 0.0
	var visible_count := 0
	for child: Control in content.get_children():
		if not child.visible:
			continue
		visible_count += 1
		if child == stat_header:
			text_height += maxf(_label_height(name_label), _label_height(rarity_label))
		else:
			text_height += _label_height(child) if child is Label else child.get_combined_minimum_size().y
	text_height += maxi(0, visible_count - 1) * content.get_theme_constant("separation")
	# Keep stat artwork, names and values on the same rows. A short secondary
	# detail must not move an entire tall card upward beside the other choices.
	if centered and _kind == &"upgrade" and not detail_label.visible:
		text_height += _label_height(detail_label) + content.get_theme_constant("separation")
	var body_height := art_size + gap + text_height if centered else maxf(art_size, text_height)
	var floor_height := (312.0 if _kind == &"upgrade" else 300.0) if _tall else ((96.0 if _kind == &"upgrade" else 132.0) if _compact else 148.0)
	if _kind == &"item": floor_height = 160 if _compact else 240
	custom_minimum_size = Vector2(0, maxf(floor_height, body_height + padding * 2))
	# Parent grids can make all cards as tall as the longest one. Center the
	# complete art/text group within that space without distorting the artwork.
	var available_height := maxf(size.y, custom_minimum_size.y) - padding * 2
	var offset_y := maxf(0, (available_height - body_height) * 0.5)
	icon_rect.custom_minimum_size = Vector2.ZERO
	icon_rect.size = Vector2.ONE * art_size
	icon_rect.position = Vector2((inner_width - art_size) * 0.5 if centered else 0.0, offset_y if centered else offset_y + (body_height - art_size) * 0.5)
	content.position = Vector2(0, offset_y + art_size + gap) if centered else Vector2(art_size + gap, offset_y + (body_height - text_height) * 0.5)
	content.size = Vector2(text_width, text_height)
	content.queue_sort()
	_laying_out = false


func _layout_affix(inner_width: float) -> void:
	if icon_rect.get_parent() != affix_header:
		icon_rect.reparent(affix_header)
		name_label.reparent(affix_header)
	# Re-sorts after a resize must not move the rarity below the effect text.
	content.move_child(affix_header, 0)
	content.move_child(stat_header, 1)
	content.move_child(rarity_label, 2)
	content.move_child(effect_label, 3)
	content.move_child(detail_label, 4)
	content.move_child(progress_bar, 5)
	content.move_child(keep_label, 6)
	affix_header.show()
	icon_rect.custom_minimum_size = Vector2(34, 34)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var height := maxf(34, _label_height(name_label))
	var visible_count := 1
	for child: Control in content.get_children():
		if child == affix_header or not child.visible:
			continue
		visible_count += 1
		height += _label_height(child) if child is Label else child.get_combined_minimum_size().y
	height += maxi(0, visible_count - 1) * content.get_theme_constant("separation")
	custom_minimum_size = Vector2(0, maxf(140, height + (24 if _compact else 32)))
	content.position = Vector2.ZERO
	content.size = Vector2(inner_width, height)
	content.queue_sort()


func _label_height(label: Label) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var lines := maxi(1, label.text.count("\n") + 1)
	return ceilf(font.get_height(font_size) * lines + label.get_theme_constant("line_spacing") * maxi(0, lines - 1))


func _on_hover(hovered: bool) -> void:
	if is_inside_tree() and icon_rect != null and icon_rect.is_inside_tree() and not disabled:
		DentiUIMotion.hover_art(icon_rect, hovered)
