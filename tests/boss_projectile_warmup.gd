extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	EnemyProjectileVisuals.textures.clear()
	var warmup: SubViewport = load("res://scripts/enemies/boss_projectile_warmup.gd").new()
	root.add_child(warmup)
	_check(warmup.size == Vector2i(8, 8) and warmup.world_2d != null and warmup.world_2d != root.world_2d and warmup.gui_disable_input, "warmup is not isolated from the game viewport/input")
	_check(warmup.render_target_update_mode == SubViewport.UPDATE_ONCE and warmup.get_child_count() == 4, "warmup did not schedule boss textures and charge primitives for rendering")
	var cache_size := EnemyProjectileVisuals.textures.size()
	_check(cache_size == 3, "warmup did not prepare the fan and emperor orb textures")
	paused = true
	for frame in 4:
		await process_frame
	_check(not is_instance_valid(warmup), "warmup remained allocated after menu rendering while paused")
	var projectiles := Node2D.new()
	root.add_child(projectiles)
	EnemyProjectilePatterns.fire_aimed_fan(projectiles, Vector2.ZERO, Vector2.RIGHT, 3, 240, 10, null)
	var fan: AcidProjectile = projectiles.get_child(0)
	_check(fan.body_sprite.texture == EnemyProjectileVisuals.body(EnemyProjectilePatterns.BOSS_COLOR, 9), "first boss fan did not use its prepared texture")
	_check(fan.hit_radius == 21 and fan.visual_radius == 9 and fan.damage == 10 and projectiles.get_child_count() == 3, "warmup changed fan attack geometry/damage/count")
	var emperor: EnemyData = load("res://data/enemies/cavity_emperor.tres")
	EnemyProjectilePatterns.fire_space_orb(projectiles, Vector2.ZERO, Vector2.RIGHT, 330, 12, emperor.boss_signature_orb_radius, null)
	var orb: AcidProjectile = projectiles.get_child(3)
	_check(orb.body_sprite.texture == EnemyProjectileVisuals.body(EnemyProjectilePatterns.SPACE_ORB_COLOR, emperor.boss_signature_orb_radius * 0.7) and orb.halo_sprite.texture == EnemyProjectileVisuals.halo(EnemyProjectilePatterns.SPACE_ORB_COLOR, emperor.boss_signature_orb_radius), "first emperor charge did not use its prepared body/halo")
	_check(orb.hit_radius == 50 and orb.visual_radius == 35 and orb.damage == 12 and is_equal_approx(orb.speed, 181.5), "warmup changed emperor attack geometry/damage/speed")
	_check(EnemyProjectileVisuals.textures.size() == cache_size, "first boss attacks generated new textures after warmup")
	projectiles.free()
	paused = false
	if failures.is_empty():
		print("Denti boss projectile warmup test passed")
	quit(0 if failures.is_empty() else 1)
