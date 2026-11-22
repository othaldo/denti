class_name ClassSelection
extends Control

## Class step of the run setup: class portraits as selectable tiles beside a
## preview that explains the choice (verb, facts, play style and the three
## branch skills). Skill rows open their description on request.
## The tile grid scales with the class count: few classes get large tiles in
## one column, more classes add columns and finally scroll, like the weapon
## gallery. Tiles never shrink below a comfortable touch size.

signal selected(id: StringName)
signal details_requested(title: String, text: String)

const GAP := 32.0
const TILE_MIN := 88.0
const TILE_MAX := 168.0
const TILE_SEPARATION := 12.0
## Portrait screens show at most this many tile rows before the grid scrolls.
const PORTRAIT_ROWS := 2
var selected_id: StringName = ClassCatalog.DEFAULT.id
var buttons: Array[Button] = []
var gallery_scroll: ScrollContainer
var gallery: GridContainer
var preview_scroll: ScrollContainer
var preview: VBoxContainer
var title_label: Label
var tagline_label: Label
var facts: HFlowContainer
var style_box: VBoxContainer
var skills_title: Label
var skills: HFlowContainer
var keyboard_focus := false
@onready var session: Node = get_node("/root/GameSession")

func _ready() -> void:
	gallery_scroll = ScrollContainer.new()
	gallery_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gallery_scroll.follow_focus = true
	add_child(gallery_scroll)
	gallery = GridContainer.new()
	gallery.add_theme_constant_override("h_separation", int(TILE_SEPARATION))
	gallery.add_theme_constant_override("v_separation", int(TILE_SEPARATION))
	gallery_scroll.add_child(gallery)
	for profile in ClassCatalog.profiles:
		var button := RunSetupChoice.new()
		button.tooltip_text = profile.display_name
		button.set_meta("controller_details", func() -> void: _show_class_details(profile))
		gallery.add_child(button)
		button.show_artwork(profile.portrait)
		if profile.id == ClassCatalog.NECRODENT_ID: _add_unlock_progress(button)
		button.pressed.connect(func() -> void:
			if not session.class_unlocked(profile.id):
				_show_class_details(profile)
				return
			selected_id = profile.id
			refresh()
			DentiUIMotion.reveal(preview)
			selected.emit(profile.id))
		buttons.append(button)
	preview_scroll = ScrollContainer.new()
	preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(preview_scroll)
	preview = VBoxContainer.new()
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.add_theme_constant_override("separation", 14)
	preview_scroll.add_child(preview)
	# The selected tile already shows the portrait; the preview is text and facts.
	title_label = _label(preview, 30)
	tagline_label = _label(preview, 17)
	tagline_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	facts = HFlowContainer.new()
	facts.add_theme_constant_override("h_separation", 10)
	facts.add_theme_constant_override("v_separation", 8)
	preview.add_child(facts)
	style_box = VBoxContainer.new()
	style_box.add_theme_constant_override("separation", 6)
	preview.add_child(style_box)
	skills_title = _label(preview, 18)
	skills_title.text = "Skills im Baum"
	skills = HFlowContainer.new()
	skills.add_theme_constant_override("h_separation", 10)
	skills.add_theme_constant_override("v_separation", 10)
	preview.add_child(skills)
	resized.connect(_layout)
	_layout()
	refresh()

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _add_unlock_progress(button: RunSetupChoice) -> void:
	var progress := PanelContainer.new()
	progress.name = "UnlockProgress"
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("panel", MenuStyle.box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 8, 1))
	button.add_child(progress)
	progress.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	progress.offset_left = -51.0
	progress.offset_top = -28.0
	progress.offset_right = -6.0
	progress.offset_bottom = -6.0
	var row := HBoxContainer.new()
	row.name = "ProgressRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_child(row)
	var lock := TextureRect.new()
	lock.texture = preload("res://assets/ui/setup_lock.svg")
	lock.custom_minimum_size = Vector2(12, 12)
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lock)
	var count := _label(row, 12)
	count.name = "Count"
	count.autowrap_mode = TextServer.AUTOWRAP_OFF


