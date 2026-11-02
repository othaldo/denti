extends "res://tools/benchmark_weapon_support.gd"

var failures := 0


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	_check(ROSTER.ids().size() == WeaponCatalog.ALL.size(), "roster omitted regular weapons")
	var builds := ROSTER.ids()
	builds.append_array(ROSTER.MIXES.keys())
	for wave_number in [4, 5, 19, 20]:
		for mode in ["base", "shop", "electric_shop"]:
			var expected_points := int(PROFILES.setup("uv_floss", wave_number, "shop" if mode == "electric_shop" else mode).upgrade_points)
			for build: String in builds:
				var config: Dictionary = ROSTER.setup(build, wave_number, mode)
				_check(config.roots == 6 and config.gold_unspent >= 0, "roster exceeds root/gold budget: " + build)
				_check(config.upgrade_points == expected_points, "roster upgrade budgets differ")
				var paid := 0
				for entry: Dictionary in config.equipment:
					var data := WeaponCatalog.by_id(StringName(entry.id))
					for affix: Dictionary in entry.affixes:
						paid += WeaponUpgrades.level(affix) * data.hands
						if mode == "electric_shop": _check(affix.id != "fire", "electric control retained fire")
				_check(paid == expected_points, "roster charged rejected upgrades")
	# Extraction preserves every original profile exactly.
	for build: String in PROFILES.BUILDS:
		_check(PROFILES.setup(build, 19, "shop") == PROFILES.setup_equipment(PROFILES.BUILDS[build], build, 19, "shop"), "original setup changed")
	for build in ["water_turbine", "support_turbine"]:
		var sample := await sample_combat(ROSTER.setup(build, 19, "electric_shop"), "orbit", 13579, 1.5)
		_check(sample.damage_dealt > 0 and sample.distance_travelled > 0, "turbine probe never attacked/moved: %s damage %.1f distance %.1f" % [build, sample.damage_dealt, sample.distance_travelled])
	var game = make_game(ROSTER.setup("water_turbine", 20, "base"))
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, game.player.position + Vector2(300, 0))
	_check(ROSTER.pursuit_direction(game).is_normalized(), "pursuit omitted boss-relative movement")
	var same_route := movement_direction(game, "pursuit", 0)
	game.player.loadout.restore(ROSTER.setup("support_damage", 20, "electric_shop").equipment)
	_check(movement_direction(game, "pursuit", 0).is_equal_approx(same_route), "support choice changed the controlled boss route")
	game.run_flow.enter(RunFlow.Phase.ENDED)
	game._clear_arena(false)
	await process_frame
	await process_frame
	game.queue_free()
	await process_frame
	print("PASS complete weapon roster: regular catalog, equal roots/gold/points, mixed supports, real turbine combat, electric ablation and boss pursuit")
	finish(1 if failures else 0)


func make_game(config: Dictionary):
	var game = super.make_game(config)
	# A nearby durable target makes the short smoke test independent of arrivals.
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(ORBIT_RADIUS.x + 100, 0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.max_health = 100000
	enemy.health = enemy.max_health
	return game
