class_name TalentPanel
extends CanvasLayer

signal talent_requested(id: StringName)
signal stat_requested(id: StringName)
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
var content: VBoxContainer
var grid: GridContainer
var branches: BoxContainer
var details: VBoxContainer
var detail_title: Label
var detail_text: Label
var buy_button: Button
var undo_button: Button
var done_button: Button
var tab_buttons: Array[Button] = []
var cards: Dictionary = {}

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	stage = RewardStage.new()
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	var tabs := HBoxContainer.new()
	content.add_child(tabs)
	for kind in ["talent", "stat"]:
		var button := _button("Talente" if kind == "talent" else "Attribute")
		button.pressed.connect(func() -> void:
			tab = kind
			selected = &""
			_save_cursor()
			refresh())
		tabs.add_child(button)
		tab_buttons.append(button)
	details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	content.add_child(details)
	detail_title = _label(details, "", 22)
	detail_text = _label(details, "", 16)
	buy_button = _button("Skillen · 1 LP", true)
	details.add_child(buy_button)
	buy_button.pressed.connect(func() -> void:
		if tab == "talent": talent_requested.emit(selected)
		else: stat_requested.emit(selected))
	branches = BoxContainer.new()
	branches.add_theme_constant_override("separation", 20)
	content.add_child(branches)
	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	undo_button = _button("Rückgängig")
	undo_button.pressed.connect(undo_requested.emit)
	stage.footer.add_child(undo_button)
	done_button = _button("Übernehmen", true)
	done_button.pressed.connect(completed.emit)
	stage.footer.add_child(done_button)
	stage.layout_changed.connect(func(extent: Vector2) -> void:
		branches.vertical = extent.x < 620
		grid.columns = 2 if extent.x < 620 else 4)
	stage.present("Entwicklung", content)
	ControllerPrompt.bind(done_button, &"ui_confirm", false)
	ControllerPrompt.bind(undo_button, &"ui_undo", false)
	hide()

func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_button(button, primary)
	return button

func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func present(progress: TalentProgression, context: PlayerStats, templates: Array[UpgradeData], pending: int) -> void:
	state = progress
	stats = context
	upgrades = templates
	count = pending
	tab = str(state.cursor.get("tab", "talent"))
	selected = StringName(str(state.cursor.get("id", "")))
	show()
	refresh()
	stage.body_scroll.scroll_vertical = 0

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _select(id: StringName) -> void:
	selected = id
	_save_cursor()
	_refresh_detail()
	stage.body_scroll.scroll_vertical = 0
	buy_button.grab_focus()

func _save_cursor() -> void:
	state.cursor = {"tab": tab, "id": str(selected)}
	cursor_changed.emit()

func refresh() -> void:
	if state == null or stats == null: return
	var tree := stats.class_data.talent_tree
	stage.title_label.text = stats.class_data.display_name
	stage.progress_label.visible = true
	stage.progress_label.text = "LP · %d" % (count - state.used(tree))
	stage.progress_label.tooltip_text = "Freie Levelpunkte"
	undo_button.disabled = state.actions.is_empty()
	done_button.disabled = count <= 0 or state.used(tree) != count
	for index in tab_buttons.size(): RunSetupStyle.choice(tab_buttons[index], tab == ("talent" if index == 0 else "stat"), get_node("/root/GameInput").navigation_active)
	_clear(branches)
	_clear(grid)
	cards.clear()
	branches.visible = tab == "talent"
	grid.visible = tab == "stat"
	var ranks := state.draft_ranks()
	if tab == "talent":
		for branch in 2:
			var column := VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.add_theme_constant_override("separation", 10)
			branches.add_child(column)
			_label(column, tree.branches[branch], 21)
			for node in tree.nodes:
				if node.branch != branch: continue
				if node.parent != &"":
					var line := ColorRect.new()
					line.color = DentiUIStyle.GOLD if int(ranks.get(str(node.parent), 0)) >= node.parent_rank else DentiUIStyle.LINE
					line.custom_minimum_size = Vector2(2, 14)
					line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					column.add_child(line)
				var rank := int(ranks.get(str(node.id), 0))
				var button := _button("%s  ·  %d/%d" % [node.display_name, rank, node.max_ranks])
				button.icon = DentiUIIcons.item(node.icon_index)
				button.add_theme_constant_override("icon_max_width", 40)
				button.custom_minimum_size.y = 64
				button.clip_text = true
				button.tooltip_text = node.description
				var reason := state.reason(node.id, stats, upgrades, count)
				if not reason.is_empty() and rank == 0: button.modulate = Color(0.65, 0.65, 0.65)
				RunSetupStyle.choice(button, rank > 0, get_node("/root/GameInput").navigation_active)
				button.pressed.connect(func() -> void: _select(node.id))
				column.add_child(button)
				cards[str(node.id)] = button
	else:
		for upgrade in upgrades:
			if upgrade.stat == &"ranged_damage" and stats.class_data.allowed_weapon_roles == [&"contact"]: continue
			var choice := state.stat_choice(upgrade.stat, stats, upgrades)
			var button := _button(upgrade.display_name)
			button.add_theme_font_size_override("font_size", 14)
			button.icon = DentiUIIcons.stat(upgrade.icon_index)
			button.add_theme_constant_override("icon_max_width", 22)
			button.clip_text = true
			button.disabled = choice == null
			button.pressed.connect(func() -> void: _select(upgrade.stat))
			grid.add_child(button)
			cards[str(upgrade.stat)] = button
	_refresh_detail()
	stage.relayout()

func _refresh_detail() -> void:
	details.visible = selected != &""
	if not details.visible: return
	if tab == "talent":
		var node := stats.class_data.talent_tree.by_id(selected)
		if node == null:
			details.hide()
			return
		detail_title.text = node.display_name
		var reason := state.reason(selected, stats, upgrades, count)
		detail_text.text = node.description + ("\n" + reason if not reason.is_empty() else "")
		if reason.is_empty() and not node.stat_changes.is_empty():
			var preview := state.preview_stats(stats, upgrades)
			for key in node.stat_changes:
				detail_text.text += "\n" + DentiAttributes.upgrade_preview_text(preview, DentiAttributes.from_key(StringName(key)), float(node.stat_changes[key]))
			preview.free()
		buy_button.text = "Skillen · %d LP" % node.cost
		buy_button.disabled = not reason.is_empty()
	else:
		var choice := state.stat_choice(selected, stats, upgrades)
		var template := TalentProgression.template_for(upgrades, selected)
		if template == null:
			details.hide()
			return
		detail_title.text = template.display_name
		var preview := state.preview_stats(stats, upgrades)
		detail_text.text = (choice.effect_text() + "\n" + DentiAttributes.upgrade_preview_text(preview, DentiAttributes.from_key(choice.stat), choice.amount)) if choice != null else "Attributgrenze erreicht"
		preview.free()
		buy_button.text = "Steigern · 1 LP"
		buy_button.disabled = choice == null or state.used(stats.class_data.talent_tree) >= count

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not ControllerFocus.active(stage): return
	if event.is_action_pressed("ui_undo") and not undo_button.disabled:
		undo_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_confirm") and not done_button.disabled:
		completed.emit()
		get_viewport().set_input_as_handled()
