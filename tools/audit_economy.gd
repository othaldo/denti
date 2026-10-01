extends SceneTree

# Spawn-plan forecast, not a combat simulation: all requested spawns are counted.
const RUNS := 30
var wave: WaveController
var current: Dictionary = {}

func _initialize() -> void:
	var rows: Array[Dictionary] = []
	for number in range(1, 21):
		rows.append({"wave": number, "spawns": 0.0, "current_gold": 0.0, "candidate_gold": 0.0, "bounded_gold": 0.0, "current_xp": 0.0})
	for run in RUNS:
		seed(20261001 + run)
		wave = WaveController.new()
		wave.enemy_requested.connect(_count_enemy)
		wave.horde_requested.connect(_count_horde)
		wave.elite_requested.connect(_count_elite)
		for number in range(1, 21):
			current = {"spawns": 0.0, "current_gold": 0.0, "candidate_gold": 0.0, "bounded_gold": 0.0, "current_xp": 0.0}
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
	var report := {"method": "Normal difficulty; 30 seeded spawn plans at 60 Hz; expected drop values if every requested enemy dies during active combat. Includes elite escorts; excludes caps, combat, boss summons, items, chests, carryover and spending. Candidates affect gold only; XP unchanged. current_gold is the pre-change baseline; candidate_gold uses the implemented EconomyRules; bounded_gold is an alternative forecast.", "candidate": "Independent coin roll: Plaque 40%, Bacteria 45%, Acid 50%, Sugar 65%; elites unchanged. Gold decay 100% waves 1-4, then max(1-0.015*wave,0.70), no XP gate; implemented early coin-chance bonus +60/+40/+20 percent in waves 1/2/3.", "bounded_candidate": "Current expected gold per normal enemy times a multiplier: 1.8 through wave 4, linearly declining to 1.15 on wave 16; elites unchanged. Single independent gold roll can retain this expectation without sharing the XP gate.", "waves": rows, "catalog": prices}
	var output := FileAccess.open("res://docs/economy_audit.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	for row in rows:
		if int(row.wave) in [1, 2, 4, 5, 10, 15, 19, 20]:
			print("Wave %d: %.1f enemies; full-clear gold current %.1f / generous %.1f / bounded %.1f; at 60%% clear current %.1f / bounded %.1f" % [row.wave, row.spawns, row.current_gold, row.candidate_gold, row.bounded_gold, row.current_gold * 0.6, row.bounded_gold * 0.6])
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
	var old_chance := data.coin_drop_chance
	if data == WaveController.PLAQUE:
		old_chance = 0.22
	elif data == WaveController.BACTERIA:
		old_chance = 0.28
	elif data == WaveController.ACID_SPITTER:
		old_chance = 0.32
	elif data == WaveController.SUGAR:
		old_chance = 0.55
	current.current_gold += gate * old_chance * data.coin_drop
	current.current_xp += gate * data.xp_drop
	var boost := lerpf(1.80, 1.15, clampf(float(wave.current_wave - 4) / 12.0, 0.0, 1.0))
	current.bounded_gold += gate * old_chance * data.coin_drop * (1.0 if data.is_elite else boost)
	current.candidate_gold += EconomyRules.coin_chance(data, wave.current_wave) * data.coin_drop
