extends "res://tests/support/test_runtime.gd"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func values(id: StringName) -> Array[Dictionary]:
	return [{"id": str(id), "level": 1, "rarity": 1, "damage": 8.0}]


func _run() -> void:
	ProjectilePaint.source_images.clear()
	var data := WeaponCatalog.by_id(&"magic_toothbrush")
	var plain := ProjectileEnchantmentSkins.base_texture(data, 1)
	var image := WeaponElementVisuals.PREPARED.EFFECTS.get_image()
	var styles: Array[WeaponInstance] = []
	var hashes: Dictionary = {}
	for id in WeaponElementVisuals.ELEMENTS:
		var affixes := values(id)
		var base := ProjectileEnchantmentSkins.base_texture(data, 1, affixes)
		check(base is AtlasTexture and base.atlas == WeaponElementVisuals.PREPARED.PROJECTILES, "element uses the old projectile core: " + str(id))
		check(base != plain, "element only added particles around the old projectile")
		var pixels := base.get_image()
		check(pixels.get_pixelv(pixels.get_size() / 2).a > 0.8, "element head moved off the collision center: " + str(id))
		var digest := hash(pixels.get_data())
		check(not hashes.has(digest), "two elements have identical projectile art")
		hashes[digest] = true
		var weapon := WeaponInstance.new()
		weapon.configure(data, 1)
		weapon.affixes = affixes
		styles.append(weapon)
		for kind in range(5):
			for frame in WeaponElementVisuals.FRAMES:
				var seconds := (frame + 0.1) / (WeaponElementVisuals.FPS * WeaponElementVisuals.animation_rate(id))
				var region := Rect2i(WeaponElementVisuals.region(id, kind, seconds))
				check(Rect2i(Vector2i.ZERO, image.get_size()).encloses(region), "effect samples another atlas region")
				for x in region.size.x:
					check(image.get_pixel(region.position.x + x, region.position.y).a == 0 and image.get_pixel(region.position.x + x, region.end.y - 1).a == 0, "effect atlas has a filtering seam")
		WeaponElementVisuals.prepare_spray(id, 65)
	# Prepared six-element loadout stays a single sprite per projectile and never
	# loads the high-resolution painting or uploads new textures during salvos.
	var pool := PlayerProjectilePool.new()
	root.add_child(pool)
	pool.prepare_loadout(styles)
	var composed := pool.skins.composed_total
	var uploaded := pool.skins.uploads_total
	var created := pool.created
	for cycle in 60:
		var weapon := styles[cycle % styles.size()]
		var shot := pool.acquire(data, 1)
		shot.launch(Vector2.ZERO, Vector2.RIGHT, 10, data, null, false, 1, weapon.affixes)
		check(shot.visual_element == StringName(weapon.affixes[0].id) and shot.get_child_count() == 1, "pooled projectile retained another element or added nodes")
		var saved := shot.save_state({})
		var expected := shot.visual_frames[0].get_image().get_data()
		var restored := pool.acquire(data, 1)
		restored.restore_state(saved, null, [])
		check(restored.visual_element == shot.visual_element and restored.visual_frames[0].get_image().get_data() == expected, "resume changed the projectile element")
		restored.retire()
		shot.retire()
	check(pool.skins.composed_total == composed and pool.skins.uploads_total == uploaded and pool.created == created, "prepared elemental salvos generated textures or nodes")
	check(ProjectilePaint.source_images.is_empty(), "ordinary elemental combat loaded a source painting")
	var shot := pool.acquire(data, 1)
	shot.launch(Vector2.ZERO, Vector2.RIGHT, 10, data)
	check(shot.visual_element == &"" and shot.visual_rate == 1 and shot.visual_frames.size() == 1, "plain projectile retained elemental state")
	shot.retire()
	pool.free()
	for weapon in styles:
		weapon.free()
	if failures == 0:
		print("PASS weapon_element_visuals: six distinct cores, 120 effect frames, collision origins, prepared pooling and resume")
	finish(0 if failures == 0 else 1)
