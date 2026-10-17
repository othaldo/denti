class_name ProjectileParticleFrames
extends RefCounted

# Small cyclic VFX are rasterized during equipment preparation, never in flight.
# These are trails, sparks, droplets and shards; no icons or symbols are stamped.
const COUNT := 8
const FPS := 12.0

static func render(base: Image, definitions: Array[WeaponAffixData], radius: float, frame: int) -> Image:
	var image := Image.create(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8)
	var center := Vector2(base.get_size()) * 0.5
	var r := radius * CombatSpriteTextures.RESOLUTION
	var phase := float(frame) / COUNT
	for definition in definitions:
		_particles(image, center, r, definition, phase, false)
	image.blend_rect(base, Rect2i(Vector2i.ZERO, base.get_size()), Vector2i.ZERO)
	for definition in definitions:
		if definition.id == &"electric":
			_particles(image, center, r, definition, phase, true)
	return image

static func _particles(image: Image, center: Vector2, r: float, data: WeaponAffixData, phase: float, foreground: bool) -> void:
	var color := data.color
	for index in 3:
		var age := fposmod(phase + float(index) / 3.0 + data.projectile_effect_index * 0.137, 1.0)
		var alpha := sin(age * PI)
		var x := -r * (0.55 + age * 2.1)
		var wave := sin(age * TAU + index * 2.1)
		var at := center + Vector2(x, wave * r * 0.15)
		var tint := Color(color, alpha * 0.85)
		match data.id:
			&"fire":
				at.y -= r * (0.55 + age * 0.35)
				_glow(image, at, r * (0.45 - age * 0.22), Color(color, alpha * 0.8))
				_line(image, at - Vector2(r * 0.4 * (1.0 - age), wave * r * 0.12), at, maxf(1.0, r * 0.17 * (1.0 - age)), tint)
			&"ice":
				at.y += r * (0.75 + age * 0.3)
				var extent := r * (0.22 - age * 0.08)
				_triangle(image, at, extent, Color(0.7, 0.94, 1.0, alpha * 0.9))
			&"poison":
				at.y += r * (0.65 + wave * 0.25)
				_glow(image, at, r * (0.35 + age * 0.12), Color(color, alpha * 0.6))
			&"bleed":
				at.y += r * (0.4 + age * 0.2)
				_line(image, at - Vector2(r * 0.32, 0), at, r * 0.13, tint)
			&"electric":
				if not foreground:
					continue
				at = center + Vector2(-r * 0.6 + index * r * 0.35, -r * 0.72 + wave * r * 0.15)
				var end := at + Vector2(r * 0.42, wave * r * 0.12)
				var middle := (at + end) * 0.5 + Vector2(0, r * 0.16 * cos(age * TAU))
				_line(image, at, middle, 0.8, Color(1, 1, 0.65, alpha))
				_line(image, middle, end, 0.8, Color(1, 0.9, 0.25, alpha))
			&"range":
				at.y -= r * 0.35
				_line(image, at - Vector2(r * 0.55, 0), at, 0.7, Color(0.65, 0.9, 1, alpha * 0.65))
			&"tempo":
				at.y += r * 0.5
				_line(image, at - Vector2(r * 0.4, 0), at, 0.7, Color(color, alpha * 0.7))
			&"wet":
				at.y += r * (0.9 + age * 0.15)
				_line(image, at - Vector2(r * 0.12, 0), at, maxf(0.8, r * 0.08), tint)
			&"holy":
				at.y -= r * (0.9 + age * 0.2)
				_glow(image, at, r * 0.18, Color(1, 0.93, 0.65, alpha * 0.85))
			&"leech":
				at.y += r * (0.9 + wave * 0.1)
				_line(image, at - Vector2(r * 0.3, wave * r * 0.15), at, 0.8, Color(color, alpha * 0.8))

static func _glow(image: Image, at: Vector2, radius: float, color: Color) -> void:
	var first := Vector2i((at - Vector2.ONE * radius).floor()).max(Vector2i.ZERO)
	var last := Vector2i((at + Vector2.ONE * radius).ceil()).min(image.get_size() - Vector2i.ONE)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var coverage := maxf(1.0 - Vector2(x + 0.5, y + 0.5).distance_to(at) / maxf(radius, 0.1), 0.0)
			_blend(image, x, y, Color(color, color.a * coverage * coverage))

static func _line(image: Image, start: Vector2, end: Vector2, width: float, color: Color) -> void:
	var padding := Vector2.ONE * (width + 1.0)
	var first := Vector2i((start.min(end) - padding).floor()).max(Vector2i.ZERO)
	var last := Vector2i((start.max(end) + padding).ceil()).min(image.get_size() - Vector2i.ONE)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var at := Vector2(x + 0.5, y + 0.5)
			var distance := at.distance_to(Geometry2D.get_closest_point_to_segment(at, start, end))
			var coverage := clampf(width + 0.6 - distance, 0, 1)
			_blend(image, x, y, Color(color, color.a * coverage))

static func _triangle(image: Image, at: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([at + Vector2(radius, 0), at + Vector2(-radius, -radius * 0.55), at + Vector2(-radius * 0.3, radius)])
	var first := Vector2i((at - Vector2.ONE * radius).floor()).max(Vector2i.ZERO)
	var last := Vector2i((at + Vector2.ONE * radius).ceil()).min(image.get_size() - Vector2i.ONE)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_blend(image, x, y, color)

static func _blend(image: Image, x: int, y: int, color: Color) -> void:
	if color.a > 0.0:
		image.set_pixel(x, y, image.get_pixel(x, y).blend(color))
