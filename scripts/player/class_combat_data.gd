class_name ClassCombatData
extends Resource

@export var opener_bonus := 0.0
@export var opener_duration := 0.9
@export var opener_roles: Array[StringName] = []
@export var focus_duration := 2.0
@export var focus_interval := 0.45
@export var focus_limit := 4

func valid() -> bool:
	for value in [opener_bonus, opener_duration, focus_duration, focus_interval]:
		if not is_finite(value) or value < 0: return false
	for role in opener_roles:
		if role not in WeaponRoles.ALL: return false
	return focus_limit > 0 and opener_duration > 0 and focus_interval > 0
