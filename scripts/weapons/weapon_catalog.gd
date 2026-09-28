class_name WeaponCatalog
extends RefCounted

const ALL: Array[WeaponData] = [
	preload("res://data/weapons/magic_toothbrush.tres"),
	preload("res://data/weapons/turbo_drill.tres"),
	preload("res://data/weapons/floss_whip.tres"),
	preload("res://data/weapons/water_jet.tres"),
	preload("res://data/weapons/crown_launcher.tres"),
	preload("res://data/weapons/enamel_mirror.tres"),
	preload("res://data/weapons/plaque_scaler.tres"),
	preload("res://data/weapons/mouthwash_mortar.tres"),
]

const STARTERS: Array[WeaponData] = [
	preload("res://data/weapons/magic_toothbrush.tres"),
	preload("res://data/weapons/turbo_drill.tres"),
	preload("res://data/weapons/water_jet.tres"),
]


static func by_id(id: StringName) -> WeaponData:
	for weapon in ALL:
		if weapon.id == id:
			return weapon
	return null
