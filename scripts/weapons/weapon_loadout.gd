class_name WeaponLoadout
extends Node2D

const CAPACITY := 6
const MAX_TIER := 4


func equipped() -> Array[WeaponInstance]:
	var result: Array[WeaponInstance] = []
	for child in get_children():
		if child is WeaponInstance:
			result.append(child)
	return result


func used_slots() -> int:
	var total := 0
	for weapon in equipped():
		total += weapon.data.hands
	return total


func can_acquire(data: WeaponData, tier: int = 1) -> bool:
	return (tier < MAX_TIER and _find_tier(data.id, tier) != null) or used_slots() + data.hands <= CAPACITY


func acquire(data: WeaponData, tier: int = 1) -> bool:
	if not can_acquire(data, tier):
		return false
	var matching := _find_tier(data.id, tier) if tier < MAX_TIER else null
	if matching != null:
		matching.tier += 1
		_merge_pairs(data.id)
	else:
		_add(data, tier)
	_refresh_positions()
	return true


func restore(saved: Array) -> void:
	for weapon in equipped():
		weapon.free()
	for entry in saved:
		if not entry is Dictionary:
			continue
		var data := WeaponCatalog.by_id(StringName(str(entry.get("id", ""))))
		if data != null and used_slots() + data.hands <= CAPACITY:
			_add(data, clampi(int(entry.get("tier", 1)), 1, MAX_TIER))
	_refresh_positions()


func save_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for weapon in equipped():
		result.append({"id": str(weapon.data.id), "tier": weapon.tier})
	return result


func sell(index: int) -> int:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return 0
	var weapon := weapons[index]
	var refund := refund_for(index)
	weapon.free()
	_refresh_positions()
	return refund


func refund_for(index: int) -> int:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return 0
	var weapon := weapons[index]
	return maxi(int(round(float(weapon.data.price) * pow(1.65, weapon.tier - 1) * 0.5)), 1)


func _add(data: WeaponData, tier: int) -> void:
	var weapon := WeaponInstance.new()
	weapon.configure(data, tier)
	add_child(weapon)


func _find_tier(id: StringName, tier: int) -> WeaponInstance:
	for weapon in equipped():
		if weapon.data.id == id and weapon.tier == tier:
			return weapon
	return null


func _merge_pairs(id: StringName) -> void:
	for tier in range(2, MAX_TIER):
		var first: WeaponInstance
		for weapon in equipped():
			if weapon.data.id != id or weapon.tier != tier:
				continue
			if first == null:
				first = weapon
			else:
				first.tier += 1
				weapon.free()
				break


func _refresh_positions() -> void:
	var weapons := equipped()
	for index in weapons.size():
		var angle := TAU * float(index) / float(maxi(weapons.size(), 1))
		weapons[index].position = Vector2(cos(angle), sin(angle)) * 35.0
