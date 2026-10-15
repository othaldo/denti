class_name WeaponChestPanel
extends CanvasLayer

signal chosen(weapon_uid: String, option: int, replace: int)
signal scrapped
signal selection_changed

var reward: Dictionary = {}
var weapons: Array[WeaponInstance] = []
var stats: PlayerStats
var item_context: ItemInventory
var root_control: Control
var panel: PanelContainer
var scroll: ScrollContainer
var rows: VBoxContainer
var title_label: Label
var weapon_grid: GridContainer
var weapon_buttons: Array[Button] = []
var selected_weapon: int = 0
var target_summary: RichTextLabel
var replacement: VBoxContainer
var replacement_grid: GridContainer
var replacement_buttons: Array[Button] = []
var cards: GridContainer
var buttons: Array[UpgradeCard] = []
var scrap_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	visible = false
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = DentiUIStyle.make_theme()
	add_child(root_control)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.12, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center)
	panel = PanelContainer.new()
	DentiUIStyle.style_dialog(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	panel.add_child(margin)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	margin.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	title_label = _label("Upgrade-Kapsel!", 26)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Waffe wählen, dann verzaubern. Gleiche Effekte werden stärker.", 14)
	weapon_grid = GridContainer.new()
	weapon_grid.add_theme_constant_override("h_separation", 6)
	weapon_grid.add_theme_constant_override("v_separation", 6)
	rows.add_child(weapon_grid)
	target_summary = RichTextLabel.new()
	target_summary.bbcode_enabled = true
	target_summary.fit_content = true
	target_summary.scroll_active = false
	target_summary.add_theme_font_size_override("normal_font_size", 14)
	rows.add_child(target_summary)
	replacement = VBoxContainer.new()
	rows.add_child(replacement)
	ShopDetails._label(replacement, "Alle Plätze belegt. Für einen neuen Effekt Ersatz wählen:", 13)
	replacement_grid = GridContainer.new()
	replacement_grid.columns = 2
	replacement_grid.add_theme_constant_override("h_separation", 6)
	replacement.add_child(replacement_grid)
	cards = GridContainer.new()
	cards.add_theme_constant_override("h_separation", 8)
	cards.add_theme_constant_override("v_separation", 6)
	rows.add_child(cards)
	for index in 3:
		var card := UpgradeCard.new()
		cards.add_child(card)
		card.pressed.connect(func() -> void:
			if not card.disabled:
				chosen.emit(weapons[selected_weapon].instance_uid, index, int(reward.get("replace", -1))))
		buttons.append(card)
	scrap_button = Button.new()
	scrap_button.custom_minimum_size.y = 40
	DentiUIStyle.style_button(scrap_button)
	scrap_button.pressed.connect(func() -> void: scrapped.emit())
	rows.add_child(scrap_button)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _label(value: String, font_size: int) -> Label:
	return ShopDetails._label(rows, value, font_size)


func show_chest(chest: Dictionary, loadout: WeaponLoadout, player_stats: PlayerStats, scrap_coins: int, items: ItemInventory = null) -> void:
	reward = chest
	item_context = items
	weapons = loadout.equipped()
	stats = player_stats
	title_label.text = "Goldene Upgrade-Kapsel!" if bool(chest.get("golden", false)) else "Upgrade-Kapsel!"
	for button in weapon_buttons:
		button.free()
	weapon_buttons.clear()
	var selected := 0
	for index in weapons.size():
		var weapon := weapons[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 66)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = WeaponPresentation.weapon_name(weapon) + "\n" + WeaponAffixes.summary(weapon, stats, item_context) + "\n" + weapon.data.stats_text(weapon.tier)
		weapon_grid.add_child(button)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for edge in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + edge, 6)
		button.add_child(margin)
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(line)
		var art := TextureRect.new()
		art.texture = weapon.data.sprite
		art.custom_minimum_size = Vector2(30, 30)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(art)
		var text_rows := VBoxContainer.new()
		text_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text_rows)
		var name_label := ShopDetails._label(text_rows, WeaponPresentation.weapon_name(weapon), 14)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var info := ShopDetails._label(text_rows, "%s · %d/%d Effekte" % [WeaponPresentation.tier_text(weapon.data, weapon.tier), weapon.affixes.size(), weapon.affix_slots], 12)
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.set_meta("labels", [name_label, info])
		button.set_meta("art", art)
		button.pressed.connect(_select_weapon.bind(index))
		weapon_buttons.append(button)
		if weapon.instance_uid == str(chest.get("target_uid", "")):
			selected = index
	scrap_button.text = "Upgrade-Kapsel für %d Münzen zerlegen" % scrap_coins
	if not weapons.is_empty():
		_select_weapon(selected, false)
	else:
		target_summary.text = "Keine Waffe ausgerüstet. Die Upgrade-Kapsel kann zerlegt werden."
		replacement.hide()
		for button in buttons:
			button.hide()
	visible = true
	_layout()


