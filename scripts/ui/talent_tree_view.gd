class_name TalentTreeView
extends Control

## Wide screens show all branches beside the details. Narrow screens show a
## single branch and tabs. The reward stage scrolls when these cannot fit.

signal node_pressed(id: StringName)
signal node_previewed(id: StringName)
signal branch_selected(branch: int)
signal compact_changed(compact: bool)

const WIDE := 860.0
const HEADER := 34.0
const TABS := 48.0
const BRANCH_GAP := 28.0
const MIN_CELL := 40.0

var tree: TalentTreeData
var detail: Control
var buttons: Dictionary = {}
var headers: Array[Label] = []
var note_labels: Array[Label] = []
var branch_notes := PackedStringArray()
var tabs: Array[Button] = []
var focus_branch := 0
var compact := false
var points: Array[int] = [0, 0, 0]
var ranks: Dictionary = {}
var cell := 64.0
var origins: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var columns: Array[Rect2] = [Rect2(), Rect2(), Rect2()]
var extent := Vector2.ZERO
var transposed := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

func setup(new_tree: TalentTreeData, upgrades: Array[UpgradeData], detail_control: Control) -> void:
	detail = detail_control
	if detail.get_parent() != self: add_child(detail)
	if tree == new_tree: return
	tree = new_tree
	for button in buttons.values(): button.queue_free()
	buttons.clear()
	for label in headers: label.queue_free()
	headers.clear()
	for label in note_labels: label.queue_free()
	note_labels.clear()
	for tab in tabs: tab.queue_free()
	tabs.clear()
	for branch in TalentNodeData.BRANCHES:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.clip_text = true
		add_child(label)
		headers.append(label)
		var note := Label.new()
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		note.mouse_filter = Control.MOUSE_FILTER_PASS
		note.tooltip_text = "Grundwerte je Zahn"
		note.add_theme_color_override("font_color", DentiUIStyle.MUTED)
		note.add_theme_font_size_override("font_size", 13)
		note.hide()
		add_child(note)
		note_labels.append(note)
		var tab := Button.new()
		tab.clip_text = true
		ControllerFocus.tag(tab, "talent:branch:%d" % branch)
		tab.pressed.connect(func() -> void:
			focus_branch = branch
			layout_in(extent)
			branch_selected.emit(branch))
		add_child(tab)
		tabs.append(tab)
	for node in tree.nodes:
		var button := TalentNodeButton.new()
		button.configure(node, _icon(node, upgrades))
		var id := node.id
		ControllerFocus.tag(button, "talent:node:%s" % id)
		button.pressed.connect(func() -> void: node_pressed.emit(id))
		button.mouse_entered.connect(_request_preview.bind(id, false))
		button.mouse_exited.connect(_request_preview.bind(&"", false))
		button.focus_entered.connect(_request_preview.bind(id, true))
		button.focus_exited.connect(_request_preview.bind(&"", true))
		add_child(button)
		buttons[str(node.id)] = button

func _request_preview(id: StringName, focus_event: bool) -> void:
	if not is_visible_in_tree(): return
	var navigation_active: bool = get_node("/root/GameInput").navigation_active
	if focus_event == navigation_active: node_previewed.emit(id)

static func _icon(node: TalentNodeData, upgrades: Array[UpgradeData]) -> Texture2D:
	if node.free_attribute: return null
	if not node.is_attribute(): return DentiUIIcons.talent(node.icon_index)
	var template := TalentProgression.template_for(upgrades, node.stat)
	return DentiUIIcons.stat(template.icon_index if template != null else 0)

func update_state(new_ranks: Dictionary, branch_points: Array[int], keyboard: bool) -> void:
	ranks = new_ranks
	points = branch_points
	for branch in headers.size():
		headers[branch].text = "%s · %d" % [tree.branches[branch], points[branch]]
		RunSetupStyle.choice(tabs[branch], branch == focus_branch, keyboard)
	_fit_branch_titles()
	queue_redraw()

func _fit_branch_titles() -> void:
	for branch in tabs.size():
		var header := headers[branch]
		if header.visible and header.size.x > 0:
			var header_size := _fit_font_size(header.get_theme_font("font"), header.text, header.size.x - 16, 20)
			header.add_theme_font_size_override("font_size", header_size)
		var tab := tabs[branch]
		if not tab.visible or tab.size.x <= 0: continue
		var font := tab.get_theme_font("font")
		var width := tab.size.x - 12
		var preferred := 13 if tab.size.x < 140 else 16
		var fits := font.get_string_size(header.text, HORIZONTAL_ALIGNMENT_LEFT, -1, preferred).x <= width
		tab.text = header.text if fits else tree.branches[branch]
		tab.add_theme_font_size_override("font_size", _fit_font_size(font, tab.text, width, preferred))

