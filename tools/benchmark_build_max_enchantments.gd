extends "res://tools/benchmark_build_comparison.gd"
## Separate element/sustain ablations after the reported max-element/max-leech run.


func _run() -> void:
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string,
		"hz": 60, "difficulty": "normal", "controller": "max_enchantments", "setups": {}, "samples": []}
	for wave_value in _arguments("waves", [19, 20]):
		var number := int(wave_value)
		if number not in [19, 20]:
			push_error("Max-enchantment checkpoints are waves 19 and 20")
			finish(1)
			return
		for build_value in _arguments("builds", PROFILES.BUILDS.keys()):
			var build := str(build_value)
			for mode_value in _arguments("modes", ["element10", "leech10", "both10", "bare_both10"]):
				var mode := str(mode_value)
				if not PROFILES.BUILDS.has(build) or mode not in ["element10", "leech10", "both10", "bare_both10"]:
					push_error("Unknown max-enchantment build/mode")
					finish(1)
					return
				if mode == "bare_both10" and build != "uv_floss": continue
				for element_value in _arguments("elements", ["fire", "ice", "poison", "bleed", "electric", "wet"]):
					var element := str(element_value)
					if element not in ["fire", "ice", "poison", "bleed", "electric", "wet"]:
						push_error("Unknown element: " + element)
						finish(1)
						return
					# All roles get the same fire ablation; extra elements isolate
					# the reported UV/floss build without expanding to a huge grid.
					if element != "fire" and (mode != "both10" or build != "uv_floss"): continue
					var config := max_setup(build, number, mode, element)
					var key := "%d/%s/%s" % [number, build, config.mode]
					report.setups[key] = config
					for movement_value in _arguments("movements", PROFILES.MOVEMENTS):
						var movement := str(movement_value)
						if element != "fire" and movement != "orbit": continue
						for seed_value in _arguments("seeds", PROFILES.SEEDS):
							var sample := await sample_combat(config, movement, int(seed_value))
							if config.upgrade_points != (60 if mode in ["element10", "leech10"] else 120):
								push_error("Invalid max-enchantment investment")
								finish(1)
								return
							sample["setup"] = key
							report.samples.append(sample)
							print("%s %s seed %d: %s %.1fs; HP %.1f; taken %.1f; healed %.1f" % [key, movement, int(seed_value), sample.outcome, sample.seconds, sample.health_end, sample.damage_taken, sample.healing])
	var output := str(_arguments("output", ["res://docs/balance_build_max_enchantments.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write max-enchantment report: " + output)
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	finish()


func max_setup(build: String, wave_number: int, mode: String, element: String) -> Dictionary:
	var config: Dictionary = PROFILES.setup(build, wave_number, "base" if mode == "bare_both10" else "shop")
	config["mode"] = mode + "_" + element
	config["upgrade_points"] = 0
	for entry: Dictionary in config.equipment:
		var data := WeaponCatalog.by_id(StringName(entry.id))
		var affixes: Array[Dictionary] = []
		var kinds: Array[StringName] = []
		if mode != "leech10": kinds.append(StringName(element))
		if mode != "element10": kinds.append(&"leech")
		for kind in kinds:
			for rank in 10:
				affixes = WeaponUpgrades.advance(affixes, kind, data, int(config.tier))
				config.upgrade_points += WeaponUpgrades.cost(data)
		entry["affixes"] = affixes
	config["capsules"] = int(config.upgrade_points) / WeaponUpgrades.POINTS_PER_CAPSULE
	return config