func _select_weapon(index: int, reset_replace: bool = true) -> void:
	selected_weapon = index
	var weapon := weapons[index]
	reward["target_uid"] = weapon.instance_uid
	if reset_replace:
		reward["replace"] = -1
	var needs_replacement := false
	if weapon.affixes.size() >= weapon.affix_slots:
		for option: Dictionary in reward.options:
			if option.id not in ["slot", "mk"] and WeaponAffixes.find(weapon.affixes, StringName(option.id)) < 0:
				needs_replacement = true
	target_summary.text = "Verzauberungen · %d/%d Plätze belegt" % [weapon.affixes.size(), weapon.affix_slots]
	if not needs_replacement:
		target_summary.text += "\n" + WeaponPresentation.enchantment_list(weapon)
	for button in replacement_buttons:
		button.free()
	replacement_buttons.clear()
	for affix_index in weapon.affixes.size():
		var affix := weapon.affixes[affix_index]
		var data := WeaponAffixes.by_id(StringName(affix.id))
		var button := Button.new()
		var text_rows := VBoxContainer.new()
		text_rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_rows.alignment = BoxContainer.ALIGNMENT_CENTER
		text_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(text_rows)
		var effect := ShopDetails._label(text_rows, "%s +%s%s" % [data.display_name, WeaponAffixes.value_text(float(affix.damage), data.id, weapon.data, stats, item_context), " %" if data.stat_key != &"" else (" s" if data.effect_kind == "wet" else (" HP" if data.effect_kind == "leech" else ""))], 13)
		effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rarity := ShopDetails._label(text_rows, WeaponAffixes.progress_text(affix), 12)
		rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		DentiUIStyle.style_affix_rarity_label(rarity, affix.rarity)
		button.set_meta("rarity_label", rarity)
		button.add_theme_font_size_override("font_size", 13)
		button.custom_minimum_size = Vector2(0, 60)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		replacement_grid.add_child(button)
		button.pressed.connect(func() -> void:
			reward["replace"] = affix_index
			_refresh_cards()
			selection_changed.emit())
		replacement_buttons.append(button)
	replacement.visible = needs_replacement
	var replace := int(reward.get("replace", -1))
	if replace < -1 or replace >= weapon.affixes.size():
		reward["replace"] = -1
	_refresh_cards()
	selection_changed.emit()


func _refresh_cards() -> void:
	if weapons.is_empty():
		return
	for index in weapon_buttons.size():
		var selected := index == selected_weapon
		DentiUIStyle.style_button(weapon_buttons[index], selected)
		for label: Label in weapon_buttons[index].get_meta("labels"):
			label.add_theme_color_override("font_color", DentiUIStyle.GOLD_INK if selected else DentiUIStyle.INK)
	for index in replacement_buttons.size():
		DentiUIStyle.style_button(replacement_buttons[index], index == int(reward.get("replace", -1)))
	var weapon := weapons[selected_weapon]
	for index in buttons.size():
		var option: Dictionary = reward.options[index]
		var replace := int(reward.get("replace", -1))
		var preview := WeaponAffixes.comparison(weapon, option, stats, replace, true, item_context)
		var hint := WeaponPresentation.enchantment_hint(StringName(option.id), weapon, item_context, replace)
		buttons[index].show_affix(option, preview + ("\n" + hint if not hint.is_empty() else ""), WeaponAffixes.comparison(weapon, option, stats, replace, false, item_context))
		buttons[index].disabled = not WeaponAffixes.can_apply(weapon, option, int(reward.get("replace", -1)))
		var badge := "Verzaubern"
		if option.id == "slot":
			buttons[index].name_label.text = "Mehr Platz"
			badge = "Platz freischalten" if not buttons[index].disabled else "Alle 4 Plätze offen"
		elif option.id == "mk":
			buttons[index].name_label.text = "Mk-Aufstieg"
			badge = "Nächste Mk-Stufe" if not buttons[index].disabled else "Benötigt Mk IV"
		else:
			var existing := WeaponAffixes.find(weapon.affixes, StringName(option.id))
			if existing >= 0:
				badge = "Verstärken" if int(option.rarity) <= int(weapon.affixes[existing].rarity) else "Seltenheit erhöhen"
			elif buttons[index].disabled:
				badge = "Erst Ersatz wählen"
			elif weapon.affixes.size() >= weapon.affix_slots:
				badge = "Ersetzen"
		buttons[index].content.move_child(buttons[index].keep_label, -1)
		if option.id not in ["slot", "mk"]:
			var existing := WeaponAffixes.find(weapon.affixes, StringName(option.id))
			if existing >= 0 and int(option.rarity) <= int(weapon.affixes[existing].rarity):
				buttons[index].progress_bar.show()
				buttons[index].progress_bar.value = minf(float(weapon.affixes[existing].get("progress", 0)) + WeaponAffixes.progress_weight(weapon.affixes[existing], option), 1.0) * 100
		buttons[index].keep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		buttons[index].keep_label.add_theme_font_size_override("font_size", 14)
		buttons[index].keep_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		buttons[index].keep_label.text = badge
		buttons[index].keep_label.visible = true
		buttons[index].keep_label.add_theme_color_override("font_color", DentiUIStyle.CORAL if buttons[index].disabled else DentiUIStyle.MINT)
		buttons[index].show()
	_layout()


