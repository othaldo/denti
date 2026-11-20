class_name PlayerStatKeys
extends RefCounted

# Save keys and native units shared by resources, stats and presentation.
const DEFAULT_DODGE_LIMIT := 0.60
const DEFAULT_CRIT_LIMIT := 0.65
const ALL: Array[StringName] = [
	&"damage_bonus", &"armor", &"max_health", &"attack_speed", &"crit_chance",
	&"regen", &"speed_bonus", &"luck", &"melee_damage", &"ranged_damage", &"dodge_chance",
	&"dash_recovery_bonus",
]
