extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var atlas := Image.load_from_file("res://assets/vfx/enemy_projectiles.png")
	check(atlas != null and not atlas.is_empty(), "prepared projectile atlas is missing")
	if atlas == null or atlas.is_empty():
		finish(1)
		return
	EnemyProjectileVisuals.textures.clear()
	for spec in EnemyProjectileVisuals.standard_specs():
		var texture := (EnemyProjectileVisuals.body(spec.tint, spec.radius) if spec.kind == "body" else EnemyProjectileVisuals.halo(spec.tint, spec.radius)) as AtlasTexture
		check(texture != null, "standard projectile generated a texture during combat: %s" % spec)
		if texture == null:
			continue
		check(texture.atlas == EnemyProjectileVisuals.PREPARED.ATLAS, "projectile does not share the atlas")
		var reference := EnemyProjectileVisuals.body_image(spec.tint, spec.radius) if spec.kind == "body" else EnemyProjectileVisuals.halo_image(spec.tint, spec.radius)
		var prepared := atlas.get_region(Rect2i(texture.region))
		check(prepared.get_size() == reference.get_size() and prepared.get_data() == reference.get_data(), "prepared projectile pixels differ from the original raster: %s" % spec)
	check(EnemyProjectileVisuals.textures.size() == EnemyProjectileVisuals.standard_specs().size(), "prepared variants overlap or were omitted")
	# Custom/future data still works before the atlas is regenerated.
	var custom := EnemyProjectileVisuals.body(Color(0.3, 0.5, 0.7), 12.3)
	check(custom is ImageTexture and custom.get_size() == Vector2(EnemyProjectileVisuals.body_image(Color(0.3, 0.5, 0.7), 12.3).get_size()), "nonstandard projectile lost its painted fallback")
	check(custom == EnemyProjectileVisuals.body(Color(0.3, 0.5, 0.7), 12.3), "fallback texture is not cached")
	if failures.is_empty():
		print("Denti prepared projectile atlas test passed")
	finish_checks()
