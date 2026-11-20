class_name TalentPanel
extends CanvasLayer

## Post-wave level point distribution in one talent tree. Attributes are path
## nodes inside the tree; there is no separate attribute tab any more.
## Tap/click selects a node, tapping the selected node again (or the button)
## spends a point.

signal talent_requested(id: StringName, stat: StringName)
signal undo_requested
signal completed
signal cursor_changed

var state: TalentProgression
var stats: PlayerStats
var upgrades: Array[UpgradeData] = []
var count := 0
var tab := "talent"
var selected: StringName
var stage: RewardStage
var view: TalentTreeView
var details: PanelContainer
var detail_title: Label
var detail_kind: Label
var detail_text: Label
var detail_reason: Label
var buy_button: Button
var choice_row: HFlowContainer
var free_stat: StringName
var undo_button: Button
var points_badge: LevelPointsBadge
var done_button: Button

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	stage = RewardStage.new()
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view = TalentTreeView.new()
	view.node_pressed.connect(_on_node_pressed)
	view.branch_selected.connect(func(_branch: int) -> void: stage.refresh_focus())
	view.compact_changed.connect(_on_compact_changed)
	details = PanelContainer.new()
	DentiUIStyle.style_chip(details)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	details.add_child(column)
	view.add_child(details)
	detail_title = _label(column, "", 22)
	detail_kind = _label(column, "", 14)
	detail_kind.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	detail_text = _label(column, "", 16)
	detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_reason = _label(column, "", 15)
	detail_reason.add_theme_color_override("font_color", DentiUIStyle.CORAL)
	choice_row = HFlowContainer.new()
	choice_row.add_theme_constant_override("h_separation", 6)
	choice_row.add_theme_constant_override("v_separation", 6)
	column.add_child(choice_row)
	buy_button = _button("Skillen", true)
	column.add_child(buy_button)
	buy_button.pressed.connect(_buy_selected)
	undo_button = _button("Rückgängig")
	undo_button.pressed.connect(undo_requested.emit)
	stage.footer.add_child(undo_button)
	done_button = _button("Übernehmen", true)
	done_button.pressed.connect(completed.emit)
	stage.footer.add_child(done_button)
	stage.present("Entwicklung", view)
	ControllerPrompt.bind(done_button, &"ui_confirm", false)
	ControllerPrompt.bind(undo_button, &"ui_undo", false)
	hide()

func _on_compact_changed(compact: bool) -> void:
	detail_title.add_theme_font_size_override("font_size", 18 if compact else 22)
	detail_text.add_theme_font_size_override("font_size", 14 if compact else 16)
	detail_kind.visible = not compact
	buy_button.custom_minimum_size.y = 40 if compact else 48

func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_button(button, primary)
	return button

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func present(progress: TalentProgression, context: PlayerStats, templates: Array[UpgradeData], pending: int) -> void:
	state = progress
	stats = context
	upgrades = templates
	count = pending
	tab = "talent"
	selected = StringName(str(state.cursor.get("id", "")))
	view.setup(stats.class_data.talent_tree, upgrades, details)
	if stats.class_data.talent_tree.by_id(selected) == null: selected = _default_selection()
	var node := stats.class_data.talent_tree.by_id(selected)
	if node != null: view.focus_branch = node.branch
	show()
	refresh()

func _default_selection() -> StringName:
	var tree := stats.class_data.talent_tree
	for node in tree.nodes:
		if state.reason(node.id, stats, upgrades, count).is_empty(): return node.id
	return tree.nodes[0].id

func _on_node_pressed(id: StringName) -> void:
	if id == selected and state.reason(id, stats, upgrades, count).is_empty():
		_buy_selected()
		return
	_select(id)

func _buy_selected() -> void:
	var node := stats.class_data.talent_tree.by_id(selected)
	if node == null: return
	if node.free_attribute:
		var options := state.free_choices(stats, upgrades, node)
		if free_stat not in options: free_stat = options[0] if not options.is_empty() else &""
		if free_stat == &"": return
	talent_requested.emit(selected, free_stat if node.free_attribute else &"")

func _pick_free(key: StringName) -> void:
	free_stat = key
	refresh()

func _select(id: StringName) -> void:
	selected = id
	var node := stats.class_data.talent_tree.by_id(id)
	if node != null and view.compact and node.branch != view.focus_branch:
		view.focus_branch = node.branch
		view.layout_in(view.extent)
	_save_cursor()
	refresh()
	var focused := view.button(id)
	if focused != null and focused.visible: focused.grab_focus()

func _save_cursor() -> void:
	state.cursor = {"tab": "talent", "id": str(selected)}
	cursor_changed.emit()

func node_state(node: TalentNodeData, ranks: Dictionary) -> TalentNodeButton.State:
	var rank := int(ranks.get(str(node.id), 0))
	if rank >= node.max_ranks: return TalentNodeButton.State.MAXED
	if state.reason(node.id, stats, upgrades, count).is_empty(): return TalentNodeButton.State.AVAILABLE
	if rank > 0: return TalentNodeButton.State.INVESTED
	return TalentNodeButton.State.OPEN if state.structurally_open(node.id, stats.class_data.talent_tree) else TalentNodeButton.State.LOCKED

