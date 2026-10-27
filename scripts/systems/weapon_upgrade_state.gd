class_name WeaponUpgradeState
extends RefCounted
## A persisted intermission draft. Combat equipment changes only on confirmation.

var points := 0
var actions: Array[Dictionary] = []
var cursor: Dictionary = {}


func remaining() -> int:
	return maxi(points - actions.size(), 0)


func preview(weapon: WeaponInstance) -> Array[Dictionary]:
	var result: Array[Dictionary] = weapon.affixes.duplicate(true)
	for action in actions:
		if str(action.uid) != weapon.instance_uid: continue
		var next := WeaponUpgrades.advance(result, StringName(action.id), weapon.data, weapon.tier)
		if next.is_empty(): return result
		result = next
	return result


func plan(loadout: WeaponLoadout, uid: String, id: StringName) -> bool:
	if remaining() == 0: return false
	for weapon in loadout.equipped():
		if weapon.instance_uid != uid: continue
		if WeaponUpgrades.advance(preview(weapon), id, weapon.data, weapon.tier).is_empty(): return false
		actions.append({"uid": uid, "id": str(id)})
		cursor = {"target_uid": uid}
		return true
	return false


func undo() -> void:
	if actions.is_empty(): return
	var action: Dictionary = actions.pop_back()
	cursor = {"target_uid": str(action.uid)}


func commit(loadout: WeaponLoadout) -> bool:
	if actions.size() > points: return false
	var planned: Dictionary = {}
	for action in actions:
		var target: WeaponInstance
		for weapon in loadout.equipped():
			if weapon.instance_uid == str(action.uid): target = weapon
		if target == null: return false
		var before: Array[Dictionary] = planned.get(target, target.affixes)
		var after := WeaponUpgrades.advance(before, StringName(action.id), target.data, target.tier)
		if after.is_empty(): return false
		planned[target] = after
	for weapon: WeaponInstance in planned:
		weapon.affixes.assign(planned[weapon])
		weapon.affix_slots = maxi(WeaponUpgrades.slots(weapon.tier), weapon.affixes.size())
		weapon.refresh_affix_stats()
	points -= actions.size()
	actions.clear()
	cursor.clear()
	if not planned.is_empty(): loadout.prepare_projectile_visuals()
	return true


func save_data() -> Dictionary:
	return {"points": points, "actions": actions.duplicate(true), "cursor": cursor.duplicate(true)}


func restore(value: Dictionary) -> void:
	points = maxi(int(value.get("points", 0)), 0)
	actions.clear()
	for entry in value.get("actions", []):
		if not entry is Dictionary or actions.size() >= points: continue
		if WeaponAffixes.by_id(StringName(str(entry.get("id", "")))) == null: continue
		actions.append({"uid": str(entry.get("uid", "")), "id": str(entry.id)})
	var saved_cursor: Dictionary = value.get("cursor", {})
	var effect := str(saved_cursor.get("selected_effect", ""))
	cursor = {"target_uid": str(saved_cursor.get("target_uid", "")),
		"picking_slot": clampi(int(saved_cursor.get("picking_slot", -1)), -1, WeaponAffixes.MAX_SLOTS - 1),
		"selected_effect": effect if WeaponAffixes.by_id(StringName(effect)) != null else ""}


func validate(loadout: WeaponLoadout) -> void:
	# Replay a resumed draft through the same rules, returning invalid investments
	# to the bank rather than losing points or partially applying equipment.
	var saved := actions.duplicate(true)
	actions.clear()
	var saved_cursor := cursor.duplicate(true)
	for action in saved: plan(loadout, str(action.uid), StringName(action.id))
	cursor = saved_cursor