func profile() -> PlayerClassData:
	return ClassCatalog.by_id(selected_id) if ClassCatalog.by_id(selected_id) != null else ClassCatalog.DEFAULT

func _show_class_details(data: PlayerClassData) -> void:
	if session.class_unlocked(data.id):
		details_requested.emit(data.display_name, DentipediaData.class_body(data))
		return
	var missing: PackedStringArray = []
	for id in ClassCatalog.MASTERY_CLASSES:
		if str(id) not in session.progression_data.class_wins:
			missing.append(ClassCatalog.by_id(id).display_name)
	details_requested.emit("Die dritten Zähne", "Besiege Welle 20 auf Hard oder Hell mit jeder dieser Klassen.\n\nOffen · " + ", ".join(missing))


## Facts derived from the class data, never duplicated as free text.
static func fact_rows(data: PlayerClassData) -> Array[Dictionary]:
	var dash := data.dash_config()
	var health := 100.0 + float(data.starting_stats.get("max_health", 0.0))
	var dashes := maxi(floori(dash.capacity / maxf(dash.cost, 1.0)), 1)
	var allowed := "Kontaktwaffen" if not data.allowed_weapon_roles.is_empty() else "Alle Waffen"
	if data.exclusive_weapon_id != &"": allowed = WeaponCatalog.by_id(data.exclusive_weapon_id).display_name
	return [
		{"icon": null, "text": "%d %s" % [data.root_capacity, "Wurzel" if data.root_capacity == 1 else "Wurzeln"], "tip": "Ausrüstungsplätze für Waffen"},
		{"icon": DentiUIIcons.stat(8 if not data.allowed_weapon_roles.is_empty() else 0), "text": allowed, "tip": "Erlaubte Waffen"},
		{"icon": DentiUIIcons.stat(2), "text": "%d Schmelz" % roundi(health), "tip": "Startleben"},
		{"icon": DentiUIIcons.stat(11), "text": "%d %s" % [dashes, "Dash" if dashes == 1 else "Dashes"], "tip": "Dashes aus vollem Vorrat"},
	]

static func skill_nodes(data: PlayerClassData) -> Array[TalentNodeData]:
	var result: Array[TalentNodeData] = []
	if data.talent_tree == null: return result
	for node in data.talent_tree.nodes:
		if node.is_skill(): result.append(node)
	return result

func refresh() -> void:
	keyboard_focus = get_node("/root/GameInput").navigation_active
	for index in buttons.size():
		var choice: RunSetupChoice = buttons[index]
		var entry := ClassCatalog.profiles[index]
		var unlocked: bool = session.class_unlocked(entry.id)
		choice.selected = entry.id == selected_id
		choice.keyboard_focus = keyboard_focus
		choice.artwork.modulate.a = 1.0 if unlocked else 0.45
		var progress := choice.get_node_or_null("UnlockProgress") as Control
		if progress != null:
			progress.visible = not unlocked
			var count: Label = progress.get_node("ProgressRow/Count")
			count.text = "%d/%d" % [session.progression_data.class_wins.size(), ClassCatalog.MASTERY_CLASSES.size()]
		choice.refresh()
		choice.set_meta("controller_action_label", entry.display_name)
	var data := profile()
	title_label.text = data.display_name
	tagline_label.text = data.tagline
	_clear(facts)
	for fact in fact_rows(data):
		var chip := RunSetupValue.new()
		RunSetupStyle.quiet(chip)
		chip.tooltip_text = fact.tip
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.focus_mode = Control.FOCUS_NONE
		facts.add_child(chip)
		chip.set_presentation(fact.icon, 16, 22)
		chip.image.visible = fact.icon != null
		chip.value = fact.text
		chip.custom_minimum_size = Vector2(chip.value_label.get_minimum_size().x + (34 if fact.icon != null else 12) + 16, 40)
	_clear(style_box)
	for line in data.play_style:
		_label(style_box, 16).text = "•  " + line
	_clear(skills)
	var tree := data.talent_tree
	for node in skill_nodes(data):
		var row := Button.new()
		row.text = "%s\n%s" % [node.display_name, tree.branches[node.branch]]
		row.icon = DentiUIIcons.talent(node.icon_index)
		row.expand_icon = false
		row.add_theme_constant_override("icon_max_width", 40)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size = Vector2(196, 58)
		row.tooltip_text = node.description
		DentiUIStyle.style_button(row)
		var title := node.display_name
		var text := node.description
		row.pressed.connect(func() -> void: details_requested.emit(title, text))
		row.set_meta("controller_details", func() -> void: details_requested.emit(title, text))
		RunSetupStyle.focus(row, keyboard_focus)
		skills.add_child(row)
	skills_title.visible = skills.get_child_count() > 0
	_layout()

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

