extends "res://tests/support/test_runtime.gd"
## Supply forecast, not a combat bot: sampled kills from real spawn plans.
const TRIALS := 30
const SEED := 20261031
var game: Node2D
var spawns: Array[EnemyData] = []

func _initialize() -> void: call_deferred("_run")

func _record(data: EnemyData, count: int = 1) -> void:
	if data.is_boss: return
	for index in count: spawns.append(data)

func _elite(data: EnemyData) -> void:
	_record(data)
	if data.escort_data != null: _record(data.escort_data, data.escort_count)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://ascension_supply_forecast.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	var rows: Array[Dictionary] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var buckets: Array[Array] = [[], [], []]
		for trial in TRIALS:
			seed(SEED + trial)
			var wave := WaveController.new()
			wave.difficulty_id = difficulty.id
			wave.enemy_requested.connect(_record)
			wave.horde_requested.connect(_record)
			wave.elite_requested.connect(_elite)
			var plan: Array[Array] = []
			for number in range(1, 21):
				spawns = []
				wave.start_next_wave()
				while wave.active: wave._process(1.0 / 60)
				plan.append(spawns.duplicate())
			wave.free()
			for index in 3:
				buckets[index].append(_sample(plan, difficulty, [0.25, 0.5, 0.75][index], SEED + trial * 19 + index))
		for index in 3:
			var results: Array = buckets[index]
			var row := {"difficulty": str(difficulty.id), "kill_fraction": [0.25, 0.5, 0.75][index], "runs": TRIALS, "unspent_points_at_10": 0.0, "unspent_points_at_20": 0.0, "mk_iv_by_20": 0, "mk_v_affordable_by_20": 0, "mk_iv_median_wave": 0, "mk_v_median_wave": 0}
			var iv: Array[int] = []
			var v: Array[int] = []
			for result: Dictionary in results:
				row.unspent_points_at_10 += result.points10 / float(TRIALS)
				row.unspent_points_at_20 += result.points / float(TRIALS)
				if result.iv > 0: iv.append(result.iv)
				if result.v > 0: v.append(result.v)
			iv.sort(); v.sort()
			row.mk_iv_by_20 = iv.size()
			row.mk_v_affordable_by_20 = v.size()
			if not iv.is_empty(): row.mk_iv_median_wave = iv[iv.size() / 2]
			if not v.is_empty(): row.mk_v_median_wave = v[v.size() / 2]
			rows.append(row)
			print(JSON.stringify(row))
	var report := {"seed": SEED, "trials_per_scenario": TRIALS,
		"limits": "Spawn-plan forecast, not measured play. 25/50/75% sampled kills. No luck, items, gold carriers, goblin or overtime. Ordinary capsules only. All points saved. Shop focuses only the two-root starting brush, buys matching copies and fuses, at most one paid reroll/wave; no other purchases. Affordability includes current gold and real shop prices. Successful-run medians exclude runs that never reach the target.", "rows": rows}
	var file := FileAccess.open("res://docs/weapon_ascension_access.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	session.clear_run()
	finish()

func _sample(plan: Array[Array], difficulty: DifficultyData, fraction: float, sample_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = sample_seed
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "magic_toothbrush", "tier": 1}])
	game.shop.rng.seed = sample_seed
	var coins := 0
	var points := 0
	var result := {"iv": 0, "v": 0, "points10": 0, "points": 0}
	for index in plan.size():
		var number := index + 1
		var capsules := 0
		for data: EnemyData in plan[index]:
			if rng.randf() >= fraction: continue
			if capsules < ChestRewards.MAX_RANDOM_CHESTS_PER_WAVE and rng.randf() < ChestRewards.drop_chance(0, data.is_elite): capsules += 1
			if rng.randf() < EconomyRules.coin_chance(data, number, difficulty.reward_chance_multiplier): coins += data.coin_drop
		points += capsules * WeaponUpgrades.POINTS_PER_CAPSULE
		if number == 10: result.points10 = points
		if result.iv == 0:
			game.shop.open_shop(number, 0, loadout)
			for roll in 2:
				for offer in game.shop.offers:
					if offer == null or offer.id != &"magic_toothbrush" or offer.price > coins: continue
					if loadout.acquire(offer.weapon_data, offer.weapon_tier, offer.price): coins -= offer.price
					var merged := true
					while merged:
						merged = false
						for slot in loadout.equipped().size():
							if loadout.can_merge(slot): loadout.merge(slot); merged = true; break
				if loadout.equipped().any(func(weapon: WeaponInstance) -> bool: return weapon.tier == 4): result.iv = number; break
				if roll == 0 and coins >= game.shop.reroll_cost:
					coins -= game.shop.reroll_cost
					game.shop.reroll(number, 0, loadout)
				else: break
		if result.iv > 0 and result.v == 0:
			var price := WeaponAscension.quote(WeaponCatalog.by_id(&"magic_toothbrush"), number)
			if points >= int(price.cost) and coins >= int(price.coins): result.v = number
	result.points = points
	return result
