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
var stage: RewardStage
var panel: Control
var scroll: ScrollContainer
var rows: VBoxContainer
var title_label: Label
var weapon_grid: GridContainer
var weapon_buttons: Array[Button] = []
var selected_weapon: int = 0
var target_summary: RichTextLabel
var target_art: TextureRect
var weapon_name: Label
var weapon_meta: Label
var replacement: VBoxContainer
var replacement_grid: GridContainer
var replacement_buttons: Array[Button] = []
var cards: GridContainer
var buttons: Array[UpgradeCard] = []
var scrap_button: Button
var _keyboard_focus := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	visible = false
	stage = RewardStage.new()
	add_child(stage)
	root_control = stage
	panel = stage.panel
	scroll = stage.body_scroll
	title_label = stage.title_label
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 16)
	weapon_grid = GridContainer.new()
	weapon_grid.add_theme_constant_override("h_separation", 8)
	weapon_grid.add_theme_constant_override("v_separation", 8)
	rows.add_child(weapon_grid)
	var preview := HBoxContainer.new()
	preview.add_theme_constant_override("separation", 16)
	rows.add_child(preview)
	target_art = TextureRect.new()
	target_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	target_art.custom_minimum_size = Vector2(64, 64)
	target_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(target_art)
	var preview_rows := VBoxContainer.new()
	preview_rows.add_theme_constant_override("separation", 4)
	preview_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.add_child(preview_rows)
	weapon_name = DentiUIComponents.label(preview_rows, "", 20)
	weapon_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_meta = DentiUIComponents.label(preview_rows, "", 16)
	weapon_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_meta.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	target_summary = RichTextLabel.new()
	target_summary.bbcode_enabled = true
	target_summary.fit_content = true
	target_summary.scroll_active = false
	target_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_summary.add_theme_font_size_override("normal_font_size", 16)
	preview_rows.add_child(target_summary)
	replacement = VBoxContainer.new()
	replacement.add_theme_constant_override("separation", 8)
	rows.add_child(replacement)
	var replacement_title := DentiUIComponents.label(replacement, "Ersetzen", 16)
	replacement_title.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	replacement_grid = GridContainer.new()
	replacement_grid.add_theme_constant_override("h_separation", 8)
	replacement_grid.add_theme_constant_override("v_separation", 8)
	replacement.add_child(replacement_grid)
	cards = GridContainer.new()
	cards.add_theme_constant_override("h_separation", 16)
	cards.add_theme_constant_override("v_separation", 12)
	rows.add_child(cards)
	for index in 3:
		var card := RewardCard.new()
		cards.add_child(card)
		card.pressed.connect(func() -> void:
			if not card.disabled and not weapons.is_empty():
				chosen.emit(weapons[selected_weapon].instance_uid, index, int(reward.get("replace", -1))))
		buttons.append(card)
	scrap_button = Button.new()
	scrap_button.custom_minimum_size = Vector2(156, 48)
	scrap_button.add_theme_font_size_override("font_size", 17)
	MenuStyle.action(scrap_button, false, true)
	DentiUIMotion.bind_action(scrap_button)
	scrap_button.pressed.connect(func() -> void: scrapped.emit())
	stage.footer.add_child(scrap_button)
	stage.layout_changed.connect(_on_stage_layout)
	stage.present("Upgrade-Kapsel", rows)
	_layout()


