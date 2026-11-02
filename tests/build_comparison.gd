extends "res://tools/benchmark_build_comparison.gd"

var fixture := ""
var failures := 0


func _run() -> void:
	_check_budgets()
	_check_spawn_plans()
	fixture = "healing"
	var config: Dictionary = PROFILES.setup("ranged_single", 19, "enchanted")
	var healed := await sample_combat(config, "stationary", 13579, 1.5)
	_check(healed.healing > 0 and healed.leech_healing > 0, "Real weapon lifesteal was not measured")
	_check(is_equal_approx(healed.health_end, healed.health_start - healed.damage_taken + healed.healing), "Health accounting lost damage or healing")
	_check(healed.damage_dealt > 0 and not healed.weapon_damage.is_empty(), "Real attacks did not run")
	var repeated := await sample_combat(config, "stationary", 13579, 1.5)
	_check(healed == repeated, "Fixed seed and setup are not reproducible")
	fixture = "lethal"
	var lethal := await sample_combat(config, "stationary", 13579, 1.0)
	_check(lethal.outcome == "death" and lethal.health_end == 0, "Death was bypassed or healed away")
	_check(lethal.damage_taken == lethal.health_start, "Lethal damage includes overkill")
	_check(lethal.boss_ttk == null, "An unfinished boss must not receive a TTK")
	fixture = ""
	var moved := await sample_combat(PROFILES.setup("uv_floss", 4, "base"), "orbit", 13579, 1.0)
	_check(moved.distance_travelled > 100, "Orbit input did not move the real player")
	_check(moved.max_step_distance <= PlayerStats.BASE_MOVE_SPEED / 60.0 + 0.01, "Movement teleported or exceeded the player's speed")
	_check(moved.target_in_range_fraction >= 0 and moved.target_in_range_fraction <= 1)
	# This real overtime/pooled-projectile encounter exposed the probe's former
	# before-physics wave finish: queued bullets were recycled, then freed twice.
	var boss := await sample_combat(PROFILES.setup("uv_floss", 10, "shop"), "orbit", 112233)
	_check(boss.outcome == "boss_killed" and boss.boss_ttk != null, "Boss encounter/cleanup did not complete")
	_check(not root.get_node("GameSession").has_run(), "Comparison wrote a run save")
	print("PASS build comparison: matched budgets, independent spawn plans, deterministic real attacks, healing/death accounting and physical movement")
	finish(1 if failures else 0)


func _check_budgets() -> void:
	for wave_number in PROFILES.WAVES:
		for mode in PROFILES.MODES:
			var expected := -1
			for build: String in PROFILES.BUILDS:
				var config: Dictionary = PROFILES.setup(build, wave_number, mode)
				_check(config.roots == 6 and config.gold_unspent >= 0, "Preset exceeds its root/gold budget")
				if expected < 0: expected = config.upgrade_points
				_check(config.upgrade_points == expected, "Builds spent different upgrade-point budgets")
				var spent := 0
				for entry: Dictionary in config.equipment:
					var data := WeaponCatalog.by_id(StringName(entry.id))
					_check(entry.affixes.size() <= WeaponUpgrades.slots(entry.tier))
					for affix: Dictionary in entry.affixes:
						spent += WeaponUpgrades.level(affix) * data.hands
				_check(spent == expected, "Rejected upgrades were charged to a preset")
				_check(config.weapon_gold + config.item_gold + config.gold_unspent == config.gold_budget)


func _check_spawn_plans() -> void:
	var first: Dictionary = PROFILES.spawn_plan(19, 13579)
	for index in 1000: randf()
	var repeated: Dictionary = PROFILES.spawn_plan(19, 13579)
	_check(first.trace == repeated.trace, "Combat RNG consumption changed the spawn schedule")
	_check(first.digest != PROFILES.spawn_plan(19, 24680).digest)
	_check(first.events.size() > 100, "Late-wave spawning was not planned")
	var boss: Dictionary = PROFILES.spawn_plan(20, 13579)
	_check(boss.events[0].data.is_boss and boss.events[0].frame == 0)


func make_game(config: Dictionary):
	var game = super.make_game(config)
	if fixture == "healing":
		game.player.stats.health = 40
		game._create_enemy(WaveController.SUGAR, game.player.position + Vector2(100, 0))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_simulation_enabled(false)
		enemy.max_health = 100000
		enemy.health = enemy.max_health
	elif fixture == "lethal":
		game.player.stats.health = 1
		game.player.loadout.restore([])
		game._create_enemy(WaveController.PLAQUE, game.player.position)
	return game


func _check(condition: bool, message: String = "Build comparison invariant failed") -> void:
	if not condition:
		failures += 1
		push_error(message)
