class_name Dentipedia
extends Control

var session: Node
var category_index := 0
var category_buttons: Array[Button] = []
var category_grid: GridContainer
var search: LineEdit
var listing: VBoxContainer
var detail: VBoxContainer
var split: HBoxContainer
var list_scroll: ScrollContainer
var detail_scroll: ScrollContainer
var entries: Array[Dictionary] = []
var selected: Dictionary = {}
var available := Vector2.ZERO
var detail_open := false
var portrait := false
var hero_art: TextureRect
var hero_title: Label
var category_focus: Dictionary = {}

func controller_shortcuts() -> Dictionary:
	var actions := {}
	if category_index > 0: actions[&"ui_previous"] = "Voriger Tab"
	if category_index < category_buttons.size() - 1: actions[&"ui_next"] = "Nächster Tab"
	return actions

func _controller_scope_active() -> bool:
	if not ControllerFocus.visible(self): return false
	var navigation: ControllerNavigation = get_node("/root/GameInput").navigation
	if navigation.popup_open(): return false
	var scope := navigation.top_scope()
	return not scope.is_empty() and ControllerFocus.contains(scope.scope.get_ref(), self)

func _unhandled_input(event: InputEvent) -> void:
	if not _controller_scope_active(): return
	if not (event.is_action_pressed("ui_previous") or event.is_action_pressed("ui_next")): return
	var direction := -1 if event.is_action_pressed("ui_previous") else 1
	var next := clampi(category_index + direction, 0, category_buttons.size() - 1)
	get_viewport().set_input_as_handled()
	if next == category_index: return
	var focus := get_viewport().gui_get_focus_owner()
	var on_tabs := focus in category_buttons
	var on_search := focus == search
	if focus != null and focus.has_meta("entry"):
		category_focus[category_index] = str(focus.get_meta("entry").title)
	elif not selected.is_empty(): category_focus[category_index] = str(selected.title)
	select_category(next)
	_restore_category_focus.call_deferred(next, on_tabs, on_search)

func _restore_category_focus(goal: int, on_tabs: bool, on_search: bool) -> void:
	if category_index != goal or not _controller_scope_active(): return
	var target: Control = category_buttons[category_index]
	if on_search:
		target = search
	elif not on_tabs and listing.get_child_count() > 0:
		target = listing.get_child(0)
		for button: Button in listing.get_children():
			if str(button.get_meta("entry").title) == str(category_focus.get(category_index, "")):
				target = button
				break
		_show(target.get_meta("entry"), false)
	target.grab_focus()
	ControllerFocus.reveal(target)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	session = get_node("/root/GameSession")
	category_grid = GridContainer.new()
	category_grid.columns = 6
	category_grid.add_theme_constant_override("h_separation", 4)
	category_grid.add_theme_constant_override("v_separation", 4)
	add_child(category_grid)
	var group := ButtonGroup.new()
	for index in DentipediaData.CATEGORIES.size():
		var button := Button.new()
		button.text = DentipediaData.CATEGORIES[index]
		button.tooltip_text = button.text
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 48
		_tab_style(button)
		button.pressed.connect(select_category.bind(index))
		category_grid.add_child(button)
		category_buttons.append(button)
		DentiUIMotion.bind_action(button)
	search = LineEdit.new()
	search.placeholder_text = "Suchen …"
	search.clear_button_enabled = true
	search.custom_minimum_size.y = 48
	search.add_theme_font_size_override("font_size", 16)
	var field := MenuStyle.box(Color(DentiUIStyle.PANEL, 0.5), DentiUIStyle.LINE, 8, 0)
	field.border_width_bottom = 1
	field.content_margin_left = 14
	field.content_margin_right = 14
	search.add_theme_stylebox_override("normal", field)
	var focused := field.duplicate() as StyleBoxFlat
	focused.border_color = DentiUIStyle.GOLD
	focused.border_width_bottom = 2
	search.add_theme_stylebox_override("focus", focused)
	add_child(search)
	split = HBoxContainer.new()
	split.add_theme_constant_override("separation", 32)
	add_child(split)
	list_scroll = _scroll(split)
	listing = VBoxContainer.new()
	listing.mouse_filter = Control.MOUSE_FILTER_PASS
	listing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listing.add_theme_constant_override("separation", 4)
	list_scroll.add_child(listing)
	detail_scroll = _scroll(split)
	detail = VBoxContainer.new()
	detail.mouse_filter = Control.MOUSE_FILTER_PASS
	detail.add_theme_constant_override("separation", 18)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail)
	search.text_changed.connect(func(_query: String) -> void:
		detail_open = false
		_refresh())
	resized.connect(_layout)
	_refresh()
	call_deferred("_layout")

