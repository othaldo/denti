extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var atlas := Image.load_from_file("res://assets/vfx/combat_textures.png")
	var images := CombatSpriteTextures.standard_images()
	_check(images.size() == CombatSpriteTextures.PREPARED.REGIONS.size(), "baked player/loot variants are stale")
	for key: String in images:
		var texture := CombatSpriteTextures.PREPARED.find(key) as AtlasTexture
		_check(texture != null, "missing combat texture: " + key)
		if texture == null:
			continue
		var prepared := atlas.get_region(Rect2i(texture.region))
		_check(prepared.get_data() == images[key].get_data() and prepared.get_size() == images[key].get_size(), "combat raster changed: " + key)
		_check(texture.atlas == CombatSpriteTextures.PREPARED.ATLAS, "combat textures do not share one atlas")
	CombatSpriteTextures.textures.clear()
	CombatSpriteTextures.standard_textures()
	var count := CombatSpriteTextures.textures.size()
	for weapon in WeaponCatalog.ALL:
		if weapon.attack_mode != &"projectile":
			continue
		for tier in range(1, 5):
			var radius := 11.0 if weapon.splash_at_tier(tier) > 0 or weapon.pierce_at_tier(tier) > 0 else 7.0
			if weapon.projectile_shape == &"rocket":
				_check(CombatSpriteTextures.rocket(weapon.projectile_color) is AtlasTexture, "rocket generated pixels during combat")
			else:
				_check(CombatSpriteTextures.projectile_body(weapon.projectile_color, radius) is AtlasTexture, "player shot generated pixels during combat")
	_check(CombatSpriteTextures.enemy_shadow() is AtlasTexture and CombatSpriteTextures.loot(&"chest") is AtlasTexture and CombatSpriteTextures.textures.size() == count, "standard calls generated new textures after warmup")
	CombatDrawCache.prepare()
	var arc_count := CombatDrawCache.arcs.size()
	for points in CombatDrawCache.POINT_COUNTS:
		var full: PackedVector2Array = CombatDrawCache.arcs[points][64]
		_check(full.size() == points and full[0].is_equal_approx(Vector2.RIGHT) and full[-1].is_equal_approx(Vector2.RIGHT), "cached full circle has incorrect point count or seam")
	var glyph_image := Image.load_from_file("res://assets/vfx/combat_glyphs.png")
	for radius in [20, 24, 26, 31]:
		var texture := CombatGlyphs.region("%s:64" % radius)
		var image := glyph_image.get_region(Rect2i(texture.region))
		var middle := image.get_width() / 2
		_check(image.get_pixel(middle, middle - radius * 2).a > 0.9 and image.get_pixel(middle, middle).a == 0.0, "warning ring lost its physical radius or clear center")
	_check(CombatDrawCache.arcs.size() == arc_count, "standard geometry cache grew during use")
	if failures == 0:
		print("Denti prepared combat textures and geometry test passed")
	quit(0 if failures == 0 else 1)
