class_name MenuStage
extends Control

signal back_requested

var panel: Control
var header: HBoxContainer
var heading: Label
var body_scroll: ScrollContainer
var footer: Label
var back_button: Button
var content: Control
var keyboard_focus := false
var maximum := Vector2(1400, 900)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = MenuStyle.make_theme()
	panel = Control.new()
	add_child(panel)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	panel.add_child(header)
	back_button = Button.new()
	back_button.text = "‹"
	back_button.tooltip_text = "Zurück"
	MenuStyle.action(back_button, false, true)
	back_button.custom_minimum_size = Vector2(48, 48)
	back_button.add_theme_font_size_override("font_size", 34)
	header.add_child(back_button)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	heading = Label.new()
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	body_scroll = ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body_scroll.follow_focus = true
	var inset := StyleBoxEmpty.new()
	inset.content_margin_bottom = 4
	body_scroll.add_theme_stylebox_override("panel", inset)
	panel.add_child(body_scroll)
	body_scroll.resized.connect(_layout_content)
	footer = Label.new()
	footer.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	footer.add_theme_font_size_override("font_size", 12)
	footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(footer)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_schedule_layout)
	_layout()

func present(title: String, view: Control, footer_text: String = "", width: float = 1400) -> void:
	if content != null:
		body_scroll.remove_child(content)
		content.queue_free()
	content = view
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(content)
	heading.text = title
	header.visible = not title.is_empty()
	footer.text = footer_text
	footer.visible = not footer_text.is_empty()
	maximum.x = width
	body_scroll.scroll_vertical = 0
	visible = true
	_layout()
	_refresh_focus()

func _schedule_layout() -> void:
	if not is_inside_tree(): return
	if not get_tree().process_frame.is_connected(_layout):
		get_tree().process_frame.connect(_layout, CONNECT_ONE_SHOT)

func _layout() -> void:
	if panel == null or not is_inside_tree() or get_viewport() == null: return
	var factor := MenuLayout.ui_scale(get_viewport())
	var safe := HUDLayout.safe_rect(size)
	var bounds := MenuLayout.stage(Rect2(safe.position / factor, safe.size / factor), maximum)
	panel.scale = Vector2.ONE * factor
	panel.position = bounds.position * factor
	panel.size = bounds.size
	var compact := bounds.size.x < 600 or bounds.size.y < 480
	var top := 64.0 if header.visible else 0.0
	var bottom := 28.0 if footer.visible else 0.0
	header.position = Vector2.ZERO
	header.size = Vector2(bounds.size.x, 48)
	heading.add_theme_font_size_override("font_size", 26 if compact else 34)
	body_scroll.position = Vector2(0, top)
	body_scroll.size = Vector2(bounds.size.x, maxf(48, bounds.size.y - top - bottom))
	footer.position = Vector2(0, bounds.size.y - bottom)
	footer.size = Vector2(bounds.size.x, bottom)
	_layout_content()

func _layout_content() -> void:
	if is_inside_tree() and content != null and content.has_method("layout_in"):
		content.call("layout_in", body_scroll.size - body_scroll.get_theme_stylebox("panel").get_minimum_size())

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	var using_keyboard := event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		using_keyboard = false
	elif not using_keyboard:
		return
	if using_keyboard == keyboard_focus: return
	keyboard_focus = using_keyboard
	_refresh_focus()

func _refresh_focus() -> void:
	_style_focus(panel)

func _style_focus(control: Node) -> void:
	if control is Button or control is Range:
		MenuStyle.focus(control, keyboard_focus)
	for child in control.get_children(): _style_focus(child)
