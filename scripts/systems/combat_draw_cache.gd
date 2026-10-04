class_name CombatDrawCache
extends RefCounted

# Reuse unit geometry; only transform, color and width change during combat.
# 64 progress steps exceed the number of physics ticks in a bacteria warning.
const PROGRESS_STEPS := 64
const POINT_COUNTS := [12, 16, 20, 24, 32, 40, 48, 64]
static var arcs: Dictionary[int, Array] = {}

static func prepare() -> void:
	CombatGlyphs.prepare()
	for count in POINT_COUNTS:
		_prepare_count(count)

static func _prepare_count(count: int) -> void:
	if arcs.has(count):
		return
	var variants: Array[PackedVector2Array] = []
	for step in PROGRESS_STEPS + 1:
		var points := PackedVector2Array()
		points.resize(count)
		for index in count:
			points[index] = Vector2.from_angle(TAU * step / PROGRESS_STEPS * index / float(count - 1))
		variants.append(points)
	arcs[count] = variants

static func arc(canvas: CanvasItem, at: Vector2, radius: float, start: float, end: float, count: int, tint: Color, width: float, base: Transform2D = Transform2D.IDENTITY, visual_tint: Color = Color.WHITE) -> void:
	tint *= visual_tint
	if radius <= 0.0 or end <= start:
		return
	_prepare_count(count)
	var step := clampi(roundi((end - start) / TAU * PROGRESS_STEPS), 0, PROGRESS_STEPS)
	if step == 0:
		return
	if count == 16 and step == PROGRESS_STEPS and is_zero_approx(start) and is_equal_approx(width, 2.0) and radius == float(int(radius)):
		var mark := CombatGlyphs.region("mark:%s" % int(radius))
		if mark != null:
			var extent := radius + 3.0
			canvas.draw_texture_rect(mark, Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2.0), false, tint)
			return
	# These ordinary warning rings share a pre-rendered atlas. Larger boss
	# rings retain precise stroke widths through the cached geometry path.
	if count == 32 and is_equal_approx(width, 4.0) and is_equal_approx(start, -PI / 2.0):
		var texture := CombatGlyphs.region("%s:%s" % [int(radius), step]) if radius == float(int(radius)) else null
		if texture != null:
			var extent := radius + 4.0
			canvas.draw_texture_rect(texture, Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2.0), false, tint)
			return
	canvas.draw_set_transform_matrix(base * Transform2D(start, Vector2.ONE * radius, 0.0, at))
	canvas.draw_polyline(arcs[count][step], tint, width / radius)
	canvas.draw_set_transform_matrix(base)

static func line(canvas: CanvasItem, start: Vector2, end: Vector2, tint: Color, width: float, base: Transform2D = Transform2D.IDENTITY, visual_tint: Color = Color.WHITE, solid: bool = false) -> void:
	tint *= visual_tint
	var difference := end - start
	if difference.is_zero_approx():
		return
	canvas.draw_set_transform_matrix(base * Transform2D(difference.angle(), start))
	canvas.draw_texture_rect(CombatGlyphs.region("solid" if solid else "line"), Rect2(Vector2(0, -width * 0.5), Vector2(difference.length(), width)), false, tint)
	canvas.draw_set_transform_matrix(base)

static func circle(canvas: CanvasItem, at: Vector2, radius: float, tint: Color, visual_tint: Color = Color.WHITE) -> void:
	tint *= visual_tint
	if radius <= 0.0:
		return
	var extent := radius * CombatGlyphs.EXTENT / CombatGlyphs.RADIUS
	canvas.draw_texture_rect(CombatGlyphs.region("circle"), Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2.0), false, tint)
