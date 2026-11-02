extends "res://tools/benchmark_weapon_dps.gd"


func _run() -> void:
	_setup()
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string,
		"seconds": SECONDS, "hz": 60, "seed": 13579,
		"method": "Inherited live weapon DPS fixture: anchored immortal 50%-HP targets, default stats, no AI/armor/guard/displacement/items/affixes. Actual contact/projectiles/bleed/focus. Normal tiers I-IV, evolutions IV only. Not a combat success rate.",
		"weapons": [], "measurements": []}
	var catalog: Array[WeaponData] = WeaponCatalog.ALL.duplicate()
	for recipe in WeaponEvolutions.ALL: catalog.append(recipe.result)
	for data in catalog:
		var evolution := data not in WeaponCatalog.ALL
		report.weapons.append({"id": str(data.id), "name": data.display_name, "roots": data.hands,
			"evolution": evolution, "role": data.role, "stat": data.damage_stat, "stat_scaling": data.stat_scaling,
			"range_i": data.range_at_tier(1), "range_iv": data.range_at_tier(4),
			"knockback_i": data.knockback_at_tier(1), "knockback_iv": data.knockback_at_tier(4),
			"price": data.price, "wet_duration": data.wet_duration, "arc_degrees": data.arc_degrees})
		for tier in ([4] if evolution else [1, 2, 3, 4]):
			for scenario in SCENARIOS:
				if scenario == "edge" and not WeaponMotion.is_contact(data): continue
				report.measurements.append(_measure(data, tier, scenario))
		print("Measured " + data.display_name)
	var file := FileAccess.open("res://docs/balance_weapon_roster_dps.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write roster DPS")
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	_cleanup()
	finish()