func refresh() -> void:
	if state == null or stats == null: return
	var tree := stats.class_data.talent_tree
	stage.title_label.text = stats.class_data.display_name
	stage.progress_label.visible = false
	if points_badge == null:
		points_badge = LevelPointsBadge.new()
		stage.header.add_child(points_badge)
	points_badge.count = count - state.used(tree)
	undo_button.disabled = state.actions.is_empty()
	done_button.disabled = count <= 0 or state.used(tree) != count
	var ranks := state.draft_ranks()
	var branch_points: Array[int] = []
	for branch in TalentNodeData.BRANCHES: branch_points.append(tree.branch_points(ranks, branch))
	view.update_state(ranks, branch_points, get_node("/root/GameInput").navigation_active)
	for node in tree.nodes:
		var cell := view.button(node.id)
		if node.free_attribute: cell.set_binding(_stat_icon(state.bound_stat(node.id)))
		cell.set_state(int(ranks.get(str(node.id), 0)), node_state(node, ranks), node.id == selected)
	_refresh_detail(ranks)
	stage.relayout()

func _refresh_detail(ranks: Dictionary) -> void:
	var tree := stats.class_data.talent_tree
	var node := tree.by_id(selected)
	details.visible = node != null
	if node == null: return
	var rank := int(ranks.get(str(node.id), 0))
	var reason := state.reason(selected, stats, upgrades, count)
	var preview := state.preview_stats(stats, upgrades)
	_build_choices(node)
	if node.free_attribute:
		var binding := state.bound_stat(node.id)
		var options := state.free_choices(stats, upgrades, node)
		if binding != &"": free_stat = binding
		elif free_stat not in options and not options.is_empty(): free_stat = options[0]
		var picked := state.stat_choice(free_stat, stats, upgrades) if free_stat in options else null
		var picked_template := TalentProgression.template_for(upgrades, free_stat)
		var stat_name := picked_template.display_name if picked_template != null else ""
		detail_title.text = stat_name if binding != &"" else ("Freie Wurzel · %s" % stat_name if not stat_name.is_empty() else "Freie Wurzel")
		detail_kind.text = "%s · %s · Rang %d/%d" % ["Gebundene Wurzel" if binding != &"" else "Freie Wurzel", tree.branches[node.branch], rank, node.max_ranks]
		detail_text.text = (picked.effect_text() + "\n" + DentiAttributes.upgrade_preview_text(preview, DentiAttributes.from_key(picked.stat), picked.amount)) if picked != null else ""
		if binding == &"" and free_stat != &"":
			detail_text.text += "\nDer erste Punkt bindet diese Wurzel."
		if free_stat != &"":
			var bund := state.bund_count(free_stat) + (0 if binding != &"" else 1)
			detail_text.text += "\nWurzelbund %d/%d" % [mini(bund, TalentProgression.BUND_SIZE), TalentProgression.BUND_SIZE]
	elif node.is_attribute():
		var template := TalentProgression.template_for(upgrades, node.stat)
		var choice := state.attribute_choice(node, stats, upgrades)
		detail_title.text = template.display_name if template != null else str(node.stat)
		detail_kind.text = "%s · Rang %d/%d" % [tree.branches[node.branch], rank, node.max_ranks]
		detail_text.text = (choice.effect_text() + "\n" + DentiAttributes.upgrade_preview_text(preview, DentiAttributes.from_key(choice.stat), choice.amount)) if choice != null else ""
	else:
		detail_title.text = node.display_name
		var kind_label: String = {&"skill": "Skill · ", &"modifier": "Skill-Modifikator · ", &"keystone": "Schlüsselstein · "}.get(node.kind, "")
		detail_kind.text = "%s%s · Rang %d/%d" % [kind_label, tree.branches[node.branch], rank, node.max_ranks]
		detail_text.text = node.description
		if reason.is_empty():
			for key in node.stat_changes:
				detail_text.text += "\n" + DentiAttributes.upgrade_preview_text(preview, DentiAttributes.from_key(StringName(key)), float(node.stat_changes[key]))
	preview.free()
	detail_reason.text = reason
	detail_reason.visible = not detail_reason.text.is_empty()
	buy_button.text = "Skillen" if node.cost == 1 else "Skillen · %d" % node.cost
	buy_button.disabled = not reason.is_empty()

## Free nodes: one icon per class-usable attribute; spent attributes at their cap are disabled.
func _build_choices(node: TalentNodeData) -> void:
	for child in choice_row.get_children():
		choice_row.remove_child(child)
		child.queue_free()
	choice_row.visible = node.free_attribute and state.bound_stat(node.id) == &""
	if not choice_row.visible: return
	var options := state.free_choices(stats, upgrades, node)
	var keyboard: bool = get_node("/root/GameInput").navigation_active
	for upgrade in upgrades:
		if not TalentProgression.class_allows(upgrade.stat, stats.class_data): continue
		var pick := Button.new()
		pick.icon = DentiUIIcons.stat(upgrade.icon_index)
		pick.expand_icon = true
		pick.custom_minimum_size = Vector2(40, 40)
		pick.tooltip_text = upgrade.display_name
		pick.disabled = upgrade.stat not in options
		RunSetupStyle.choice(pick, upgrade.stat == free_stat, keyboard, 10)
		var key := upgrade.stat
		pick.pressed.connect(func() -> void: _pick_free(key))
		choice_row.add_child(pick)

func _stat_icon(key: StringName) -> Texture2D:
	if key == &"": return null
	var template := TalentProgression.template_for(upgrades, key)
	return DentiUIIcons.stat(template.icon_index) if template != null else null

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not ControllerFocus.active(stage): return
	if event.is_action_pressed("ui_undo") and not undo_button.disabled:
		undo_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_confirm") and not done_button.disabled:
		completed.emit()
		get_viewport().set_input_as_handled()
