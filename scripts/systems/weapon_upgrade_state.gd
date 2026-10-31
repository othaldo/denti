class_name WeaponUpgradeState
extends RefCounted
## A persisted intermission draft. Combat equipment changes only on confirmation.

var points := 0
var actions: Array[Dictionary] = []
var cursor: Dictionary = {}


func remaining() -> int:
	var spent := 0
	for action in actions: spent += int(action.get("cost", 1))
	return maxi(points - spent, 0)


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
		if remaining() < WeaponUpgrades.cost(weapon.data): return false
		if WeaponUpgrades.advance(preview(weapon), id, weapon.data, weapon.tier).is_empty(): return false
		actions.append({"uid": uid, "id": str(id), "cost": WeaponUpgrades.cost(weapon.data)})
		cursor = {"target_uid": uid}
		return true
	return false


func undo() -> void:
	if actions.is_empty(): return
	var action: Dictionary = actions.pop_back()
	cursor = {"target_uid": str(action.uid)}


func commit(loadout: WeaponLoadout) -> bool:
	var spent := 0
	var planned: Dictionary = {}
	for action in actions:
		var target: WeaponInstance
		for weapon in loadout.equipped():
			if weapon.instance_uid == str(action.uid): target = weapon
		if target == null: return false
		var cost := WeaponUpgrades.cost(target.data)
		if int(action.get("cost", 0)) != cost: return false
		spent += cost
		if spent > points: return false
		var before: Array[Dictionary] = planned.get(target, target.affixes)
		var after := WeaponUpgrades.advance(before, StringName(action.id), target.data, target.tier)
		if after.is_empty(): return false
		planned[target] = after
	for weapon: WeaponInstance in planned:
		weapon.affixes.assign(planned[weapon])
		weapon.affix_slots = maxi(WeaponUpgrades.slots(weapon.tier), weapon.affixes.size())
		weapon.refresh_affix_stats()
	points -= spent
	actions.clear()
	cursor.clear()
	if not planned.is_empty(): loadout.prepare_projectile_visuals()
	return true


func save_data() -> Dictionary:
	return {"economy_version": WeaponUpgrades.ECONOMY_VERSION, "points": points, "actions": actions.duplicate(true), "cursor": cursor.duplicate(true)}


func restore(value: Dictionary) -> void:
	points = maxi(int(value.get("points", 0)), 0)
	if int(value.get("economy_version", 1)) < WeaponUpgrades.ECONOMY_VERSION:
		# Old bank points represented whole capsules. Convert once, then replay
		# open actions at their actual root cost in validate(loadout).
		points *= WeaponUpgrades.POINTS_PER_CAPSULE
	actions.clear()
	for entry in value.get("actions", []):
		if not entry is Dictionary or actions.size() >= points: continue
		if WeaponAffixes.by_id(StringName(str(entry.get("id", "")))) == null: continue
		actions.append({"uid": str(entry.get("uid", "")), "id": str(entry.id), "cost": maxi(int(entry.get("cost", 1)), 1)})
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
