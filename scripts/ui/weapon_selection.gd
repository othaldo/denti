class_name WeaponSelection
extends Control

signal selection_changed
signal details_requested(title: String, description: String)

var options: Array[WeaponData] = []
var selected_id: StringName = &""
var icon_buttons: Array[Button] = []
var catalog_scroll: ScrollContainer
var grid: GridContainer
var preview: Control
var art: TextureRect
var weapon_name: Label
var roots_label: Label
var stat_buttons: Array[RunSetupValue] = []
var keyboard_focus := false

func _ready() -> void:
	catalog_scroll = ScrollContainer.new()
	catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	catalog_scroll.follow_focus = true
	add_child(catalog_scroll)
	grid = GridContainer.new()
	catalog_scroll.add_child(grid)
	preview = Control.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(art)
	weapon_name = _label(28)
	weapon_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	weapon_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	roots_label = _label(17)
	roots_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	for index in 3:
		var button := RunSetupValue.new()
		RunSetupStyle.quiet(button)
		preview.add_child(button)
		button.set_presentation([DentiUIIcons.stat(0), preload("res://assets/ui/reload_light.svg"), preload("res://assets/ui/range.svg")][index], 18, 24)
		stat_buttons.append(button)
		button.pressed.connect(_stat_details.bind(index))
	resized.connect(_layout)

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(label)
	return label

func show_options(weapons: Array[WeaponData], selected: StringName = &"") -> void:
	options = weapons.duplicate()
	selected_id = &""
	for button in icon_buttons:
		grid.remove_child(button)
		button.queue_free()
	icon_buttons.clear()
	for index in options.size():
		var button := RunSetupChoice.new()
		button.tooltip_text = options[index].display_name + " · " + options[index].roots_text()
		button.pressed.connect(select_weapon.bind(index))
		grid.add_child(button)
		button.show_artwork(RunSetupPresentation.weapon_icon(options[index]))
		icon_buttons.append(button)
	art.texture = preload("res://assets/denti/denti_unarmed.png")
	weapon_name.text = ""
	roots_label.text = ""
	for button in stat_buttons: button.visible = false
	catalog_scroll.scroll_vertical = 0
	for index in options.size():
		if options[index].id == selected:
			select_weapon(index, false)
			break
	_layout()

func selected_weapon() -> WeaponData:
	for weapon in options:
		if weapon.id == selected_id: return weapon
	return null

func select_weapon(index: int, notify: bool = true) -> void:
	if index < 0 or index >= options.size(): return
	var weapon := options[index]
	selected_id = weapon.id
	art.texture = RunSetupPresentation.weapon_icon(weapon)
	weapon_name.text = weapon.display_name
	roots_label.text = weapon.roots_text()
	var values := RunSetupPresentation.values(weapon)
	for stat in 3:
		stat_buttons[stat].value = values[stat]
		stat_buttons[stat].tooltip_text = ["Grundschaden", "Angriffspause", "Reichweite"][stat]
		stat_buttons[stat].visible = true
	refresh()
	_layout()
	if notify:
		DentiUIMotion.reveal(preview)
		selection_changed.emit()

func refresh() -> void:
	for index in icon_buttons.size():
		var button: RunSetupChoice = icon_buttons[index]
		button.selected = options[index].id == selected_id
		button.keyboard_focus = keyboard_focus
		button.refresh()
	for button in stat_buttons: RunSetupStyle.focus(button, keyboard_focus)

func focus_selection() -> void:
	if icon_buttons.is_empty() or not is_visible_in_tree(): return
	var index := 0
	for current in options.size():
		if options[current].id == selected_id: index = current
	icon_buttons[index].grab_focus()
	catalog_scroll.ensure_control_visible(icon_buttons[index])

