class_name EnemyProjectileVisuals
extends RefCounted

# Identical bullets share one texture, allowing the renderer to batch their sprites.
static var textures: Dictionary[String, Texture2D] = {}
const RESOLUTION := 2.0


static func body(tint: Color, radius: float) -> Texture2D:
	var key := "body:%s:%s" % [tint.to_html(), radius]
	if textures.has(key):
		return textures[key]
	var extent := ceilf(maxf(18.0, radius) + 2.0)
	var image := Image.create(int(extent * 2.0 * RESOLUTION), int(extent * 2.0 * RESOLUTION), false, Image.FORMAT_RGBA8)
	var center := Vector2.ONE * extent
	_circle(image, center + Vector2(-14, 0), 4.0, Color(tint, 0.35))
	_circle(image, center + Vector2(-7, 0), 5.0, Color(tint, 0.55))
	_circle(image, center, radius, Color(0.20, 0.12, 0.17))
	_circle(image, center, radius * 0.72, tint)
	_circle(image, center + Vector2(-radius * 0.22, -radius * 0.3), maxf(2.0, radius * 0.22), Color(0.92, 1.0, 0.68))
	textures[key] = ImageTexture.create_from_image(image)
	return textures[key]


static func halo(tint: Color, radius: float) -> Texture2D:
	var key := "halo:%s:%s" % [tint.to_html(), radius]
	if textures.has(key):
		return textures[key]
	var extent := ceilf(radius + 3.0)
	var image := Image.create(int(extent * 2.0 * RESOLUTION), int(extent * 2.0 * RESOLUTION), false, Image.FORMAT_RGBA8)
	var center := Vector2.ONE * extent
	for y in image.get_height():
		for x in image.get_width():
			var distance := (Vector2(x + 0.5, y + 0.5) / RESOLUTION).distance_to(center)
			var coverage := clampf((1.5 - absf(distance - radius)) * RESOLUTION + 0.5, 0.0, 1.0)
			if coverage > 0.0:
				image.set_pixel(x, y, Color(tint, 0.42 * coverage))
	textures[key] = ImageTexture.create_from_image(image)
	return textures[key]


static func _circle(image: Image, center: Vector2, radius: float, tint: Color) -> void:
	var first := Vector2i((center - Vector2.ONE * (radius + 1.0)) * RESOLUTION)
	var last := Vector2i((center + Vector2.ONE * (radius + 1.0)) * RESOLUTION)
	for y in range(maxi(0, first.y), mini(image.get_height(), last.y + 1)):
		for x in range(maxi(0, first.x), mini(image.get_width(), last.x + 1)):
			var distance := (Vector2(x + 0.5, y + 0.5) / RESOLUTION).distance_to(center)
			var coverage := clampf((radius - distance) * RESOLUTION + 0.5, 0.0, 1.0)
			if coverage > 0.0:
				image.set_pixel(x, y, image.get_pixel(x, y).blend(Color(tint, tint.a * coverage)))
