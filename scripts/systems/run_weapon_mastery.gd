class_name RunWeaponMastery
extends RefCounted
## Immutable origin plus run-local presentation state. Account awards are idempotent.

var starter_id: StringName = &""
var eligible := false
var earned: Array[String] = []
var pending: Array[String] = []
## Weapons unlocked for later runs by seals of this run.
var unlocks: Array[String] = []
var pending_unlocks: Array[String] = []


func begin(id: StringName, ranked: bool) -> void:
	if starter_id != &"" or not WeaponMasteries.valid_weapon(id): return
	starter_id = id
	eligible = ranked


func record(session: Node, event: StringName, difficulty: StringName, wave: int) -> void:
	if not eligible or session.test_scenario_id != &"": return
	var flags := WeaponMasteries.flags_for(event, difficulty, wave)
	var before: Dictionary = session.progression_data.weapon_masteries.duplicate()
	for id: String in session.record_weapon_mastery(starter_id, flags):
		if not earned.has(id): earned.append(id)
		if not pending.has(id): pending.append(id)
	for id in WeaponUnlocks.newly_unlocked(before, session.progression_data.weapon_masteries):
		if not unlocks.has(str(id)): unlocks.append(str(id))
		if not pending_unlocks.has(str(id)): pending_unlocks.append(str(id))


func take_pending() -> Array[String]:
	var result: Array[String] = pending.duplicate()
	pending.clear()
	return result


func take_pending_unlocks() -> Array[String]:
	var result: Array[String] = pending_unlocks.duplicate()
	pending_unlocks.clear()
	return result


func save_data() -> Dictionary:
	return {"starter_id": str(starter_id), "eligible": eligible, "earned": earned.duplicate(), "pending": pending.duplicate(),
		"unlocks": unlocks.duplicate(), "pending_unlocks": pending_unlocks.duplicate()}


func restore(saved: Dictionary) -> void:
	starter_id = StringName(str(saved.get("starter_id", "")))
	if not WeaponMasteries.valid_weapon(starter_id): starter_id = &""
	# Historic saves have no provable starting weapon; do not infer from equipment.
	eligible = bool(saved.get("eligible", false)) and starter_id != &""
	earned.clear()
	pending.clear()
	unlocks.clear()
	pending_unlocks.clear()
	for id in saved.get("earned", []):
		if WeaponMasteries.by_id(StringName(str(id))) != null and not earned.has(str(id)): earned.append(str(id))
	for id in saved.get("pending", []):
		if earned.has(str(id)) and not pending.has(str(id)): pending.append(str(id))
	for id in saved.get("unlocks", []):
		if WeaponUnlocks.rule(StringName(str(id))) != null and not unlocks.has(str(id)): unlocks.append(str(id))
	for id in saved.get("pending_unlocks", []):
		if unlocks.has(str(id)) and not pending_unlocks.has(str(id)): pending_unlocks.append(str(id))
