class_name Dentipedia
extends VBoxContainer

var session: Node
var category: OptionButton
var search: LineEdit
var listing: VBoxContainer
var detail: VBoxContainer
var split: BoxContainer
var list_scroll: ScrollContainer
var entries: Array[Dictionary] = []
var selected: Dictionary = {}

func _ready() -> void:
	session = get_node("/root/GameSession")
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tools := HBoxContainer.new()
	add_child(tools)
	category = OptionButton.new()
	category.custom_minimum_size.y = 42
	for title in DentipediaData.CATEGORIES:
		category.add_item(title)
	tools.add_child(category)
	search = LineEdit.new()
	search.placeholder_text = "Suchen …"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(search)
	split = BoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	list_scroll = _scroll(split)
	listing = VBoxContainer.new()
	listing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(listing)
	var detail_scroll := _scroll(split)
	detail = VBoxContainer.new()
	detail.add_theme_constant_override("separation", 10)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail)
	category.item_selected.connect(func(_index: int) -> void: _refresh())
	search.text_changed.connect(func(_query: String) -> void: _refresh())
	resized.connect(_layout)
	_refresh()
	call_deferred("_layout")

func _scroll(parent: Node) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	return scroll

func _layout() -> void:
	split.vertical = size.x < 620 and get_viewport_rect().size.y >= 420
	list_scroll.custom_minimum_size = Vector2(0 if split.vertical else (160 if size.x < 620 else 210), 115 if split.vertical else 0)
	list_scroll.size_flags_stretch_ratio = 0.55 if split.vertical else 0.65

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _refresh() -> void:
	_clear(listing)
	var group := ButtonGroup.new()
	entries = DentipediaData.entries(category.selected, session.discovered_fusions)
	var query := search.text.strip_edges().to_lower()
	var first: Dictionary = {}
	for entry in entries:
		if not query.is_empty() and not (str(entry.title) + " " + str(entry.body)).to_lower().contains(query):
			continue
		if first.is_empty():
			first = entry
		var button := Button.new()
		button.text = entry.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.custom_minimum_size.y = 48
		DentiUIStyle.style_button(button, false, true)
		button.toggle_mode = true
		button.button_group = group
		button.set_meta("entry", entry)
		DentiUIMotion.bind_action(button)
		listing.add_child(button)
		if entry.has("icon"):
			button.add_theme_constant_override("h_separation", 8)
			button.icon = entry.icon
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 36)
			if entry.get("locked", false):
				# Use a shader on a separate image: only the alpha silhouette survives.
				button.icon = null
				button.text = "      " + str(entry.title)
				var silhouette := _image(button, entry.icon, true, 36)
				silhouette.position = Vector2(8, 6)
		button.pressed.connect(_show.bind(entry))
	_show(first)

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

func _show(entry: Dictionary) -> void:
	_clear(detail)
	selected = entry
	for button in listing.get_children():
		button.set_pressed_no_signal(button.get_meta("entry") == entry)
	if entry.is_empty():
		ShopDetails._label(detail, "Keine Einträge gefunden", 17)
		return
	var header := HBoxContainer.new()
	detail.add_child(header)
	var compact := get_viewport_rect().size.y < 420
	if entry.has("icon"):
		_image(header, entry.icon, entry.get("locked", false), 40 if compact else 80)
	ShopDetails._label(header, entry.title, 18 if compact else 22).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ShopDetails._label(detail, entry.body, 16)
	if entry.has("recipe"):
		ShopDetails._label(detail, "Fusion", 20)
		var ingredients := HFlowContainer.new()
		ingredients.add_theme_constant_override("h_separation", 8)
		detail.add_child(ingredients)
		for ingredient in DentipediaData.ingredients(entry.recipe):
			if ingredients.get_child_count() > 0:
				ShopDetails._label(ingredients, "+", 20)
			var cell := VBoxContainer.new()
			cell.custom_minimum_size.x = 115
			ingredients.add_child(cell)
			_image(cell, ingredient.icon, false, 52)
			ShopDetails._label(cell, ingredient.title, 14).custom_minimum_size.x = 115
		ShopDetails._label(detail, "→ " + str(entry.title) + "\nItems bleiben erhalten; die beteiligten Waffen werden ersetzt.", 16)
