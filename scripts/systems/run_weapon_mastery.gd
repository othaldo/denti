class_name RunWeaponMastery
extends RefCounted
## Immutable origin plus run-local presentation state. Account awards are idempotent.

var starter_id: StringName = &""
var eligible := false
var earned: Array[String] = []
var pending: Array[String] = []


func begin(id: StringName, ranked: bool) -> void:
	if starter_id != &"" or not WeaponMasteries.valid_weapon(id): return
	starter_id = id
	eligible = ranked


func record(session: Node, event: StringName, difficulty: StringName, wave: int) -> void:
	if not eligible or session.test_scenario_id != &"": return
	var flags := WeaponMasteries.flags_for(event, difficulty, wave)
	for id: String in session.record_weapon_mastery(starter_id, flags):
		if not earned.has(id): earned.append(id)
		if not pending.has(id): pending.append(id)


func take_pending() -> Array[String]:
	var result: Array[String] = pending.duplicate()
	pending.clear()
	return result


func save_data() -> Dictionary:
	return {"starter_id": str(starter_id), "eligible": eligible, "earned": earned.duplicate(), "pending": pending.duplicate()}


func restore(saved: Dictionary) -> void:
	starter_id = StringName(str(saved.get("starter_id", "")))
	if not WeaponMasteries.valid_weapon(starter_id): starter_id = &""
	# Historic saves have no provable starting weapon; do not infer from equipment.
	eligible = bool(saved.get("eligible", false)) and starter_id != &""
	earned.clear()
	pending.clear()
	for id in saved.get("earned", []):
		if WeaponMasteries.by_id(StringName(str(id))) != null and not earned.has(str(id)): earned.append(str(id))
	for id in saved.get("pending", []):
		if earned.has(str(id)) and not pending.has(str(id)): pending.append(str(id))
