class_name DebugCheatMenu
extends CanvasLayer

const STAT_FIELDS := [
	["health", "Leben", 1.0, 100000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.MAX_HEALTH], "", 1.0, 100000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.DAMAGE], "", -1000.0, 10000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.MELEE_DAMAGE], "", -1000.0, 10000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.RANGED_DAMAGE], "", -1000.0, 10000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.ARMOR], "", -1000.0, 10000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.ATTACK_SPEED], "", -1000.0, 10000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.MOVEMENT], "", -100.0, 1000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.REGEN], "", -100.0, 1000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.CRIT_CHANCE], "", 0.0, 65.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.LUCK], "", 0.0, 10000.0, 1.0],
	[DentiAttributes.KEYS[DentiAttributes.Type.DODGE], "", -100.0, 200.0, 1.0],
	["shield_charges", "Schild", 0.0, 5.0, 1.0],
]

var controls: DebugRunControls
var was_paused := false
var root_control: Control
var panel: PanelContainer
var weapon_select: OptionButton
var tier_select: SpinBox
var equipped_rows: VBoxContainer
var add_weapon_button: Button
var item_select: OptionButton
var item_copies: SpinBox
var item_detail: Label
var item_list: Array[ShopOfferData] = []
var owned_rows: VBoxContainer
var coin_amount: SpinBox
var wave_number: SpinBox
var wave_button: Button
var status: Label
var stats: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	if not DebugRunControls.allowed():
		set_process_input(false)
		return
	controls = DebugRunControls.new(get_parent() as Node2D)
	_build_ui()
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		get_viewport().set_input_as_handled()
		if visible:
			close_menu()
		else:
			open_menu()
	elif visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_menu()


func open_menu() -> void:
	if not DebugRunControls.allowed() or visible:
		return
	was_paused = get_tree().paused
	get_tree().paused = true
	visible = true
	status.text = ""
	refresh()


func close_menu() -> void:
	if not visible:
		return
	visible = false
	weapon_select.get_popup().hide()
	item_select.get_popup().hide()
	get_tree().paused = was_paused


func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = DentiUIStyle.make_theme()
	root_control.theme.set_stylebox("panel", "TabContainer", DentiUIStyle._box(DentiUIStyle.CREAM, DentiUIStyle.CREAM, 8, 0))
	root_control.theme.set_stylebox("tab_selected", "TabContainer", DentiUIStyle._box(DentiUIStyle.GOLD, DentiUIStyle.GOLD, 8, 1))
	root_control.theme.set_stylebox("tab_unselected", "TabContainer", DentiUIStyle._box(Color(0.93, 0.88, 0.79), DentiUIStyle.CREAM, 8, 0))
	root_control.theme.set_color("font_selected_color", "TabContainer", DentiUIStyle.INK)
	root_control.theme.set_color("font_unselected_color", "TabContainer", DentiUIStyle.MUTED)
	var input_style := DentiUIStyle._box(Color.WHITE, DentiUIStyle.MUTED, 8, 1)
	input_style.content_margin_top = 4
	input_style.content_margin_bottom = 4
	root_control.theme.set_stylebox("normal", "LineEdit", input_style)
	root_control.theme.set_color("font_color", "LineEdit", DentiUIStyle.INK)
	root_control.theme.set_color("caret_color", "LineEdit", DentiUIStyle.INK)
	add_child(root_control)
	var shade := ColorRect.new()
	shade.color = Color(0.10, 0.06, 0.12, 0.80)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(shade)
	panel = PanelContainer.new()
	DentiUIStyle.style_dialog(panel)
	root_control.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := _label("Testmenü · F4")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header, "Schließen", close_menu)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	var weapons := _tab(tabs, "Waffen")
	var row := HBoxContainer.new()
	weapons.add_child(row)
	weapon_select = OptionButton.new()
	weapon_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_select.clip_text = true
	weapon_select.fit_to_longest_item = false
	DentiUIStyle.style_button(weapon_select, false, true)
	weapon_select.add_theme_constant_override("icon_max_width", 32)
	row.add_child(weapon_select)
	for weapon in WeaponCatalog.ALL:
		weapon_select.add_icon_item(_small_icon(weapon.sprite), weapon.display_name)
	tier_select = _spin(row, 1, 4, 1, 1)
	tier_select.prefix = "Stufe "
	add_weapon_button = _button(row, "+", _add_weapon)
	weapon_select.item_selected.connect(func(_index: int) -> void: _refresh_weapon_button())
	equipped_rows = VBoxContainer.new()
	weapons.add_child(equipped_rows)
	var items := _tab(tabs, "Items")
	row = HBoxContainer.new()
	items.add_child(row)
	item_select = OptionButton.new()
	item_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_select.clip_text = true
	item_select.fit_to_longest_item = false
	DentiUIStyle.style_button(item_select, false, true)
	item_select.add_theme_constant_override("icon_max_width", 32)
	row.add_child(item_select)
	for item in ShopController.CATALOG:
		if item.weapon_data == null:
			item_list.append(item)
			item_select.add_icon_item(_small_icon(item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index)), item.display_name)
	item_copies = _spin(row, 1, 99, 1, 1)
	_button(row, "+", _add_item)
	item_detail = _label("")
	item_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	items.add_child(item_detail)
	item_select.item_selected.connect(func(_index: int) -> void: _refresh_item_detail())
	owned_rows = VBoxContainer.new()
	items.add_child(owned_rows)
	var stat_tab := _tab(tabs, "Stats")
	var grid := GridContainer.new()
	grid.columns = 2
	stat_tab.add_child(grid)
	for field in STAT_FIELDS:
		var type := DentiAttributes.from_key(StringName(field[0]))
		var label := _label(DentiAttributes.name_for(type) + (" · %" if DentiAttributes.is_percent(type) else "") if type >= 0 else str(field[1]))
		if type >= 0:
			label.tooltip_text = DentiAttributes.meaning_for(type)
		grid.add_child(label)
		stats[field[0]] = _spin(grid, field[2], field[3], field[4], 0)
	_button(stat_tab, "Übernehmen", _apply_stats)
	var run := _tab(tabs, "Run")
	row = HBoxContainer.new()
	run.add_child(row)
	row.add_child(_label("Münzen"))
	coin_amount = _spin(row, 0, 10000000, 1, 0)
	_button(row, "Setzen", func() -> void: controls.set_coins(int(coin_amount.value)); refresh())
	row = HBoxContainer.new()
	run.add_child(row)
	row.add_child(_label("Welle"))
	wave_number = _spin(row, 1, WaveController.MAX_WAVES, 1, 1)
	wave_button = _button(row, "Starten", _start_wave, true)
	_button(run, "Voll heilen", func() -> void: controls.set_stats({"health": controls.game.player.stats.max_health}); refresh())
	status = _label("")
	box.add_child(status)


