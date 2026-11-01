class_name WeaponFusionPanel
extends CanvasLayer

signal confirmed(plan: WeaponFusionPlan)
signal cancelled

var plan: WeaponFusionPlan
var stage: RewardStage
var body: Control
var refund_label: Label
var confirm_button: Button
var cancel_button: Button
var effect_buttons: Array[Button] = []
var slot_buttons: Array[Button] = []
var result_art: TextureRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 26
	visible = false
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = RewardStage.new()
	root.add_child(stage)
	cancel_button = Button.new()
	cancel_button.text = "Abbrechen"
	MenuStyle.action(cancel_button, false, true)
	cancel_button.pressed.connect(_cancel)
	stage.footer.add_child(cancel_button)
	refund_label = Label.new()
	refund_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refund_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refund_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	refund_label.add_theme_color_override("font_color", DentiUIStyle.MINT)
	stage.footer.add_child(refund_label)
	confirm_button = Button.new()
	confirm_button.text = "Fusionieren"
	MenuStyle.action(confirm_button, true)
	confirm_button.pressed.connect(func() -> void:
		if plan != null and plan.valid(): confirmed.emit(plan))
	stage.footer.add_child(confirm_button)
	body = Control.new()
	stage.layout_changed.connect(_layout)
	stage.present("Waffen fusionieren", body)
	ControllerPrompt.bind(cancel_button, &"ui_cancel", false)
	ControllerPrompt.bind(confirm_button, &"ui_confirm", false)
	get_node("/root/GameInput").changed.connect(_sync_input_mode)


func show_plan(value: WeaponFusionPlan) -> void:
	plan = value
	visible = true
	stage.body_scroll.scroll_vertical = 0
	stage.title_label.text = "Evolution" if plan.recipe_id != &"" else "Waffen fusionieren"
	_layout(stage.last_extent)
	DentiUIMotion.reveal(body)
	cancel_button.grab_focus()


func _cancel() -> void:
	visible = false
	plan = null
	cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not ControllerFocus.active(stage): return
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_confirm"):
		if plan != null and plan.valid(): confirmed.emit(plan)
		get_viewport().set_input_as_handled()

func _sync_input_mode() -> void:
	var controller: bool = get_node("/root/GameInput").controller_active
	for button in slot_buttons:
		button.focus_mode = Control.FOCUS_NONE if controller else Control.FOCUS_ALL


func toggle(id: StringName) -> void:
	if plan.toggle(id): _layout.call_deferred(stage.last_extent)


func _layout(extent: Vector2) -> void:
	if body == null or plan == null or extent.x < 1: return
	for child in body.get_children(): child.free()
	effect_buttons.clear()
	slot_buttons.clear()
	var narrow := extent.x < 680
	var compact := extent.x < 420
	var refund_parent: Node = stage.header if compact else stage.footer
	if refund_label.get_parent() != refund_parent:
		refund_label.reparent(refund_parent)
		if not compact: stage.footer.move_child(refund_label, 1)
	refund_label.size_flags_horizontal = Control.SIZE_SHRINK_END if compact else Control.SIZE_EXPAND_FILL
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	for button in [cancel_button, confirm_button]: button.add_theme_font_size_override("font_size", 16 if compact else 20)
	stage.title_label.text = "Evolution" if plan.recipe_id != &"" else ("Fusion" if compact else "Waffen fusionieren")
	var short_layout := extent.y < 280 and not compact
	var source_width := (extent.x - 16) / plan.ingredients.size() - (8 if plan.ingredients.size() == 2 else 0)
	var source_height := 152.0 if not compact else 180.0
	for index in plan.ingredients.size():
		var rect := Rect2(0, index * 106, 136, 98) if short_layout else Rect2(index * (source_width + 32), 0, source_width, source_height)
		_source(index, rect, compact)
	if plan.ingredients.size() == 2 and not short_layout:
		_text(body, "+", Rect2(source_width, 40, 32, 40), 26, DentiUIStyle.GOLD)
	var top := source_height + 16
	var hero_width := extent.x if narrow else clampf(extent.x * 0.32, 220, 370)
	var hero_height := 112.0 if narrow else 310.0
	var result := plan.preview()
	if short_layout:
		result_art = _art(body, RunSetupPresentation.weapon_icon(result), Rect2(152, 0, 44, 46))
		_text(body, result.display_name, Rect2(202, 0, extent.x - 202, 40), 18, DentiUIStyle.INK, true)
	else:
		result_art = _art(body, RunSetupPresentation.weapon_icon(result), Rect2(0, top, 94 if narrow else hero_width, 100 if narrow else 242))
		_text(body, result.display_name, Rect2(108 if narrow else 0, top if narrow else top + 248, hero_width - (108 if narrow else 0), 50), 21, DentiUIStyle.INK, true)
		_text(body, "%s · %s" % [WeaponPresentation.tier_text(result, plan.tier), result.roots_text()], Rect2(108 if narrow else 0, top + (66 if narrow else 298), hero_width - (108 if narrow else 0), 28), 15, DentiUIStyle.MUTED)
	var x := 0.0 if narrow else hero_width + 24
	var y := top + hero_height + 12 if narrow else top
	if short_layout:
		x = 152
		y = 52
	var width := extent.x - x
	var slot_width := (width - 24) / 4
	var effects := plan.effects()
	for index in 4:
		var button := _button(Rect2(x + index * (slot_width + 8), y, slot_width, 62))
		button.disabled = index >= WeaponUpgrades.slots(plan.tier)
		if index < effects.size():
			var entry: Dictionary = effects[index]
			var definition := WeaponAffixes.by_id(StringName(entry.id))
			_art(button, DentiUIIcons.item(definition.icon_index), Rect2(6, 7, 30, 38))
			_text(button, "%d" % WeaponUpgrades.level(entry), Rect2(slot_width - 28, 18, 24, 28), 17)
			button.tooltip_text = definition.display_name + " · Entfernen"
			button.pressed.connect(toggle.bind(definition.id))
		else:
			_text(button, "–" if not button.disabled else "×", Rect2(0, 14, slot_width, 30), 22, DentiUIStyle.MUTED)
			button.tooltip_text = "Freier Platz" if not button.disabled else "Ab Mk %s" % ["I", "II", "III", "IV"][index]
		slot_buttons.append(button)
	y += 78
	var columns := 1 if compact else 2
	var cell := (width - (columns - 1) * 10) / columns
	for index in plan.candidates.size():
		var entry: Dictionary = plan.candidates[index]
		var id := StringName(entry.id)
		var definition := WeaponAffixes.by_id(id)
		var chosen := plan.selected.has(id)
		var can_swap := definition.elemental and plan._element() != &""
		var full := plan.selected.size() >= WeaponUpgrades.slots(plan.tier)
		var button := _button(Rect2(x + index % columns * (cell + 10), y + (index / columns) * 58, cell, 50))
		button.disabled = full and not chosen and not can_swap
		RunSetupStyle.choice(button, chosen, stage.keyboard_focus)
		button.add_theme_stylebox_override("disabled", MenuStyle.box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 16, 1))
		button.modulate.a = 0.5 if button.disabled else 1.0
		_art(button, DentiUIIcons.item(definition.icon_index), Rect2(8, 7, 32, 36))
		_text(button, definition.display_name, Rect2(48, 2, cell - 104, 46), 16)
		_text(button, "%d/10" % WeaponUpgrades.level(entry), Rect2(cell - 52, 2, 48, 46), 15, DentiUIStyle.GOLD if chosen else DentiUIStyle.MUTED)
		button.tooltip_text = ("Alle %d Plätze belegt\n" % WeaponUpgrades.slots(plan.tier) if button.disabled else "") + AffixPresentation.effect_description(id)
		button.pressed.connect(toggle.bind(id))
		ControllerFocus.tag(button, "fusion:%s" % id)
		button.set_meta("controller_details", func() -> void: DentiDentikon.open(button, definition.display_name, button.tooltip_text, DentiUIIcons.item(definition.icon_index)))
		effect_buttons.append(button)
	var bottom := y + ceili(float(plan.candidates.size()) / columns) * 58
	body.custom_minimum_size.y = maxf(212 if short_layout else top + hero_height + 24, bottom + 8)
	body.size = Vector2(extent.x, maxf(extent.y, body.custom_minimum_size.y))
	refund_label.text = "+%d Punkte" % plan.refund() if compact else "%d Upgradepunkte zurück" % plan.refund()
	refund_label.add_theme_font_size_override("font_size", 13 if compact else 17)
	refund_label.tooltip_text = "Wurzelkosten bestimmen die übernommenen Ränge. Nicht übernommene Punkte werden vollständig erstattet."
	confirm_button.disabled = not plan.valid()
	_sync_input_mode()
	stage.refresh_focus()


