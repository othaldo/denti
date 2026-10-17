extends SceneTree

var failures := 0
const MAX_PAINTED_CHANNEL_ERROR := 1
const MAX_PAINTED_CHANGED_FRACTION := 0.005

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _compare_raster(prepared: Image, reference: Image, allow_resize_rounding: bool) -> Dictionary:
	if prepared.get_size() != reference.get_size() or prepared.get_format() != reference.get_format():
		return {"matches": false, "changed": -1, "maximum": -1}
	var left := prepared.get_data()
	var right := reference.get_data()
	if left == right:
		return {"matches": true, "changed": 0, "maximum": 0}
	var changed := 0
	var maximum := 0
	for index in left.size():
		var difference := absi(int(left[index]) - int(right[index]))
		if difference > 0:
			changed += 1
			maximum = maxi(maximum, difference)
	# CPU image resizing can round a channel one byte differently between
	# Windows and Linux builds. Keep dimensions/format exact, all other rasters
	# byte-exact, and reject larger or widespread differences in painted art.
	var allowed_channels := maxi(1, floori(left.size() * MAX_PAINTED_CHANGED_FRACTION))
	return {"matches": allow_resize_rounding and maximum <= MAX_PAINTED_CHANNEL_ERROR and changed <= allowed_channels, "changed": changed, "maximum": maximum}

func _check_comparison_bounds() -> void:
	var reference := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var changed: Image = reference.duplicate()
	changed.set_pixel(0, 0, Color(1.0 / 255.0, 0, 0, 0))
	_check(_compare_raster(changed, reference, true).matches, "single-byte painted resize rounding was rejected")
	_check(not _compare_raster(changed, reference, false).matches, "non-resized loot/procedural rasters lost exact comparison")
	changed.set_pixel(0, 0, Color(2.0 / 255.0, 0, 0, 0))
	_check(not _compare_raster(changed, reference, true).matches, "painted raster comparison allows larger color errors")
	for index in 6:
		changed.set_pixel(index, 0, Color(1.0 / 255.0, 0, 0, 0))
	_check(not _compare_raster(changed, reference, true).matches, "painted raster comparison allows widespread differences")
	_check(not _compare_raster(Image.create(17, 16, false, Image.FORMAT_RGBA8), reference, true).matches, "painted raster comparison allows changed bounds")

func _run() -> void:
	_check_comparison_bounds()
	var atlas := Image.load_from_file("res://assets/vfx/combat_textures.png")
	var images := CombatSpriteTextures.standard_images()
	_check(images.size() == CombatSpriteTextures.PREPARED.REGIONS.size(), "baked player/loot variants are stale")
	for key: String in images:
		var texture := CombatSpriteTextures.PREPARED.find(key) as AtlasTexture
		_check(texture != null, "missing combat texture: " + key)
		if texture == null:
			continue
		var prepared := atlas.get_region(Rect2i(texture.region))
		var comparison := _compare_raster(prepared, images[key], key.begins_with("shot:") or key.begins_with("rocket:"))
		_check(comparison.matches, "combat raster changed: %s (changed channels=%d, maximum channel error=%d/255)" % [key, comparison.changed, comparison.maximum])
		if comparison.matches and comparison.changed > 0:
			print("Painted resize rounding: %s, %d channels, maximum %d/255" % [key, comparison.changed, comparison.maximum])
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
				_check(CombatSpriteTextures.projectile(weapon.projectile_color, radius) is AtlasTexture, "painted shot generated pixels during combat")
	_check(CombatSpriteTextures.enemy_shadow() is AtlasTexture and CombatSpriteTextures.loot(&"chest") == CombatSpriteTextures.UPGRADE_CAPSULE and CombatSpriteTextures.textures.size() == count, "standard calls generated new textures after warmup")
	CombatDrawCache.prepare()
	var arc_count := CombatDrawCache.arcs.size()
	for points in CombatDrawCache.POINT_COUNTS:
		var full: PackedVector2Array = CombatDrawCache.arcs[points][64]
		_check(full.size() == points and full[0].is_equal_approx(Vector2.RIGHT) and full[-1].is_equal_approx(Vector2.RIGHT), "cached full circle has incorrect point count or seam")
	var glyph_image := Image.load_from_file("res://assets/vfx/combat_glyphs.png")
	var solid := CombatGlyphs.region("solid")
	_check(CombatGlyphs.solid_texture == solid and CombatGlyphs.line_texture == CombatGlyphs.region("line") and CombatGlyphs.circle_texture == CombatGlyphs.region("circle"), "direct glyph references differ from the prepared artwork")
	_check(solid.atlas == CombatGlyphs.ATLAS and solid.region == CombatGlyphs.region("line").region.grow(-1.0), "lane fill does not reuse the opaque atlas interior")
	var solid_image := glyph_image.get_region(Rect2i(solid.region))
	for y in solid_image.get_height():
		for x in solid_image.get_width():
			_check(solid_image.get_pixel(x, y).is_equal_approx(Color.WHITE), "lane atlas fill contains transparent/colored edges")
	for radius in [20, 24, 26, 31]:
		for step in 65:
			_check(CombatGlyphs.warning_rings[radius][step] == CombatGlyphs.region("%s:%s" % [radius, step]), "numeric warning cache selects the wrong radius/progress cell")
		var texture := CombatGlyphs.region("%s:64" % radius)
		var image := glyph_image.get_region(Rect2i(texture.region))
		var middle := image.get_width() / 2
		_check(image.get_pixel(middle, middle - radius * 2).a > 0.9 and image.get_pixel(middle, middle).a == 0.0, "warning ring lost its physical radius or clear center")
	_check(CombatDrawCache.arcs.size() == arc_count, "standard geometry cache grew during use")
	for path in DirAccess.get_files_at("res://data/enemies"):
		if not path.ends_with(".tres"):
			continue
		var enemy := load("res://data/enemies/" + path) as EnemyData
		var radius := int(enemy.radius + 5)
		var texture := CombatGlyphs.region("mark:%s" % radius)
		_check(CombatGlyphs.marks.get(radius) == texture, "numeric evolution mark cache selects the wrong glyph")
		_check(texture != null and texture.atlas == CombatGlyphs.ATLAS, "evolution mark missing from shared atlas: " + path)
		if texture != null:
			var image := glyph_image.get_region(Rect2i(texture.region))
			var middle := image.get_width() / 2
			_check(image.get_pixel(middle + radius * 2, middle).a > 0.9 and image.get_pixel(middle, middle).a == 0.0, "evolution mark lost radius/stroke or clear center")
	if failures == 0:
		print("Denti prepared combat textures and geometry test passed")
	quit(0 if failures == 0 else 1)
