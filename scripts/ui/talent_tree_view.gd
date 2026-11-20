class_name TalentTreeView
extends Control

## Fits the whole three-branch talent grid into the reward stage body without
## scrolling. Wide screens show all branches plus a side detail column;
## narrow screens show one branch at a time with branch tabs and details below.

signal node_pressed(id: StringName)
signal branch_selected(branch: int)
signal compact_changed(compact: bool)

const WIDE := 860.0
const HEADER := 34.0
const TABS := 48.0
const BRANCH_GAP := 28.0

var tree: TalentTreeData
var detail: Control
var buttons: Dictionary = {}
var headers: Array[Label] = []
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
		var tab := Button.new()
		tab.clip_text = true
		tab.pressed.connect(func() -> void:
			focus_branch = branch
			branch_selected.emit(branch)
			layout_in(extent))
		add_child(tab)
		tabs.append(tab)
	for node in tree.nodes:
		var button := TalentNodeButton.new()
		button.configure(node, _icon(node, upgrades))
		var id := node.id
		button.pressed.connect(func() -> void: node_pressed.emit(id))
		add_child(button)
		buttons[str(node.id)] = button

static func _icon(node: TalentNodeData, upgrades: Array[UpgradeData]) -> Texture2D:
	if node.free_attribute: return null
	if not node.is_attribute(): return DentiUIIcons.item(node.icon_index)
	var template := TalentProgression.template_for(upgrades, node.stat)
	return DentiUIIcons.stat(template.icon_index if template != null else 0)

func update_state(new_ranks: Dictionary, branch_points: Array[int], keyboard: bool) -> void:
	ranks = new_ranks
	points = branch_points
	for branch in headers.size():
		headers[branch].text = "%s · %d" % [tree.branches[branch], points[branch]]
		RunSetupStyle.choice(tabs[branch], branch == focus_branch, keyboard)
	_fit_tabs()
	queue_redraw()

## Narrow tabs drop the point count instead of clipping the branch name.
func _fit_tabs() -> void:
	for branch in tabs.size():
		var tab := tabs[branch]
		var font := tab.get_theme_font("font")
		var font_size := tab.get_theme_font_size("font_size")
		var full := headers[branch].text
		var fits := font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 20 <= tab.size.x
		tab.text = full if fits or tab.size.x <= 0 else tree.branches[branch]

func button(id: StringName) -> TalentNodeButton:
	return buttons.get(str(id)) as TalentNodeButton

func layout_in(available: Vector2) -> void:
	if tree == null or detail == null: return
	extent = available
	custom_minimum_size = Vector2.ZERO
	size = available
	compact = available.x < WIDE
	compact_changed.emit(compact)
	var area: Rect2
	var tab_height := 0.0
	if not compact:
		var side := clampf(available.x * 0.28, 280.0, 420.0)
		area = Rect2(0, 0, available.x - side - 24, available.y)
		_place_detail(Vector2(available.x - side, 0), side, available.y)
	elif available.x >= available.y * 1.35:
		# Landscape phone: one branch with tabs, details beside it.
		var side := clampf(available.x * 0.4, 200.0, 340.0)
		tab_height = 40.0
		area = Rect2(0, tab_height + 6, available.x - side - 12, available.y - tab_height - 6)
		_place_detail(Vector2(available.x - side, 0), side, available.y)
	else:
		tab_height = TABS
		detail.size = Vector2(available.x, 0)
		var wanted := detail.get_combined_minimum_size().y
		var detail_height := clampf(wanted, 120.0, available.y * 0.45)
		area = Rect2(0, tab_height + 8, available.x, maxf(available.y - tab_height - 8 - detail_height - 10, 100))
		_place_detail(Vector2(0, available.y - detail_height), available.x, detail_height)
	var shown: Array[int] = []
	if compact: shown.append(focus_branch)
	else: shown.assign([0, 1, 2])
	var row_count := 3
	for branch in shown: row_count = maxi(row_count, tree.rows(branch))
	var branch_width := (area.size.x - BRANCH_GAP * (shown.size() - 1)) / shown.size()
	var header := 0.0 if compact else HEADER
	var grid_height := area.size.y - header - 8
	cell = minf(branch_width / TalentNodeData.COLUMNS, grid_height / row_count)
	transposed = false
	if compact:
		# Short areas grow the tree to the right instead of downward.
		var sideways := minf(branch_width / row_count, grid_height / TalentNodeData.COLUMNS)
		if sideways > cell:
			cell = sideways
			transposed = true
	cell = clampf(cell, 40.0, 132.0)
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
		origins[branch] = Vector2(left + (branch_width - grid.x) * 0.5, area.position.y + header + 4 + maxf(grid_height - grid.y, 0.0) * (0.5 if transposed else 0.0))
		headers[branch].position = Vector2(left, area.position.y)
		headers[branch].size = Vector2(branch_width, HEADER)
	var tabs_width := area.size.x if compact else available.x
	var tab_width := (tabs_width - 8 * (TalentNodeData.BRANCHES - 1)) / TalentNodeData.BRANCHES
	for branch in tabs.size():
		tabs[branch].position = Vector2(branch * (tab_width + 8), 0)
		tabs[branch].size = Vector2(tab_width, maxf(tab_height, 40.0))
		tabs[branch].add_theme_font_size_override("font_size", 13 if tab_width < 140 else 16)
	_fit_tabs()
	for key in buttons:
		var node_button: TalentNodeButton = buttons[key]
		var node := node_button.node
		node_button.visible = node.branch in shown
		if not node_button.visible: continue
		var own := maxf(node_size * 0.82, minf(34.0, cell * 0.85)) if node.is_attribute() else node_size
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
