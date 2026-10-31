class_name WarningEffects
extends RefCounted
## Every enemy floor warning shares geometry, layers, timing and palette handling.

const BATCH := preload("res://scripts/vfx/telegraph_batch.gd")
const DEFAULT_COLOR := Color(1, 0.38, 0.19, 0.90)
# Kept as references for offline/historical atlas tooling.
const ATLAS: Texture2D = preload("res://assets/vfx/attack_effects.png")
const PREPARED = preload("res://scripts/systems/prepared_warning_shapes.gd")
const CHARGE_BODY := Rect2(1024, 1728, 64, 64)
const CHARGE_HEAD := Rect2(1152, 1728, 64, 64)

static func prepare() -> void:
	BATCH.prepare()

static func fill_fraction(progress: float) -> float:
	return pow(clampf(progress, 0, 1), 2.2)

static func charge_front(path_length: float, aim_distance: float, progress: float) -> float:
	var destination := minf(aim_distance, path_length) if aim_distance > 0 else path_length
	return destination * fill_fraction(progress)

static func _density(values: PackedFloat32Array) -> float:
	# Conservatively fade the whole fill where any section is crowded.
	# The contour and moving front use the separate, unattenuated edge pass.
	var result := 1.0
	for value in values: result = minf(result, value)
	return result

static func charge(canvas: CanvasItem, start: Vector2, end: Vector2, half_width: float, aim_distance: float, tint: Color, progress: float, base: Transform2D = Transform2D.IDENTITY, density: PackedFloat32Array = PackedFloat32Array()) -> void:
	var length := start.distance_to(end)
	if length < 0.01 or half_width <= 0 or tint.a <= 0: return
	var local_aim := maxf(aim_distance - start.length(), 0.001) if aim_distance > 0 else length
	var limit := minf(local_aim / length, 1.0)
	BATCH.for_canvas(canvas).add(BATCH.Shape.LANE, length, half_width, progress, tint, base * Transform2D((end - start).angle(), start), BATCH.Phase.WARNING, _density(density), limit)

static func lane(canvas: CanvasItem, start: Vector2, end: Vector2, half_width: float, tint: Color, progress: float, base: Transform2D = Transform2D.IDENTITY, density: PackedFloat32Array = PackedFloat32Array(), phase: int = BATCH.Phase.WARNING) -> void:
	var length := start.distance_to(end)
	if length < 0.01 or half_width <= 0 or tint.a <= 0: return
	BATCH.for_canvas(canvas).add(BATCH.Shape.LANE, length, half_width, progress, tint, base * Transform2D((end - start).angle(), start), phase, _density(density))

static func capsule(canvas: CanvasItem, start: Vector2, end: Vector2, radius: float, tint: Color, progress: float, base: Transform2D = Transform2D.IDENTITY, phase: int = BATCH.Phase.WARNING) -> void:
	var length := start.distance_to(end)
	if radius <= 0 or tint.a <= 0: return
	if length < 0.01:
		circle(canvas, start, radius, progress, tint, base, phase)
		return
	BATCH.for_canvas(canvas).add(BATCH.Shape.CAPSULE, length, radius, progress, tint, base * Transform2D((end - start).angle(), start), phase)

static func rectangle(canvas: CanvasItem, rect: Rect2, progress: float, tint: Color, base: Transform2D = Transform2D.IDENTITY, phase: int = BATCH.Phase.WARNING, vertical: bool = false) -> void:
	if vertical:
		lane(canvas, Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y), rect.size.x * 0.5, tint, progress, base, PackedFloat32Array(), phase)
	else:
		lane(canvas, Vector2(rect.position.x, rect.get_center().y), Vector2(rect.end.x, rect.get_center().y), rect.size.y * 0.5, tint, progress, base, PackedFloat32Array(), phase)

static func circle(canvas: CanvasItem, at: Vector2, radius: float, progress: float, tint: Color = DEFAULT_COLOR, base: Transform2D = Transform2D.IDENTITY, phase: int = BATCH.Phase.WARNING) -> void:
	if radius <= 0 or tint.a <= 0: return
	BATCH.for_canvas(canvas).add(BATCH.Shape.CIRCLE, radius, 0, progress, tint, base * Transform2D(0, at), phase)

static func charge_impact(canvas: CanvasItem, at: Vector2, radius: float, progress: float, tint: Color = Color.WHITE, base: Transform2D = Transform2D.IDENTITY, active: bool = false) -> void:
	circle(canvas, at, radius, progress, DEFAULT_COLOR * tint, base, BATCH.Phase.ACTIVE if active else BATCH.Phase.WARNING)

static func sector(canvas: CanvasItem, origin: Vector2, direction: Vector2, reach: float, half_angle: float, progress: float, active: bool, flash: bool, base: Transform2D = Transform2D.IDENTITY, tint: Color = DEFAULT_COLOR) -> void:
	if reach <= 0 or half_angle <= 0 or tint.a <= 0: return
	var phase := BATCH.Phase.ACTIVE if active and flash else (BATCH.Phase.RELEASE if active else BATCH.Phase.WARNING)
	var color := Color(tint, tint.a * (0.3 if active and not flash else 1.0))
	BATCH.for_canvas(canvas).add(BATCH.Shape.SECTOR, reach, clampf(half_angle, 0, PI), progress, color, base * Transform2D(direction.angle(), origin), phase)

static func ring(canvas: CanvasItem, origin: Vector2, inner: float, outer: float, progress: float, active: bool, flash: bool, base: Transform2D = Transform2D.IDENTITY, tint: Color = DEFAULT_COLOR) -> void:
	if outer <= 0 or inner >= outer or tint.a <= 0: return
	var phase := BATCH.Phase.ACTIVE if active and flash else (BATCH.Phase.RELEASE if active else BATCH.Phase.WARNING)
	var color := Color(tint, tint.a * (0.3 if active and not flash else 1.0))
	BATCH.for_canvas(canvas).add(BATCH.Shape.CIRCLE, outer, maxf(inner, 0), progress, color, base * Transform2D(0, origin), phase)

static func timer(canvas: CanvasItem, at: Vector2, radius: float, progress: float, tint: Color, base: Transform2D = Transform2D.IDENTITY) -> void:
	if radius <= 0 or progress <= 0 or tint.a <= 0: return
	BATCH.for_canvas(canvas).add(BATCH.Shape.TIMER, radius, 0, progress, tint, base * Transform2D(0, at))

static func aim(canvas: CanvasItem, start: Vector2, end: Vector2, tint: Color, progress: float, base: Transform2D = Transform2D.IDENTITY) -> void:
	lane(canvas, start, end, 2.5, tint, progress, base)
