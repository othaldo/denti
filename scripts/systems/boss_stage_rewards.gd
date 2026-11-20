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
## Fixed for the stage at its first payout; -1 = not yet decided.
var xp_budget := -1
var paid := false
var legacy_credit := false

static func profile(wave_number: int) -> BossStageRewardData:
	return PROFILES[clampi(wave_number / 5 - 1, 0, 3)]

## XP that brings the player exactly `levels` level-ups from the current state.
static func xp_for_levels(game, levels: int) -> int:
	if levels <= 0: return 0
	var total := maxi(game.xp_goal - game.xp, 1)
	var next: int = game.level
	for step in levels - 1:
		next += 1
		total += game.xp_goal_for_level(next)
	return total

func stage_xp(game) -> int:
	if xp_budget < 0:
		var budget := profile(game.wave.current_wave)
		xp_budget = xp_for_levels(game, budget.levels) if budget.levels > 0 else budget.xp
	return xp_budget

func release_phase(game, at: Vector2, phase: int) -> void:
	if paid or legacy_credit or not WaveController.is_boss_wave(game.wave.current_wave): return
	var bit := 1 << clampi(phase - 1, 0, 1)
	if phase_mask & bit: return
	phase_mask |= bit
	var budget := profile(game.wave.current_wave)
	var amount := roundi(stage_xp(game) * budget.phase_xp_fraction)
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
	var remaining_xp := maxi(stage_xp(game) - xp_released - credit.xp, 0)
	while remaining_xp > 0:
		var amount := mini(remaining_xp, maxi(8, ceili(stage_xp(game) / 12.0)))
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
	return {"version": 1, "phase_mask": phase_mask, "xp_released": xp_released, "xp_budget": xp_budget, "paid": paid, "legacy_credit": legacy_credit}

func restore(saved: Dictionary) -> void:
	phase_mask = clampi(int(saved.get("phase_mask", 0)), 0, 3)
	xp_budget = clampi(int(saved.get("xp_budget", -1)), -1, 100000)
	xp_released = clampi(int(saved.get("xp_released", 0)), 0, maxi(xp_budget, PROFILES[-1].xp))
	paid = bool(saved.get("paid", false))
	legacy_credit = bool(saved.get("legacy_credit", not saved.has("version")))

