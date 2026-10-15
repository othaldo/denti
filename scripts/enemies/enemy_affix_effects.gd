class_name EnemyAffixEffects
extends RefCounted

const TICK_INTERVAL := 0.5
var remaining := TICK_INTERVAL
# Fixed future installments per type: repeated hits add their own budget rather
# than refreshing/multiplying an existing DPS stack. Memory is bounded by duration.
var pending: Dictionary = {}
var fire_budget: float = 0.0
var fire_time: float = 0.0
var fire_can_spread: bool = false
var poison_stacks: int = 0
var poison_time: float = 0.0
var poison_lock: float = 0.0
var ice_power: float = 0.0
var holy_marks: int = 0
var holy_time: float = 0.0
var holy_power: float = 0.0

const MAX_DOT_DURATION := 8.0

func is_active() -> bool:
	return not pending.is_empty() or poison_time > 0 or holy_time > 0 or fire_time > 0

func apply(kind: StringName, amount: float, can_spread: bool = true, duration: float = 0.0) -> void:
	var definition := WeaponAffixes.by_id(kind)
	if definition == null or definition.dot_duration <= 0 or amount <= 0:
		return
	if kind == &"fire":
		remember_fire(amount, can_spread)
	if kind == &"poison":
		if poison_lock <= 0:
			poison_stacks = mini(poison_stacks + 1, definition.buildup_limit)
			poison_lock = definition.buildup_interval
		poison_time = definition.dot_duration
		amount *= 1.0 + maxi(poison_stacks - 1, 0) * definition.buildup_bonus
	if pending.is_empty():
		remaining = TICK_INTERVAL
	var seconds := clampf(duration if duration > 0 else definition.dot_duration, TICK_INTERVAL, MAX_DOT_DURATION)
	var count := maxi(roundi(seconds / TICK_INTERVAL), 1)
	var ticks: Array = pending.get(str(kind), [])
	while ticks.size() < count:
		ticks.append(0.0)
	for index in count:
		ticks[index] += amount / float(count)
	pending[str(kind)] = ticks

func remember_fire(amount: float, can_spread: bool) -> void:
	if amount <= 0:
		return
	fire_budget = maxf(fire_budget, amount)
	fire_time = WeaponAffixes.by_id(&"fire").dot_duration
	fire_can_spread = fire_can_spread or can_spread

func budget(kind: StringName) -> float:
	var total := 0.0
	for value in pending.get(str(kind), []):
		total += float(value)
	return total

func advance(enemy: Enemy, delta: float) -> void:
	var had_marks := holy_marks > 0
	poison_lock = maxf(poison_lock - delta, 0)
	poison_time = maxf(poison_time - delta, 0)
	if poison_time <= 0:
		poison_stacks = 0
	holy_time = maxf(holy_time - delta, 0)
	if holy_time <= 0:
		holy_marks = 0
		holy_power = 0
		if had_marks:
			enemy.queue_redraw()
	fire_time = maxf(fire_time - delta, 0)
	if fire_time <= 0 and not pending.has("fire"):
		fire_budget = 0
		fire_can_spread = false
	if pending.is_empty() or enemy.health <= 0:
		return
	remaining -= delta
	while remaining <= 0 and not pending.is_empty() and enemy.health > 0:
		remaining += TICK_INTERVAL
		var additions: Array[Dictionary] = []
		for kind: String in pending.keys():
			var ticks: Array = pending[kind]
			var amount := float(ticks.pop_front())
			if amount > 0:
				# Resistance was accounted for at application. Tick damage still
				# goes through ordinary defense, boss phases and guard budgets.
				additions.append({"id": kind, "damage": amount, "dot_tick": true})
		if not additions.is_empty():
			enemy.take_damage(0, null, false, &"", additions)
		# Death listeners still see the status on its final tick.
		for kind: String in pending.keys():
			if (pending[kind] as Array).is_empty():
				pending.erase(kind)
		enemy.queue_redraw()
	# The central motion fast path stops ticking inactive components. Clear the
	# expired provenance now, after death listeners had access to the final tick.
	if fire_time <= 0 and not pending.has("fire"):
		fire_budget = 0
		fire_can_spread = false

func save_data() -> Dictionary:
	return {"remaining": remaining, "pending": pending.duplicate(true),
		"fire_budget": fire_budget, "fire_time": fire_time, "fire_can_spread": fire_can_spread,
		"poison_stacks": poison_stacks, "poison_time": poison_time, "poison_lock": poison_lock,
		"ice_power": ice_power, "holy_marks": holy_marks, "holy_time": holy_time, "holy_power": holy_power}

func restore(saved: Dictionary) -> void:
	pending.clear()
	fire_budget = maxf(float(saved.get("fire_budget", 0)), 0)
	fire_time = clampf(float(saved.get("fire_time", 0)), 0, WeaponAffixes.by_id(&"fire").dot_duration)
	fire_can_spread = bool(saved.get("fire_can_spread", false))
	poison_stacks = clampi(int(saved.get("poison_stacks", 0)), 0, WeaponAffixes.by_id(&"poison").buildup_limit)
	poison_time = clampf(float(saved.get("poison_time", 0)), 0, WeaponAffixes.by_id(&"poison").dot_duration)
	poison_lock = clampf(float(saved.get("poison_lock", 0)), 0, WeaponAffixes.by_id(&"poison").buildup_interval)
	ice_power = maxf(float(saved.get("ice_power", 0)), 0)
	holy_marks = clampi(int(saved.get("holy_marks", 0)), 0, WeaponAffixes.by_id(&"holy").mark_threshold)
	holy_time = clampf(float(saved.get("holy_time", 0)), 0, WeaponAffixes.by_id(&"holy").mark_duration)
	holy_power = maxf(float(saved.get("holy_power", 0)), 0)
	remaining = clampf(float(saved.get("remaining", TICK_INTERVAL)), 0, TICK_INTERVAL)
	var values: Dictionary = saved.get("pending", {})
	for kind: String in values:
		var definition := WeaponAffixes.by_id(StringName(kind))
		if definition == null or definition.dot_duration <= 0 or not values[kind] is Array:
			continue
		var ticks: Array = []
		var count := roundi(MAX_DOT_DURATION / TICK_INTERVAL)
		for value in values[kind].slice(0, count):
			var amount := float(value)
			ticks.append(amount if is_finite(amount) and amount >= 0 else 0.0)
		if not ticks.is_empty():
			pending[kind] = ticks

func draw_markers(enemy: Enemy) -> void:
	var offset := 0
	for definition in WeaponAffixes.ALL:
		if enemy.data.affix_resistance(definition.id) > 0:
			var center := Vector2(enemy.data.radius + 3, -enemy.data.radius + offset * 13)
			var points := PackedVector2Array([center + Vector2(-5, -5), center + Vector2(5, -5), center + Vector2(5, 1), center + Vector2(0, 6), center + Vector2(-5, 1), center + Vector2(-5, -5)])
			enemy.draw_colored_polygon(points, definition.color.darkened(0.3))
			enemy.draw_polyline(points, definition.color, 1.5)
			offset += 1
	var active_offset := 0
	for definition in WeaponAffixes.ALL:
		if pending.has(str(definition.id)):
			enemy.draw_circle(Vector2(-8 + active_offset * 8, -enemy.data.radius - 7), 3.0, definition.color)
			active_offset += 1
	if holy_time > 0 and holy_marks > 0:
		for index in holy_marks:
			enemy.draw_circle(Vector2(-7 + index * 7, -enemy.data.radius - 14), 2.5, WeaponAffixes.by_id(&"holy").color)
