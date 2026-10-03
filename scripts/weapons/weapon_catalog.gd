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
	preload("res://data/weapons/toothpick_spear.tres"),
	preload("res://data/weapons/cavity_grinder.tres"),
	preload("res://data/weapons/interdental_brush.tres"),
	preload("res://data/weapons/fluoride_sprayer.tres"),
	preload("res://data/weapons/water_turbine.tres"),
	preload("res://data/weapons/uv_lamp.tres"),
	preload("res://data/weapons/amalgam_slingshot.tres"),
	preload("res://data/weapons/floss_garrote.tres"),
	preload("res://data/weapons/prophylaxis_polisher.tres"),
	preload("res://data/weapons/fluoride_rocket.tres"),
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
	return WeaponEvolutions.weapon_by_id(id)
