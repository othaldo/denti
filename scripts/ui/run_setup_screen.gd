class_name RunSetupScreen
extends Control

signal chosen(weapon: WeaponData)
signal selection_changed
signal back_requested
signal next_requested
signal difficulty_chosen(id: StringName)
signal step_requested(id: StringName)

var panel: Control
var header: Control
var body: Control
var footer: Control
var branding: HBoxContainer
var brand_text: Label
var steps: HBoxContainer
var step_buttons: Dictionary = {}
var difficulty_view: DifficultySelection
var weapon_view: WeaponSelection
var back_button: Button
var confirm_button: Button
var details_button: RunSetupValue
var details: RunSetupDetails
var current_step: StringName = &"weapon"
var current_difficulty: StringName = &"normal"
var committed := false
var keyboard_focus := false
var standalone := true
var options: Array[WeaponData]:
	get: return weapon_view.options
var selected_id: StringName:
	get: return weapon_view.selected_id
var icon_buttons: Array[Button]:
	get: return weapon_view.icon_buttons
var weapon_name: Label:
	get: return weapon_view.weapon_name
var catalog_scroll: ScrollContainer:
	get: return weapon_view.catalog_scroll

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = RunSetupStyle.make_theme()
	_build_background()
	panel = Control.new()
	add_child(panel)
	header = Control.new()
	panel.add_child(header)
	branding = HBoxContainer.new()
	branding.add_theme_constant_override("separation", 12)
	header.add_child(branding)
	var mascot := TextureRect.new()
	mascot.texture = preload("res://assets/denti/denti_unarmed.png")
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mascot.custom_minimum_size = Vector2(40, 44)
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	branding.add_child(mascot)
	brand_text = Label.new()
	brand_text.text = "DENTI"
	brand_text.add_theme_font_size_override("font_size", 18)
	branding.add_child(brand_text)
	steps = HBoxContainer.new()
	steps.add_theme_constant_override("separation", 8)
	header.add_child(steps)
	for id in RunSetup.STEPS:
		if not step_buttons.is_empty():
			var separator := Label.new()
			separator.text = "›"
			separator.add_theme_color_override("font_color", DentiUIStyle.MUTED)
			steps.add_child(separator)
		var button := Button.new()
		button.text = RunSetup.LABELS[id]
		RunSetupStyle.quiet(button)
		button.custom_minimum_size.y = 44
		button.pressed.connect(func() -> void: step_requested.emit(id))
		steps.add_child(button)
		step_buttons[id] = button
	body = Control.new()
	panel.add_child(body)
	difficulty_view = DifficultySelection.new()
	body.add_child(difficulty_view)
	difficulty_view.selected.connect(func(id: StringName) -> void:
		current_difficulty = id
		difficulty_chosen.emit(id))
	difficulty_view.locked_requested.connect(_locked_details)
	weapon_view = WeaponSelection.new()
	body.add_child(weapon_view)
	weapon_view.selection_changed.connect(func() -> void:
		confirm_button.disabled = selected_id == &""
		details_button.disabled = selected_id == &""
		selection_changed.emit())
	weapon_view.details_requested.connect(func(title: String, text: String) -> void:
		details.present(title, text, get_viewport().gui_get_focus_owner()))
	footer = Control.new()
	panel.add_child(footer)
	var line := ColorRect.new()
	line.color = DentiUIStyle.LINE
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(line)
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = -12
	line.offset_bottom = -11
	back_button = _action("Zurück", false)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	details_button = RunSetupValue.new()
	RunSetupStyle.quiet(details_button)
	footer.add_child(details_button)
	details_button.set_presentation(preload("res://assets/ui/info.svg"), 18, 18)
	details_button.value = "Details"
	details_button.tooltip_text = "Details"
	details_button.add_theme_constant_override("icon_max_width", 18)
	details_button.pressed.connect(show_details)
	confirm_button = _action("Run starten", true)
	confirm_button.pressed.connect(confirm_selection)
	details = RunSetupDetails.new()
	add_child(details)
	for button in [back_button, confirm_button, details_button, details.close_button] + step_buttons.values():
		RunSetupStyle.focus(button, keyboard_focus)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_schedule_layout)
	visibility_changed.connect(func() -> void:
		if not visible: details.visible = false)
	_layout()

func _schedule_layout() -> void:
	if not get_tree().process_frame.is_connected(_layout):
		get_tree().process_frame.connect(_layout, CONNECT_ONE_SHOT)

func _build_background() -> void:
	var background := ColorRect.new()
	background.color = DentiUIStyle.BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var glow := TextureRect.new()
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.35)
	texture.fill_to = Vector2(1, 0.7)
	texture.gradient = Gradient.new()
	texture.gradient.colors = PackedColorArray([Color("322435"), DentiUIStyle.BACKGROUND])
	glow.texture = texture
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

