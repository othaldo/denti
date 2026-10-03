class_name StoryTravelCard
extends Control

var art: TextureRect
var art_surface: Panel
var caption: Label
var mystery: Label
var active: bool = false
var frame: StyleBoxFlat
const BORDER := 2.0
const FRAME_RADIUS := 12

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	frame = DentiUIStyle._box(DentiUIStyle.BACKGROUND, DentiUIStyle.LINE, FRAME_RADIUS, int(BORDER))
	art_surface = DentiUIStyle.rounded_image_surface(FRAME_RADIUS - int(BORDER))
	add_child(art_surface)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_surface.add_child(art)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_color_override("font_color", DentiUIStyle.INK)
	add_child(caption)
	mystery = Label.new()
	mystery.text = "?"
	mystery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mystery.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mystery.add_theme_font_size_override("font_size", 44)
	mystery.add_theme_color_override("font_color", DentiUIStyle.LINE.lightened(0.35))
	add_child(mystery)
	resized.connect(_layout)

func set_world(texture: Texture2D, title: String, highlighted: bool) -> void:
	art.texture = texture
	caption.text = title
	mystery.visible = texture == null
	active = highlighted
	frame.border_color = DentiUIStyle.GOLD if active else DentiUIStyle.LINE
	_layout()
	queue_redraw()

func _layout() -> void:
	if art == null:
		return
	pivot_offset = size / 2
	var label_height := 44.0 if size.x < 220 else 34.0
	art_surface.position = Vector2.ONE * BORDER
	art_surface.size = Vector2(size.x - BORDER * 2, maxf(10, size.y - label_height - BORDER * 2))
	caption.position = Vector2(8, size.y - label_height)
	caption.size = Vector2(size.x - 16, label_height - BORDER)
	caption.add_theme_font_size_override("font_size", 12 if size.x < 160 else 16)
	if size.y < 150:
		var aspect := StoryCatalog.CARDS.get_width() / (4.0 * StoryCatalog.CARDS.get_height())
		art_surface.size = Vector2(minf(size.x * 0.38, (size.y - BORDER * 2) * aspect), size.y - BORDER * 2)
		caption.position = Vector2(art_surface.position.x + art_surface.size.x + 8, BORDER)
		caption.size = Vector2(size.x - caption.position.x - 8, size.y - BORDER * 2)
	mystery.position = art_surface.position
	mystery.size = art_surface.size

func _draw() -> void:
	draw_style_box(frame, Rect2(Vector2.ZERO, size))
