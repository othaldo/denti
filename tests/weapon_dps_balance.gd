extends "res://tools/benchmark_weapon_dps.gd"


func _run() -> void:
	_setup()
	var brush := WeaponCatalog.by_id(&"magic_toothbrush")
	var previous: Dictionary = {}
	for tier in range(1, 5):
		var reference := float(_measure(brush, tier, "single").dps_per_root)
		for data in WeaponCatalog.ALL:
			if data.damage_stat != "melee":
				continue
			var result := _measure(data, tier, "single")
			var dps := float(result.dps_per_root)
			# Focused contact damage must compensate for lost range/uptime.
			if data.attack_animation == "floss_cut":
				# Anchored floss is a piercing line, paid for by hitting successive targets.
				var lane := _measure(data, tier, "lane")
				check(float(lane.dps_per_root) >= reference * 2.0, "%s tier %d lacks piercing-line payoff" % [data.id, tier])
			elif data.attack_mode in [&"melee", &"thrust"]:
				check(dps >= reference * 1.25, "%s tier %d lacks melee risk premium" % [data.id, tier])
			else:
				var pack := _measure(data, tier, "pack")
				check(float(pack.dps_per_root) >= reference * 2.0, "%s tier %d lacks crowd-clear payoff" % [data.id, tier])
			if previous.has(data.id):
				check(dps > float(previous[data.id]) * 1.25, "%s tier %d has a weak fusion step" % [data.id, tier])
			previous[data.id] = dps
	# Existing evolution upgrades inherit the improved direct weapon chassis.
	for recipe in WeaponEvolutions.ALL:
		var base := WeaponCatalog.by_id(recipe.base_weapon)
		check(recipe.result.damage_at_tier(4) >= base.damage_at_tier(4), "evolution loses base damage: " + str(recipe.id))
		check(recipe.result.interval_at_tier(4) <= base.interval_at_tier(4), "evolution loses base cadence: " + str(recipe.id))
	_cleanup()
	if failures.is_empty():
		print("PASS weapon_dps_balance: live tier I-IV contact throughput, risk premium, AoE payoff and evolution chassis")
	finish_checks()
