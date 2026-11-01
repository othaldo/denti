class_name WeaponEnchantmentPanel
extends CanvasLayer

signal completed
signal cancelled
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
var focus_rows: Array[WeaponEnchantmentAction] = []
var focus_policy: WeaponEnchantmentFocus
var exit_dialog: EnchantmentExitDialog
var exit_focus := ""
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
var block_controller_accept := false


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
	details.closed.connect(_focus_after_refresh)
	focus_policy = WeaponEnchantmentFocus.new(self)
	exit_dialog = EnchantmentExitDialog.new()
	root_control.add_child(exit_dialog)
	exit_dialog.decided.connect(_exit_decided)
	stage.set_meta("controller_shortcuts", _controller_shortcuts)
	ControllerFocus.tag(finish_button, "enchant:confirm")
	ControllerFocus.tag(back_button, "enchant:back")
	ControllerPrompt.bind(finish_button, &"ui_confirm", false)
	get_node("/root/GameInput").changed.connect(_sync_input_mode)
	_sync_input_mode()

func _controller_shortcuts() -> Dictionary:
	var result := {}
	if not visible or details.visible or exit_dialog.visible or state == null: return result
	if not models.is_empty(): result[&"ui_details"] = "Details"
	result[&"ui_cancel"] = "Zurück"
	if not finish_button.disabled: result[&"ui_confirm"] = finish_button.text
	if picking_slot < 0 and not state.actions.is_empty(): result[&"ui_undo"] = "Rückgängig"
	if picking_slot < 0 and models.size() > 1:
		result[&"ui_previous"] = "Vorige Waffe"
		result[&"ui_next"] = "Nächste Waffe"
	return result

func _sync_input_mode() -> void:
	var input := get_node("/root/GameInput")
	var controller: bool = input.controller_active
	if controller:
		stage.set_meta("controller_focus_targets", focus_policy.targets)
		stage.set_meta("controller_focus_neighbor", focus_policy.neighbor)
	else:
		for key in ["controller_focus_targets", "controller_focus_neighbor"]:
			if stage.has_meta(key): stage.remove_meta(key)
	var focus := get_viewport().gui_get_focus_owner()
	var reflow := stage.footer.visible == controller
	if visible and reflow and ControllerFocus.contains(body, focus) and focus_after_layout.is_empty():
		focus_after_layout = str(focus.get_meta("controller_focus_key", ""))
	if visible and controller and ControllerFocus.contains(stage.footer, focus):
		# Consuming the press prevents A from applying an upgrade to whichever
		# card receives focus when the desktop footer disappears.
		block_controller_accept = true
		focus_after_layout = ("effect:%s" % selected_effect if selected_effect != &"" else "picker") if picking_slot >= 0 else "weapon"
	elif not controller:
		block_controller_accept = false
	stage.footer.visible = not controller
	finish_button.visible = not controller
	back_button.visible = not controller and not back_button.disabled
	if visible and reflow:
		# Rebuild and restore focus before the acquiring button reaches the GUI;
		# otherwise the resize can delete its pressed target before release.
		stage.relayout()
		_focus_after_refresh()
	if visible and input.navigation_active: input.navigation.ensure_focus.call_deferred()

func _input(event: InputEvent) -> void:
	if visible and block_controller_accept and event is InputEventJoypadButton and event.device == get_node("/root/GameInput").controller_device and event.button_index == JOY_BUTTON_A:
		if not event.pressed: block_controller_accept = false
		get_viewport().set_input_as_handled()


func show_upgrades(upgrades: WeaponUpgradeState, equipment: WeaponLoadout, player_stats: PlayerStats, items: ItemInventory, upgrade_income: WeaponUpgradeIncome = null, available_coins: int = 0, wave: int = 1) -> void:
	coins = available_coins
	wave_number = wave
	income = upgrade_income
	state = upgrades
	loadout = equipment
	stats = player_stats
	item_context = items
	details.hide()
	exit_dialog.hide()
	visible = true
	stage.body_scroll.scroll_vertical = 0
	refresh()
	focus_after_layout = ("effect:%s" % selected_effect if selected_effect != &"" else "picker") if picking_slot >= 0 else "weapon"
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
	finish_button.text = "Verzaubern · %d" % _cost() if picking_slot >= 0 else "Fertig"
	finish_button.disabled = picking_slot >= 0 and (selected_effect == &"" or remaining < _cost() or not _selection_allowed())
	var back_prompt := ControllerPrompt.bind(back_button)
	back_prompt.action = &"ui_cancel" if picking_slot >= 0 else &"ui_undo"
	back_prompt.focused_only = false
	back_prompt.refresh()
	var finish_prompt := ControllerPrompt.bind(finish_button)
	finish_prompt.action = &"ui_confirm"
	finish_prompt.focused_only = false
	finish_prompt.refresh()
	_sync_input_mode()
	_layout(stage.last_extent)
	if picking_slot >= 0 and selected_effect != &"": _reveal_selection.call_deferred()