func show_chest(chest: Dictionary, loadout: WeaponLoadout, player_stats: PlayerStats, scrap_coins: int, items: ItemInventory = null) -> void:
	reward = chest
	item_context = items
	weapons = loadout.equipped()
	stats = player_stats
	title_label.text = "Goldene Kapsel" if bool(chest.get("golden", false)) else "Upgrade-Kapsel"
	title_label.add_theme_color_override("font_color", DentiUIStyle.GOLD if bool(chest.get("golden", false)) else DentiUIStyle.INK)
	for button in weapon_buttons:
		button.free()
	weapon_buttons.clear()
	var selected := 0
	for index in weapons.size():
		var weapon := weapons[index]
		var button := RunSetupChoice.new()
		button.rarity_tier = weapon.tier
		button.rarity_color = WeaponPresentation.special_color(weapon.data)
		button.custom_minimum_size = Vector2(64, 64)
		button.tooltip_text = WeaponPresentation.weapon_name(weapon) + "\n" + AffixPresentation.summary(weapon, stats, item_context) + "\n" + weapon.data.stats_text(weapon.tier)
		weapon_grid.add_child(button)
		button.show_artwork(RunSetupPresentation.weapon_icon(weapon.data))
		button.set_meta("art", button.artwork)
		button.pressed.connect(_select_weapon.bind(index))
		weapon_buttons.append(button)
		if weapon.instance_uid == str(chest.get("target_uid", "")):
			selected = index
	scrap_button.text = "Zerlegen · %d Münzen" % scrap_coins
	if not weapons.is_empty():
		_select_weapon(selected, false)
	else:
		target_art.hide()
		weapon_name.text = "Keine Waffe ausgerüstet"
		weapon_meta.text = ""
		target_summary.text = ""
		target_summary.hide()
		replacement.hide()
		for button in replacement_buttons:
			button.free()
		replacement_buttons.clear()
		for button in buttons:
			button.hide()
	visible = true
	scroll.scroll_vertical = 0
	_layout()
	DentiUIMotion.reveal(rows)


func set_progress(current: int, total: int) -> void:
	stage.set_progress(current, total)


func _select_weapon(index: int, reset_replace: bool = true) -> void:
	if index < 0 or index >= weapons.size():
		return
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
	target_art.texture = RunSetupPresentation.weapon_icon(weapon.data)
	target_art.show()
	weapon_name.text = WeaponPresentation.weapon_name(weapon)
	weapon_meta.text = "%s · %d/%d Plätze" % [WeaponPresentation.tier_text(weapon.data, weapon.tier), weapon.affixes.size(), weapon.affix_slots]
	weapon_meta.add_theme_color_override("font_color", DentiUIStyle.rarity_text_color(mini(weapon.tier + int(weapon.data.chest_upgrades.get("mk", 0)), 5)))
	target_summary.text = WeaponPresentation.enchantment_list(weapon) if not needs_replacement and not weapon.affixes.is_empty() else ""
	target_summary.visible = not target_summary.text.is_empty()
	for button in replacement_buttons:
		button.free()
	replacement_buttons.clear()
	for affix_index in weapon.affixes.size():
		var affix := weapon.affixes[affix_index]
		var data := WeaponAffixes.by_id(StringName(affix.id))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 68)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		replacement_grid.add_child(button)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for edge in ["left", "right"]:
			margin.add_theme_constant_override("margin_" + edge, 12)
		for edge in ["top", "bottom"]:
			margin.add_theme_constant_override("margin_" + edge, 8)
		button.add_child(margin)
		var text_rows := VBoxContainer.new()
		text_rows.add_theme_constant_override("separation", 3)
		text_rows.alignment = BoxContainer.ALIGNMENT_CENTER
		text_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(text_rows)
		var unit := " %" if data.stat_key != &"" else (" s" if data.effect_kind == "wet" else (" HP" if data.effect_kind == "leech" else ""))
		var effect := DentiUIComponents.label(text_rows, "%s +%s%s" % [data.display_name, AffixPresentation.value_text(float(affix.damage), data.id, weapon.data, stats, item_context), unit], 16)
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rarity := DentiUIComponents.label(text_rows, AffixPresentation.progress_text(affix), 14)
		rarity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The whole replacement card already conveys rarity; no nested badge.
		DentiUIStyle.style_rarity_label(rarity, affix.rarity)
		button.set_meta("rarity_label", rarity)
		button.set_meta("effect_label", effect)
		button.set_meta("text_rows", text_rows)
		button.set_meta("effect_source", effect.text)
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
		var selector := weapon_buttons[index] as RunSetupChoice
		selector.selected = index == selected_weapon
		selector.keyboard_focus = _keyboard_focus
		selector.refresh()
	for index in replacement_buttons.size():
		DentiUIStyle.style_card(replacement_buttons[index], int(weapons[selected_weapon].affixes[index].rarity), Color.TRANSPARENT, 12)
		DentiUIStyle.mark_card(replacement_buttons[index], DentiUIStyle.INK if index == int(reward.get("replace", -1)) else Color.TRANSPARENT)
		RunSetupStyle.focus(replacement_buttons[index], _keyboard_focus)
	var weapon := weapons[selected_weapon]
	for index in buttons.size():
		var option: Dictionary = reward.options[index]
		var replace := int(reward.get("replace", -1))
		var preview := AffixPresentation.comparison(weapon, option, stats, replace, true, item_context)
		# Blockers belong beside the action; avoid repeating the same condition
		# or adding a second instruction paragraph to the comparison itself.
		if option.id == "slot" and weapon.affix_slots >= WeaponAffixes.MAX_SLOTS:
			preview = "Plätze · %d/%d" % [weapon.affix_slots, WeaponAffixes.MAX_SLOTS]
		elif option.id == "mk":
			preview = "Aktuell %s" % WeaponPresentation.tier_text(weapon.data, weapon.tier) if weapon.tier < 4 else preview.replace("\nBenötigt mindestens Mk IV", "")
		else:
			preview = preview.replace("\nErsetzt: Bitte Ersatz wählen", "")
		var hint := WeaponPresentation.enchantment_hint(StringName(option.id), weapon, item_context, replace)
		buttons[index].show_affix(option, preview + ("\n" + hint if not hint.is_empty() else ""), AffixPresentation.comparison(weapon, option, stats, replace, false, item_context))
		buttons[index].disabled = not WeaponAffixes.can_apply(weapon, option, replace)
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
		buttons[index].keep_label.text = badge
		buttons[index].keep_label.visible = true
		buttons[index].keep_label.add_theme_color_override("font_color", DentiUIStyle.CORAL if buttons[index].disabled else DentiUIStyle.MINT)
		buttons[index].show()
	_layout()


