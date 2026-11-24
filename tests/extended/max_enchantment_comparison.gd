extends "res://tools/benchmark_build_max_enchantments.gd"


func _run() -> void:
	for wave_number in [19, 20]:
		for build: String in PROFILES.BUILDS:
			for mode in ["element10", "leech10", "both10", "bare_both10"]:
				for element in ["fire", "ice", "poison", "bleed", "electric", "wet"]:
					var config := max_setup(build, wave_number, mode, element)
					var paid := 0
					for entry: Dictionary in config.equipment:
						var roots := WeaponCatalog.by_id(StringName(entry.id)).hands
						check(entry.affixes.size() == (1 if mode in ["element10", "leech10"] else 2), "max profile lost an effect")
						for affix: Dictionary in entry.affixes:
							check(WeaponUpgrades.level(affix) == 10, "max profile is not rank ten")
							paid += WeaponUpgrades.level(affix) * roots
					check(paid == config.upgrade_points and paid == (60 if mode in ["element10", "leech10"] else 120), "max build investment differs per root")
					check(config.gold_unspent >= 0, "max build exceeds its gold ceiling")
					if mode == "bare_both10": check(config.items.is_empty(), "bare max build received items")
	print("PASS max-enchantment comparison: all six elements at rank ten, matched 60/120-point budgets and bare ablation")
	finish_checks()


