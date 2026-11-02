extends "res://tools/benchmark_earned_progression.gd"


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var normal: Dictionary = PROFILES.spawn_plan(4, 13579)
	_check(normal.trace == PROFILES.spawn_plan(4, 13579, &"normal").trace, "adding difficulty changed the default spawn plan")
	var hell: Dictionary = PROFILES.spawn_plan(4, 13579, &"hell")
	_check(hell.events.size() > normal.events.size(), "Hell reused Normal's density")
	_check(hell.events.any(func(event: Dictionary): return event.kind == "elite"), "Hell opening omitted its early elites")
	var run := await sample_run("turbo_drill", &"hell", "hunt", 13579, 2)
	_check(run.waves.size() == 2 and run.outcome == "wave_complete", "earned fixture did not complete its two real waves")
	var start: Dictionary = run.waves[0].start
	_check(start.coins == 0 and start.level == 1 and start.equipment.size() == 1 and start.equipment[0].tier == 1, "opening received fabricated progression")
	var first: Dictionary = run.waves[0]
	var second: Dictionary = run.waves[1]
	_check(first.after_rewards.coins == first.all_loot.coins_collected and first.after_rewards.gold_earned > 0, "loot sweep lost earned gold")
	_check(first.after_rewards.xp_earned == first.all_loot.xp_collected and first.after_rewards.level > 1, "loot sweep/reward queue lost XP levels")
	_check(first.after_shop.coins >= 0 and first.after_shop.coins < first.after_rewards.coins, "shop did not pay for its actual purchases/rerolls")
	_check(first.after_shop.equipment.size() > 1, "earned gold bought no actual weapon offers")
	_check(second.start.coins == first.after_shop.coins and second.start.equipment == first.after_shop.equipment, "next wave replaced earned gear or wallet")
	_check(second.start.stats == first.after_shop.stats, "next wave silently healed or replaced earned stats")
	_check(not root.get_node("GameSession").has_run(), "economy probe wrote a player save")
	var repeat := await sample_run("turbo_drill", &"hell", "hunt", 13579, 2)
	for key in ["outcome", "wave", "level", "kills", "gold_earned", "xp_earned", "chests"]:
		_check(run[key] == repeat[key], "earned progression is not deterministic: " + key)
	print("PASS earned progression: actual Hell requests, finite HP, one starter, full loot sweep, earned levels, paid real offers, persistent gear/HP and deterministic economy")
	finish(1 if failures else 0)