func _layout() -> void:
	if panel == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var narrow := viewport.x < 1000 or viewport.y < 480
	panel.custom_minimum_size = Vector2(minf(viewport.x - 16, 1160), 0)
	scroll.custom_minimum_size.y = minf(viewport.y - 60, 800)
	weapon_grid.columns = (1 if viewport.x < 360 else 2) if narrow else 3
	var outer_width := panel.get_theme_stylebox("panel").get_minimum_size().x + 24 + scroll.get_v_scroll_bar().get_combined_minimum_size().x
	var weapon_width := (panel.custom_minimum_size.x - outer_width - (weapon_grid.columns - 1) * weapon_grid.get_theme_constant("h_separation")) / weapon_grid.columns
	for index in weapon_buttons.size():
		var button := weapon_buttons[index]
		var labels: Array = button.get_meta("labels")
		labels[0].add_theme_font_size_override("font_size", 13 if narrow else 14)
		buttons[0]._wrap_chest_text(labels[0], WeaponPresentation.weapon_name(weapons[index]), maxf(weapon_width - (42 if narrow else 48), 32))
		labels[1].text = "%s · %d/%d%s" % [WeaponPresentation.tier_text(weapons[index].data, weapons[index].tier), weapons[index].affixes.size(), weapons[index].affix_slots, "" if narrow else " Effekte"]
		labels[1].add_theme_font_size_override("font_size", 11 if narrow else 12)
		button.custom_minimum_size.y = maxf(66, _label_height(labels[0]) + _label_height(labels[1]) + 16)
		var art: TextureRect = button.get_meta("art")
		art.custom_minimum_size = Vector2(24, 24) if narrow else Vector2(30, 30)
	cards.columns = 1 if narrow else 3
	title_label.add_theme_font_size_override("font_size", 21 if narrow else 26)
	scrap_button.text = scrap_button.text.replace("\n", " ")
	if narrow:
		scrap_button.text = scrap_button.text.replace(" für ", "\nfür ")
	scrap_button.custom_minimum_size.y = 60 if narrow else 40
	for button in buttons:
		button.custom_minimum_size = Vector2(0, 0)
		button.content.alignment = BoxContainer.ALIGNMENT_BEGIN
		button.set_affix_header()
		button.name_label.custom_minimum_size.y = 0
		button.name_label.max_lines_visible = -1
		button.name_label.add_theme_font_size_override("font_size", 18)
		button.rarity_label.add_theme_font_size_override("font_size", 11)
		button.effect_label.add_theme_font_size_override("font_size", 14)
		button.content.add_theme_constant_override("separation", 2)
		for label in [button.name_label, button.rarity_label, button.effect_label]:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label.add_theme_constant_override("line_spacing", 1)
		button.rarity_label.size_flags_horizontal = Control.SIZE_FILL
		for edge in ["left", "right"]:
			button.content_margin.add_theme_constant_override("margin_" + edge, 10)
		var card_width := (panel.custom_minimum_size.x - outer_width - (cards.columns - 1) * cards.get_theme_constant("h_separation")) / cards.columns
		var text_width := maxf(card_width - 20, 100)
		button._wrap_chest_text(button.name_label, button.name_label.text.replace("\n", " "), text_width - 34)
		button._wrap_chest_text(button.keep_label, button.keep_label.text.replace("\n", " "), text_width)
		button._wrap_chest_text(button.effect_label, button.upgrade_description, text_width)
		# Measure explicit lines including theme spacing; cached Label minima
		# can still describe the previous text until the next container sort.
		var height := 0.0
		var visible_children := 0
		for child: Control in button.content.get_children():
			if not child.visible:
				continue
			visible_children += 1
			if child == button.affix_header:
				height += maxf(26, _label_height(button.name_label))
			elif child is Label:
				height += _label_height(child)
			else:
				height += child.get_combined_minimum_size().y
		button.custom_minimum_size.y = maxf(140, height + maxi(visible_children - 1, 0) * 2 + 24)
	for index in replacement_buttons.size():
		var label: Label = replacement_buttons[index].get_meta("rarity_label")
		label.text = WeaponAffixes.progress_text(weapons[selected_weapon].affixes[index])
		if narrow:
			label.text = label.text.replace("Ungewöhnlich", "Ungew.").replace(".0 %", " %")


func _label_height(label: Label) -> float:
	var lines := label.text.split("\n").size()
	return maxf(label.custom_minimum_size.y, ceilf(label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")) * lines + label.get_theme_constant("line_spacing") * maxi(lines - 1, 0)))
