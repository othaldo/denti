extends RefCounted
## Synthetic checkpoints with explicit, shared gold and upgrade-point ceilings.

const STEP := 1.0 / 60.0
const BUILDS := {
	"uv_floss": ["uv_lamp", "uv_lamp", "floss_garrote"],
	"melee_single": ["turbo_drill", "turbo_drill", "turbo_drill", "turbo_drill", "turbo_drill", "turbo_drill"],
	"melee_area": ["interdental_brush", "interdental_brush", "interdental_brush", "interdental_brush", "interdental_brush", "interdental_brush"],
	"ranged_single": ["enamel_mirror", "enamel_mirror", "enamel_mirror", "enamel_mirror", "enamel_mirror", "enamel_mirror"],
}
const WAVES := [4, 5, 9, 10, 14, 15, 19, 20]
const MODES := ["base", "enchanted", "shop"]
const MOVEMENTS := ["stationary", "orbit"]
const SEEDS := [13579, 24680, 112233]
const GOLD := [250, 700, 1300, 2200]
const RANKS := [
	{"fire": 2}, {"fire": 3, "leech": 2},
	{"fire": 4, "leech": 2, "tempo": 2}, {"fire": 6, "leech": 3, "tempo": 3},
]
const ITEM_CYCLE := ["health_1", "armor_2", "damage_1", "regen_1", "tempo_2", "xp_heal_1"]
const ITEM_COUNTS := [2, 8, 16, 24]
const SHOP_ROLL := {"quality": 2, "damage": 1.12, "interval": 0.95, "range": 1.05, "crit": 0.04}


static func stage(wave_number: int) -> int:
	return clampi((wave_number + 1) / 5, 1, 4)


static func setup(build: String, wave_number: int, mode: String) -> Dictionary:
	return setup_equipment(BUILDS[build], build, wave_number, mode)


static func setup_equipment(ids: Array, build: String, wave_number: int, mode: String) -> Dictionary:
	var tier := stage(wave_number)
	var equipment: Array[Dictionary] = []
	var roots := 0
	var melee_roots := 0
	var weapon_gold := 0
	var points := 0
	for id: String in ids:
		var data := WeaponCatalog.by_id(StringName(id))
		roots += data.hands
		if data.damage_stat == "melee": melee_roots += data.hands
		var offer := ShopController.weapon_offer(ShopController.by_id(StringName(id)), tier)
		var price := EconomyRules.shop_price(offer.price, wave_number - 1)
		weapon_gold += price
		var affixes: Array[Dictionary] = []
		if mode != "base":
			for effect: String in RANKS[tier - 1]:
				for rank in int(RANKS[tier - 1][effect]):
					affixes = WeaponUpgrades.advance(affixes, StringName(effect), data, tier)
					points += WeaponUpgrades.cost(data)
		equipment.append({"id": id, "tier": tier, "uid": "probe_%d" % equipment.size(),
			"invested_coins": price, "affixes": affixes, "affix_slots": tier,
			"rolls": SHOP_ROLL.duplicate() if mode == "shop" else {}})
	var item_ids: Array = []
	if mode == "shop":
		for index in ITEM_COUNTS[tier - 1]: item_ids.append(ITEM_CYCLE[index % ITEM_CYCLE.size()])
	var item_gold := 0
	for id: String in item_ids:
		item_gold += EconomyRules.shop_price(ItemCatalog.by_id(StringName(id)).price, wave_number - 1)
	# A shared number of flat-stat choices, split by the roots using either stat.
	var stats := {"max_health": 100.0 + tier * 15.0, "damage_bonus": tier * 10.0,
		"attack_speed": tier * 10.0, "armor": tier * 3.0, "crit_chance": 0.05 + tier * 0.025,
		"melee_damage": tier * 4.0 * melee_roots / roots,
		"ranged_damage": tier * 4.0 * (roots - melee_roots) / roots}
	return {"build": build, "mode": mode, "wave": wave_number, "tier": tier, "roots": roots,
		"equipment": equipment, "items": item_ids, "stats": stats,
		"gold_budget": GOLD[tier - 1], "weapon_gold": weapon_gold, "item_gold": item_gold,
		"gold_unspent": GOLD[tier - 1] - weapon_gold - item_gold,
		"upgrade_points": points, "capsules": points / WeaponUpgrades.POINTS_PER_CAPSULE}


static func spawn_plan(wave_number: int, sample_seed: int, difficulty_id: StringName = &"normal", context: Dictionary = {}) -> Dictionary:
	# Build the actual wave's requests before combat can consume random numbers.
	seed(sample_seed)
	var planner := WaveController.new()
	planner.current_wave = wave_number - 1
	planner.difficulty_id = difficulty_id
	if context.has("horde_waves"):
		planner.horde_waves.assign(context.horde_waves)
		planner.current_profile_id = StringName(str(context.current_profile))
		planner.next_profile_id = StringName(str(context.next_profile))
	else: planner.plan_hordes()
	var events: Array[Dictionary] = []
	var clock := {"frame": 0}
	planner.enemy_requested.connect(func(data: EnemyData): events.append({"frame": clock.frame, "kind": "enemy", "data": data, "count": 1}))
	planner.boss_requested.connect(func(data: EnemyData): events.append({"frame": clock.frame, "kind": "enemy", "data": data, "count": 1}))
	planner.horde_requested.connect(func(data: EnemyData, count: int): events.append({"frame": clock.frame, "kind": "horde", "data": data, "count": count}))
	planner.elite_requested.connect(func(data: EnemyData): events.append({"frame": clock.frame, "kind": "elite", "data": data, "count": 1}))
	planner.loot_goblin_requested.connect(func(): events.append({"frame": clock.frame, "kind": "goblin", "count": 1}))
	planner.start_next_wave()
	# Frame zero includes the first normal spawn, as in the real wave controller.
	while planner.active and not WaveController.is_boss_wave(wave_number):
		planner._process(STEP)
		clock.frame += 1
	var trace: Array = []
	for event in events:
		trace.append([event.frame, event.kind, event.data.resource_path if event.has("data") else "", event.count])
	var result := {"events": events, "trace": trace, "digest": JSON.stringify(trace).sha256_text(),
		"profile": str(planner.current_profile_id), "duration": planner.duration,
		"planner_state": {"horde_waves": planner.horde_waves.duplicate(), "current_profile": str(planner.current_profile_id), "next_profile": str(planner.next_profile_id)}}
	planner.free()
	return result
