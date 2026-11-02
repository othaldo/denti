extends "res://tools/benchmark_build_comparison.gd"
## Control experiment: actively seek the boss instead of circling the arena.


func _run() -> void:
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string,
		"hz": 60, "difficulty": "normal", "controller": "boss_pursuit", "setups": {}, "samples": []}
	for wave_value in _arguments("waves", [5, 10, 15, 20]):
		var number := int(wave_value)
		for build_value in _arguments("builds", PROFILES.BUILDS.keys()):
			var build := str(build_value)
			for mode_value in _arguments("modes", ["shop"]):
				var mode := str(mode_value)
				if not PROFILES.BUILDS.has(build) or mode not in PROFILES.MODES:
					push_error("Unknown pursuit build/mode")
					finish(1)
					return
				var config: Dictionary = PROFILES.setup(build, number, mode)
				var key := "%d/%s/%s" % [number, build, mode]
				report.setups[key] = config
				for seed_value in _arguments("seeds", PROFILES.SEEDS):
					var sample := await sample_combat(config, "pursuit", int(seed_value))
					sample["setup"] = key
					report.samples.append(sample)
					print("%s pursuit seed %d: %s %.1fs; HP %.1f" % [key, int(seed_value), sample.outcome, sample.seconds, sample.health_end])
	var output := str(_arguments("output", ["res://docs/balance_build_pursuit.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write pursuit report: " + output)
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	finish()


func movement_direction(game, _movement: String, _elapsed: float) -> Vector2:
	var target: Enemy = game.boss if is_instance_valid(game.boss) and game.boss.health > 0 else null
	if target == null: return Vector2.ZERO
	var reach := INF
	for weapon: WeaponInstance in game.player.loadout.equipped():
		reach = minf(reach, weapon.data.range_at_tier(weapon.tier))
	if not is_finite(reach): return Vector2.ZERO
	var offset: Vector2 = target.global_position - game.player.global_position
	var inward := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	# Same policy for every build, adjusted to its shortest weapon's range.
	# No reaction to projectiles, telegraphs or enemy attack phases; no dash.
	# Weapon reach is measured to the target's body, as in acquisition/contact.
	# Omitting the boss radius steers short weapons into unavoidable body damage.
	var radial := clampf((offset.length() - target.data.radius - reach * 0.75) / 100.0, -1.0, 1.0)
	return (inward * radial + inward.orthogonal() * 0.65).normalized()
