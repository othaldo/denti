extends Control
## Isolated UX study. No WeaponInstance, combat, economy or save data is changed.

signal completed

const MAX_LEVEL := 10
const SLOT_COUNT := 4
const STARTING_UPGRADES := 3
const CAPSULE: Texture2D = preload("res://assets/loot/upgrade_capsule.png")

var stage: RewardStage
var body: Control
var details: RunSetupDetails
var count_label: Label
var back_button: Button
var finish_button: Button
var weapon_buttons: Array[Button] = []
var upgrade_buttons: Array[Button] = []
var effect_buttons: Array[Button] = []
var models: Array[Dictionary] = [
	{"id": &"magic_toothbrush", "tier": 3, "effects": [{"id": &"fire", "level": 4}, {"id": &"electric", "level": 2}]},
	{"id": &"turbo_drill", "tier": 2, "effects": [{"id": &"bleed", "level": 3}]},
	{"id": &"enamel_mirror", "tier": 2, "effects": [{"id": &"holy", "level": 10}]},
	{"id": &"mouthwash_mortar", "tier": 3, "effects": [{"id": &"wet", "level": 2}]},
]
var selected_weapon := 0
var remaining := STARTING_UPGRADES
var picking_slot := -1
var selected_effect: StringName = &""
var history: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = RewardStage.new()
	add_child(stage)
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
	add_child(details)
	_refresh()


func _refresh() -> void:
	if stage == null: return
	count_label.text = "%d Upgrade%s" % [remaining, "" if remaining == 1 else "s"]
	back_button.text = "Zurück" if picking_slot >= 0 else "Rückgängig"
	back_button.disabled = picking_slot < 0 and history.is_empty()
	back_button.visible = not back_button.disabled
	finish_button.text = "Verzaubern · 1 Upgrade" if picking_slot >= 0 else "Fertig"
	finish_button.disabled = picking_slot >= 0 and (selected_effect == &"" or remaining == 0)
	_layout(stage.last_extent)


func _layout(extent: Vector2) -> void:
	if body == null or extent.x < 1: return
	for child in body.get_children(): child.free()
	weapon_buttons.clear()
	upgrade_buttons.clear()
	effect_buttons.clear()
	var narrow := extent.x < 720
	var compact := extent.x < 420
	stage.title_label.text = "Verzaubern" if compact else "Waffen verzaubern"
	count_label.text = str(remaining) if compact else "%d Upgrade%s" % [remaining, "" if remaining == 1 else "s"]
	count_label.tooltip_text = "%d verfügbare Upgrades" % remaining
	stage.title_label.add_theme_font_size_override("font_size", 22 if compact else 32)
	count_label.add_theme_font_size_override("font_size", 16 if compact else 20)
	var top := 0.0
	if extent.x >= 420 and extent.y < 280:
		# Short landscape: put actual effects in the first viewport, beside the
		# weapon gallery, instead of spending its full height on a preview.
		for index in models.size():
			_weapon_card(index, Rect2(index % 2 * 64, (index / 2) * 64, 56, 56), true)
		_text(body, current_data().display_name, Rect2(0, 136, 122, 48), 17, DentiUIStyle.INK, true)
		_text(body, current_data().roots_text(), Rect2(0, 188, 122, 24), 14, DentiUIStyle.MUTED)
		var right := Rect2(144, 0, extent.x - 144, 0)
		var height := _picker(right) if picking_slot >= 0 else _slots(right, true)
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
	var data := WeaponCatalog.by_id(models[index].id)
	var button := RunSetupChoice.new()
	button.rarity_tier = models[index].tier
	button.selected = selected_weapon == index
	body.add_child(button)
	_place(button, rect)
	button.refresh()
	# Preserve Mk's rarity edge; the inset gold marker means selection.
	DentiUIStyle.mark_card(button, DentiUIStyle.GOLD if selected_weapon == index else Color.TRANSPARENT)
	button.tooltip_text = data.display_name + " · " + data.roots_text()
	button.pressed.connect(select_weapon.bind(index))
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
	_text(button, "Mk %s · %s" % [["I", "II", "III"][int(models[index].tier) - 1], data.roots_text()], Rect2(86, 51, rect.size.x - 98, 20), 14, DentiUIStyle.MUTED)
	var x := 86.0
	for effect: Dictionary in models[index].effects:
		_art(button, DentiUIIcons.item(WeaponAffixes.by_id(effect.id).icon_index), Rect2(x, 75, 20, 20))
		_text(button, str(effect.level), Rect2(x + 23, 74, 24, 22), 14)
		x += 52