static func _fit_font_size(font: Font, title: String, width: float, preferred: int) -> int:
	var font_size := preferred
	while font_size > 10 and font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		font_size -= 1
	return font_size

func button(id: StringName) -> TalentNodeButton:
	return buttons.get(str(id)) as TalentNodeButton

func layout_in(available: Vector2) -> void:
	if tree == null or detail == null: return
	extent = available
	compact = available.x < WIDE
	compact_changed.emit(compact)
	var shown: Array[int] = []
	if compact: shown.append(focus_branch)
	else: shown.assign([0, 1, 2])
	var row_count := 3
	for branch in shown: row_count = maxi(row_count, tree.rows(branch))
	var landscape := compact and available.x >= available.y * 1.35
	var tab_height := (40.0 if landscape else TABS) if compact else 0.0
	var tree_width := available.x
	var detail_width := available.x
	if not compact:
		detail_width = clampf(available.x * 0.28, 280.0, 420.0)
		tree_width -= detail_width + 24
	elif landscape:
		detail_width = clampf(available.x * 0.4, 200.0, 340.0)
		tree_width -= detail_width + 12
	var tab_width := (tree_width - 8 * (TalentNodeData.BRANCHES - 1)) / TalentNodeData.BRANCHES
	var wrap_notes := compact and tab_width < 144.0
	var note_height := 0.0 if branch_notes.is_empty() else (32.0 if wrap_notes else 22.0)
	var header := 0.0 if compact else HEADER + note_height
	var branch_width := (tree_width - BRANCH_GAP * (shown.size() - 1)) / shown.size()
	var can_transpose := compact and branch_width >= row_count * MIN_CELL
	var min_grid_height := (TalentNodeData.COLUMNS if can_transpose else row_count) * MIN_CELL
	var details_below := compact and not landscape
	var top := tab_height + (note_height if compact else 0.0) + (8.0 if details_below else (4.0 if landscape else 0.0))
	var detail_minimum := detail.get_combined_minimum_size().y
	var minimum_height := top + header + min_grid_height
	var detail_height := detail_minimum
	if details_below:
		detail_height = maxf(120.0, detail_height)
		minimum_height += detail_height + 10
	else:
		minimum_height = maxf(minimum_height, detail_minimum)
	custom_minimum_size = Vector2(0, minimum_height if minimum_height > available.y else 0.0)
	var height := maxf(available.y, minimum_height)
	size = Vector2(available.x, height)
	var area := Rect2(0, top, tree_width, height - top)
	if details_below:
		area.size.y -= detail_height + 10
		_place_detail(Vector2(0, height - detail_height), detail_width, detail_height)
	else:
		_place_detail(Vector2(available.x - detail_width, 0), detail_width, height)
	var grid_height := area.size.y - header - 8
	cell = minf(branch_width / TalentNodeData.COLUMNS, grid_height / row_count)
	transposed = false
	if compact:
		# Short areas grow the tree to the right instead of downward.
		var sideways := minf(branch_width / row_count, grid_height / TalentNodeData.COLUMNS)
		if sideways > cell:
			cell = sideways
			transposed = true
	cell = clampf(cell, MIN_CELL, 132.0)
	var node_size := clampf(cell * 0.72, 36.0, 92.0)
	for branch in TalentNodeData.BRANCHES:
		var visible_branch := branch in shown
		headers[branch].visible = visible_branch and not compact
		tabs[branch].visible = compact
		if not visible_branch:
			columns[branch] = Rect2()
			continue
		var index := shown.find(branch)
		var left := area.position.x + index * (branch_width + BRANCH_GAP)
		columns[branch] = Rect2(left, area.position.y, branch_width, area.size.y)
		var grid := Vector2(cell * (row_count if transposed else TalentNodeData.COLUMNS), cell * (TalentNodeData.COLUMNS if transposed else row_count))
		var spare := maxf(area.size.y - header - grid.y, 0.0)
		var leading := spare * 0.5 if transposed else minf(4.0, spare)
		origins[branch] = Vector2(left + (branch_width - grid.x) * 0.5, area.position.y + header + leading)
		headers[branch].position = Vector2(left, area.position.y)
		headers[branch].size = Vector2(branch_width, HEADER)
	for branch in tabs.size():
		tabs[branch].position = Vector2(branch * (tab_width + 8), 0)
		tabs[branch].size = Vector2(tab_width, maxf(tab_height, 40.0))
		var note := note_labels[branch]
		note.visible = branch < branch_notes.size()
		if not note.visible: continue
		note.text = branch_notes[branch].replace(" · ", "\n") if wrap_notes else branch_notes[branch]
		note.position = Vector2(tabs[branch].position.x, tab_height) if compact else headers[branch].position + Vector2(0, HEADER)
		note.size = Vector2(tab_width if compact else branch_width, note_height)
	_fit_branch_titles()
	for key in buttons:
		var node_button: TalentNodeButton = buttons[key]
		var node := node_button.node
		node_button.visible = node.branch in shown
		if not node_button.visible: continue
		var own := node_size
		if node.is_attribute(): own = maxf(node_size * 0.82, minf(34.0, cell * 0.85))
		elif node.is_skill(): own = minf(node_size * 1.22, cell * 0.96)
		elif node.is_modifier(): own = maxf(node_size * 0.82, minf(34.0, cell * 0.85))
		node_button.size = Vector2.ONE * own
		node_button.position = cell_centre(node) - Vector2.ONE * own * 0.5
	queue_redraw()

