class_name RunSetupDetails
extends Control

signal closed
var panel: Panel
var heading: Label
var body: Label
var scroll: ScrollContainer
var close_button: Button
var return_focus: Control
var keyboard_focus := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.02, 0.06, 0.8)
	add_child(shade)
	panel = Panel.new()
	panel.add_theme_stylebox_override("panel", RunSetupStyle.box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 22, 1))
	add_child(panel)
	heading = Label.new()
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 24)
	panel.add_child(heading)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 17)
	scroll.add_child(body)
	close_button = Button.new()
	close_button.text = "Schließen"
	DentiUIStyle.style_button(close_button)
	panel.add_child(close_button)
	close_button.pressed.connect(dismiss)
	# Tab/directional focus cannot leave the modal's single action.
	for direction in ["focus_next", "focus_previous", "focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top", "focus_neighbor_bottom"]:
		close_button.set(direction, NodePath("."))
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout.call_deferred)
	visible = false

func present(title: String, text: String, source: Control) -> void:
	return_focus = source
	heading.text = title
	body.text = text
	scroll.scroll_vertical = 0
	visible = true
	_layout()
	RunSetupStyle.focus(close_button, keyboard_focus)
	close_button.grab_focus()
	DentiUIMotion.reveal(panel)

func dismiss() -> void:
	visible = false
	if is_instance_valid(return_focus) and return_focus.is_visible_in_tree(): return_focus.grab_focus()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		scroll.scroll_vertical += -50 if event.is_action_pressed("ui_up") else 50
		get_viewport().set_input_as_handled()

func _layout() -> void:
	if panel == null: return
	var factor := RunSetupLayout.ui_scale(get_viewport())
	var bounds := HUDLayout.safe_rect(size)
	var safe := Rect2(bounds.position / factor, bounds.size / factor)
	panel.scale = Vector2.ONE * factor
	var width := minf(560, safe.size.x - 24)
	var margin := 16.0 if width < 400 else 24.0
	var text_width := width - margin * 2
	var heading_height := maxf(32, _text_height(heading.text, text_width, 24))
	var body_height := maxf(28, _text_height(body.text, text_width, 17))
	panel.size = Vector2(width, minf(safe.size.y - 24, heading_height + body_height + 132))
	panel.position = (safe.position + (safe.size - panel.size) * 0.5) * factor
	heading.position = Vector2(margin, 18)
	heading.size = Vector2(text_width, heading_height)
	scroll.position = Vector2(margin, heading_height + 36)
	close_button.position = Vector2(margin, panel.size.y - 66)
	close_button.size = Vector2(text_width, 48)
	scroll.size = Vector2(text_width, maxf(36, close_button.position.y - 18 - scroll.position.y))

func _text_height(text: String, width: float, font_size: int) -> float:
	var paragraph := TextParagraph.new()
	paragraph.width = width
	paragraph.add_string(text, body.get_theme_font("font"), font_size)
	return ceilf(paragraph.get_size().y)
