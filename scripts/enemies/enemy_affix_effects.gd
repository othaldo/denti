class_name EnemyAffixEffects
extends RefCounted

const TICK_INTERVAL := 0.5
var remaining := TICK_INTERVAL
# Fixed future installments per type: repeated hits add their own budget rather
# than refreshing/multiplying an existing DPS stack. Memory is bounded by duration.
var pending: Dictionary = {}

func is_active() -> bool:
	return not pending.is_empty()

func apply(kind: StringName, amount: float) -> void:
	var definition := WeaponAffixes.by_id(kind)
	if definition == null or definition.dot_duration <= 0 or amount <= 0:
		return
	if pending.is_empty():
		remaining = TICK_INTERVAL
	var count := maxi(roundi(definition.dot_duration / TICK_INTERVAL), 1)
	var ticks: Array = pending.get(str(kind), [])
	while ticks.size() < count:
		ticks.append(0.0)
	for index in count:
		ticks[index] += amount / float(count)
	pending[str(kind)] = ticks

func advance(enemy: Enemy, delta: float) -> void:
	if pending.is_empty() or enemy.health <= 0:
		return
	remaining -= delta
	while remaining <= 0 and not pending.is_empty() and enemy.health > 0:
		remaining += TICK_INTERVAL
		var additions: Array[Dictionary] = []
		for kind: String in pending.keys():
			var ticks: Array = pending[kind]
			var amount := float(ticks.pop_front())
			if ticks.is_empty():
				pending.erase(kind)
			if amount > 0:
				# Resistance was accounted for at application. Tick damage still
				# goes through ordinary defense, boss phases and guard budgets.
				additions.append({"id": kind, "damage": amount, "dot_tick": true})
		if not additions.is_empty():
			enemy.take_damage(0, null, false, &"", additions)
		enemy.queue_redraw()

func save_data() -> Dictionary:
	return {"remaining": remaining, "pending": pending.duplicate(true)}

func restore(saved: Dictionary) -> void:
	pending.clear()
	remaining = clampf(float(saved.get("remaining", TICK_INTERVAL)), 0, TICK_INTERVAL)
	var values: Dictionary = saved.get("pending", {})
	for kind: String in values:
		var definition := WeaponAffixes.by_id(StringName(kind))
		if definition == null or definition.dot_duration <= 0 or not values[kind] is Array:
			continue
		var ticks: Array = []
		var count := roundi(definition.dot_duration / TICK_INTERVAL)
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
