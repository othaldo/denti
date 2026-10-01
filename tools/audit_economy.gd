extends SceneTree

# Spawn-plan forecast, not a combat simulation: all requested spawns are counted.
const RUNS := 30
var wave: WaveController
var current: Dictionary = {}

func _initialize() -> void:
	var rows: Array[Dictionary] = []
	for number in range(1, 21):
		rows.append({"wave": number, "spawns": 0.0, "previous_gold": 0.0, "current_gold": 0.0, "current_xp": 0.0})
	for run in RUNS:
		seed(20261001 + run)
		wave = WaveController.new()
		wave.enemy_requested.connect(_count_enemy)
		wave.horde_requested.connect(_count_horde)
		wave.elite_requested.connect(_count_elite)
		for number in range(1, 21):
			current = {"spawns": 0.0, "previous_gold": 0.0, "current_gold": 0.0, "current_xp": 0.0}
			wave.start_next_wave()
			while wave.active:
				wave._process(1.0 / 60.0)
			for key in current:
				rows[number - 1][key] += float(current[key]) / RUNS
		wave.free()
	var prices: Array[Dictionary] = []
	var brush := ShopController.by_id(&"magic_toothbrush")
	for row in rows:
		var number := int(row.wave)
		row["brotato_price_brush_i"] = floori(brush.price * (1.0 + 0.1 * number) + number)
		var tier_iv_base := ShopController.weapon_offer(brush, 4).price
		row["brotato_price_brush_iv"] = floori(tier_iv_base * (1.0 + 0.1 * number) + number)
		row["brotato_price_item_base_5"] = floori(5.0 * (1.0 + 0.1 * number) + number)
	for offer in ShopController.CATALOG:
		prices.append({"id": str(offer.id), "kind": "item" if offer.weapon_data == null else "weapon", "tier": offer.rarity_tier, "base_price": offer.price})
	var report := {"method": "Normal difficulty; 30 seeded spawn plans at 60 Hz; expected drop values if every requested enemy dies during active combat. Includes elite escorts; excludes caps, combat, boss summons, items, chests, carryover and spending. XP unchanged. previous_gold is the immediately preceding independent-coin implementation, including its early bonus. current_gold uses the implemented EconomyRules.", "gold_rule": "Normal enemies: 100% base coin chance, values 1 (Plaque/Bacteria/Acid) or 2 (Sugar). Wave decay 100% through 4; then max(1-0.015*wave,0.50). Elites retain guaranteed 4 coins. No whole-wave Horde modifier, because Denti uses short bursts rather than Brotato Horde Waves.", "waves": rows, "catalog": prices}
	var output := FileAccess.open("res://docs/economy_audit.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	for row in rows:
		if int(row.wave) in [1, 2, 4, 5, 10, 15, 19, 20]:
			print("Wave %d: %.1f enemies; full-clear gold previous %.1f / current %.1f" % [row.wave, row.spawns, row.previous_gold, row.current_gold])
	quit(0)

func _count_horde(data: EnemyData, count: int) -> void:
	for member in count:
		_count_enemy(data)

func _count_elite(data: EnemyData) -> void:
	_count_enemy(data)
	if data.escort_data != null:
		_count_horde(data.escort_data, data.escort_count)

func _count_enemy(data: EnemyData) -> void:
	if data.is_boss:
		return
	current.spawns += 1.0
	var gate := 1.0 if data.is_elite else WaveController.loot_chance(wave.current_wave)
	var old_chance := 1.0
	if data == WaveController.PLAQUE:
		old_chance = 0.40
	elif data == WaveController.BACTERIA:
		old_chance = 0.45
	elif data == WaveController.ACID_SPITTER:
		old_chance = 0.50
	elif data == WaveController.SUGAR:
		old_chance = 0.65
	var early_bonus := 0.60 * clampf(float(4 - wave.current_wave) / 3.0, 0.0, 1.0)
	var previous_chance := 1.0 if data.is_elite else clampf(old_chance * (1.0 + early_bonus) * EconomyRules.gold_drop_factor(wave.current_wave), 0.0, 1.0)
	current.previous_gold += previous_chance * data.coin_drop
	current.current_xp += gate * data.xp_drop
	current.current_gold += EconomyRules.coin_chance(data, wave.current_wave) * data.coin_drop
