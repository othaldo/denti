class_name WeaponElementVisuals
extends RefCounted

## Shared painted, precompiled VFX. Only appearance changes, never hit geometry.
const PREPARED = preload("res://scripts/systems/prepared_weapon_element_effects.gd")
const ELEMENTS: Array[StringName] = [&"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]
const CELL := Vector2(256, 128)
const CONTENT := Rect2(8, 8, 240, 112)
const FRAMES := 4
const FPS := 12.0
enum Shape { STREAM, TRAIL, SPRAY, FLASH, POOL }
static var cone_uvs: Dictionary[String, Array] = {}


static func element(data: WeaponData, affixes: Array[Dictionary]) -> StringName:
	var selected := WeaponAffixes.element(affixes)
	return selected if selected != &"" else data.element_skin


static func color(element_id: StringName, fallback: Color) -> Color:
	return WeaponAffixes.by_id(element_id).color if ELEMENTS.has(element_id) else fallback


static func animation_rate(element_id: StringName) -> float:
	return WeaponAffixes.by_id(element_id).visual_animation_rate if ELEMENTS.has(element_id) else 1.0


static func projectile(data: WeaponData, tier: int, affixes: Array[Dictionary]) -> Texture2D:
	var selected := element(data, affixes)
	if not ELEMENTS.has(selected):
		return null
	var style := "rocket" if data.projectile_shape == &"rocket" else ("11" if data.splash_at_tier(tier) > 0 or data.pierce_at_tier(tier) > 0 else "7")
	return PREPARED.find("%s:%s" % [selected, style])


static func region(element_id: StringName, shape: Shape, seconds: float) -> Rect2:
	var frame := posmod(floori(seconds * FPS * animation_rate(element_id)), FRAMES)
	return Rect2(Vector2(frame * CELL.x, (ELEMENTS.find(element_id) * 5 + shape) * CELL.y), CELL)


static func strip(canvas: CanvasItem, element_id: StringName, fallback: AttackEffects.Shape, start: Vector2, end: Vector2, width: float, tint: Color, seconds: float = 0.0) -> void:
	if not ELEMENTS.has(element_id):
		AttackEffects.strip(canvas, fallback, start, end, width, tint, seconds)
		return
	var length := start.distance_to(end)
	if length < 0.01 or width <= 0 or tint.a <= 0:
		return
	var shape := Shape.TRAIL if fallback == AttackEffects.Shape.SLASH else Shape.STREAM
	var scale := Vector2(length / CONTENT.size.x, width / CONTENT.size.y)
	canvas.draw_set_transform_matrix(AttackEffects.strip_transform(start, end))
	canvas.draw_texture_rect_region(PREPARED.EFFECTS,
		Rect2(Vector2(-CONTENT.position.x * scale.x, -CELL.y * scale.y * 0.5), CELL * scale),
		region(element_id, shape, seconds), Color(1, 1, 1, tint.a))
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


static func flash(canvas: CanvasItem, element_id: StringName, at: Vector2, radius: float, tint: Color, seconds: float = 0.0) -> void:
	if not ELEMENTS.has(element_id):
		AttackEffects.flash(canvas, at, radius, tint, seconds)
		return
	if radius <= 0 or tint.a <= 0:
		return
	canvas.draw_texture_rect_region(PREPARED.EFFECTS, Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2),
		region(element_id, Shape.FLASH, seconds), Color(1, 1, 1, tint.a))


static func pool(canvas: CanvasItem, element_id: StringName, at: Vector2, radius: float, tint: Color, seconds: float = 0.0) -> void:
	if not ELEMENTS.has(element_id):
		GroundEffects.draw(canvas, GroundEffects.Shape.POOL, at, radius, tint)
		return
	var extent := radius * GroundEffects.CELL / (GroundEffects.RADIUS * 2.0)
	canvas.draw_texture_rect_region(PREPARED.EFFECTS, Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2),
		region(element_id, Shape.POOL, seconds), Color(1, 1, 1, tint.a))


static func aim(canvas: CanvasItem, element_id: StringName, start: Vector2, end: Vector2, tint: Color, progress: float) -> void:
	AttackEffects.aim(canvas, start, end, Color(color(element_id, tint), tint.a), progress)


static func prepare_spray(element_id: StringName, degrees: float) -> void:
	if not ELEMENTS.has(element_id):
		return
	var key := "%s:%s" % [element_id, degrees]
	if cone_uvs.has(key):
		return
	var variants: Array[PackedVector2Array] = []
	var lateral := maxf(sin(deg_to_rad(degrees * 0.5)), 0.01)
	for frame in FRAMES:
		var uv := PackedVector2Array()
		var bounds := Rect2(Vector2(frame * CELL.x, (ELEMENTS.find(element_id) * 5 + Shape.SPRAY) * CELL.y), CELL)
		for point in AttackEffects.cone_points(degrees):
			uv.append((bounds.position + CONTENT.position + Vector2(point.x * CONTENT.size.x, (point.y / lateral * 0.5 + 0.5) * CONTENT.size.y)) / PREPARED.EFFECTS.get_size())
		variants.append(uv)
	cone_uvs[key] = variants


static func spray(canvas: CanvasItem, element_id: StringName, at: Vector2, direction: Vector2, reach: float, degrees: float, tint: Color, seconds: float) -> void:
	if not ELEMENTS.has(element_id):
		AttackEffects.spray(canvas, at, direction, reach, degrees, tint, seconds)
		return
	if reach <= 0 or tint.a <= 0:
		return
	prepare_spray(element_id, degrees)
	var key := "%s:%s" % [element_id, degrees]
	var frame := posmod(floori(seconds * FPS * animation_rate(element_id)), FRAMES)
	canvas.draw_set_transform(at, direction.angle(), Vector2.ONE * reach)
	canvas.draw_polygon(AttackEffects.cone_points(degrees), PackedColorArray([Color(1, 1, 1, tint.a)]), cone_uvs[key][frame], PREPARED.EFFECTS)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
