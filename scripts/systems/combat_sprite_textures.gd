class_name CombatSpriteTextures
extends RefCounted

# Small shared textures replace per-node circle tessellation/draw calls.
const RESOLUTION := 2.0
static var textures: Dictionary[String, Texture2D] = {}
const PREPARED = preload("res://scripts/systems/prepared_combat_textures.gd")

static func enemy_shadow() -> Texture2D:
	if not textures.has("enemy_shadow"):
		var prepared: Texture2D = PREPARED.find("enemy_shadow")
		if prepared != null:
			textures["enemy_shadow"] = prepared
		else:
			_store("enemy_shadow", shadow_image())
	return textures["enemy_shadow"]

static func projectile_body(tint: Color, radius: float) -> Texture2D:
	_ensure_orb(tint, radius)
	return textures["body:%s:%s" % [tint.to_html(), radius]]

static func projectile_outline(tint: Color, radius: float) -> Texture2D:
	_ensure_orb(tint, radius)
	return textures["outline:%s:%s" % [tint.to_html(), radius]]

static func projectile_tail(tint: Color, radius: float) -> Texture2D:
	_ensure_orb(tint, radius)
	return textures["tail:%s:%s" % [tint.to_html(), radius]]

static func _ensure_orb(tint: Color, radius: float) -> void:
	var key := "%s:%s" % [tint.to_html(), radius]
	if textures.has("body:" + key):
		return
	var prefixes := ["tail:", "outline:", "body:"]
	var prepared: Texture2D = PREPARED.find("body:" + key)
	if prepared != null:
		for prefix in prefixes:
			textures[prefix + key] = PREPARED.find(prefix + key)
		return
	var atlas := Image.create(128, 384, false, Image.FORMAT_RGBA8)
	var layers := orb_images(tint, radius)
	for index in 3:
		atlas.blit_rect(layers[index], Rect2i(0, 0, 128, 128), Vector2i(0, index * 128))
	var texture := ImageTexture.create_from_image(atlas)
	for index in 3:
		var region := AtlasTexture.new()
		region.atlas = texture
		region.region = Rect2(0, index * 128, 128, 128)
		textures[["tail:", "outline:", "body:"][index] + key] = region

static func rocket(tint: Color) -> Texture2D:
	var key := "rocket:%s" % tint.to_html()
	if textures.has(key):
		return textures[key]
	var prepared: Texture2D = PREPARED.find(key)
	if prepared != null:
		textures[key] = prepared
		return prepared
	return _store(key, rocket_image(tint))

static func rocket_image(tint: Color) -> Image:
	var image := _image(40)
	_line(image, Vector2(24, 40), Vector2(46, 40), 10, Color(0.98, 0.94, 0.82))
	var triangle := PackedVector2Array([Vector2(57, 40), Vector2(45, 47), Vector2(45, 33)])
	for y in range(65, 96):
		for x in range(88, 117):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5) / RESOLUTION, triangle):
				image.set_pixel(x, y, tint)
	_line(image, Vector2(20, 40), Vector2(6, 40), 5, Color(1.0, 0.78, 0.28, 0.65))
	return image

static func loot(kind: StringName) -> Texture2D:
	if not textures.has("loot:xp"):
		var kinds: Array[StringName] = [&"xp", &"coin", &"chest"]
		var prepared: Texture2D = PREPARED.find("loot:xp")
		if prepared != null:
			for name in kinds:
				textures["loot:%s" % name] = PREPARED.find("loot:%s" % name)
			return textures["loot:%s" % kind]
		var atlas := Image.create(64, 192, false, Image.FORMAT_RGBA8)
		var layers := loot_images()
		for index in 3:
			atlas.blit_rect(layers[index], Rect2i(0, 0, 64, 64), Vector2i(0, index * 64))
		var texture := ImageTexture.create_from_image(atlas)
		for index in 3:
			var region := AtlasTexture.new()
			region.atlas = texture
			region.region = Rect2(0, index * 64, 64, 64)
			textures["loot:%s" % kinds[index]] = region
	return textures["loot:%s" % kind]

static func _image(extent: int) -> Image:
	return Image.create(int(extent * 2 * RESOLUTION), int(extent * 2 * RESOLUTION), false, Image.FORMAT_RGBA8)

static func _store(key: String, image: Image) -> Texture2D:
	var texture: Texture2D = PREPARED.find(key)
	if texture == null:
		texture = ImageTexture.create_from_image(image)
	textures[key] = texture
	return texture

