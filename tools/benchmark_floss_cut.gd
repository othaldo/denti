extends "res://tools/benchmark_weapon_dps.gd"


func _run() -> void:
	_setup()
	var report := {"seconds": SECONDS, "hz": 60, "seed": 13579,
		"method": "Real attacks and bleeding; immortal anchored targets, no AI, armor, guard or knockback displacement. Distances scale with each weapon's range; close=45px, single/pack=65%, lane=25–85%, edge=100%. Not a win-rate test.", "weapons": [], "measurements": []}
	for id in [&"floss_garrote", &"floss_whip"]:
		var data := WeaponCatalog.by_id(id)
		report.weapons.append({"id": str(id), "name": data.display_name, "damage": data.base_damage,
			"interval": data.interval, "range": Array(data.range_tiers), "roots": data.hands, "knockback": data.knockback})
		for tier in range(1, 5):
			for scenario in ["close", "single", "pack", "lane", "edge"]:
				report.measurements.append(_measure(data, tier, scenario))
	var stage := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	var file := FileAccess.open("res://docs/balance_floss_cut_%s.json" % stage, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	_cleanup()
	print("PASS floss cut benchmark: " + stage)
	finish()
