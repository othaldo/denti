class_name AttackEffects
extends RefCounted

# One shared, offline-baked atlas. Drawing never creates nodes or images.
const ATLAS: Texture2D = preload("res://assets/vfx/attack_effects.png")
const CELL := Vector2(256, 128)
const FRAMES := 4
const FPS := 12.0
const CONTENT := Rect2(8, 8, 240, 112)
const LANE_EDGE := 0.86
enum Shape { BEAM, THREAD, SLASH, LANE, AIM, FLASH, SPRAY, TRAIL, UV }
static var cones: Dictionary[float, PackedVector2Array] = {}
static var cone_uvs: Dictionary[float, Array] = {}
static var warning_slice_points: Array[PackedVector2Array] = []
static var warning_slice_uvs: Array = []

static func region(shape: Shape, seconds: float) -> Rect2:
	return Rect2(Vector2(posmod(floori(seconds * FPS), FRAMES) * CELL.x, shape * CELL.y), CELL)

static func strip_transform(start: Vector2, end: Vector2, base: Transform2D = Transform2D.IDENTITY) -> Transform2D:
	return base * Transform2D((end - start).angle(), start)

# Width refers to the full visual footprint, including the soft glow.
static func strip(canvas: CanvasItem, shape: Shape, start: Vector2, end: Vector2, width: float, tint: Color, seconds: float = 0.0, base: Transform2D = Transform2D.IDENTITY) -> void:
	var length := start.distance_to(end)
	if length < 0.01 or width <= 0.0 or tint.a <= 0.0:
		return
	canvas.draw_set_transform_matrix(strip_transform(start, end, base))
	# Map the logical content endpoints onto start/end; transparent gutters
	# protect neighbors from filtering. All visible light stays at these ends.
	var scale := Vector2(length / CONTENT.size.x, width / CONTENT.size.y)
	var rect := Rect2(Vector2(-CONTENT.position.x * scale.x, -CELL.y * scale.y * 0.5), CELL * scale)
	canvas.draw_texture_rect_region(ATLAS, rect, region(shape, seconds), tint)
	canvas.draw_set_transform_matrix(base)

static func lane(canvas: CanvasItem, start: Vector2, end: Vector2, half_width: float, tint: Color, progress: float, base: Transform2D = Transform2D.IDENTITY, fill_scales: PackedFloat32Array = PackedFloat32Array()) -> void:
	# A disturbed-ground decal fills the warning width without runway-like rails.
	tint.a *= lerpf(0.55, 1.0, progress)
	if fill_scales.size() == WarningVisualDensity.SLICES + 1:
		_faded_lane(canvas, start, end, half_width, tint, progress * 0.6, base, fill_scales)
	else:
		strip(canvas, Shape.LANE, start, end, half_width * 2.0 / LANE_EDGE, tint, progress * 0.6, base)

static func prepare_warning_slices() -> void:
	if not warning_slice_points.is_empty():
		return
	for index in WarningVisualDensity.SLICES:
		var left := CONTENT.position.x + CONTENT.size.x * index / WarningVisualDensity.SLICES
		var right := CONTENT.position.x + CONTENT.size.x * (index + 1) / WarningVisualDensity.SLICES
		warning_slice_points.append(PackedVector2Array([Vector2(left, 0), Vector2(right, 0), Vector2(right, CELL.y), Vector2(left, CELL.y)]))
	for frame in FRAMES:
		var variants: Array[PackedVector2Array] = []
		var offset := Vector2(frame * CELL.x, Shape.LANE * CELL.y)
		for points in warning_slice_points:
			var uv := PackedVector2Array()
			for point in points:
				uv.append((offset + point) / ATLAS.get_size())
			variants.append(uv)
		warning_slice_uvs.append(variants)

