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

# Compatibility alias: starters always follow the regular catalog, never evolutions.
const STARTERS: Array[WeaponData] = ALL
const EXTRACTION_STAFF: WeaponData = preload("res://data/weapons/extraction_staff.tres")


static func is_starter(weapon: WeaponData) -> bool:
	return weapon in ALL or weapon == EXTRACTION_STAFF


static func starters_for(profile: PlayerClassData) -> Array[WeaponData]:
	return ALL if profile == null or profile.exclusive_weapon_id == &"" else [by_id(profile.exclusive_weapon_id)]


static func by_id(id: StringName) -> WeaponData:
	if id == EXTRACTION_STAFF.id: return EXTRACTION_STAFF
	for weapon in ALL:
		if weapon.id == id:
			return weapon
	return WeaponEvolutions.weapon_by_id(id)