func _layout(extent: Vector2) -> void:
	if body == null or extent.x < 1: return
	var focused := get_viewport().gui_get_focus_owner()
	if focus_after_layout.is_empty() and ControllerFocus.contains(body, focused):
		focus_after_layout = str(focused.get_meta("controller_focus_key", ""))
	for child in body.get_children(): child.free()
	selection_preview = null
	ascension_button = null
	weapon_buttons.clear()
	upgrade_buttons.clear()
	effect_buttons.clear()
	focus_rows.clear()
	var narrow := extent.x < 720
	var compact := extent.x < 420
	finish_button.custom_minimum_size.x = 110 if compact else 180
	finish_button.add_theme_font_size_override("font_size", 16 if compact else 20)
	back_button.add_theme_font_size_override("font_size", 14 if compact else 20)
	stage.title_label.text = "Verzaubern" if compact else "Waffen verzaubern"
	stage.title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if compact else TextServer.AUTOWRAP_OFF
	if compact and not models.is_empty():
		stage.title_label.text = current_data().display_name
		var copies := 0
		for model in models:
			if model.id == models[selected_weapon].id: copies += 1
		if copies > 1: stage.title_label.text += " · #%d" % (selected_weapon + 1)
	count_label.text = _balance_text()
	count_label.tooltip_text = "%d Punkte · 2 je Kapsel" % remaining
	if income != null: count_label.tooltip_text += "\n" + income.details()
	stage.title_label.add_theme_font_size_override("font_size", 18 if compact else 32)
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
		else: height = _overview(right, true)
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
		var height := _picker(Rect2(0, top, extent.x, 0)) if picking_slot >= 0 else _overview(Rect2(0, top, extent.x, 0), true)
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
		var right := Rect2(rail + hero_width + gap * 2, 0, extent.x - rail - hero_width - gap * 2, 0)
		var height := _picker(right) if picking_slot >= 0 else _overview(right, false)
		body.custom_minimum_size.y = maxf(content_height, right.position.y + height) + 8
	body.size = Vector2(extent.x, maxf(extent.y, body.custom_minimum_size.y))
	stage.refresh_focus()
	for index in weapon_buttons.size():
		DentiUIStyle.mark_card(weapon_buttons[index], DentiUIStyle.GOLD if selected_weapon == index else Color.TRANSPARENT)
	_wire_controller_focus()
	if not focus_after_layout.is_empty(): _focus_after_refresh.call_deferred()

