class_name RewardStage
extends Control

signal layout_changed(extent: Vector2)

var panel: Control
var header: HBoxContainer
var title_label: Label
var progress_label: Label
var body_scroll: ScrollContainer
var content: Control
var footer: HBoxContainer
var keyboard_focus := false
var last_extent := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = MenuStyle.make_theme()
	MenuStyle.backdrop(self)
	panel = Control.new()
	add_child(panel)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	panel.add_child(header)
	title_label = Label.new()
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(progress_label)
	body_scroll = ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body_scroll.follow_focus = true
	var inset := StyleBoxEmpty.new()
	inset.content_margin_bottom = 4
	body_scroll.add_theme_stylebox_override("panel", inset)
	panel.add_child(body_scroll)
	body_scroll.resized.connect(_layout_content)
	body_scroll.get_v_scroll_bar().visibility_changed.connect(_schedule_layout)
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	panel.add_child(footer)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_schedule_layout)
	set_progress(0, 0)
	_layout()

func present(title: String, view: Control) -> void:
	if content != view:
		if content != null:
			body_scroll.remove_child(content)
			content.queue_free()
		content = view
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body_scroll.add_child(content)
	title_label.text = title
	body_scroll.scroll_vertical = 0
	visible = true
	_layout()
	refresh_focus()

func set_progress(current: int, total: int) -> void:
	if progress_label == null: return
	progress_label.text = "%d / %d" % [current, total]
	progress_label.visible = total > 1
	progress_label.tooltip_text = "Belohnung %d von %d" % [current, total]

func relayout() -> void:
	_layout()

func _schedule_layout() -> void:
	if not is_inside_tree(): return
	if not get_tree().process_frame.is_connected(_layout):
		get_tree().process_frame.connect(_layout, CONNECT_ONE_SHOT)

func _layout() -> void:
	if panel == null or not is_inside_tree() or get_viewport() == null: return
	var factor := MenuLayout.ui_scale(get_viewport())
	var safe := HUDLayout.safe_rect(size)
	var bounds := MenuLayout.stage(Rect2(safe.position / factor, safe.size / factor), Vector2(1400, 950))
	panel.position = bounds.position * factor
	panel.scale = Vector2.ONE * factor
	panel.size = bounds.size
	var compact := bounds.size.x < 600 or bounds.size.y < 480
	title_label.add_theme_font_size_override("font_size", 26 if compact else 34)
	header.position = Vector2.ZERO
	header.size = Vector2(bounds.size.x, 48)
	footer.position = Vector2(0, bounds.size.y - 48)
	footer.size = Vector2(bounds.size.x, 48)
	body_scroll.position = Vector2(0, 64)
	body_scroll.size = Vector2(bounds.size.x, maxf(48, bounds.size.y - 128))
	_layout_content()
	refresh_focus()

func _layout_content() -> void:
	if content == null or not is_inside_tree(): return
	var extent := body_scroll.size - body_scroll.get_theme_stylebox("panel").get_minimum_size()
	if body_scroll.get_v_scroll_bar().visible:
		extent.x -= body_scroll.get_v_scroll_bar().get_combined_minimum_size().x
	if content.has_method("layout_in"): content.call("layout_in", extent)
	if not extent.is_equal_approx(last_extent):
		last_extent = extent
		layout_changed.emit(extent)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	var using_keyboard := event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		using_keyboard = false
	elif not using_keyboard:
		return
	if using_keyboard == keyboard_focus: return
	keyboard_focus = using_keyboard
	refresh_focus()

func refresh_focus() -> void:
	_style_focus(panel)

func _style_focus(node: Node) -> void:
	if node is Button:
		MenuStyle.focus(node, keyboard_focus)
		if node is RunSetupChoice:
			node.keyboard_focus = keyboard_focus
			node.refresh()
	for child in node.get_children(): _style_focus(child)