func _stat_details(index: int) -> void:
	var weapon := selected_weapon()
	if weapon == null: return
	var title: String = ["Grundschaden", "Angriffspause", "Reichweite"][index]
	var text: String = ["Grundschaden auf Mk I: %d.\n%s" % [roundi(weapon.damage_at_tier(1)), weapon.combat_text()],
		"Zeit zwischen zwei Angriffen auf Mk I: %.2f Sekunden. Putzeifer verkürzt die Angriffspause." % weapon.interval_at_tier(1),
		"Zielreichweite auf Mk I: %d." % roundi(weapon.range_at_tier(1))][index]
	details_requested.emit(title, text)

func _layout() -> void:
	if preview == null: return
	var layout := RunSetupLayout.weapons(size, options.size())
	catalog_scroll.position = layout.gallery.position
	catalog_scroll.size = layout.gallery.size
	grid.columns = layout.columns
	grid.add_theme_constant_override("h_separation", layout.separation)
	grid.add_theme_constant_override("v_separation", layout.separation)
	for button in icon_buttons:
		button.custom_minimum_size = Vector2.ONE * layout.cell
	preview.position = layout.preview.position
	preview.size = layout.preview.size
	var extent := preview.size
	var compact := extent.y < 220
	var font_size := 18 if compact else 30
	if weapon_name.get_theme_font_size("font_size") != font_size:
		weapon_name.add_theme_font_size_override("font_size", font_size)
	var roots_size := 14 if compact else 17
	if roots_label.get_theme_font_size("font_size") != roots_size:
		roots_label.add_theme_font_size_override("font_size", roots_size)
	if selected_id == &"":
		art.position = Vector2.ZERO
		art.size = extent
		return
	if layout.portrait:
		var art_size := minf(extent.x * 0.26, extent.y)
		art.position = Vector2(0, (extent.y - art_size) * 0.5)
		art.size = Vector2.ONE * art_size
		var left := art_size + 10
		weapon_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_place_name(Rect2(left, 0, extent.x - left, 48), font_size)
		roots_label.position = Vector2(left, 49)
		roots_label.size = Vector2(extent.x - left, 22)
		roots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_place_stats(Rect2(left, extent.y - 48, extent.x - left, 48), 14)
	else:
		var art_size := minf(260, minf(extent.x * 0.8, extent.y * (0.28 if compact else 0.52)))
		var name_height := 42.0 if compact else 76.0
		var roots_height := 18.0 if compact else 26.0
		var height := art_size + name_height + roots_height + 52
		var top := maxf(0, (extent.y - height) * 0.5)
		art.position = Vector2((extent.x - art_size) * 0.5, top)
		art.size = Vector2.ONE * art_size
		weapon_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place_name(Rect2(0, top + art_size, extent.x, name_height), font_size)
		roots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roots_label.position = Vector2(0, weapon_name.position.y + name_height)
		roots_label.size = Vector2(extent.x, roots_height)
		_place_stats(Rect2(0, roots_label.position.y + roots_height + 4, extent.x, 48), 14 if compact else 18)

func _place_name(rect: Rect2, font_size: int) -> void:
	# Shape at the final width. Label's deferred autowrap minimum can retain
	# a narrow column's height across rotations (also in paused/headless saves).
	var paragraph := TextParagraph.new()
	paragraph.width = rect.size.x
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var text := selected_weapon().display_name
	paragraph.add_string(text, weapon_name.get_theme_font("font"), font_size)
	var lines := PackedStringArray()
	for index in paragraph.get_line_count():
		var span := paragraph.get_line_range(index)
		var line := text.substr(span.x, span.y - span.x).strip_edges()
		if not line.is_empty(): lines.append(line)
	weapon_name.text = "\n".join(lines)
	weapon_name.position = rect.position
	weapon_name.size = rect.size

func _place_stats(rect: Rect2, font_size: int) -> void:
	for index in 3:
		var button := stat_buttons[index]
		button.position = rect.position + Vector2(index * rect.size.x / 3.0, 0)
		button.size = Vector2(rect.size.x / 3.0, rect.size.y)
		button.set_presentation(button.image.texture, font_size, 18 if font_size < 16 else 26)