static func _circle(image: Image, at: Vector2, radius: float, tint: Color) -> void:
	EnemyProjectileVisuals._circle(image, at, radius, tint)

static func _rect(image: Image, rect: Rect2, tint: Color) -> void:
	image.fill_rect(Rect2i(rect.position * RESOLUTION, rect.size * RESOLUTION), tint)

static func _line(image: Image, start: Vector2, end: Vector2, width: float, tint: Color) -> void:
	var bounds := Rect2(start.min(end), (end - start).abs()).grow(width * 0.5 + 1)
	var direction := start.direction_to(end)
	var length := start.distance_to(end)
	for y in range(int(bounds.position.y * RESOLUTION), int(bounds.end.y * RESOLUTION) + 1):
		for x in range(int(bounds.position.x * RESOLUTION), int(bounds.end.x * RESOLUTION) + 1):
			var at := Vector2(x + 0.5, y + 0.5) / RESOLUTION
			var along := (at - start).dot(direction)
			var edge := minf(width * 0.5 - absf((at - start).dot(direction.orthogonal())), minf(along, length - along))
			var coverage := clampf(edge * RESOLUTION + 0.5, 0, 1)
			if coverage > 0:
				image.set_pixel(x, y, image.get_pixel(x, y).blend(Color(tint, tint.a * coverage)))


static func shadow_image() -> Image:
	var image := _image(16)
	_circle(image, Vector2(16, 16), 15, Color(0.17, 0.13, 0.17, 0.17))
	return image

static func orb_images(tint: Color, radius: float) -> Array[Image]:
	var layers: Array[Image] = [_image(32), _image(32), _image(32)]
	for index in 3:
		_circle(layers[0], Vector2(32 - (index + 1) * 8, 32), radius * (0.75 - index * 0.16), Color(tint, 0.34 - index * 0.08))
	_circle(layers[1], Vector2(32, 32), radius + 1.0, Color(0.11, 0.24, 0.27, 0.42))
	_circle(layers[2], Vector2(32, 32), radius, tint)
	_circle(layers[2], Vector2(29.5, 29.5), radius * 0.32, Color.WHITE)
	return layers

static func loot_images() -> Array[Image]:
	var kinds: Array[StringName] = [&"xp", &"coin", &"chest"]
	var result: Array[Image] = []
	for index in 3:
		var image := _image(16)
		if kinds[index] == &"chest":
			_rect(image, Rect2(3, 7, 26, 20), Color(0.33, 0.16, 0.30))
			_rect(image, Rect2(5, 9, 22, 16), Color(0.96, 0.69, 0.28))
			_rect(image, Rect2(5, 15, 22, 3), Color(0.52, 0.20, 0.34))
			_circle(image, Vector2(16, 16), 3, Color(1.0, 0.95, 0.65))
		else:
			_circle(image, Vector2(16, 16), 8, Color(0.2, 0.16, 0.2))
			_circle(image, Vector2(16, 16), 6, Color(0.35, 0.84, 0.96) if kinds[index] == &"xp" else Color(1.0, 0.79, 0.29))
			_circle(image, Vector2(14, 14), 2, Color.WHITE)
		result.append(image)
	return result

static func standard_images() -> Dictionary[String, Image]:
	var images: Dictionary[String, Image] = {"enemy_shadow": shadow_image()}
	var drops := loot_images()
	for index in 3:
		images["loot:%s" % [&"xp", &"coin", &"chest"][index]] = drops[index]
	var weapons: Array[WeaponData] = WeaponCatalog.ALL.duplicate()
	for recipe in WeaponEvolutions.ALL:
		weapons.append(recipe.result)
	for weapon in weapons:
		if weapon.attack_mode != &"projectile":
			continue
		if weapon.projectile_shape == &"rocket":
			images["rocket:%s" % weapon.projectile_color.to_html()] = rocket_image(weapon.projectile_color)
		else:
			for tier in range(1, 5):
				var radius := 11.0 if weapon.splash_at_tier(tier) > 0 or weapon.pierce_at_tier(tier) > 0 else 7.0
				var layers := orb_images(weapon.projectile_color, radius)
				for index in 3:
					images["%s:%s:%s" % [["tail", "outline", "body"][index], weapon.projectile_color.to_html(), radius]] = layers[index]
	return images

static func standard_textures() -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for key: String in PREPARED.REGIONS:
		var texture: Texture2D = PREPARED.find(key)
		textures[key] = texture
		result.append(texture)
	return result