func _source(index: int, rect: Rect2, compact: bool) -> void:
	var source: Dictionary = plan.ingredients[index]
	var card := Panel.new()
	body.add_child(card)
	card.position = rect.position
	card.size = rect.size
	card.add_theme_stylebox_override("panel", DentiUIStyle.rarity_surface(int(source.tier)))
	var tight := rect.size.y < 100
	if tight:
		_art(card, RunSetupPresentation.weapon_icon(plan.source_data[index]), Rect2(4, 4, 30, 40))
		_text(card, plan.source_data[index].display_name, Rect2(38, 4, rect.size.x - 42, 40), 12, DentiUIStyle.INK, true)
		for offset in source.affixes.size():
			var entry: Dictionary = source.affixes[offset]
			var at := Vector2(5 + offset * 32, 52)
			_art(card, DentiUIIcons.item(WeaponAffixes.by_id(StringName(entry.id)).icon_index), Rect2(at, Vector2(23, 23)))
			_text(card, str(WeaponUpgrades.level(entry)), Rect2(at + Vector2(0, 24), Vector2(23, 19)), 12)
		return
	_art(card, RunSetupPresentation.weapon_icon(plan.source_data[index]), Rect2(8, 8, 52, 66))
	_text(card, plan.source_data[index].display_name, Rect2(68, 6, rect.size.x - 76, 64), 14 if compact else 18, DentiUIStyle.INK, true)
	var values: Array = source.affixes
	var columns := 1 if compact else 2
	var width := (rect.size.x - 16) / columns
	for offset in values.size():
		var entry: Dictionary = values[offset]
		var definition := WeaponAffixes.by_id(StringName(entry.id))
		var at := Vector2(8 + offset % columns * width, 78 + (offset / columns) * 23)
		_art(card, DentiUIIcons.item(definition.icon_index), Rect2(at, Vector2(20, 22)))
		_text(card, "%s · %d" % [definition.display_name, WeaponUpgrades.level(entry)], Rect2(at + Vector2(24, 0), Vector2(width - 28, 22)), 13)


func _button(rect: Rect2) -> Button:
	var button := Button.new()
	body.add_child(button)
	button.position = rect.position
	button.size = rect.size
	RunSetupStyle.choice(button, false, stage.keyboard_focus)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _art(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	image.position = rect.position
	image.size = rect.size
	return image


func _text(parent: Control, value: String, rect: Rect2, font_size: int, color: Color = DentiUIStyle.INK, wrap: bool = false) -> void:
	var label := Label.new()
	label.text = value
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	label.position = rect.position
	label.size = rect.size
