extends "res://tools/benchmark_weapon_dps.gd"

func _run() -> void:
	_setup()
	game.player.stats.max_health = 1000000
	game.player.stats.crit_chance = 0
	var report := {"seconds": SECONDS, "hz": 60, "method": "Actual Mk-IV mirrors with rank-10 lifesteal, default offensive stats, no items, no incoming damage. Immortal anchored target, no armor/guard. Shared-clock baseline is emulated by giving each weapon the same proc owner; independent mode uses its real persisted UID. Not a survival or win-rate test.", "measurements": []}
	for count in [1, 3, 6]:
		for shared in [true, false]:
			for enemy in game.get_node("Enemies").get_children(): enemy.free()
			var data := WeaponCatalog.by_id(&"enamel_mirror")
			var affixes: Array[Dictionary] = []
			for rank in 10: affixes = WeaponUpgrades.advance(affixes, &"leech", data, 4)
			var entries: Array[Dictionary] = []
			for index in count: entries.append({"id": "enamel_mirror", "tier": 4, "affixes": affixes})
			game.player.loadout.restore(entries)
			var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
			for weapon in weapons:
				weapon.set_physics_process(false)
				if shared: weapon.instance_uid = "shared_clock_baseline"
			game.items.cooldowns.clear()
			game.player.stats.health = 1
			game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(200, 0))
			var enemy: Enemy = game.get_node("Enemies").get_child(-1)
			enemy.set_simulation_enabled(false)
			enemy.health = TARGET_HP * 0.5
			enemy.max_health = TARGET_HP
			enemy.damage_reduction = 0
			for frame in roundi(SECONDS / STEP):
				game.items._process(STEP)
				for weapon in weapons: weapon._physics_process(STEP)
			var healing: float = game.player.stats.health - 1
			report.measurements.append({"weapons": count, "clock": "shared_baseline" if shared else "per_weapon", "healing": snappedf(healing, 0.01), "hp_per_second": snappedf(healing / SECONDS, 0.01)})
	var file := FileAccess.open("res://docs/balance_sustain.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	for row in report.measurements: print(row.weapons, " weapons; ", row.clock, ": ", row.hp_per_second, " HP/s")
	_cleanup()
	finish()
