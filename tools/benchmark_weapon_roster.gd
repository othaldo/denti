extends "res://tools/benchmark_build_comparison.gd"

const ROSTER = preload("res://tools/balance/weapon_roster_profiles.gd")


func _run() -> void:
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string,
		"hz": 60, "difficulty": "normal", "controller": "weapon_roster", "setups": {}, "samples": []}
	for wave_value in _arguments("waves", [4, 5, 19, 20]):
		var number := int(wave_value)
		for build_value in _arguments("builds", ROSTER.ids()):
			var build := str(build_value)
			for mode_value in _arguments("modes", ["base", "shop"]):
				var mode := str(mode_value)
				if (build not in ROSTER.ids() and not ROSTER.MIXES.has(build)) or mode not in ["base", "enchanted", "shop", "electric_shop"]:
					push_error("Unknown roster build/mode")
					finish(1)
					return
				var config: Dictionary = ROSTER.setup(build, number, mode)
				var key := "%d/%s/%s" % [number, build, mode]
				report.setups[key] = config
				for movement_value in _arguments("movements", ["pursuit" if WaveController.is_boss_wave(number) else "orbit"]):
					var movement := str(movement_value)
					if movement not in ["orbit", "stationary", "pursuit"]:
						push_error("Unknown roster movement")
						finish(1)
						return
					for seed_value in _arguments("seeds", PROFILES.SEEDS):
						var sample := await sample_combat(config, movement, int(seed_value))
						sample["setup"] = key
						report.samples.append(sample)
						print("%s %s seed %d: %s %.1fs; HP %.1f; taken %.1f; healed %.1f" % [key, movement, int(seed_value), sample.outcome, sample.seconds, sample.health_end, sample.damage_taken, sample.healing])
	var output := str(_arguments("output", ["res://docs/balance_weapon_roster_combat.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write roster report: " + output)
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	finish()


func movement_direction(game, movement: String, elapsed: float) -> Vector2:
	return ROSTER.pursuit_direction(game) if movement == "pursuit" else super.movement_direction(game, movement, elapsed)