func _tab_style(button: Button) -> void:
	MenuStyle.action(button, false, true)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var active: bool = state in ["pressed", "hover_pressed"]
		var fill := Color(DentiUIStyle.GOLD, 0.06) if active else Color.TRANSPARENT
		var style := MenuStyle.box(fill, DentiUIStyle.GOLD if active else Color.TRANSPARENT, 0, 0)
		style.border_width_bottom = 2 if active else 0
		style.content_margin_left = 8
		style.content_margin_right = 8
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	button.add_theme_color_override("font_pressed_color", DentiUIStyle.GOLD)
	button.add_theme_color_override("font_hover_pressed_color", DentiUIStyle.GOLD)
	MenuStyle.focus(button, get_node("/root/GameInput").navigation_active)

func _scroll(parent: Node) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	return scroll

func _layout() -> void:
	if is_inside_tree(): layout_in(size)

func layout_in(extent: Vector2) -> void:
	if category_grid == null or extent.x < 1 or extent.y < 1: return
	available = extent
	portrait = extent.x < 620 and extent.y > extent.x
	var compact := extent.x < 760 or extent.y < 330
	var inline_search := extent.x >= 900 or not portrait and extent.x >= 530
	category_grid.columns = 3 if portrait else 6
	for index in category_buttons.size():
		var button := category_buttons[index]
		button.text = "Effekte" if compact and index == 5 else ("Mechanik" if compact and index == 4 else DentipediaData.CATEGORIES[index])
		button.add_theme_font_size_override("font_size", 13 if compact else 17)
		button.custom_minimum_size.x = 0
	var category_height := 100.0 if portrait else 48.0
	var category_width := extent.x - (160 if compact else 260) - 16 if inline_search else extent.x
	category_grid.position = Vector2.ZERO
	category_grid.size = Vector2(category_width, category_height)
	var top := category_height + 14
	if inline_search:
		search.position = Vector2(category_width + 16, 0)
		search.size = Vector2(extent.x - category_width - 16, 48)
	else:
		search.position = Vector2(0, top)
		search.size = Vector2(extent.x, 48)
		top += 62
	split.position = Vector2(0, top)
	split.size = Vector2(extent.x, maxf(48, extent.y - top))
	split.add_theme_constant_override("separation", 16 if compact else 32)
	list_scroll.visible = not portrait or not detail_open
	detail_scroll.visible = not portrait or detail_open
	detail_scroll.focus_mode = Control.FOCUS_ALL if portrait and detail_open else Control.FOCUS_NONE
	detail_scroll.set_meta("controller_info_only", true)
	list_scroll.custom_minimum_size.x = 0 if portrait else minf(320, extent.x * 0.36)
	list_scroll.size_flags_stretch_ratio = 0.36
	detail_scroll.size_flags_stretch_ratio = 0.64
	for button: Button in listing.get_children():
		button.add_theme_font_size_override("font_size", 16 if compact else 18)
		var label: Label = button.get_meta("title_label")
		label.add_theme_font_size_override("font_size", 16 if compact else 18)
		button.custom_minimum_size.y = 56 if compact else 64
	if is_instance_valid(hero_art):
		var art_size := 64 if extent.y < 300 or portrait and extent.x < 340 else (88 if portrait else 144)
		hero_art.custom_minimum_size = Vector2(art_size, art_size)
	if is_instance_valid(hero_title): hero_title.add_theme_font_size_override("font_size", 23 if compact else 32)
	custom_minimum_size.y = extent.y

