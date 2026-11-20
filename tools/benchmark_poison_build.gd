extends "res://tools/benchmark_build_comparison.gd"
## Real automatic weapons and wave spawns, synthetic checkpoint equipment.
## No dash/hazard reactions: these pilots are diagnostic, not win-rate estimates.

var followed: WeakRef

func _run() -> void:
	var report := {"schema_version": 1, "hz": 60, "seed": 13579,
		"scope": "synthetic checkpoints, real waves and automatic targeting; no earned progression", "samples": []}
	for number in _arguments("waves", [4, 5, 19]):
		for id: String in ["turbo_drill", "magic_toothbrush"]:
			for package: String in ["poison", "depot", "relic"]:
				for movement: String in ["focus", "switch"]:
					var config: Dictionary = PROFILES.setup_equipment([id, id], id, int(number), "shop")
					config.mode = package
					config["poison_relic"] = package == "relic"
					if package != "poison":
						config.items.append("poison_depot")
						config.items.append("nerve_probe")
						config.item_gold += 16
						config.gold_unspent -= 16
					config.upgrade_points = 0
					for equipment: Dictionary in config.equipment:
						var weapon := WeaponCatalog.by_id(StringName(equipment.id))
						var affixes: Array[Dictionary] = []
						for rank in config.tier + 1:
							affixes = WeaponUpgrades.advance(affixes, &"poison", weapon, config.tier)
							config.upgrade_points += WeaponUpgrades.cost(weapon)
						equipment.affixes = affixes
					config.capsules = config.upgrade_points / WeaponUpgrades.POINTS_PER_CAPSULE
					followed = null
					var sample: Dictionary = await sample_combat(config, movement, 13579)
					sample["item_gold"] = config.item_gold
					sample["upgrade_points"] = config.upgrade_points
					report.samples.append(sample)
					print("poison probe: %s wave %d %s %s: %s, %.1f damage, %s" % [id, int(number), package, movement, sample.outcome, sample.damage_dealt, JSON.stringify(sample.enchantment_support)])
	var output := str(_arguments("output", ["res://.godot/poison_build_comparison.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	finish()

func make_game(config: Dictionary):
	var game = super.make_game(config)
	if config.get("poison_relic", false): game.relics.acquire(&"venom_fang")
	return game

func movement_direction(game, movement: String, elapsed: float) -> Vector2:
	var target := followed.get_ref() as Enemy if followed != null else null
	# Change approach only after an actual application. Weapon targeting itself
	# remains unchanged; movement must bring the desired enemy into reach.
	var switch_ready := movement == "switch" and is_instance_valid(target) and target.affix_effects.depot.target_lock > 0 and target.affix_effects.depot.target_lock <= 7.25
	if not is_instance_valid(target) or not target.is_targetable() or switch_ready:
		var candidate: Enemy
		var best := INF
		for enemy: Enemy in game.get_node("Enemies").get_children():
			if not enemy.is_targetable() or switch_ready and (enemy == target or enemy.affix_effects.depot.target_lock > 0): continue
			var distance: float = game.player.global_position.distance_squared_to(enemy.global_position)
			if distance < best:
				best = distance
				candidate = enemy
		if candidate != null:
			target = candidate
			followed = weakref(target)
	if not is_instance_valid(target): return super.movement_direction(game, "orbit", elapsed)
	var away: Vector2 = target.global_position.direction_to(game.player.global_position)
	var reach: float = game.player.loadout.equipped()[0].data.range_at_tier(game.player.loadout.equipped()[0].tier)
	var preferred := maxf(minf(reach * 0.65, 140), target.data.radius + 25)
	var desired: Vector2 = target.global_position + away * preferred
	return game.player.global_position.direction_to(desired) if game.player.global_position.distance_to(desired) > 5 else Vector2.ZERO
