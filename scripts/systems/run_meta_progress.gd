class_name RunMetaProgress
extends RefCounted
## Run-side half of the lifetime counters. Kills, bosses, elites and coins
## gather here during a wave and are added to the profile after every wave
## and at the run end, so a crash loses at most one wave. Unflushed counts and
## the weapons this run opened survive save/resume.

var pending: Dictionary = {}
## Weapons this run opened, for the run-end cards.
var unlocks: Array[String] = []
## Opened but not yet announced in the post-wave banner.
var pending_unlocks: Array[String] = []


func record_kill(data: EnemyData) -> void:
	_add("kills", 1)
	if data.is_boss: _add("bosses", 1)
	elif data.is_elite: _add("elites", 1)


func record_coins(amount: int) -> void:
	if amount > 0: _add("coins", amount)


## `new_run` is false for a death in endless after the wave-20 victory,
## which already counted the run.
func record_run_end(died: bool, new_run: bool = true) -> void:
	if new_run: _add("runs", 1)
	if died: _add("deaths", 1)


## Adds pending counts (and a first wave-20 victory) to the profile.
func flush(session: Node, eligible: bool, victory_class: StringName = &"") -> Array[String]:
	var counts := pending.duplicate()
	pending.clear()
	if not eligible: return []
	var gained: Array[String] = session.add_meta_progress(counts, victory_class)
	for id in gained:
		if not unlocks.has(id): unlocks.append(id)
		if not pending_unlocks.has(id): pending_unlocks.append(id)
	return gained


func take_pending_unlocks() -> Array[String]:
	var result := pending_unlocks.duplicate()
	pending_unlocks.clear()
	return result


func save_data() -> Dictionary:
	return {"pending": pending.duplicate(), "unlocks": unlocks.duplicate(), "pending_unlocks": pending_unlocks.duplicate()}


func restore(saved: Dictionary) -> void:
	pending.clear()
	unlocks.clear()
	pending_unlocks.clear()
	var counts: Variant = saved.get("pending", {})
	if counts is Dictionary:
		for key in MetaCounters.KEYS:
			var value: Variant = counts.get(key, 0)
			if (value is int or value is float) and is_finite(float(value)) and float(value) > 0: pending[key] = int(value)
	for id in saved.get("unlocks", []):
		if WeaponUnlocks.rule(StringName(str(id))) != null and not unlocks.has(str(id)): unlocks.append(str(id))
	for id in saved.get("pending_unlocks", []):
		if unlocks.has(str(id)) and not pending_unlocks.has(str(id)): pending_unlocks.append(str(id))


func _add(key: String, amount: int) -> void:
	pending[key] = int(pending.get(key, 0)) + amount