func select_category(index: int) -> void:
	category_index = clampi(index, 0, DentipediaData.CATEGORIES.size() - 1)
	selected = {}
	detail_open = false
	list_scroll.scroll_vertical = 0
	_refresh()

func go_back() -> bool:
	if not portrait or not detail_open: return false
	detail_open = false
	_layout()
	for button: Button in listing.get_children():
		if button.get_meta("entry") == selected:
			button.grab_focus()
			ControllerFocus.reveal(button)
			break
	return true

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _row_style(button: Button, entry: Dictionary) -> void:
	MenuStyle.action(button, false, true)
	var accent := DentiRarity.color_for(int(entry.rarity_tier)) if entry.has("rarity_tier") else Color.TRANSPARENT
	if entry.get("evolved", false): accent = WeaponPresentation.EVOLUTION_COLOR
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var active: bool = state in ["pressed", "hover_pressed"]
		var fill := DentiUIStyle.PANEL.lerp(DentiUIStyle.GOLD, 0.08) if active else Color(DentiUIStyle.PANEL, 0.35 if state == "normal" else 0.85)
		var edge := accent if accent.a > 0 else (DentiUIStyle.GOLD if active else Color.TRANSPARENT)
		var style := MenuStyle.box(fill, edge, 8, 0)
		style.border_width_left = 3 if edge.a > 0 else 0
		style.content_margin_left = 14
		style.content_margin_right = 14
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_pressed_color", DentiUIStyle.GOLD)
	MenuStyle.focus(button, get_node("/root/GameInput").navigation_active)

func _refresh() -> void:
	_clear(listing)
	var group := ButtonGroup.new()
	entries = DentipediaData.entries(category_index, session.discovered_fusions)
	for index in category_buttons.size(): category_buttons[index].set_pressed_no_signal(index == category_index)
	var query := search.text.strip_edges().to_lower()
	var first: Dictionary = {}
	var retained: Dictionary = {}
	for entry in entries:
		if not query.is_empty() and not (str(entry.title) + " " + str(entry.body)).to_lower().contains(query): continue
		if first.is_empty(): first = entry
		if entry == selected: retained = entry
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.tooltip_text = entry.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.custom_minimum_size.y = 64
		_row_style(button, entry)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = group
		button.set_meta("entry", entry)
		DentiUIMotion.bind_action(button)
		listing.add_child(button)
		_entry_content(button, entry)
		button.pressed.connect(_show.bind(entry))
		ControllerFocus.tag(button, "dentipedia:%d:%s" % [category_index, entry.title])
		button.set_meta("controller_info_only", true)
		button.set_meta("controller_details", func() -> void: button.pressed.emit())
	_show(first if retained.is_empty() else retained, false)
	_layout()

func _entry_content(button: Button, entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.offset_top = 8
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 12)
	button.add_child(row)
	if entry.has("icon"): _image(row, entry.icon, entry.get("locked", false), 40)
	var label := Label.new()
	label.text = entry.title
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)
	button.set_meta("title_label", label)

