class_name WeaponFusionPlan
extends RefCounted
## A reversible selection. Neither ingredients nor points change until commit.

var primary_uid := ""
var partner_uid := ""
var recipe_id: StringName = &""
var ingredients: Array[Dictionary] = []
var source_data: Array[WeaponData] = []
var result_data: WeaponData
var tier := 4
var candidates: Array[Dictionary] = []
var selected: Array[StringName] = []
var total_points := 0
var effect_points: Dictionary = {}


func configure(primary: WeaponInstance, partner: WeaponInstance, result: WeaponData, result_tier: int, recipe: StringName = &"") -> void:
	ingredients.clear()
	source_data.clear()
	candidates.clear()
	selected.clear()
	effect_points.clear()
	total_points = 0
	primary_uid = primary.instance_uid
	partner_uid = partner.instance_uid if partner != null else ""
	recipe_id = recipe
	result_data = result
	tier = result_tier
	for weapon in [primary, partner]:
		if weapon == null: continue
		ingredients.append(snapshot(weapon))
		source_data.append(weapon.data)
		total_points += WeaponAscension.invested_points(weapon.data)
		for entry: Dictionary in weapon.affixes:
			var invested := WeaponUpgrades.level(entry) * WeaponUpgrades.cost(weapon.data)
			total_points += invested
			effect_points[str(entry.id)] = int(effect_points.get(str(entry.id), 0)) + invested
			var index := WeaponAffixes.find(candidates, StringName(entry.id))
			if index < 0: candidates.append(entry.duplicate(true))
			else: candidates[index] = WeaponAffixes.merge_entries(candidates[index], entry)
	# Transfer purchased root budgets, not free ranks across weapon sizes.
	for index in range(candidates.size() - 1, -1, -1):
		var entry := candidates[index]
		var ranks := mini(int(effect_points[str(entry.id)]) / WeaponUpgrades.cost(result_data), WeaponUpgrades.MAX_LEVEL)
		if ranks == 0:
			candidates.remove_at(index)
		elif entry.has("level") or ranks != WeaponUpgrades.level(entry):
			if not entry.has("level"): entry["legacy_floor"] = float(entry.damage)
			entry["level"] = ranks
			entry.stacks = ranks
	# Primary weapon first; compatible additions follow in source order.
	for entry in candidates:
		var id := StringName(entry.id)
		if selected.size() >= WeaponUpgrades.slots(tier): break
		if WeaponAffixes.by_id(id).elemental and _element() != &"": continue
		selected.append(id)


static func snapshot(weapon: WeaponInstance) -> Dictionary:
	return {"uid": weapon.instance_uid, "id": str(weapon.data.id), "tier": weapon.tier,
		"affixes": weapon.affixes.duplicate(true), "rolls": weapon.data.rolls.duplicate(true),
		"upgrades": weapon.data.chest_upgrades.duplicate(true), "coins": weapon.invested_coins}


func _element() -> StringName:
	for id in selected:
		if WeaponAffixes.by_id(id).elemental: return id
	return &""


func toggle(id: StringName) -> bool:
	if WeaponAffixes.find(candidates, id) < 0: return false
	if selected.has(id):
		selected.erase(id)
		return true
	if WeaponAffixes.by_id(id).elemental and _element() != &"":
		selected.erase(_element())
	if selected.size() >= WeaponUpgrades.slots(tier): return false
	selected.append(id)
	return true


func valid() -> bool:
	if selected.size() > WeaponUpgrades.slots(tier): return false
	var seen: Array[StringName] = []
	var elements := 0
	for id in selected:
		if seen.has(id) or WeaponAffixes.find(candidates, id) < 0: return false
		seen.append(id)
		if WeaponAffixes.by_id(id).elemental: elements += 1
	return elements <= 1


func effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in selected:
		var index := WeaponAffixes.find(candidates, id)
		if index < 0: continue
		var entry := candidates[index].duplicate(true)
		# Historic affixes keep their stored power until explicitly upgraded.
		result.append(entry)
	WeaponUpgrades.refresh(result, result_data, tier)
	return result


func refund() -> int:
	var kept := WeaponAscension.invested_points(result_data)
	for entry in effects(): kept += WeaponUpgrades.level(entry) * WeaponUpgrades.cost(result_data)
	return maxi(total_points - kept, 0)


func preview() -> WeaponData:
	return WeaponRolls.with_affixes(result_data, effects())