func _hero(rect: Rect2, compact: bool) -> void:
	var data := current_data()
	if compact:
		_art(body, RunSetupPresentation.weapon_icon(data), Rect2(rect.position, Vector2(50, 60)))
		_text(body, data.display_name, Rect2(rect.position + Vector2(64, 0), Vector2(rect.size.x - 64, 30)), 22)
		_root_info(Rect2(rect.position + Vector2(64, 29), Vector2(rect.size.x - 64, 36)))
		return
	var art_height := minf(280, rect.size.y - 140)
	var y := rect.position.y + (rect.size.y - art_height - 100) / 2
	_art(body, RunSetupPresentation.weapon_icon(data), Rect2(rect.position.x + 28, y, rect.size.x - 56, art_height))
	var title := _text(body, data.display_name, Rect2(rect.position.x, y + art_height + 24, rect.size.x, 38), 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_info(Rect2(rect.position.x, y + art_height + 67, rect.size.x, 40))


func _root_info(rect: Rect2) -> void:
	var data := current_data()
	var button := _button(body, "Mk %s · %s  ⓘ" % [["I", "II", "III"][int(models[selected_weapon].tier) - 1], data.roots_text()], rect)
	MenuStyle.quiet(button)
	button.add_theme_font_size_override("font_size", 16)
	button.tooltip_text = "Effektstärke nach Wurzeln. Details öffnen."
	button.pressed.connect(func() -> void:
		details.present(data.display_name, "Entwurf: %s geben dieser Waffe das %d-fache Wirkungsbudget einer Ein-Wurzel-Waffe.\n\nAktivieren kostet 1 Upgrade und startet bei 1/10. Jede weitere Stufe kostet 1 Upgrade. Alle vier Plätze sind von Beginn an offen.\n\nDie Vorschauwerte sind Beispielwerte für die Gestaltung, keine gemessene Balance. Angriffspause und Projektilzahl müssen bei der späteren Berechnung berücksichtigt werden." % [data.roots_text(), data.hands], button))


func _slots(rect: Rect2, compact: bool) -> float:
	var very_narrow := compact and rect.size.x < 310
	var row_height := (90.0 if very_narrow else 74.0) if compact else minf(100, maxf(78, (stage.last_extent.y - 38) / 4))
	var gap := 8.0 if compact else 10.0
	for index in SLOT_COUNT:
		var row := Rect2(rect.position + Vector2(0, index * (row_height + gap)), Vector2(rect.size.x, row_height))
		var effects: Array = models[selected_weapon].effects
		if index >= effects.size():
			var empty := _button(body, "+  Verzaubern", row)
			empty.add_theme_stylebox_override("normal", MenuStyle.box(Color(DentiUIStyle.PANEL, 0.55), DentiUIStyle.LINE, 14, 1))
			empty.disabled = remaining == 0
			empty.pressed.connect(open_picker.bind(index))
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
		icon.pressed.connect(func() -> void: details.present(data.display_name, AffixPresentation.effect_description(data.id) + "\n\n" + _value_text(data.id, level) + ".\nBeispielwert dieses UI-Entwurfs.", icon))
		var action_width := 72.0 if compact else 82.0
		var text_width := row.size.x - 90 - action_width
		_text(panel, data.display_name, Rect2(72, 3 if compact else 9, text_width - 48, 25), 18 if compact else 19)
		var rank := _text(panel, "%d/10" % level, Rect2(row.size.x - action_width - 66, 4 if compact else 10, 52, 24), 16, DentiUIStyle.MINT if level == MAX_LEVEL else DentiUIStyle.INK)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for pip in MAX_LEVEL:
			var cell := ColorRect.new()
			cell.color = data.color if pip < level else DentiUIStyle.LINE
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(cell)
			_place(cell, Rect2(73 + pip * (text_width / 10), 31 if compact else 42, text_width / 10 - 3, 3 if compact else 4))
		var preview := _value_text(data.id, level) if level == MAX_LEVEL else _delta_text(data.id, level)
		if very_narrow: preview = preview.trim_suffix(" " + _unit(data.id)) + "\n" + _unit(data.id)
		var preview_height := 50.0 if very_narrow else (36.0 if compact else 28.0)
		var preview_top := 37.0 if compact else minf(53, row_height - 32)
		_text(panel, preview, Rect2(72, preview_top, text_width + 4, preview_height), 13 if compact else 14, DentiUIStyle.MUTED, true)
		var action := _button(panel, "MAX" if level == MAX_LEVEL else "+ 1", Rect2(row.size.x - action_width - 12, 13 if compact else 25, action_width, 48))
		action.tooltip_text = "Maximalstufe erreicht" if level == MAX_LEVEL else "%s: %d/10 → %d/10 · kostet 1 Upgrade" % [data.display_name, level, level + 1]
		action.disabled = level == MAX_LEVEL or remaining == 0
		action.pressed.connect(upgrade.bind(index))
		upgrade_buttons.append(action)
	return SLOT_COUNT * (row_height + gap) - gap


func _picker(rect: Rect2) -> float:
	_text(body, "Verzauberung hinzufügen", Rect2(rect.position, Vector2(rect.size.x, 32)), 22)
	var columns := 2 if rect.size.x < 400 else 3
	var gap := 8.0
	var width := (rect.size.x - gap * (columns - 1)) / columns
	for index in WeaponAffixes.ALL.size():
		var data := WeaponAffixes.ALL[index]
		var row := Rect2(rect.position + Vector2(index % columns * (width + gap), 42 + (index / columns) * 66), Vector2(width, 58))
		var button := _button(body, "", row)
		RunSetupStyle.choice(button, selected_effect == data.id, stage.keyboard_focus)
		_art(button, DentiUIIcons.item(data.icon_index), Rect2(8, 12, 34, 36))
		_text(button, data.display_name, Rect2(47, 8, width - 52, 46), 15)
		button.disabled = _has_effect(data.id)
		if button.disabled:
			_art(button, preload("res://assets/ui/setup_check.svg"), Rect2(width - 20, 5, 14, 14))
		button.tooltip_text = "Bereits auf dieser Waffe" if button.disabled else AffixPresentation.effect_description(data.id)
		button.pressed.connect(func() -> void:
			selected_effect = data.id
			_refresh.call_deferred())
		effect_buttons.append(button)
	var bottom := 42 + ceili(float(WeaponAffixes.ALL.size()) / columns) * 66
	if selected_effect != &"":
		var data := WeaponAffixes.by_id(selected_effect)
		_text(body, "%s · 1/10" % data.display_name, Rect2(rect.position + Vector2(0, bottom + 6), Vector2(rect.size.x, 30)), 22)
		_text(body, _value_text(selected_effect, 1), Rect2(rect.position + Vector2(0, bottom + 38), Vector2(rect.size.x, 30)), 17, DentiUIStyle.MINT)
		_text(body, AffixPresentation.effect_description(selected_effect), Rect2(rect.position + Vector2(0, bottom + 76), Vector2(rect.size.x, 50)), 16, DentiUIStyle.MUTED, true)
	return bottom + 132


func current_data() -> WeaponData:
	return WeaponCatalog.by_id(models[selected_weapon].id)


func select_weapon(index: int) -> void:
	if index < 0 or index >= models.size(): return
	selected_weapon = index
	picking_slot = -1
	selected_effect = &""
	_refresh.call_deferred()


func open_picker(slot: int) -> void:
	if remaining == 0 or slot < models[selected_weapon].effects.size() or slot >= SLOT_COUNT: return
	picking_slot = slot
	selected_effect = &""
	_refresh.call_deferred()


func upgrade(slot: int) -> void:
	if remaining == 0 or slot < 0 or slot >= models[selected_weapon].effects.size(): return
	if int(models[selected_weapon].effects[slot].level) >= MAX_LEVEL: return
	_remember()
	models[selected_weapon].effects[slot].level += 1
	remaining -= 1
	_refresh.call_deferred()


func _confirm() -> void:
	if picking_slot < 0:
		completed.emit()
		return
	if remaining == 0 or selected_effect == &"" or _has_effect(selected_effect): return
	_remember()
	models[selected_weapon].effects.append({"id": selected_effect, "level": 1})
	remaining -= 1
	picking_slot = -1
	selected_effect = &""
	_refresh.call_deferred()


func _back() -> void:
	if picking_slot >= 0:
		picking_slot = -1
		selected_effect = &""
	elif not history.is_empty():
		var previous: Dictionary = history.pop_back()
		models.assign(previous.models)
		remaining = previous.remaining
		selected_weapon = previous.selected_weapon
	_refresh.call_deferred()


func _remember() -> void:
	history.append({"models": models.duplicate(true), "remaining": remaining, "selected_weapon": selected_weapon})


func _has_effect(id: StringName) -> bool:
	for effect: Dictionary in models[selected_weapon].effects:
		if effect.id == id: return true
	return false


func _value(id: StringName, level: int) -> float:
	# Deliberately illustrative; the production affix formulas are not called.
	var roots := float(current_data().hands)
	match id:
		&"range", &"tempo": return level * (1.5 if roots > 1 else 1.0)
		&"wet": return minf(1.0 + level * 0.12 * roots, 4.0)
		&"leech": return minf(0.15 * level * roots, 2.0)
	return 3.0 * level * roots * current_data().interval


func _unit(id: StringName) -> String:
	match id:
		&"fire": return "Schaden / 2 s"
		&"poison": return "Schaden / 5 s"
		&"bleed": return "Schaden / 3 s"
		&"wet": return "s Nässe"
		&"leech": return "HP / Impuls"
		&"holy": return "Schaden / Lichtstoß"
		&"range": return "% Reichweite"
		&"tempo": return "% Angriffstempo"
	return "Schaden / Treffer"


func _number(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


func _value_text(id: StringName, level: int) -> String:
	return "%s %s" % [_number(_value(id, level)), _unit(id)]


func _delta_text(id: StringName, level: int) -> String:
	return "%s → %s %s" % [_number(_value(id, level)), _number(_value(id, level + 1)), _unit(id)]


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
