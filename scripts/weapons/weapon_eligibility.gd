class_name WeaponEligibility
extends RefCounted

static func allowed(data: WeaponData, profile: PlayerClassData) -> bool:
	if data == null: return false
	if profile == null or profile.allowed_weapon_roles.is_empty(): return true
	for role in data.class_roles:
		if role in profile.allowed_weapon_roles: return true
	return false

static func starter(data: WeaponData, profile: PlayerClassData, capacity: int) -> bool:
	return allowed(data, profile) and data.evolution_kind == &"" and data.hands <= capacity