## Columns and tile size for `count` classes in an area of `width` x `height`.
## Few classes: one column of large tiles. More classes: extra columns until
## the tiles would get smaller than TILE_MIN; beyond that the grid scrolls.
static func grid_layout(count: int, width: float, height: float) -> Dictionary:
	count = maxi(count, 1)
	var columns := 1
	var cell := TILE_MAX
	while true:
		cell = minf(TILE_MAX, (width - TILE_SEPARATION * (columns - 1)) / columns)
		var rows := ceili(float(count) / columns)
		if rows * cell + (rows - 1) * TILE_SEPARATION <= height or columns >= count: break
		var next := minf(TILE_MAX, (width - TILE_SEPARATION * columns) / (columns + 1))
		if next < TILE_MIN: break
		columns += 1
	cell = maxf(cell, TILE_MIN)
	var rows := ceili(float(count) / columns)
	return {"columns": columns, "cell": cell, "width": columns * cell + (columns - 1) * TILE_SEPARATION,
		"height": rows * cell + (rows - 1) * TILE_SEPARATION}

func _layout() -> void:
	if gallery == null: return
	var extent := size
	var count := maxi(buttons.size(), 1)
	var grid: Dictionary
	if extent.y > extent.x:
		# Portrait: tiles across the top, at most PORTRAIT_ROWS rows visible.
		var columns := clampi(floori((extent.x + TILE_SEPARATION) / (TILE_MIN + TILE_SEPARATION)), 1, count)
		var cell := clampf(minf((extent.x - TILE_SEPARATION * (columns - 1)) / columns, extent.y * 0.24), TILE_MIN * 0.8, TILE_MAX)
		var rows := ceili(float(count) / columns)
		grid = {"columns": columns, "cell": cell, "width": columns * cell + (columns - 1) * TILE_SEPARATION, "height": rows * cell + (rows - 1) * TILE_SEPARATION}
		var visible_height := minf(grid.height, PORTRAIT_ROWS * cell + (PORTRAIT_ROWS - 1) * TILE_SEPARATION)
		gallery_scroll.position = Vector2((extent.x - grid.width) * 0.5, 0)
		gallery_scroll.size = Vector2(grid.width, visible_height)
		preview_scroll.position = Vector2(0, visible_height + 16)
		preview_scroll.size = Vector2(extent.x, maxf(48, extent.y - visible_height - 16))
	else:
		grid = grid_layout(count, maxf(TILE_MIN, extent.x * 0.36), extent.y)
		var visible_height := minf(grid.height, extent.y)
		var scrollbar := 14.0 if grid.height > extent.y else 0.0
		gallery_scroll.position = Vector2(0, (extent.y - visible_height) * 0.5)
		gallery_scroll.size = Vector2(grid.width + scrollbar, visible_height)
		var left: float = gallery_scroll.size.x + GAP
		preview_scroll.position = Vector2(left, 0)
		preview_scroll.size = Vector2(maxf(48, extent.x - left), extent.y)
	gallery.columns = grid.columns
	for button in buttons: button.custom_minimum_size = Vector2.ONE * float(grid.cell)
	var compact := preview_scroll.size.x < 520 or extent.y < 380
	title_label.add_theme_font_size_override("font_size", 22 if compact else 30)
	tagline_label.add_theme_font_size_override("font_size", 15 if compact else 17)

func focus_selection() -> void:
	if not is_inside_tree() or not is_visible_in_tree() or is_queued_for_deletion(): return
	for index in buttons.size():
		if ClassCatalog.profiles[index].id == selected_id and buttons[index].is_inside_tree(): buttons[index].grab_focus()
