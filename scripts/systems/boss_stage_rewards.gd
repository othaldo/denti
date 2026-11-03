class_name BossStageRewards
extends RefCounted
## A wave owns one budget, including double bosses and combat-time XP fragments.

const PROFILES: Array[BossStageRewardData] = [
	preload("res://data/encounters/boss_rewards_count.tres"),
	preload("res://data/encounters/boss_rewards_prince.tres"),
	preload("res://data/encounters/boss_rewards_king.tres"),
	preload("res://data/encounters/boss_rewards_emperor.tres"),
]
var phase_mask := 0
var xp_released := 0
var paid := false
var legacy_credit := false

static func profile(wave_number: int) -> BossStageRewardData:
	return PROFILES[clampi(wave_number / 5 - 1, 0, 3)]

func release_phase(game, at: Vector2, phase: int) -> void:
	if paid or legacy_credit or not WaveController.is_boss_wave(game.wave.current_wave): return
	var bit := 1 << clampi(phase - 1, 0, 1)
	if phase_mask & bit: return
	phase_mask |= bit
	var budget := profile(game.wave.current_wave)
	var amount := roundi(budget.xp * budget.phase_xp_fraction)
	xp_released += amount
	game._spawn_loot(at, &"xp", amount, &"", {"source": "boss_stage"})

func deliver(game, at: Vector2) -> void:
	if paid: return
	paid = true
	var budget := profile(game.wave.current_wave)
	var credit := {"xp": 0, "coins": 0, "capsules": 0}
	if legacy_credit:
		# Old boss saves may already contain trash earnings. Keep those pickups,
		# and only top up the missing portion of the new shared stage budget.
		credit.xp = game.telemetry.wave_xp
		credit.coins = game.telemetry.wave_coins
		credit.capsules = game.telemetry.wave_chests_found
		for drop: Loot in game.get_node("Loot").get_children():
			if drop.is_queued_for_deletion(): continue
			if drop.kind == &"xp": credit.xp += drop.amount
			elif drop.kind == &"coin": credit.coins += drop.amount
			else: credit.capsules += 1
	var remaining_xp := maxi(budget.xp - xp_released - credit.xp, 0)
	while remaining_xp > 0:
		var amount := mini(remaining_xp, 8)
		game._spawn_loot(at + Vector2(randf_range(-45, 45), randf_range(-35, 35)), &"xp", amount, &"", {"source": "boss_stage"})
		remaining_xp -= amount
	# Roll normal denominations separately: Goldsonde/Goldextraktor keep their
	# drop semantics; pickup/XP modifiers still run exactly once when collected.
	var remaining_coins := maxi(budget.coins - credit.coins, 0)
	var rich_budget := floori(remaining_coins * budget.rich_coin_fraction)
	while remaining_coins > 0:
		var amount := 2 if rich_budget >= 2 else 1
		game._spawn_loot(at + Vector2(randf_range(-55, 55), randf_range(-40, 40)), &"coin", game.items.coin_drop_value(amount), &"", {"source": "boss_stage"})
		remaining_coins -= amount
		if amount == 2: rich_budget -= 2
	# The existing end-of-wave luck bonus still resolves once after collection.
	var count := maxi(budget.capsules - credit.capsules, 0)
	for index in count:
		var capsule := WeaponUpgrades.capsule(game.wave.current_wave, false)
		game._spawn_loot(at + Vector2((index - (count - 1) * 0.5) * 40, -45), &"chest", int(capsule.scrap_coins), WeaponAffixes.CHEST_ID, capsule)

func save_data() -> Dictionary:
	return {"version": 1, "phase_mask": phase_mask, "xp_released": xp_released, "paid": paid, "legacy_credit": legacy_credit}

func restore(saved: Dictionary) -> void:
	phase_mask = clampi(int(saved.get("phase_mask", 0)), 0, 3)
	xp_released = clampi(int(saved.get("xp_released", 0)), 0, PROFILES[-1].xp)
	paid = bool(saved.get("paid", false))
	legacy_credit = bool(saved.get("legacy_credit", not saved.has("version")))

