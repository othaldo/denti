class_name ClassSelection
extends Control

signal selected(id: StringName)
signal details_requested(title: String, text: String)
var selected_id: StringName = ClassCatalog.DEFAULT.id
var buttons: Array[Button] = []
var grid: GridContainer
var scroll: ScrollContainer

func _ready() -> void:
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	for profile in ClassCatalog.profiles:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 230)
		button.tooltip_text = profile.description
		button.set_meta("controller_details", func() -> void: details_requested.emit(profile.display_name, profile.description))
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 18
		content.offset_right = -18
		content.offset_top = 10
		content.offset_bottom = -12
		var art := TextureRect.new()
		art.texture = preload("res://assets/classes/assassin_portrait.png") if profile.id == &"assassin" else preload("res://assets/denti/denti_unarmed.png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size.y = 125
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(art)
		var title := Label.new()
		title.text = profile.display_name
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 23)
		content.add_child(title)
		var summary := Label.new()
		summary.text = "4 Wurzeln · Kontaktwaffen\nAntritt nach Dash" if profile.id == &"assassin" else "6 Wurzeln · freie Waffenwahl\nFlexible Entwicklung"
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.add_theme_font_size_override("font_size", 15)
		content.add_child(summary)
		button.pressed.connect(func() -> void:
			selected_id = profile.id
			refresh()
			scroll.ensure_control_visible(button)
			selected.emit(profile.id))
		buttons.append(button)
		grid.add_child(button)
	resized.connect(_layout)
	_layout()
	refresh()

func _layout() -> void:
	if grid != null: grid.columns = 2 if size.x >= 580 else 1

func refresh() -> void:
	for index in buttons.size():
		var chosen := ClassCatalog.profiles[index].id == selected_id
		RunSetupStyle.choice(buttons[index], chosen, get_node("/root/GameInput").navigation_active)
		buttons[index].set_meta("controller_action_label", ClassCatalog.profiles[index].display_name)

func focus_selection() -> void:
	if not is_inside_tree() or not is_visible_in_tree() or is_queued_for_deletion(): return
	for index in buttons.size():
		if ClassCatalog.profiles[index].id == selected_id and buttons[index].is_inside_tree(): buttons[index].grab_focus()
