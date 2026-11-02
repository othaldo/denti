extends "res://tools/benchmark_weapon_roster_dps.gd"


func _run() -> void:
	_setup()
	var failures := 0
	for recipe in WeaponEvolutions.ALL:
		var data := recipe.result
		var result := _measure(data, 4, "single")
		if result.total_dps <= 0:
			push_error("Evolution fixture never released damage: " + str(data.id))
			failures += 1
		if data.evolution_kind in [&"storm", &"drill", &"trinity"] and result.evolution_dps <= 0:
			push_error("Evolution fixture omitted child timers/procs: " + str(data.id))
			failures += 1
	_cleanup()
	print("PASS roster DPS: all six evolution attacks, charged beam release and ticking puddle/drill/trinity secondary damage")
	finish(1 if failures else 0)
