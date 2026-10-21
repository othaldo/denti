class_name RunSetupValue
extends Button

# Keep the painted icon and its value together; Button's centered icon mode
# overlays its text instead of centering the two as a group.
var image: TextureRect
var value_label: Label
var value: String:
	get: return value_label.text
	set(text): value_label.text = text

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(row)
	image = TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(image)
	value_label = Label.new()
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_label)

func set_presentation(texture: Texture2D, font_size: int, icon_size: int) -> void:
	image.texture = texture
	image.custom_minimum_size = Vector2.ONE * icon_size
	value_label.add_theme_font_size_override("font_size", font_size)

func _draw() -> void:
	if value_label == null: return
	value_label.modulate.a = 0.35 if disabled else 1.0
	image.modulate.a = 0.35 if disabled else 1.0
