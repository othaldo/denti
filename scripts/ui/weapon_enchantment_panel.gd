class_name WeaponEnchantmentPanel
extends CanvasLayer

signal completed
signal upgrade_requested(uid: String, id: StringName)
signal ascension_requested(uid: String)
signal undo_requested
signal selection_changed

const MAX_LEVEL := 10
const SLOT_COUNT := 4
const CAPSULE: Texture2D = preload("res://assets/loot/upgrade_capsule.png")

var stage: RewardStage
var root_control: Control
var body: Control
var details: RunSetupDetails
var count_label: Label
var back_button: Button
var finish_button: Button
var weapon_buttons: Array[Button] = []
var upgrade_buttons: Array[Button] = []
var effect_buttons: Array[Button] = []
var models: Array[Dictionary] = []
var income: WeaponUpgradeIncome
var state: WeaponUpgradeState
var loadout: WeaponLoadout
var stats: PlayerStats
var item_context: ItemInventory
var selected_weapon := 0
var remaining := 0
var picking_slot := -1
var selected_effect: StringName = &""
var selection_preview: Control
var ascension_button: Button
var coins := 0
var wave_number := 1
var focus_after_layout := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	visible = false
	root_control = Control.new()
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = RewardStage.new()
	root_control.add_child(stage)
	stage.title_label.text = "Waffen verzaubern"
	stage.header.add_theme_constant_override("separation", 10)
	var counter := HBoxContainer.new()
	counter.add_theme_constant_override("separation", 8)
	stage.header.add_child(counter)
	var icon := TextureRect.new()
	icon.texture = CAPSULE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(34, 40)
	counter.add_child(icon)
	count_label = Label.new()
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 20)
	counter.add_child(count_label)
	back_button = Button.new()
	MenuStyle.action(back_button, false, true)
	back_button.pressed.connect(_back)
	stage.footer.add_child(back_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.footer.add_child(spacer)
	finish_button = Button.new()
	MenuStyle.action(finish_button, true)
	finish_button.custom_minimum_size.x = 180
	finish_button.pressed.connect(_confirm)
	stage.footer.add_child(finish_button)
	body = Control.new()
	stage.layout_changed.connect(_layout)
	stage.present("Waffen verzaubern", body)
	details = RunSetupDetails.new()
	root_control.add_child(details)
	ControllerPrompt.bind(finish_button)


func show_upgrades(upgrades: WeaponUpgradeState, equipment: WeaponLoadout, player_stats: PlayerStats, items: ItemInventory, upgrade_income: WeaponUpgradeIncome = null, available_coins: int = 0, wave: int = 1) -> void:
	coins = available_coins
	wave_number = wave
	income = upgrade_income
	state = upgrades
	loadout = equipment
	stats = player_stats
	item_context = items
	details.hide()
	visible = true
	stage.body_scroll.scroll_vertical = 0
	refresh()
	DentiUIMotion.reveal(body)
	if get_node("/root/GameInput").navigation_active:
		get_node("/root/GameInput").navigation.ensure_focus.call_deferred()


func refresh() -> void:
	models = WeaponUpgradePresentation.equipment(state, loadout, stats, item_context, coins, wave_number)
	remaining = state.remaining()
	selected_weapon = 0
	for index in models.size():
		if str(models[index].uid) == str(state.cursor.get("target_uid", "")): selected_weapon = index
	picking_slot = int(state.cursor.get("picking_slot", -1))
	selected_effect = StringName(str(state.cursor.get("selected_effect", "")))
	if models.is_empty() or picking_slot >= int(models[selected_weapon].slot_count):
		picking_slot = -1
		selected_effect = &""
	_refresh.call_deferred()


func _refresh() -> void:
	if stage == null: return
	count_label.text = _balance_text()
	back_button.text = "Zurück" if picking_slot >= 0 else "Rückgängig"
	back_button.disabled = picking_slot < 0 and state.actions.is_empty()
	back_button.visible = not back_button.disabled
	finish_button.text = "Verzaubern · %d" % _cost() if picking_slot >= 0 else "Fertig"
	finish_button.disabled = picking_slot >= 0 and (selected_effect == &"" or remaining < _cost() or not _selection_allowed())
	var back_prompt := ControllerPrompt.bind(back_button)
	back_prompt.action = &"ui_cancel" if picking_slot >= 0 else &"ui_accept"
	back_prompt.focused_only = picking_slot < 0
	back_prompt.refresh()
	var finish_prompt := ControllerPrompt.bind(finish_button)
	finish_prompt.action = &"ui_accept" if picking_slot >= 0 else &"ui_cancel"
	finish_prompt.focused_only = picking_slot >= 0
	finish_prompt.refresh()
	_layout(stage.last_extent)
	if picking_slot >= 0 and selected_effect != &"": _reveal_selection.call_deferred()


func _layout(extent: Vector2) -> void:
	if body == null or extent.x < 1: return
	for child in body.get_children(): child.free()
	selection_preview = null
	ascension_button = null
	weapon_buttons.clear()
	upgrade_buttons.clear()
	effect_buttons.clear()
	var narrow := extent.x < 720
	var compact := extent.x < 420
	finish_button.custom_minimum_size.x = 110 if compact else 180
	finish_button.add_theme_font_size_override("font_size", 16 if compact else 20)
	back_button.add_theme_font_size_override("font_size", 14 if compact else 20)
	stage.title_label.text = "Verzaubern" if compact else "Waffen verzaubern"
	count_label.text = _balance_text()
	count_label.tooltip_text = "%d Punkte · 2 je Kapsel" % remaining
	if income != null: count_label.tooltip_text += "\n" + income.details()
	stage.title_label.add_theme_font_size_override("font_size", 22 if compact else 32)
	count_label.add_theme_font_size_override("font_size", 14 if compact else 18)
	var top := 0.0
	if models.is_empty():
		_text(body, "Keine Waffe ausgerüstet", Rect2(0, 12, extent.x, 40), 22)
		body.custom_minimum_size.y = 60
		return
	if extent.x >= 420 and extent.y < 280:
		# Short landscape: put actual effects in the first viewport, beside the
		# weapon gallery, instead of spending its full height on a preview.
		for index in models.size():
			_weapon_card(index, Rect2(index % 2 * 64, (index / 2) * 64, 56, 56), true)
		_text(body, current_data().display_name, Rect2(0, 136, 122, 48), 17, DentiUIStyle.INK, true)
		_text(body, current_data().roots_text(), Rect2(0, 188, 122, 24), 14, DentiUIStyle.MUTED)
		var right := Rect2(144, 0, extent.x - 144, 0)
		var height := 0.0
		if picking_slot >= 0: height = _picker(right)
		else:
			_ascension(Rect2(right.position, Vector2(right.size.x, 72)))
			height = 84 + _slots(Rect2(right.position + Vector2(0, 84), right.size), true)
		body.custom_minimum_size.y = maxf(212, height) + 8
	elif narrow:
		var columns := models.size()
		if (extent.x - (columns - 1) * 8) / columns < 48: columns = 3
		var cell := minf(68 if compact else 76, (extent.x - (columns - 1) * 8) / columns)
		for index in models.size():
			_weapon_card(index, Rect2(index % columns * (cell + 8), (index / columns) * (cell + 8), cell, cell), true)
		top = ceili(float(models.size()) / columns) * (cell + 8) + 4
		_hero(Rect2(0, top, extent.x, 64), true)
		top += 72 if compact else 98
		_ascension(Rect2(0, top, extent.x, 72))
		top += 84
		var height := _picker(Rect2(0, top, extent.x, 0)) if picking_slot >= 0 else _slots(Rect2(0, top, extent.x, 0), true)
		body.custom_minimum_size.y = top + height + 8
	else:
		var rail := clampf(extent.x * 0.22, 190, 260)
		var hero_width := clampf(extent.x * 0.25, 184, 340)
		var gap := 24.0
		var content_height := maxf(340, extent.y - 8)
		var rail_top := maxf(0, (content_height - 430) / 2)
		for index in models.size():
			if models.size() <= 4 and rail >= 240:
				_weapon_card(index, Rect2(0, rail_top + index * 110, rail, 100), false)
			else:
				var cell := (rail - 12) / 2
				var rows := ceili(float(models.size()) / 2)
				var gallery_top := maxf(0, (content_height - (rows * (cell + 12) - 12)) / 2)
				_weapon_card(index, Rect2(index % 2 * (cell + 12), gallery_top + (index / 2) * (cell + 12), cell, cell), true)
		_hero(Rect2(rail + gap, 0, hero_width, content_height), false)
		var slot_height := minf(100, maxf(78, (extent.y - 38) / 4)) * 4 + 30
		var right := Rect2(rail + hero_width + gap * 2, maxf(0, (content_height - slot_height) / 2), extent.x - rail - hero_width - gap * 2, 0)
		var height := _picker(right) if picking_slot >= 0 else _slots(right, false)
		body.custom_minimum_size.y = maxf(content_height, right.position.y + height) + 8
	body.size = Vector2(extent.x, maxf(extent.y, body.custom_minimum_size.y))
	stage.refresh_focus()
	for index in weapon_buttons.size():
		DentiUIStyle.mark_card(weapon_buttons[index], DentiUIStyle.GOLD if selected_weapon == index else Color.TRANSPARENT)


func _weapon_card(index: int, rect: Rect2, compact: bool) -> void:
	var data: WeaponData = models[index].data
	var button := RunSetupChoice.new()
	button.rarity_tier = models[index].tier
	button.rarity_color = WeaponPresentation.special_color(data)
	button.selected_color = DentiUIStyle.GOLD
	button.selected = selected_weapon == index
	body.add_child(button)
	_place(button, rect)
	button.refresh()
	# Preserve Mk's rarity edge; the inset gold marker means selection.
	DentiUIStyle.mark_card(button, DentiUIStyle.GOLD if selected_weapon == index else Color.TRANSPARENT)
	button.tooltip_text = str(models[index].name) + "\n" + str(models[index].meta)
	button.pressed.connect(select_weapon.bind(index))
	ControllerFocus.tag(button, "weapon:%s" % models[index].uid)
	weapon_buttons.append(button)
	if compact:
		button.show_artwork(RunSetupPresentation.weapon_icon(data))
		var copies := 0
		for model in models:
			if model.id == data.id: copies += 1
		if copies > 1: _text(button, "#%d" % (index + 1), Rect2(4, rect.size.y - 24, 32, 22), 14)
		return
	_art(button, RunSetupPresentation.weapon_icon(data), Rect2(12, 12, 62, 76))
	var name_text := data.display_name.replace("-", "-\n") if data.display_name.length() > 16 else data.display_name
	_text(button, name_text, Rect2(86, 5, rect.size.x - 98, 46), 16 if data.display_name.length() > 16 else 18, DentiUIStyle.INK, true)
	_text(button, models[index].meta, Rect2(86, 51, rect.size.x - 98, 20), 14, DentiUIStyle.MUTED)
	var x := 86.0
	for effect: Dictionary in models[index].effects:
		_art(button, DentiUIIcons.item(WeaponAffixes.by_id(effect.id).icon_index), Rect2(x, 75, 16, 20))
		_text(button, str(effect.level), Rect2(x + 18, 74, 22, 22), 13)
		x += 38


func _hero(rect: Rect2, compact: bool) -> void:
	var data := current_data()
	if compact:
		_art(body, RunSetupPresentation.weapon_icon(data), Rect2(rect.position, Vector2(50, 60)))
		_text(body, data.display_name, Rect2(rect.position + Vector2(64, 0), Vector2(rect.size.x - 64, 30)), 22)
		_root_info(Rect2(rect.position + Vector2(64, 29), Vector2(rect.size.x - 64, 36)))
		return
	var art_height := minf(260, rect.size.y - 200)
	var y := rect.position.y + (rect.size.y - art_height - 182) / 2
	_art(body, RunSetupPresentation.weapon_icon(data), Rect2(rect.position.x + 28, y, rect.size.x - 56, art_height))
	var title := _text(body, data.display_name, Rect2(rect.position.x, y + art_height + 16, rect.size.x, 38), 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_info(Rect2(rect.position.x, y + art_height + 58, rect.size.x, 40))
	_ascension(Rect2(rect.position.x, y + art_height + 110, rect.size.x, 72))


func _root_info(rect: Rect2) -> void:
	var data := current_data()
	var meta := str(models[selected_weapon].meta)
	var button := _button(body, meta, rect)
	MenuStyle.quiet(button)
	button.add_theme_font_size_override("font_size", 16)
	var text_width := button.get_theme_font("font").get_string_size(meta, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_art(button, preload("res://assets/ui/info.svg"), Rect2(minf((rect.size.x + text_width) / 2 + 8, rect.size.x - 18), (rect.size.y - 14) / 2, 14, 14))
	button.tooltip_text = "Effektstärke nach Wurzeln. Details öffnen."
	button.pressed.connect(func() -> void:
		details.present(data.display_name, models[selected_weapon].root_info, button))


func _slots(rect: Rect2, compact: bool) -> float:
	var very_narrow := compact and rect.size.x < 310
	var row_height := (90.0 if very_narrow else 74.0) if compact else minf(100, maxf(78, (stage.last_extent.y - 38) / 4))
	var gap := 8.0 if compact else 10.0
	for index in SLOT_COUNT:
		var row := Rect2(rect.position + Vector2(0, index * (row_height + gap)), Vector2(rect.size.x, row_height))
		var effects: Array = models[selected_weapon].effects
		if index >= effects.size():
			var locked := index >= int(models[selected_weapon].slot_count)
			var empty := _button(body, "Ab Mk %s" % ["I", "II", "III", "IV"][index] if locked else "+  Verzaubern", row)
			empty.add_theme_stylebox_override("normal", MenuStyle.box(Color(DentiUIStyle.PANEL, 0.55), DentiUIStyle.LINE, 14, 1))
			empty.tooltip_text = "Öffnet sich beim Waffenupgrade auf Mk %s" % ["I", "II", "III", "IV"][index] if locked else "Neue Verzauberung · %d Punkte" % _cost()
			if locked:
				empty.icon = preload("res://assets/ui/setup_lock.svg")
				empty.expand_icon = true
				empty.add_theme_constant_override("icon_max_width", 18)
				empty.alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.disabled = remaining < _cost() or locked
			empty.pressed.connect(open_picker.bind(index))
			ControllerFocus.tag(empty, "slot:%d" % index)
			upgrade_buttons.append(empty)
			continue
		var effect: Dictionary = effects[index]
		var data := WeaponAffixes.by_id(effect.id)
		var level := int(effect.level)
		var panel := _panel(body, row)
		var icon := _button(panel, "", Rect2(8, 12 if compact else 22, 50, 48))
		MenuStyle.quiet(icon)
		_art(icon, DentiUIIcons.item(data.icon_index), Rect2(2, 3, 46, 46))
		icon.tooltip_text = data.display_name + " · Details"
		icon.pressed.connect(func() -> void: details.present(data.display_name, effect.details, icon))
		ControllerFocus.tag(icon, "details:%d" % index)
		var action_width := 72.0 if compact else 106.0
		var text_width := row.size.x - 90 - action_width
		_text(panel, data.display_name, Rect2(72, 3 if compact else 9, text_width if compact else text_width - 48, 25), 16 if compact else 19)
		var rank := _text(panel, "%d/10" % level, Rect2(row.size.x - action_width - 12 if compact else row.size.x - action_width - 66, 0 if compact else 10, action_width if compact else 52, 22 if compact else 24), 13 if compact else 16, DentiUIStyle.MINT if level == MAX_LEVEL else DentiUIStyle.INK)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for pip in MAX_LEVEL:
			var cell := ColorRect.new()
			cell.color = data.color if pip < level else DentiUIStyle.LINE
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(cell)
			_place(cell, Rect2(73 + pip * (text_width / 10), 31 if compact else 42, text_width / 10 - 3, 3 if compact else 4))
		var preview := str(effect.preview)
		if very_narrow: preview = preview.trim_suffix(" " + str(effect.unit)) + "\n" + str(effect.unit)
		var preview_height := 50.0 if very_narrow else (36.0 if compact else 28.0)
		var preview_top := 37.0 if compact else minf(53, row_height - 32)
		_text(panel, preview, Rect2(72, preview_top, text_width + 4, preview_height), 13 if compact else 14, DentiUIStyle.MUTED, true)
		var action := _button(panel, "MAX" if level == MAX_LEVEL else ("+ · %d" if compact else "+ Rang · %d") % _cost(), Rect2(row.size.x - action_width - 12, 25, action_width, 44 if compact else 48))
		action.add_theme_font_size_override("font_size", 16)
		action.tooltip_text = "Maximalstufe erreicht" if level == MAX_LEVEL else "%s: %d/10 -> %d/10 · kostet %d Punkte" % [data.display_name, level, level + 1, _cost()]
		action.disabled = level == MAX_LEVEL or remaining < _cost()
		action.pressed.connect(upgrade.bind(index))
		ControllerFocus.tag(action, "upgrade:%d" % index)
		upgrade_buttons.append(action)
	return SLOT_COUNT * (row_height + gap) - gap


func _picker(rect: Rect2) -> float:
	var columns := 2 if rect.size.x < 400 else 3
	var gap := 8.0
	var width := (rect.size.x - gap * (columns - 1)) / columns
	var options: Array = models[selected_weapon].options
	var bottom := 0.0
	for elemental in [true, false]:
		var current := StringName(models[selected_weapon].element)
		var heading := ("Element · " + (WeaponAffixes.by_id(current).display_name if current != &"" else "0/1")) if elemental else "Verstärkung"
		_text(body, heading, Rect2(rect.position + Vector2(0, bottom), Vector2(rect.size.x, 26)), 21)
		bottom += 30
		var index := 0
		for option: Dictionary in options:
			var data := WeaponAffixes.by_id(option.id)
			if data.elemental != elemental: continue
			var row := Rect2(rect.position + Vector2(index % columns * (width + gap), bottom + (index / columns) * 66), Vector2(width, 58))
			var button := _button(body, "", row)
			button.set_meta("effect_id", data.id)
			ControllerFocus.tag(button, "effect:%s" % data.id)
			RunSetupStyle.choice(button, selected_effect == data.id, stage.keyboard_focus)
			_art(button, DentiUIIcons.item(data.icon_index), Rect2(8, 12, 34, 36))
			_text(button, data.display_name, Rect2(47, 6, width - 52, 46), 15, DentiUIStyle.INK, true)
			button.disabled = not str(option.blocked).is_empty()
			if bool(option.existing):
				_art(button, preload("res://assets/ui/setup_check.svg"), Rect2(width - 20, 5, 14, 14))
			elif button.disabled:
				_art(button, preload("res://assets/ui/setup_lock.svg"), Rect2(width - 20, 5, 14, 14))
			button.modulate.a = 0.48 if button.disabled and not bool(option.existing) else 1.0
			button.tooltip_text = str(option.blocked) if button.disabled else AffixPresentation.effect_description(data.id)
			button.pressed.connect(func() -> void:
				selected_effect = data.id
				_save_cursor()
				_refresh.call_deferred())
			effect_buttons.append(button)
			index += 1
		bottom += ceili(float(index) / columns) * 66 + 6
	if selected_effect != &"":
		var data := WeaponAffixes.by_id(selected_effect)
		var selected: Dictionary = {}
		for option: Dictionary in options:
			if option.id == selected_effect: selected = option
		selection_preview = Control.new()
		body.add_child(selection_preview)
		_place(selection_preview, Rect2(rect.position + Vector2(0, bottom), Vector2(rect.size.x, 160)))
		_text(selection_preview, "%s · 1/10" % data.display_name, Rect2(0, 6, rect.size.x, 30), 22)
		var target_name := str(models[selected_weapon].name) + " · " + WeaponPresentation.tier_text(current_data(), int(models[selected_weapon].tier))
		var copies := 0
		for model: Dictionary in models:
			if model.id == current_data().id: copies += 1
		if copies > 1: target_name += " · #%d" % (selected_weapon + 1)
		_text(selection_preview, target_name, Rect2(0, 36, rect.size.x, 24), 14, DentiUIStyle.MUTED)
		_text(selection_preview, str(selected.get("value", "")), Rect2(0, 64, rect.size.x, 30), 17, DentiUIStyle.MINT)
		var description := AffixPresentation.effect_description(selected_effect)
		if not str(selected.get("blocked", "")).is_empty(): description = str(selected.blocked)
		var label := _text(selection_preview, description, Rect2(0, 100, rect.size.x, 72), 16, DentiUIStyle.MUTED, true)
		selection_preview.size.y = 104 + maxf(72, label.get_minimum_size().y)
		return bottom + selection_preview.size.y
	return bottom


func _reveal_selection() -> void:
	await get_tree().process_frame
	if visible and is_instance_valid(selection_preview): stage.body_scroll.ensure_control_visible(selection_preview)


func current_data() -> WeaponData:
	var data: WeaponData = models[selected_weapon].data
	if picking_slot >= 0 and selected_effect != &"" and _selection_allowed():
		var effect := WeaponAffixes.by_id(selected_effect)
		if effect != null and effect.elemental:
			return WeaponSkins.with_element(data, selected_effect)
	return data


func select_weapon(index: int) -> void:
	if index < 0 or index >= models.size(): return
	selected_weapon = index
	picking_slot = -1
	selected_effect = &""
	_save_cursor()
	_refresh.call_deferred()


func open_picker(slot: int) -> void:
	if remaining < _cost() or slot < models[selected_weapon].effects.size() or slot >= int(models[selected_weapon].slot_count): return
	picking_slot = slot
	selected_effect = &""
	focus_after_layout = "picker"
	_save_cursor()
	_refresh.call_deferred()
	_focus_after_refresh.call_deferred()


func upgrade(slot: int) -> void:
	if remaining < _cost() or slot < 0 or slot >= models[selected_weapon].effects.size(): return
	if int(models[selected_weapon].effects[slot].level) >= MAX_LEVEL: return
	upgrade_requested.emit(str(models[selected_weapon].uid), StringName(models[selected_weapon].effects[slot].id))


func _confirm() -> void:
	if picking_slot < 0:
		completed.emit()
		return
	if remaining < _cost() or not _selection_allowed(): return
	upgrade_requested.emit(str(models[selected_weapon].uid), selected_effect)


func _back() -> void:
	if picking_slot >= 0:
		focus_after_layout = "slot:%d" % picking_slot
		picking_slot = -1
		selected_effect = &""
		_save_cursor()
	else:
		undo_requested.emit()
	_refresh.call_deferred()
	_focus_after_refresh.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or details.visible or not ControllerFocus.active(stage) or not event.is_action_pressed("ui_cancel"): return
	if picking_slot >= 0: _back()
	else: _confirm()
	get_viewport().set_input_as_handled()


func _focus_after_refresh() -> void:
	if not get_node("/root/GameInput").navigation_active: return
	for control in effect_buttons if focus_after_layout == "picker" else upgrade_buttons:
		if ControllerFocus.available(control) and (focus_after_layout == "picker" or str(control.get_meta("controller_focus_key", "")) == focus_after_layout):
			control.grab_focus()
			ControllerFocus.reveal(control)
			break
	focus_after_layout = ""


func _save_cursor() -> void:
	if state == null or models.is_empty(): return
	state.cursor = {"target_uid": str(models[selected_weapon].uid), "picking_slot": picking_slot, "selected_effect": str(selected_effect)}
	selection_changed.emit()


func _cost() -> int:
	return int(models[selected_weapon].cost) if not models.is_empty() else 1


func _balance_text() -> String:
	var gold := state.remaining_gold(coins) if state != null else coins
	return "%d Punkt%s\n%d Gold" % [remaining, "" if remaining == 1 else "e", gold]


func _ascension(rect: Rect2, short: bool = false) -> void:
	var offer: Dictionary = models[selected_weapon].ascension
	var locked := int(models[selected_weapon].tier) < WeaponLoadout.MAX_TIER
	var title := "Ab Mk IV" if locked else ("Aufstieg · " if short else "Aufsteigen · ") + str(offer.next)
	var price := "%d P · %d G" % [offer.cost, offer.coins] if short else "%d Punkte · %d Gold" % [offer.cost, offer.coins]
	ascension_button = _button(body, title if locked else title + "\n" + price, rect)
	ascension_button.add_theme_font_size_override("font_size", 13 if short else (14 if rect.size.x < 220 else 16))
	ascension_button.disabled = not str(offer.blocked).is_empty()
	ascension_button.tooltip_text = (str(offer.blocked) + "\n" if ascension_button.disabled else "") + "%s · %d Punkte · %d Gold\n+10 %% Basisschaden · +3 %% Tempo und Reichweite\nFertig übernimmt den Aufstieg; Rückgängig nimmt ihn zurück." % [offer.next, offer.cost, offer.coins]
	ascension_button.pressed.connect(func() -> void:
		ascension_requested.emit(str(models[selected_weapon].uid)))
	ControllerFocus.tag(ascension_button, "ascension")


func _selection_allowed() -> bool:
	if models.is_empty(): return false
	for option: Dictionary in models[selected_weapon].options:
		if option.id == selected_effect: return str(option.blocked).is_empty()
	return false


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func _text(parent: Node, value: String, rect: Rect2, font_size: int, color: Color = DentiUIStyle.INK, wrap: bool = false) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	# Establish the real width before shaping wrapped text. Shaping it at zero
	# width first can retain a huge minimum height in a manually laid out Label.
	_place(label, rect)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.text = value
	_place(label, rect)
	return label


func _art(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	_place(art, rect)
	return art


func _button(parent: Node, value: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = value
	MenuStyle.action(button)
	parent.add_child(button)
	_place(button, rect)
	return button


func _panel(parent: Node, rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 14, 1))
	parent.add_child(panel)
	_place(panel, rect)
	return panel