func _action(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	DentiUIStyle.style_button(button, primary)
	footer.add_child(button)
	return button

func show_difficulty(setup: RunSetup, eligible: Callable) -> void:
	standalone = false
	current_step = &"difficulty"
	current_difficulty = setup.difficulty_id
	committed = false
	difficulty_view.show_selection(current_difficulty, eligible)
	_show_step(setup)
	_focus_difficulty.call_deferred()

func _focus_difficulty() -> void:
	if is_inside_tree() and is_visible_in_tree() and current_step == &"difficulty":
		(difficulty_view.buttons[current_difficulty] as Button).grab_focus()

func show_preparation(setup: RunSetup, weapons: Array[WeaponData]) -> void:
	standalone = false
	current_step = &"weapon"
	current_difficulty = setup.difficulty_id
	committed = false
	weapon_view.show_options(weapons, setup.weapon_id)
	_show_step(setup)
	weapon_view.focus_selection.call_deferred()

func show_options(weapons: Array[WeaponData], selected: StringName = &"") -> void:
	current_step = &"weapon"
	committed = false
	weapon_view.show_options(weapons, selected)
	_show_step()
	weapon_view.focus_selection.call_deferred()

func _show_step(setup: RunSetup = null) -> void:
	details.visible = false
	difficulty_view.visible = current_step == &"difficulty"
	weapon_view.visible = current_step == &"weapon"
	confirm_button.text = "Weiter" if current_step == &"difficulty" else "Run starten"
	confirm_button.disabled = current_step == &"weapon" and selected_id == &""
	details_button.disabled = confirm_button.disabled
	for id in step_buttons:
		var button: Button = step_buttons[id]
		button.disabled = id == current_step or standalone or (setup != null and not setup.can_visit(id))
		var style := RunSetupStyle.box(Color.TRANSPARENT, DentiUIStyle.GOLD if id == current_step else Color.TRANSPARENT, 0, 0)
		style.border_width_bottom = 2 if id == current_step else 0
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("disabled", style)
		button.add_theme_color_override("font_disabled_color", DentiUIStyle.INK if id == current_step else DentiUIStyle.MUTED.darkened(0.45))
	_layout()
	DentiUIMotion.reveal(body)

func select_weapon(index: int, notify: bool = true) -> void:
	if committed: return
	weapon_view.select_weapon(index, notify)
	confirm_button.disabled = selected_id == &""
	details_button.disabled = selected_id == &""

func confirm_selection() -> void:
	if committed or not is_visible_in_tree() or details.visible: return
	if current_step == &"difficulty":
		next_requested.emit()
		return
	var weapon := weapon_view.selected_weapon()
	if weapon == null: return
	committed = true
	confirm_button.disabled = true
	chosen.emit(weapon)

func show_details() -> void:
	if current_step == &"difficulty":
		var data := DifficultyCatalog.by_id(current_difficulty)
		details.present(data.display_name, data.description, details_button)
	else:
		var weapon := weapon_view.selected_weapon()
		if weapon == null: return
		details.present(weapon.display_name, RunSetupPresentation.details(weapon), details_button)

func _locked_details(id: StringName) -> void:
	details.present(DifficultyCatalog.by_id(id).display_name, "Ein Sieg auf Hard schaltet Hell frei.", difficulty_view.buttons[id])

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	# The primary action changes from Continue to Start at the same position.
	# A double click/tap is one navigation gesture, never consent to both.
	var repeated_pointer: bool = (event is InputEventMouseButton and event.double_click) or (event is InputEventScreenTouch and event.double_tap)
	if repeated_pointer and event.pressed and confirm_button.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.echo and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) < 0.5: return
	var using_keyboard := event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		using_keyboard = false
	elif not using_keyboard:
		return
	if using_keyboard == keyboard_focus: return
	keyboard_focus = using_keyboard
	details.keyboard_focus = keyboard_focus
	difficulty_view.keyboard_focus = keyboard_focus
	difficulty_view.refresh()
	weapon_view.keyboard_focus = keyboard_focus
	weapon_view.refresh()
	for button in [back_button, confirm_button, details_button, details.close_button] + step_buttons.values():
		RunSetupStyle.focus(button, keyboard_focus)

func _layout() -> void:
	if panel == null: return
	var factor := RunSetupLayout.ui_scale(get_viewport())
	var safe := HUDLayout.safe_rect(size)
	var rect := RunSetupLayout.stage(Rect2(safe.position / factor, safe.size / factor))
	panel.scale = Vector2.ONE * factor
	panel.position = rect.position * factor
	panel.size = rect.size
	var compact := rect.size.x < 600 or rect.size.y < 480
	header.size = Vector2(rect.size.x, 44 if compact else 60)
	brand_text.visible = rect.size.x >= 650
	branding.position = Vector2.ZERO
	branding.size = Vector2(130 if brand_text.visible else 40, header.size.y)
	for button: Button in step_buttons.values(): button.add_theme_font_size_override("font_size", 14 if compact else 18)
	steps.reset_size()
	steps.size.y = header.size.y
	steps.position = Vector2(rect.size.x - steps.size.x, 0)
	var content := RunSetupLayout.body(rect.size)
	body.position = content.position
	body.size = content.size
	for view in [difficulty_view, weapon_view]:
		view.position = Vector2.ZERO
		view.size = content.size
	footer.position = Vector2(0, rect.size.y - (52 if compact else 56))
	footer.size = Vector2(rect.size.x, 52 if compact else 56)
	var back_width := 88.0 if compact else 112.0
	var primary_width := 128.0 if compact else 192.0
	back_button.position = Vector2.ZERO
	back_button.size = Vector2(back_width, footer.size.y)
	confirm_button.position = Vector2(footer.size.x - primary_width, 0)
	confirm_button.size = Vector2(primary_width, footer.size.y)
	details_button.value = "" if rect.size.x < 600 else "Details"
	var details_width := 48.0 if compact else 112.0
	details_button.position = Vector2(back_width + (footer.size.x - back_width - primary_width - details_width) * 0.5, 0)
	details_button.size = Vector2(details_width, footer.size.y)
	for button in [back_button, confirm_button, details_button]: button.add_theme_font_size_override("font_size", 16 if compact else 19)
