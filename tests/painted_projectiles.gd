extends "res://tests/support/test_runtime.gd"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	ProjectilePaint.source_images.clear()
	CombatSpriteTextures.standard_textures()
	EnemyProjectileVisuals.standard_textures()
	var weapons: Array[WeaponData] = WeaponCatalog.ALL.duplicate()
	for recipe in WeaponEvolutions.ALL:
		weapons.append(recipe.result)
	var atlas_image := CombatSpriteTextures.PREPARED.ATLAS.get_image()
	for data in weapons:
		if data.attack_mode != &"projectile":
			continue
		for tier in range(1, 5):
			var shot := WeaponProjectile.new()
			root.add_child(shot)
			shot.launch(Vector2.ZERO, Vector2.UP, 10, data, null, false, tier)
			_check(shot.get_child_count() == 1 and shot.body_sprite.texture is AtlasTexture, "shot did not use one prepared sprite: " + str(data.id))
			var texture := shot.body_sprite.texture as AtlasTexture
			if texture != null:
				var center := Vector2i(texture.region.get_center())
				_check(atlas_image.get_pixelv(center).a > 0.8, "painted projectile head is offset from the collision origin: " + str(data.id))
			_check(is_equal_approx(shot.body_sprite.rotation, -PI / 2.0), "painted projectile does not point along its flight direction")
			shot.direction = Vector2.LEFT
			shot._sync_visuals()
			_check(is_equal_approx(shot.body_sprite.rotation, PI), "returning projectile retained its original heading")
			shot.free()
	_check(ProjectilePaint.source_images.is_empty(), "ordinary combat loaded or rasterized the high-resolution art source")
	_check(ProjectilePaint.player_kind(Color(0.24, 0.8, 1)) != ProjectilePaint.player_kind(Color(0.76, 0.96, 1)), "water and toothpaste lost their distinct silhouettes")
	_check(ProjectilePaint.player_kind(Color(0.27, 0.9, 0.67)) != ProjectilePaint.player_kind(Color(0.69, 0.72, 0.8)), "mouthwash and metal lost their distinct silhouettes")
	_check_world_heading()
	if failures == 0:
		print("Painted projectiles: all tiers/evolutions, collision anchors, heading and no runtime rasterization passed")
	finish(0 if failures == 0 else 1)

func _check_world_heading() -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	# Include mirrored/nonuniform arena transforms, not just an identity parent.
	parent.transform = Transform2D(0.43, Vector2(-1.2, 0.7), 0.15, Vector2(70, 30))
	var data := WeaponCatalog.by_id(&"halo")
	var shot := WeaponProjectile.new()
	parent.add_child(shot)
	for index in 8:
		var heading := Vector2.from_angle(index * TAU / 8.0)
		shot.launch(Vector2.ZERO, heading, 10, data)
		_check(shot.body_sprite.global_transform.x.normalized().dot(heading) > 0.99999, "player projectile faces away from its world-space flight direction")
		var enemy := AcidProjectile.new()
		parent.add_child(enemy)
		enemy.launch(Vector2.ZERO, heading, 100, 5, null)
		_check(enemy.body_sprite.global_transform.x.normalized().dot(heading) > 0.99999, "enemy projectile faces away from its world-space flight direction")
		enemy.free()
	# Orbit has a changing tangent while the saved attack direction remains intact.
	var additions: Array[Dictionary] = [{"id": "fire", "damage": 8.0}, {"id": "ice", "damage": 6.0}]
	shot.launch(Vector2.ZERO, Vector2.RIGHT, 10, data, null, false, 1, additions)
	shot.orbit_time = 0.5
	shot.orbit_center = Vector2(200, 200)
	for frame in 5:
		shot._physics_process(1.0 / 60.0)
		var tangent := Vector2.from_angle(shot.animation_time * 9.0).orthogonal()
		_check(shot.body_sprite.global_transform.x.normalized().dot(tangent) > 0.99999, "orbiting projectile does not follow the circle tangent")
		_check(shot.direction == Vector2.RIGHT, "visual orbit heading changed the saved combat direction")
	var saved := shot.save_state({})
	var restored := WeaponProjectile.new()
	parent.add_child(restored)
	restored.restore_state(saved, null, [])
	_check(restored.body_sprite.global_transform.x.normalized().dot(shot.body_sprite.global_transform.x.normalized()) > 0.99999, "resumed orbit lost its tangential heading")
	_check(restored.affixes.size() == 2 and restored.affixes[0].id == "fire" and restored.affixes[1].id == "ice" and restored.get_child_count() == 1, "painted/resumed projectile lost enchantments or added effect sprites")
	# Exercise the actual return movement, whose direction changes with Denti.
	var player := Player.new()
	var inventory := ItemInventory.new()
	# Only the return target is needed; keep full scene-dependent nodes inert.
	inventory.player = player
	shot.items = inventory
	shot.orbit_time = 0.0
	shot.orbit_finished = true
	shot.returning = true
	shot.global_position = Vector2(600, 500)
	player.global_position = Vector2(100, 300)
	shot.traveled = 0.0
	shot._physics_process(1.0 / 60.0)
	_check(shot.body_sprite.global_transform.x.normalized().dot(shot.direction) > 0.99999, "return flight did not face Denti")
	parent.free()
	inventory.free()
	player.free()
