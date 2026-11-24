extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	EnemyProjectileVisuals.textures.clear()
	var warmup: SubViewport = load("res://scripts/enemies/boss_projectile_warmup.gd").new()
	root.add_child(warmup)
	check(warmup.size == Vector2i(8, 8) and warmup.world_2d != null and warmup.world_2d != root.world_2d and warmup.gui_disable_input, "warmup is not isolated from the game viewport/input")
	check(warmup.render_target_update_mode == SubViewport.UPDATE_ONCE and warmup.get_child_count() == EnemyProjectileVisuals.standard_specs().size() + CombatSpriteTextures.PREPARED.REGIONS.size() + BossProjectileWarmup.art_textures().size() + 11, "warmup did not schedule enemy/player/loot textures, art, ground/warning/attack atlases, HUD and charge primitives for rendering")
	check(warmup.has_node("GoblinRigWarmup") and warmup.get_node("GoblinRigWarmup").skeleton.get_bone_count() == 6 and LootGoblinRig.prepared_atlas.get_image().has_mipmaps(), "goblin joints and smooth atlas were omitted from warmup")
	check(warmup.has_node("EmperorRigWarmup") and warmup.get_node("EmperorRigWarmup").bones.size() == 8, "Emperor modular guard/core pipeline was omitted from warmup")
	check(warmup.has_node("CombatHUDWarmup") and warmup.get_node("CombatHUDWarmup").get_child_count() == 4, "life/stamina/level/boss graphics were omitted from the initial warmup")
	check(warmup.has_node("CloakRigWarmup") and warmup.get_node("CloakRigWarmup").skeleton.get_bone_count() == 12, "skeletal cloth pipeline was omitted from warmup")
	check(warmup.has_node("KingRigWarmup") and warmup.get_node("KingRigWarmup").reservoirs.size() == 2, "King reservoir shaders were omitted from warmup")
	var has_ground_atlas := false
	var has_attack_atlas := false
	for child in warmup.get_children():
		if child is Sprite2D and child.texture == GroundEffects.ATLAS:
			has_ground_atlas = true
		if child is Sprite2D and child.texture == AttackEffects.ATLAS:
			has_attack_atlas = true
	check(has_ground_atlas, "ground effect atlas was not drawn before combat")
	check(has_attack_atlas, "attack effect atlas was not drawn before combat")
	check(warmup.has_node("CombatFontWarmup") and warmup.get_node("CombatFontWarmup").text == "0123456789-+!", "combat number font was omitted from warmup")
	var cache_size := EnemyProjectileVisuals.textures.size()
	check(cache_size == EnemyProjectileVisuals.standard_specs().size(), "warmup did not prepare acid, status and orb textures")
	paused = true
	for frame in 4:
		await process_frame
	check(not is_instance_valid(warmup), "warmup remained allocated after menu rendering while paused")
	var projectiles := Node2D.new()
	root.add_child(projectiles)
	EnemyProjectilePatterns.fire_aimed_fan(projectiles, Vector2.ZERO, Vector2.RIGHT, 3, 240, 10, null)
	var fan: AcidProjectile = projectiles.get_child(0)
	check(fan.body_sprite.texture == EnemyProjectileVisuals.body(EnemyProjectilePatterns.BOSS_COLOR, 9), "first boss fan did not use its prepared texture")
	check(fan.hit_radius == 21 and fan.visual_radius == 9 and fan.damage == 10 and projectiles.get_child_count() == 3, "warmup changed fan attack geometry/damage/count")
	var emperor: EnemyData = load("res://data/enemies/cavity_emperor.tres")
	EnemyProjectilePatterns.fire_space_orb(projectiles, Vector2.ZERO, Vector2.RIGHT, 330, 12, emperor.boss_signature_orb_radius, null)
	var orb: AcidProjectile = projectiles.get_child(3)
	check(orb.body_sprite.texture == EnemyProjectileVisuals.body(EnemyProjectilePatterns.SPACE_ORB_COLOR, emperor.boss_signature_orb_radius * 0.7) and orb.halo_sprite.texture == EnemyProjectileVisuals.halo(EnemyProjectilePatterns.SPACE_ORB_COLOR, emperor.boss_signature_orb_radius), "first emperor charge did not use its prepared body/halo")
	check(orb.hit_radius == 50 and orb.visual_radius == 35 and orb.damage == 12 and is_equal_approx(orb.speed, 181.5), "warmup changed emperor attack geometry/damage/speed")
	check(EnemyProjectileVisuals.textures.size() == cache_size, "first boss attacks generated new textures after warmup")
	for kind in [DentiStatus.Type.POISON, DentiStatus.Type.BLEED]:
		var status: Array[Dictionary] = [{"kind": kind, "damage": 1.0, "duration": 2.0}]
		EnemyProjectilePatterns.fire_aimed_fan(projectiles, Vector2.ZERO, Vector2.RIGHT, 3, 240, 10, null, EnemyProjectilePatterns.ACID_COLOR, 3, status)
		EnemyProjectilePatterns.fire_space_orb(projectiles, Vector2.ZERO, Vector2.RIGHT, 120, 9, 34, null, status)
	check(EnemyProjectileVisuals.textures.size() == cache_size, "first poison/bleed attacks generated new textures after warmup")
	projectiles.free()
	paused = false
	if failures.is_empty():
		print("Denti boss projectile warmup test passed")
	finish_checks()