static func _faded_lane(canvas: CanvasItem, start: Vector2, end: Vector2, half_width: float, tint: Color, seconds: float, base: Transform2D, values: PackedFloat32Array) -> void:
	var length := start.distance_to(end)
	if length < 0.01 or half_width <= 0.0 or tint.a <= 0.0:
		return
	prepare_warning_slices()
	var scale := Vector2(length / CONTENT.size.x, half_width * 2.0 / LANE_EDGE / CONTENT.size.y)
	var offset := Vector2(-CONTENT.position.x * scale.x, -CELL.y * scale.y * 0.5)
	canvas.draw_set_transform_matrix(strip_transform(start, end, base) * Transform2D(0, scale, 0, offset))
	var frame := posmod(floori(seconds * FPS), FRAMES)
	for index in WarningVisualDensity.SLICES:
		var left := Color(tint, tint.a * values[index])
		var right := Color(tint, tint.a * values[index + 1])
		canvas.draw_primitive(warning_slice_points[index], PackedColorArray([left, right, right, left]), warning_slice_uvs[frame][index], ATLAS)
	canvas.draw_set_transform_matrix(base)

static func aim(canvas: CanvasItem, start: Vector2, end: Vector2, tint: Color, progress: float, base: Transform2D = Transform2D.IDENTITY) -> void:
	strip(canvas, Shape.AIM, start, end, 12.0, Color(tint, tint.a * lerpf(0.4, 0.9, progress)), progress * 0.6, base)

static func flash(canvas: CanvasItem, at: Vector2, radius: float, tint: Color, seconds: float = 0.0) -> void:
	if radius <= 0.0:
		return
	canvas.draw_texture_rect_region(ATLAS, Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), region(Shape.FLASH, seconds), tint)

static func warning_ring(canvas: CanvasItem, at: Vector2, radius: float, progress: float, tint: Color) -> void:
	var step := clampi(roundi(progress * 64.0), 0, 64)
	if step == 0 or radius <= 0.0:
		return
	var extent := radius * 40.0 / 32.0
	var source := Rect2(Vector2(step % 12 * 80, 1152 + step / 12 * 80), Vector2(80, 80))
	canvas.draw_texture_rect_region(ATLAS, Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2), source, tint)

static func danger(canvas: CanvasItem, at: Vector2, radius: float, tint: Color) -> void:
	if radius <= 0.0:
		return
	var extent := radius * GroundEffects.CELL / (GroundEffects.RADIUS * 2.0)
	canvas.draw_texture_rect_region(ATLAS, Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2), Rect2(480, 1552, 128, 128), tint)

static func cone_points(degrees: float) -> PackedVector2Array:
	if not cones.has(degrees):
		var points := PackedVector2Array([Vector2.ZERO])
		var half := deg_to_rad(degrees * 0.5)
		for index in 25:
			points.append(Vector2.from_angle(lerpf(-half, half, index / 24.0)))
		cones[degrees] = points
	return cones[degrees]

static func spray(canvas: CanvasItem, at: Vector2, direction: Vector2, reach: float, degrees: float, tint: Color, seconds: float) -> void:
	if reach <= 0.0:
		return
	prepare_spray(degrees)
	var uv: PackedVector2Array = cone_uvs[degrees][posmod(floori(seconds * FPS), FRAMES)]
	canvas.draw_set_transform(at, direction.angle(), Vector2.ONE * reach)
	canvas.draw_polygon(cone_points(degrees), PackedColorArray([tint]), uv, ATLAS)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

static func prepare_spray(degrees: float) -> void:
	if cone_uvs.has(degrees):
		return
	var variants: Array[PackedVector2Array] = []
	var lateral := maxf(sin(deg_to_rad(degrees * 0.5)), 0.01)
	for frame in FRAMES:
		var uv := PackedVector2Array()
		var bounds := region(Shape.SPRAY, (frame + 0.1) / FPS)
		for point in cone_points(degrees):
			uv.append((bounds.position + CONTENT.position + Vector2(point.x * CONTENT.size.x, (point.y / lateral * 0.5 + 0.5) * CONTENT.size.y)) / ATLAS.get_size())
		variants.append(uv)
	cone_uvs[degrees] = variants