func _wire_controller_focus() -> void:
	if get_node("/root/GameInput").controller_active: return
	var choices: Array[Button] = []
	for button in effect_buttons if picking_slot >= 0 else upgrade_buttons:
		if ControllerFocus.available(button): choices.append(button)
	var footer: Button
	if ControllerFocus.available(finish_button): footer = finish_button
	elif ControllerFocus.available(back_button): footer = back_button
	if not choices.is_empty():
		var bottom := -INF
		for button in choices: bottom = maxf(bottom, button.get_global_rect().get_center().y)
		for button in choices:
			if footer != null and is_equal_approx(button.get_global_rect().get_center().y, bottom):
				button.focus_neighbor_bottom = button.get_path_to(footer)
		finish_button.focus_neighbor_top = finish_button.get_path_to(choices.back())
	for button in weapon_buttons:
		var right: Button = choices[0] if not choices.is_empty() else footer
		if right != null: button.focus_neighbor_right = button.get_path_to(right)
	if footer == null: return
	if not weapon_buttons.is_empty():
		weapon_buttons.back().focus_neighbor_bottom = weapon_buttons.back().get_path_to(footer)
		back_button.focus_neighbor_top = back_button.get_path_to(weapon_buttons[selected_weapon])
		if choices.is_empty(): finish_button.focus_neighbor_top = finish_button.get_path_to(weapon_buttons[selected_weapon])
	if ControllerFocus.available(back_button): finish_button.focus_neighbor_left = finish_button.get_path_to(back_button)
	if ControllerFocus.available(finish_button): back_button.focus_neighbor_right = back_button.get_path_to(finish_button)
	if ControllerFocus.available(ascension_button): ascension_button.focus_neighbor_bottom = ascension_button.get_path_to(footer)


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
	var art_height := minf(300, rect.size.y - 110)
	var y := rect.position.y + (rect.size.y - art_height - 98) / 2
	_art(body, RunSetupPresentation.weapon_icon(data), Rect2(rect.position.x + 28, y, rect.size.x - 56, art_height))
	var title := _text(body, data.display_name, Rect2(rect.position.x, y + art_height + 16, rect.size.x, 38), 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_info(Rect2(rect.position.x, y + art_height + 58, rect.size.x, 40))


func _root_info(rect: Rect2) -> void:
	var data := current_data()
	var meta := str(models[selected_weapon].meta)
	var button := _button(body, meta, rect)
	ControllerFocus.tag(button, "weapon:details")
	MenuStyle.quiet(button)
	button.add_theme_font_size_override("font_size", 16)
	var text_width := button.get_theme_font("font").get_string_size(meta, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_art(button, preload("res://assets/ui/info.svg"), Rect2(minf((rect.size.x + text_width) / 2 + 8, rect.size.x - 18), (rect.size.y - 14) / 2, 14, 14))
	button.tooltip_text = "Effektstärke nach Wurzeln. Details öffnen."
	button.pressed.connect(func() -> void:
		details.present(data.display_name, models[selected_weapon].root_info, button))


func _overview(rect: Rect2, compact: bool) -> float:
	var ascension_height := 96.0
	# Allocate the ascent, four gaps and the body inset before sizing the rows.
	var row_height := (90.0 if rect.size.x < 310 else 74.0) if compact else clampf((stage.last_extent.y - ascension_height - 48) / 4, 78, 100)
	var gap := 8.0 if compact else 10.0
	_ascension(Rect2(rect.position, Vector2(rect.size.x, ascension_height)), compact)
	var offset := ascension_height + gap
	return offset + _slots(Rect2(rect.position + Vector2(0, offset), rect.size), compact, row_height)

func _slots(rect: Rect2, compact: bool, row_height: float) -> float:
	var very_narrow := compact and rect.size.x < 310
	var gap := 8.0 if compact else 10.0
	for index in SLOT_COUNT:
		var row := Rect2(rect.position + Vector2(0, index * (row_height + gap)), Vector2(rect.size.x, row_height))
		var effects: Array = models[selected_weapon].effects
		var focus_row := _action_row(body, row)
		ControllerFocus.tag(focus_row, "row:%d" % index)
		focus_rows.append(focus_row)
		if index >= effects.size():
			var locked := index >= int(models[selected_weapon].slot_count)
			var empty := _button(focus_row, "Ab Mk %s" % ["I", "II", "III", "IV"][index] if locked else "+  Verzaubern", Rect2(Vector2.ZERO, row.size))
			for style in ["normal", "hover", "pressed", "disabled"]: empty.add_theme_stylebox_override(style, StyleBoxEmpty.new())
			empty.tooltip_text = "Öffnet sich beim Waffenupgrade auf Mk %s" % ["I", "II", "III", "IV"][index] if locked else "Neue Verzauberung · %d Punkte" % _cost()
			if locked:
				empty.icon = preload("res://assets/ui/setup_lock.svg")
				empty.expand_icon = true
				empty.add_theme_constant_override("icon_max_width", 18)
				empty.alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.disabled = remaining < _cost() or locked
			focus_row.blocked_reason = "Erst ab Mk %s" % ["I", "II", "III", "IV"][index] if locked else _points_blocked()
			focus_row.action_label = "Verzaubern"
			focus_row.details_title = "Platz %d" % (index + 1)
			focus_row.details_text = (focus_row.blocked_reason + "\n\n" if not focus_row.blocked_reason.is_empty() else "") + "Neue Verzauberung · %d Punkte\n\n" % _cost() + str(models[selected_weapon].root_info)
			focus_row.pressed.connect(open_picker.bind(index))
			focus_row.status_label = _text(focus_row, "", Rect2(8, row_height - 28, row.size.x - 16, 24), 13, DentiUIStyle.GOLD)
			focus_row.status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.pressed.connect(open_picker.bind(index))
			ControllerFocus.tag(empty, "slot:%d" % index)
			upgrade_buttons.append(empty)
			continue
		var effect: Dictionary = effects[index]
		var data := WeaponAffixes.by_id(effect.id)
		var level := int(effect.level)
		var panel := focus_row
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
		var preview_label := _text(panel, preview, Rect2(72, preview_top, text_width + 4, preview_height), 13 if compact else 14, DentiUIStyle.MUTED, true)
		focus_row.blocked_reason = "Maximalstufe erreicht" if level == MAX_LEVEL else _points_blocked()
		focus_row.action_label = "+ Rang · %d" % _cost()
		focus_row.details_title = data.display_name
		focus_row.details_text = (focus_row.blocked_reason + "\n\n" if not focus_row.blocked_reason.is_empty() else "") + str(effect.details)
		focus_row.status_label = preview_label
		focus_row.original_status = preview
		focus_row.pressed.connect(upgrade.bind(index))
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

func _cycle_weapon(direction: int) -> void:
	if picking_slot >= 0 or models.size() < 2: return
	var focus := get_viewport().gui_get_focus_owner()
	focus_after_layout = str(focus.get_meta("controller_focus_key", "weapon")) if ControllerFocus.contains(body, focus) else "weapon"
	select_weapon(posmod(selected_weapon + direction, models.size()))


func open_picker(slot: int) -> void:
	if remaining < _cost() or slot < models[selected_weapon].effects.size() or slot >= int(models[selected_weapon].slot_count): return
	picking_slot = slot
	selected_effect = &""
	focus_after_layout = "picker"
	_save_cursor()
	_refresh.call_deferred()


func upgrade(slot: int) -> void:
	if picking_slot >= 0: return
	if remaining < _cost() or slot < 0 or slot >= models[selected_weapon].effects.size(): return
	if int(models[selected_weapon].effects[slot].level) >= MAX_LEVEL: return
	focus_after_layout = "upgrade:%d" % slot
	upgrade_requested.emit(str(models[selected_weapon].uid), StringName(models[selected_weapon].effects[slot].id))


func _confirm() -> void:
	if picking_slot < 0:
		completed.emit()
		return
	if remaining < _cost() or not _selection_allowed(): return
	focus_after_layout = "upgrade:%d" % picking_slot
	upgrade_requested.emit(str(models[selected_weapon].uid), selected_effect)


func _back() -> void:
	if picking_slot >= 0:
		focus_after_layout = "slot:%d" % picking_slot
		picking_slot = -1
		selected_effect = &""
		_save_cursor()
	else:
		_undo()
	_refresh.call_deferred()

func _undo() -> void:
	if state == null or state.actions.is_empty(): return
	var action: Dictionary = state.actions.back()
	focus_after_layout = "ascension" if StringName(action.id) == WeaponAscension.ID else "row:0"
	for model in models:
		if str(model.uid) != str(action.uid): continue
		for slot in model.effects.size():
			if StringName(model.effects[slot].id) == StringName(action.id): focus_after_layout = "row:%d" % slot
	undo_requested.emit()

func _ascend() -> void:
	if picking_slot >= 0 or models.is_empty() or not str(models[selected_weapon].ascension.blocked).is_empty(): return
	focus_after_layout = "ascension"
	ascension_requested.emit(str(models[selected_weapon].uid))

func _request_close() -> void:
	if picking_slot >= 0:
		_back()
	elif state.actions.is_empty():
		cancelled.emit()
	else:
		var focus := get_viewport().gui_get_focus_owner()
		exit_focus = str(focus.get_meta("controller_focus_key", "")) if focus != null else ""
		exit_dialog.present()

func _exit_decided(choice: StringName) -> void:
	exit_dialog.hide()
	match choice:
		&"discard": cancelled.emit()
		&"finish": _confirm()
		_:
			focus_after_layout = exit_focus
			_focus_after_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or details.visible or exit_dialog.visible or not ControllerFocus.active(stage): return
	if event.is_action_pressed("ui_confirm"):
		if not finish_button.disabled: _confirm()
	elif event.is_action_pressed("ui_undo"):
		if picking_slot < 0: _undo()
	elif event.is_action_pressed("ui_previous"):
		_cycle_weapon(-1)
	elif event.is_action_pressed("ui_next"):
		_cycle_weapon(1)
	elif event.is_action_pressed("ui_details"):
		_show_focused_details()
	elif event.is_action_pressed("ui_cancel"):
		_request_close()
	else: return
	get_viewport().set_input_as_handled()


func _focus_after_refresh() -> void:
	if not visible or details.visible or focus_after_layout.is_empty() or not get_node("/root/GameInput").navigation_active: return
	var desired := focus_after_layout
	focus_after_layout = ""
	if get_node("/root/GameInput").controller_active:
		var target := focus_policy.resolve(desired)
		if target != null:
			target.grab_focus()
			ControllerFocus.reveal(target)
		return
	# Desktop actions keep their original buttons instead of the row wrappers.
	if desired.begins_with("row:"):
		var index := desired.get_slice(":", 1).to_int()
		if index < upgrade_buttons.size(): desired = str(upgrade_buttons[index].get_meta("controller_focus_key", ""))
	var candidates: Array[Control] = ControllerFocus.controls(body)
	if desired == "picker": candidates.assign(effect_buttons)
	elif desired == "weapon" and selected_weapon < weapon_buttons.size(): candidates = [weapon_buttons[selected_weapon]]
	elif desired == "ascension" and is_instance_valid(ascension_button): candidates = [ascension_button]
	for control in candidates:
		if ControllerFocus.available(control) and (desired in ["picker", "weapon", "ascension"] or str(control.get_meta("controller_focus_key", "")) == desired):
			control.grab_focus()
			ControllerFocus.reveal(control)
			return
	if ControllerFocus.available(finish_button): finish_button.grab_focus()


func _save_cursor() -> void:
	if state == null or models.is_empty(): return
	state.cursor = {"target_uid": str(models[selected_weapon].uid), "picking_slot": picking_slot, "selected_effect": str(selected_effect)}
	selection_changed.emit()


func _cost() -> int:
	return int(models[selected_weapon].cost) if not models.is_empty() else 1

func _points_blocked() -> String:
	return "Noch %d Punkte nötig" % (_cost() - remaining) if remaining < _cost() else ""

func _show_focused_details() -> void:
	if models.is_empty(): return
	var source := get_viewport().gui_get_focus_owner()
	if source is WeaponEnchantmentAction:
		details.present(source.details_title, source.details_text, source)
	elif source != null and source.has_meta("effect_id"):
		var id := StringName(source.get_meta("effect_id"))
		details.present(WeaponAffixes.by_id(id).display_name, AffixPresentation.effect_description(id), source)
	else:
		details.present(current_data().display_name, str(models[selected_weapon].root_info), source)


func _balance_text() -> String:
	var gold := state.remaining_gold(coins) if state != null else coins
	return "%d Punkt%s\n%d Gold" % [remaining, "" if remaining == 1 else "e", gold]


func _ascension(rect: Rect2, short: bool = false) -> void:
	var offer: Dictionary = models[selected_weapon].ascension
	var locked := int(models[selected_weapon].tier) < WeaponLoadout.MAX_TIER
	var title := "Ab Mk IV" if locked else ("Aufstieg · " if short else "Aufsteigen · ") + str(offer.next)
	var price := "%d P · %d G" % [offer.cost, offer.coins] if short else "%d Punkte · %d Gold" % [offer.cost, offer.coins]
	var row := _action_row(body, rect)
	ascension_button = row
	row.focus_mode = Control.FOCUS_ALL
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.blocked_reason = str(offer.blocked)
	row.disabled = not row.blocked_reason.is_empty() and not get_node("/root/GameInput").controller_active
	row.action_label = "Aufsteigen"
	row.details_title = title
	row.details_text = (row.blocked_reason + "\n\n" if not row.blocked_reason.is_empty() else "") + "%s · %d Punkte · %d Gold\n+10 %% Basisschaden · +3 %% Tempo und Reichweite\nFertig übernimmt den Aufstieg; Rückgängig nimmt ihn zurück." % [offer.next, offer.cost, offer.coins]
	row.tooltip_text = row.details_text
	var blocked := not row.blocked_reason.is_empty()
	var heading := _text(row, title, Rect2(12, 6 if blocked else 16, rect.size.x - 24, 28), 16 if short else 19)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cost := _text(row, price, Rect2(12, 34 if blocked else 48, rect.size.x - 24, 24), 14 if short else 16, DentiUIStyle.MUTED)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if blocked:
		var reason := _text(row, row.blocked_reason, Rect2(12, 60, rect.size.x - 24, 30), 13, DentiUIStyle.GOLD, true)
		reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.pressed.connect(_ascend)
	ControllerFocus.tag(row, "ascension")


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

func _action_row(parent: Node, rect: Rect2) -> WeaponEnchantmentAction:
	var row := WeaponEnchantmentAction.new()
	MenuStyle.action(row)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.focus_mode = Control.FOCUS_ALL if get_node("/root/GameInput").controller_active else Control.FOCUS_NONE
	row.add_theme_stylebox_override("normal", MenuStyle.box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 14, 1))
	parent.add_child(row)
	_place(row, rect)
	return row