func _layout() -> void:
	if stage != null:
		stage.relayout()
		if stage.last_extent.x > 0:
			_on_stage_layout(stage.last_extent)


func _on_stage_layout(extent: Vector2) -> void:
	var compact := extent.x < 880
	var tile := 48.0 if extent.x < 600 else 64.0
	weapon_grid.columns = maxi(1, mini(weapons.size(), floori((extent.x + 8) / (tile + 8))))
	for button in weapon_buttons:
		button.custom_minimum_size = Vector2(tile, tile)
	replacement_grid.columns = 1 if extent.x < 600 else 2
	var replacement_width := (extent.x - (replacement_grid.columns - 1) * 8) / replacement_grid.columns
	for index in replacement_buttons.size():
		var button := replacement_buttons[index]
		var effect: Label = button.get_meta("effect_label")
		var rarity: Label = button.get_meta("rarity_label")
		buttons[0]._wrap_chest_text(effect, str(button.get_meta("effect_source")), maxf(100, replacement_width - 24))
		buttons[0]._wrap_chest_text(rarity, AffixPresentation.progress_text(weapons[selected_weapon].affixes[index]), maxf(100, replacement_width - 24))
		button.custom_minimum_size = Vector2(0, maxf(68, _label_height(effect) + _label_height(rarity) + 19))
	cards.columns = 1 if compact else 3
	var card_width := (extent.x - (cards.columns - 1) * 16) / cards.columns
	for button in buttons:
		(button as RewardCard).configure_layout(card_width, compact, false)
	target_art.custom_minimum_size = Vector2(56, 56) if extent.x < 600 else Vector2(64, 64)


func _label_height(label: Label) -> float:
	var lines := label.text.split("\n").size()
	return ceilf(label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")) * lines + label.get_theme_constant("line_spacing") * maxi(lines - 1, 0))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_keyboard_focus = true
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		_keyboard_focus = false
	else:
		return
	for index in weapon_buttons.size():
		var selector := weapon_buttons[index] as RunSetupChoice
		selector.keyboard_focus = _keyboard_focus
		selector.refresh()
	for index in replacement_buttons.size():
		RunSetupStyle.choice(replacement_buttons[index], index == int(reward.get("replace", -1)), _keyboard_focus, 12)
	RunSetupStyle.focus(scrap_button, _keyboard_focus)