func _image(parent: Node, texture: Texture2D, locked: bool, extent: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.size = icon.custom_minimum_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked:
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment() { vec4 tex = texture(TEXTURE, UV); COLOR = vec4(0.0, 0.0, 0.0, tex.a * COLOR.a); }"
		var material := ShaderMaterial.new()
		material.shader = shader
		icon.material = material
	parent.add_child(icon)
	return icon

func _show(entry: Dictionary, open_detail: bool = true) -> void:
	_clear(detail)
	hero_art = null
	hero_title = null
	if open_detail: detail_open = true
	detail_scroll.scroll_vertical = 0
	selected = entry
	for button in listing.get_children():
		button.set_pressed_no_signal(button.get_meta("entry") == entry)
		var label: Label = button.get_meta("title_label")
		label.add_theme_color_override("font_color", DentiUIStyle.GOLD if button.button_pressed else DentiUIStyle.INK)
	if entry.is_empty():
		DentiUIComponents.label(detail, "Keine Einträge gefunden", 17)
		return
	var header := HBoxContainer.new()
	detail.add_child(header)
	var compact := size.y < 300 or size.x < 620
	var art: TextureRect
	if entry.has("icon"):
		art = _image(header, entry.icon, entry.get("locked", false), 64 if compact else 144)
	var title := DentiUIComponents.label(header, entry.title, 23 if compact else 32)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_art = art
	hero_title = title
	if entry.get("evolved", false):
		title.add_theme_color_override("font_color", WeaponPresentation.EVOLUTION_COLOR)
	if entry.has("weapon_data"):
		_forms(entry.weapon_data, art, title)
	if entry.has("rarity_tier"):
		var rarity := DentiUIComponents.label(detail, str(entry.get("rarity_caption", DentiRarity.name_for(int(entry.rarity_tier)))), 13)
		DentiUIStyle.style_affix_rarity_label(rarity, int(entry.rarity_tier))
	if entry.has("weapon_data"):
		DentipediaWeaponDetails.build(detail, entry.weapon_data, entry.body)
	else:
		DentiUIComponents.label(detail, entry.body, 17)
	_layout()
	if open_detail and portrait: _focus_detail.call_deferred()
	if entry.has("recipe"):
		DentiUIComponents.label(detail, "Fusion", 20)
		var ingredients := HFlowContainer.new()
		ingredients.add_theme_constant_override("h_separation", 8)
		detail.add_child(ingredients)
		for ingredient in DentipediaData.ingredients(entry.recipe):
			if ingredients.get_child_count() > 0:
				DentiUIComponents.label(ingredients, "+", 20)
			var cell := VBoxContainer.new()
			cell.custom_minimum_size.x = 115
			ingredients.add_child(cell)
			_image(cell, ingredient.icon, false, 52)
			DentiUIComponents.label(cell, ingredient.title, 14).custom_minimum_size.x = 115
		DentiUIComponents.label(detail, "→ " + str(entry.title) + "\nItems bleiben erhalten; die beteiligten Waffen werden ersetzt.", 16)


func _focus_detail() -> void:
	if portrait and detail_open and ControllerFocus.available(detail_scroll): detail_scroll.grab_focus()

func _forms(data: WeaponData, art: TextureRect, title: Label) -> void:
	if data.element_skins.is_empty(): return
	var forms := HFlowContainer.new()
	forms.add_theme_constant_override("h_separation", 4)
	forms.add_theme_constant_override("v_separation", 4)
	detail.add_child(forms)
	var group := ButtonGroup.new()
	var elements: Array[StringName] = [&""]
	elements.append_array(WeaponElementVisuals.ELEMENTS)
	for element in elements:
		var button := Button.new()
		_tab_style(button)
		button.add_theme_font_size_override("font_size", 14)
		button.custom_minimum_size = Vector2(48, 48)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.toggle_mode = true
		button.button_group = group
		button.set_meta("element", element)
		button.set_pressed_no_signal(element == &"")
		var name := "Normal" if element == &"" else WeaponAffixes.by_id(element).display_name
		button.text = "Normal" if element == &"" else ""
		button.icon = null if element == &"" else DentiUIIcons.item(WeaponAffixes.by_id(element).icon_index)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 20)
		button.tooltip_text = name + "form ansehen · Basiswerte bleiben gleich"
		forms.add_child(button)
		button.pressed.connect(func() -> void:
			art.texture = WeaponSkins.with_element(data, element).sprite
			title.text = data.display_name + ("" if element == &"" else " · " + name)
		)
