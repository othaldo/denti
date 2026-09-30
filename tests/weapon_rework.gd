extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_rework.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	var brush := WeaponCatalog.by_id(&"magic_toothbrush")
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	var whip := WeaponCatalog.by_id(&"floss_whip")
	var water := WeaponCatalog.by_id(&"water_jet")
	var crown := WeaponCatalog.by_id(&"crown_launcher")
	var mirror := WeaponCatalog.by_id(&"enamel_mirror")
	var scaler := WeaponCatalog.by_id(&"plaque_scaler")
	var mortar := WeaponCatalog.by_id(&"mouthwash_mortar")
	if brush.projectile_count_at_tier(1) != 1 or brush.projectile_count_at_tier(3) != 2 or brush.projectile_count_at_tier(4) != 3:
		_fail("brush projectile tiers were not loaded")
		return
	if not brush.stats_text(4).contains("3 Geschosse") or brush.estimated_dps(4, 18.0, 0.0, 0.65, 1.0) <= brush.damage_at_tier(4) / brush.interval_at_tier(4):
		_fail("brush tier traits were missing from shop information")
		return
	if whip.range_at_tier(4) != 140.0 or crown.pierce_at_tier(1) != 1 or crown.pierce_at_tier(4) != 3 or mortar.splash_at_tier(4) != 115.0:
		_fail("crowd-clear weapon tiers were not loaded")
		return
	if water.base_damage != 9.0 or water.knockback_at_tier(4) != 30.0 or scaler.base_damage != 12.0 or mirror.base_damage != 22.0:
		_fail("single-target balance values were not loaded")
		return
	if not is_equal_approx(brush.damage_at_tier(4), 36.0) or not is_equal_approx(mortar.damage_at_tier(4), 61.5):
		_fail("weapon-specific damage tiers were not applied")
		return
	var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	boss.configure(WaveController.BOSS, game.player)
	if not is_equal_approx(drill.damage_against(boss, 100.0, 4), 140.0):
		_fail("drill boss bonus did not scale with tier")
		return
	boss.free()
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(180.0, 0.0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_physics_process(false)
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 3}])
	game.player.loadout.equipped()[0]._physics_process(0.016)
	if game.get_node("Projectiles").get_child_count() != 2:
		_fail("tier III brush did not fire two projectiles")
		return
	for projectile in game.get_node("Projectiles").get_children():
		projectile.free()
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}])
	game.player.loadout.equipped()[0]._physics_process(0.016)
	if game.get_node("Projectiles").get_child_count() != 3:
		_fail("tier IV brush did not fire three projectiles")
		return
	session.clear_run()
	print("Denti weapon rework test passed")
	quit(0)


func _fail(message: String) -> void:
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
