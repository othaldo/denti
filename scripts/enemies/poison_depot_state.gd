class_name PoisonDepotState
extends RefCounted

const RULES: PoisonBuildData = preload("res://data/synergies/poison_build.tres")
const TICK := 0.5
var ticks: Array[float] = []
var remaining := TICK
var target_lock := 0.0
var nerve_time := 0.0
var nerve_lock := 0.0
var origin_range := 0.0
var ticking := false

func active() -> bool:
	return not ticks.is_empty() or target_lock > 0 or nerve_time > 0 or nerve_lock > 0

func budget() -> float:
	var total := 0.0
	for value in ticks: total += value
	return total

func open(amount: float, reach: float) -> void:
	ticks.clear()
	var count := maxi(roundi(RULES.depot_duration / TICK), 1)
	for index in count: ticks.append(amount / count)
	remaining = TICK
	target_lock = RULES.depot_target_lock
	origin_range = reach

func consume(amount: float) -> float:
	var total := budget()
	var spent := minf(maxf(amount, 0), total)
	if total > 0:
		for index in ticks.size(): ticks[index] *= 1.0 - spent / total
	return spent

func advance(enemy: Enemy, delta: float) -> void:
	target_lock = maxf(target_lock - delta, 0)
	nerve_lock = maxf(nerve_lock - delta, 0)
	var was_slowed := nerve_time > 0
	nerve_time = maxf(nerve_time - delta, 0)
	if was_slowed and nerve_time <= 0: enemy.queue_redraw()
	if ticks.is_empty() or enemy.health <= 0: return
	remaining -= delta
	while remaining <= 0 and not ticks.is_empty() and enemy.health > 0:
		remaining += TICK
		var amount := ticks.pop_front() as float
		if amount > 0:
			ticking = true
			var additions: Array[Dictionary] = [{"id": "poison", "damage": amount, "dot_tick": true, "proc_id": "poison_depot"}]
			enemy.take_damage(0, null, false, &"", additions)
			ticking = false
	if ticks.is_empty(): enemy.queue_redraw()

func save_data() -> Dictionary:
	return {"ticks": ticks.duplicate(), "remaining": remaining, "target_lock": target_lock,
		"nerve_time": nerve_time, "nerve_lock": nerve_lock, "origin_range": origin_range}

func restore(saved: Dictionary) -> void:
	ticks.clear()
	for value in (saved.get("ticks", []) as Array).slice(0, roundi(RULES.depot_duration / TICK)):
		var amount := float(value)
		ticks.append(amount if is_finite(amount) and amount >= 0 else 0.0)
	remaining = clampf(float(saved.get("remaining", TICK)), 0, TICK)
	target_lock = clampf(float(saved.get("target_lock", 0)), 0, RULES.depot_target_lock)
	nerve_time = clampf(float(saved.get("nerve_time", 0)), 0, RULES.nerve_duration)
	nerve_lock = clampf(float(saved.get("nerve_lock", 0)), 0, RULES.nerve_target_lock)
	origin_range = maxf(float(saved.get("origin_range", 0)), 0)
	ticking = false
