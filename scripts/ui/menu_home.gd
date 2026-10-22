class_name MenuHome
extends Control

signal action_requested(id: StringName)

var logo: TextureRect
var hero: TextureRect
var column: VBoxContainer
var context: Label
var primary_button: Button
var main_actions: BoxContainer
var secondary: HBoxContainer
var utilities: GridContainer
var extra: HBoxContainer
var actions: Dictionary = {}
var paused_view := false
var available := Vector2.ZERO
var layout_queued := false

func _ready() -> void:
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	column.minimum_size_changed.connect(_schedule_layout)
	logo = TextureRect.new()
	logo.texture = preload("res://assets/story/title.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(logo)
	context = Label.new()
	context.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	context.add_theme_font_size_override("font_size", 16)
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(context)
	hero = TextureRect.new()
	hero.texture = preload("res://assets/denti/denti_unarmed.png")
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero)
	resized.connect(func() -> void:
		if available != Vector2.ZERO: layout_in(available))

func _schedule_layout() -> void:
	if layout_queued: return
	layout_queued = true
	call_deferred("_relayout")

func _relayout() -> void:
	layout_queued = false
	if available != Vector2.ZERO: layout_in(available)

func configure(is_pause: bool, can_continue: bool, run_context: String, code_unlocked: bool, test_run: bool = false) -> void:
	paused_view = is_pause
	context.text = run_context
	context.visible = not run_context.is_empty()
	logo.visible = not is_pause
	if is_pause:
		var title := Label.new()
		title.text = "Zahnpause"
		title.add_theme_font_size_override("font_size", 38)
		column.add_child(title)
		column.move_child(title, 0)
	main_actions = BoxContainer.new()
	main_actions.vertical = true
	main_actions.add_theme_constant_override("separation", 12)
	column.add_child(main_actions)
	primary_button = _action(&"continue" if can_continue else &"new_run", "Fortsetzen" if can_continue else "Neuer Run", main_actions, true)
	primary_button.custom_minimum_size.y = 56
	secondary = HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 12)
	main_actions.add_child(secondary)
	if is_pause:
		_action(&"build", "Mein Build", secondary)
		_action(&"settings", "Einstellungen", secondary)
	else:
		if can_continue: _action(&"new_run", "Neuer Run", secondary)
		_action(&"story", "Story-Modus", secondary)
	utilities = GridContainer.new()
	utilities.add_theme_constant_override("h_separation", 8)
	utilities.add_theme_constant_override("v_separation", 4)
	column.add_child(utilities)
	if not is_pause: _action(&"settings", "Einstellungen", utilities, false, true)
	_action(&"dentipedia", "Dentipedia", utilities, false, true)
	if not is_pause: _action(&"credits", "Credits", utilities, false, true)
	if test_run: _action(&"test_restart", "Test neu starten", utilities, false, true)
	extra = HBoxContainer.new()
	extra.add_theme_constant_override("separation", 12)
	column.add_child(extra)
	if code_unlocked and not is_pause: _action(&"code", "Code eingeben", extra, false, true)
	if not is_pause and not OS.has_feature("web"):
		_action(&"quit", "Beenden", extra, false, true)
	elif is_pause:
		_action(&"main_menu", "Hauptmenü", extra, false, true)

func _action(id: StringName, text: String, parent: Container, primary: bool = false, quiet_action: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuStyle.action(button, primary, quiet_action)
	parent.add_child(button)
	button.pressed.connect(func() -> void: action_requested.emit(id))
	actions[id] = button
	return button

func layout_in(extent: Vector2) -> void:
	if utilities == null: return
	available = extent
	var wide := extent.x >= 760
	var short_view := extent.y < 400
	var left_width := minf(440, extent.x * 0.43) if wide else minf(420, extent.x)
	if short_view: left_width = minf(600, extent.x)
	main_actions.vertical = not short_view
	secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secondary.size_flags_stretch_ratio = float(maxi(1, secondary.get_child_count()))
	utilities.columns = 3 if wide or extent.x >= 480 else 2
	if paused_view: utilities.columns = 1 if not wide else 2
	logo.custom_minimum_size.y = 150 if wide else (56 if short_view else 112)
	column.add_theme_constant_override("separation", 6 if short_view else 12)
	for button: Button in actions.values():
		button.add_theme_font_size_override("font_size", 16 if extent.x < 600 else 18)
	column.size.x = left_width
	var height := column.get_combined_minimum_size().y
	column.size = Vector2(left_width, height)
	var minimum_height := height
	var total_height := maxf(extent.y, height)
	var top := maxf(0, (total_height - height) * 0.5)
	column.position = Vector2(extent.x * 0.05 if wide else (extent.x - left_width) * 0.5, top)
	var tall_portrait := not wide and extent.y >= 650 and extent.x >= 380
	hero.visible = (wide and not short_view) or tall_portrait
	if tall_portrait:
		var side := minf(220, minf(extent.x * 0.42, extent.y * 0.25))
		var group_height := height + side + 24
		minimum_height = group_height
		var group_top := maxf(0, (extent.y - group_height) * 0.5)
		hero.size = Vector2.ONE * side
		hero.position = Vector2((extent.x - side) * 0.5, group_top)
		column.position = Vector2((extent.x - left_width) * 0.5, group_top + side + 24)
	elif hero.visible:
		var side := minf(470, minf(extent.x * 0.43, extent.y * 0.86))
		hero.size = Vector2.ONE * side
		hero.position = Vector2(extent.x * 0.73 - side * 0.5, (total_height - side) * 0.5)
	custom_minimum_size.y = minimum_height
