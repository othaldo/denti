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


func gold_spent() -> int:
	var spent := 0
	for action in actions: spent += int(action.get("coins", 0))
	return spent


func remaining_gold(coins: int) -> int:
	return maxi(coins - gold_spent(), 0)


func _ascended_data(weapon: WeaponInstance) -> WeaponData:
	var result := weapon.data
	for action in actions:
		if str(action.uid) == weapon.instance_uid and StringName(action.id) == WeaponAscension.ID:
			result = WeaponAscension.advance(result)
	return result


func preview_data(weapon: WeaponInstance) -> WeaponData:
	return WeaponRolls.with_affixes(_ascended_data(weapon), preview(weapon))


func preview(weapon: WeaponInstance) -> Array[Dictionary]:
	var result: Array[Dictionary] = weapon.affixes.duplicate(true)
	for action in actions:
		if str(action.uid) != weapon.instance_uid: continue
		if StringName(action.id) == WeaponAscension.ID: continue
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


func ascension_blocked(weapon: WeaponInstance, coins: int, wave: int) -> String:
	if weapon.tier < WeaponLoadout.MAX_TIER: return "Erst auf Mk IV fusionieren"
	var price := WeaponAscension.quote(_ascended_data(weapon), wave)
	if remaining() < int(price.cost): return "Noch %d Punkte nötig" % (int(price.cost) - remaining())
	if remaining_gold(coins) < int(price.coins): return "Noch %d Gold nötig" % (int(price.coins) - remaining_gold(coins))
	return ""


func plan_ascension(loadout: WeaponLoadout, uid: String, coins: int, wave: int) -> bool:
	for weapon in loadout.equipped():
		if weapon.instance_uid != uid: continue
		if not ascension_blocked(weapon, coins, wave).is_empty(): return false
		var data := _ascended_data(weapon)
		var price := WeaponAscension.quote(data, wave)
		actions.append({"uid": uid, "id": str(WeaponAscension.ID), "cost": int(price.cost),
			"coins": int(price.coins), "from_mk": WeaponAscension.level(data)})
		cursor = {"target_uid": uid}
		return true
	return false


func undo() -> void:
	if actions.is_empty(): return
	var action: Dictionary = actions.pop_back()
	cursor = {"target_uid": str(action.uid)}


func commit(loadout: WeaponLoadout, coins: int = 0, wave: int = 1) -> bool:
	var spent := 0
	var gold := 0
	var planned: Dictionary = {}
	for action in actions:
		var target: WeaponInstance
		for weapon in loadout.equipped():
			if weapon.instance_uid == str(action.uid): target = weapon
		if target == null: return false
		var draft: Dictionary = planned.get(target, {"data": target.data, "values": target.affixes.duplicate(true), "gold": 0})
		var id := StringName(action.id)
		if id == WeaponAscension.ID:
			if target.tier < WeaponLoadout.MAX_TIER or int(action.get("from_mk", -1)) != WeaponAscension.level(draft.data): return false
			var price := WeaponAscension.quote(draft.data, wave)
			if int(action.get("cost", 0)) != int(price.cost) or int(action.get("coins", 0)) != int(price.coins): return false
			spent += int(price.cost)
			gold += int(price.coins)
			draft.gold += int(price.coins)
			draft.data = WeaponAscension.advance(draft.data)
		else:
			var cost := WeaponUpgrades.cost(target.data)
			if int(action.get("cost", 0)) != cost or int(action.get("coins", 0)) != 0: return false
			spent += cost
			var after := WeaponUpgrades.advance(draft.values, id, draft.data, target.tier)
			if after.is_empty(): return false
			draft.values = after
		if spent > points or gold > coins: return false
		planned[target] = draft
	for weapon: WeaponInstance in planned:
		weapon.data = planned[weapon].data
		weapon.affixes.assign(planned[weapon].values)
		weapon.invested_coins += int(planned[weapon].gold)
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
		var id := StringName(str(entry.get("id", "")))
		if id != WeaponAscension.ID and WeaponAffixes.by_id(id) == null: continue
		var action := {"uid": str(entry.get("uid", "")), "id": str(id), "cost": maxi(int(entry.get("cost", 1)), 1)}
		if id == WeaponAscension.ID:
			action["coins"] = maxi(int(entry.get("coins", 0)), 0)
			action["from_mk"] = maxi(int(entry.get("from_mk", 0)), 0)
		actions.append(action)
	var saved_cursor: Dictionary = value.get("cursor", {})
	var effect := str(saved_cursor.get("selected_effect", ""))
	cursor = {"target_uid": str(saved_cursor.get("target_uid", "")),
		"picking_slot": clampi(int(saved_cursor.get("picking_slot", -1)), -1, WeaponAffixes.MAX_SLOTS - 1),
		"selected_effect": effect if WeaponAffixes.by_id(StringName(effect)) != null else ""}


func validate(loadout: WeaponLoadout, coins: int = 0, wave: int = 1) -> void:
	# Replay a resumed draft through the same rules, returning invalid investments
	# to the bank rather than losing points or partially applying equipment.
	var saved := actions.duplicate(true)
	actions.clear()
	var saved_cursor := cursor.duplicate(true)
	for action in saved:
		if StringName(action.id) == WeaponAscension.ID:
			for weapon in loadout.equipped():
				if weapon.instance_uid == str(action.uid) and WeaponAscension.level(_ascended_data(weapon)) == int(action.get("from_mk", -1)):
					plan_ascension(loadout, str(action.uid), coins, wave)
		else: plan(loadout, str(action.uid), StringName(action.id))
	cursor = saved_cursor
