class_name ItemInventoryData
extends RefCounted

var owned: Dictionary = {}
var powers: Dictionary = {}


func count(id: StringName) -> int:
	return int(owned.get(str(id), 0))


func can_acquire(item: ShopOfferData) -> bool:
	if item == null or item.weapon_data != null:
		return false
	if item.rarity_tier == 5 and count(item.id) > 0:
		return false
	if item.max_stacks > 0 and count(item.id) >= item.max_stacks:
		return false
	return item.family_limit == 0 or family_count(item.family_id) < item.family_limit


func family_count(family_id: StringName) -> int:
	var total := 0
	if family_id == &"":
		return total
	for template in ItemCatalog.ALL:
		if template.weapon_data == null and template.family_id == family_id:
			total += count(template.id)
	return total


func rebuild_powers() -> void:
	powers.clear()
	for key in owned:
		var item := ItemCatalog.by_id(StringName(str(key)))
		if item == null or item.effect_kind == &"":
			continue
		var effect_key: StringName = item.effect_kind
		powers[effect_key] = float(powers.get(effect_key, 0.0)) + item.effect_value * int(owned[key])
