class_name DamageNumberBatch
extends Node2D

# All outlines, then all fills: avoid alternating font textures per label.
# Labels retain their public feedback API, but have no individual draw/tween.
const MAX_IDLE := 128
const MAX_TEXT_LAYOUTS := 256
var idle: Array[DamageNumber] = []
var created := 0
var text_layouts: Dictionary[Array, TextLine] = {}
var layout_fonts: Array[Font] = []

func _ready() -> void:
	# Arena/test cleanup can free children without going through retirement.
	child_exiting_tree.connect(func(_child: Node) -> void: queue_redraw())

func acquire(scene: PackedScene) -> DamageNumber:
	var number: DamageNumber
	if idle.is_empty():
		number = scene.instantiate()
		created += 1
	else:
		number = idle.pop_back()
	number.batch = self
	number.hide()
	number.set_process(false)
	add_child(number)
	return number

func begin(number: DamageNumber, at: Vector2) -> void:
	number.elapsed = 0.0
	number.modulate = Color.WHITE
	number.render_font = number.get_theme_font("font")
	number.render_size = number.get_theme_font_size("font_size")
	number.render_color = number.get_theme_color("font_color")
	number.render_outline_color = number.get_theme_color("font_outline_color")
	number.render_outline_size = number.get_theme_constant("outline_size")
	number.render_line = _text_layout(number.text, number.render_font, number.render_size)
	var text_size := number.render_line.get_size()
	number.render_extent = number.custom_minimum_size.max(text_size)
	number.baseline = (number.render_extent - text_size) * 0.5
	# A reused long feedback label must not shift a later short damage number.
	number.scale = Vector2.ONE
	number.global_position = at + Vector2(randf_range(-12.0, 12.0) - number.render_extent.x * 0.5, -number.render_extent.y * 0.5)
	number.scale = Vector2.ONE * 0.85
	number.origin = number.position
	number.travel = Vector2(randf_range(-14.0, 14.0), -48.0)
	number.render_transform = number.get_transform()
	number.render_alpha = 1.0
	queue_redraw()

func _text_layout(text: String, font: Font, font_size: int) -> TextLine:
	# Layout is immutable after shaping and independent of popup color/position.
	# Repeated damage values share glyph placement, including cached kerning.
	var key := [font, font_size, text]
	if text_layouts.has(key):
		return text_layouts[key]
	if not layout_fonts.has(font):
		layout_fonts.append(font)
		font.changed.connect(_clear_text_layouts)
	var line := TextLine.new()
	line.add_string(text, font, font_size)
	if text_layouts.size() >= MAX_TEXT_LAYOUTS:
		text_layouts.erase(text_layouts.keys()[0])
	text_layouts[key] = line
	return line

func _clear_text_layouts() -> void:
	text_layouts.clear()

func _process(delta: float) -> void:
	if get_child_count() == 0:
		return
	for number: DamageNumber in get_children():
		if number.is_queued_for_deletion():
			continue
		number.elapsed += delta
		if number.elapsed >= DamageNumber.LIFETIME + 0.08:
			remove_child(number)
			if idle.size() < MAX_IDLE:
				idle.append(number)
			else:
				number.queue_free()
			continue
		var movement := float(Tween.interpolate_value(0.0, 1.0, minf(number.elapsed, DamageNumber.LIFETIME), DamageNumber.LIFETIME, Tween.TRANS_CUBIC, Tween.EASE_OUT))
		number.render_alpha = 1.0 - clampf((number.elapsed - 0.08) / DamageNumber.LIFETIME, 0.0, 1.0)
		var growth := float(Tween.interpolate_value(0.85, 0.15, minf(number.elapsed, 0.16), 0.16, Tween.TRANS_BACK, Tween.EASE_OUT))
		# Keep hidden Controls inert: their transform notifications/layout are
		# unnecessary when the parent renders the prepared text directly.
		number.render_transform = Transform2D(0.0, Vector2.ONE * growth, 0.0, number.origin + number.travel * movement + number.pivot_offset * (1.0 - growth))
	queue_redraw()

func _draw() -> void:
	var numbers := get_children()
	for outline in [true, false]:
		for number: DamageNumber in numbers:
			if number.render_font == null or number.is_queued_for_deletion():
				continue
			draw_set_transform_matrix(number.render_transform)
			var fade := Color(1, 1, 1, number.render_alpha)
			if outline:
				number.render_line.draw_outline(get_canvas_item(), number.baseline, number.render_outline_size, number.render_outline_color * fade)
			else:
				number.render_line.draw(get_canvas_item(), number.baseline, number.render_color * fade)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _exit_tree() -> void:
	for number in idle:
		number.free()
	idle.clear()
	for font in layout_fonts:
		font.changed.disconnect(_clear_text_layouts)
	layout_fonts.clear()
	text_layouts.clear()