func _place_detail(at: Vector2, width: float, height: float) -> void:
	detail.position = at
	detail.size = Vector2(width, height)

## Row/column of a node in screen space. Transposed trees grow to the right.
func cell_centre(node: TalentNodeData) -> Vector2:
	var grid := Vector2(node.row, node.column) if transposed else Vector2(node.column, node.row)
	return origins[node.branch] + (grid + Vector2(0.5, 0.5)) * cell

func _draw() -> void:
	if tree == null: return
	var font := DentiUIStyle.FONT
	for branch in TalentNodeData.BRANCHES:
		var column := columns[branch]
		if column.size.x <= 0: continue
		var backdrop := StyleBoxFlat.new()
		backdrop.bg_color = Color(DentiUIStyle.PANEL, 0.55)
		backdrop.set_corner_radius_all(16)
		draw_style_box(backdrop, column)
		# WoW-style gate: one faint line where the first still-closed row begins.
		for row in tree.rows(branch):
			var needed := tree.row_requirement(row)
			if needed <= points[branch]: continue
			var font_size := 14
			if transposed:
				var x := origins[branch].x + row * cell
				draw_line(Vector2(x, column.position.y + 8), Vector2(x, column.end.y - 8), Color(DentiUIStyle.LINE, 0.9), 1.5)
				draw_string(font, Vector2(x + 4, column.position.y + 4 + font.get_ascent(font_size)), str(needed), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, DentiUIStyle.MUTED)
			else:
				var y := origins[branch].y + row * cell
				draw_line(Vector2(column.position.x + 12, y), Vector2(column.end.x - 12, y), Color(DentiUIStyle.LINE, 0.9), 1.5)
				draw_string(font, Vector2(column.position.x + 14, y + 4 + font.get_ascent(font_size)), str(needed), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, DentiUIStyle.MUTED)
			break
	var down := Vector2.RIGHT if transposed else Vector2.DOWN
	var across := Vector2.DOWN if transposed else Vector2.RIGHT
	for node in tree.nodes:
		if node.parent == &"" or columns[node.branch].size.x <= 0: continue
		var parent := tree.by_id(node.parent)
		if parent == null: continue
		var done := int(ranks.get(str(parent.id), 0)) >= node.parent_rank
		var color := DentiUIStyle.GOLD if done else DentiUIStyle.LINE
		var start := cell_centre(parent) + down * (button(parent.id).size.x * 0.5 + 2)
		var finish := cell_centre(node) - down * (button(node.id).size.x * 0.5 + 4)
		var line := PackedVector2Array([start])
		if not is_zero_approx((finish - start).dot(across)):
			var bend := cell_centre(node) - down * cell * 0.5
			line.append(start + down * (bend - start).dot(down))
			line.append(finish - down * (finish - bend).dot(down))
		line.append(finish)
		draw_polyline(line, color, 3.0, true)
		var head := 7.0
		draw_colored_polygon(PackedVector2Array([finish + down * 2, finish - down * head - across * head, finish - down * head + across * head]), color)