func _fit_panel() -> void:
	var extent := get_viewport().get_visible_rect().size
	panel.size = Vector2(minf(760, extent.x - 32), minf(560, extent.y - 32))
	panel.position = (extent - panel.size) / 2.0


func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	return rows


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	return label


func _small_icon(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	var extent := Vector2(image.get_size())
	extent *= 32.0 / maxf(extent.x, extent.y)
	image.resize(maxi(roundi(extent.x), 1), maxi(roundi(extent.y), 1), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _button(parent: Node, text: String, callback: Callable, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	DentiUIStyle.style_button(button, accent)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _spin(parent: Node, minimum: float, maximum: float, step: float, value: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.value = value
	spin.custom_minimum_size.x = 125
	parent.add_child(spin)
	return spin


func refresh() -> void:
	var game: Node2D = controls.game
	coin_amount.value = game.coins
	wave_number.value = maxi(game.wave.current_wave, 1)
	var saved: Dictionary = game.player.stats.to_save_data()
	for key in stats:
		stats[key].value = float(saved[key]) * (100.0 if DentiAttributes.is_fraction(DentiAttributes.from_key(StringName(key))) else 1.0)
	for child in equipped_rows.get_children():
		child.free()
	var equipped: Array[WeaponInstance] = game.player.loadout.equipped()
	equipped_rows.add_child(_label("Wurzeln · %d/%d" % [game.player.loadout.used_slots(), WeaponLoadout.CAPACITY]))
	for index in equipped.size():
		var row := HBoxContainer.new()
		equipped_rows.add_child(row)
		var name_label := _label(equipped[index].data.display_name)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var spin := _spin(row, 1, 4, 1, equipped[index].tier)
		spin.value_changed.connect(func(value: float) -> void: controls.set_weapon_tier(index, int(value)))
		_button(row, "Entfernen", func() -> void: controls.remove_weapon(index); call_deferred("refresh"))
	for child in owned_rows.get_children():
		child.free()
	for item in game.items.all_items():
		var label := _label("%s ×%d" % [item["name"], item["count"]])
		label.tooltip_text = item["description"]
		owned_rows.add_child(label)
	_refresh_weapon_button()
	_refresh_item_detail()
	wave_button.disabled = equipped.is_empty()
	wave_button.tooltip_text = "Waffe auswählen" if equipped.is_empty() else ""


func _refresh_weapon_button() -> void:
	var data: WeaponData = WeaponCatalog.ALL[weapon_select.selected]
	add_weapon_button.disabled = controls.game.player.loadout.used_slots() + data.hands > WeaponLoadout.CAPACITY
	add_weapon_button.tooltip_text = "Keine freien Wurzeln" if add_weapon_button.disabled else ""


func _refresh_item_detail() -> void:
	var item := item_list[item_select.selected]
	var count: int = controls.game.items.count(item.id)
	item_detail.text = "%s\n%d%s" % [item.effect_text(), count, "/%d" % item.max_stacks if item.max_stacks > 0 else ""]


func _add_weapon() -> void:
	controls.add_weapon(WeaponCatalog.ALL[weapon_select.selected].id, int(tier_select.value))
	refresh()


func _add_item() -> void:
	var added := controls.add_item(item_list[item_select.selected].id, int(item_copies.value))
	status.text = "+%d Items" % added if added > 0 else "Stack-Limit erreicht"
	refresh()


func _apply_stats() -> void:
	var values := {}
	for key in stats:
		values[key] = stats[key].value / (100.0 if DentiAttributes.is_fraction(DentiAttributes.from_key(StringName(key))) else 1.0)
	controls.set_stats(values)
	status.text = "Stats übernommen"
	refresh()


func _start_wave() -> void:
	if controls.start_wave(int(wave_number.value)):
		was_paused = false
		close_menu()
