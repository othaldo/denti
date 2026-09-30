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
	return used_slots() + data.hands <= CAPACITY or (tier < MAX_TIER and _find_tier(data.id, tier) != null)


func acquire(data: WeaponData, tier: int = 1, paid_coins: int = -1) -> bool:
	if not can_acquire(data, tier):
		return false
	var value := paid_coins if paid_coins >= 0 else _legacy_value(data, tier)
	if used_slots() + data.hands <= CAPACITY:
		_add(data, tier, value)
	else:
		var matching := _find_tier(data.id, tier)
		matching.tier += 1
		matching.invested_coins += value
	_refresh_positions()
	return true


func can_merge(index: int) -> bool:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return false
	var weapon := weapons[index]
	return weapon.tier < MAX_TIER and _find_tier(weapon.data.id, weapon.tier, weapon) != null


func merge(index: int) -> bool:
	if not can_merge(index):
		return false
	var weapon := equipped()[index]
	var partner := _find_tier(weapon.data.id, weapon.tier, weapon)
	weapon.tier += 1
	weapon.invested_coins += partner.invested_coins
	partner.free()
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
			var tier := clampi(int(entry.get("tier", 1)), 1, MAX_TIER)
			_add(data, tier, maxi(int(entry.get("invested_coins", _legacy_value(data, tier))), 0))
	_refresh_positions()


func save_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for weapon in equipped():
		result.append({"id": str(weapon.data.id), "tier": weapon.tier, "invested_coins": weapon.invested_coins})
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
	return roundi(float(weapon.invested_coins) * 0.5)


func _add(data: WeaponData, tier: int, value: int) -> void:
	var weapon := WeaponInstance.new()
	weapon.configure(data, tier)
	weapon.invested_coins = value
	add_child(weapon)


func _find_tier(id: StringName, tier: int, except: WeaponInstance = null) -> WeaponInstance:
	for weapon in equipped():
		if weapon != except and weapon.data.id == id and weapon.tier == tier:
			return weapon
	return null


func _legacy_value(data: WeaponData, tier: int) -> int:
	return data.price * (1 << (tier - 1))


func _refresh_positions() -> void:
	var weapons := equipped()
	for index in weapons.size():
		var angle := TAU * float(index) / float(maxi(weapons.size(), 1))
		weapons[index].position = Vector2(cos(angle), sin(angle)) * 35.0
