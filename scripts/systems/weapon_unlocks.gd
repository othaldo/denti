class_name WeaponUnlocks
extends RefCounted
## Meta progression for standard weapons, derived only from mastery seals.
## Weapons without a rule are available from the first run. Only the chain
## counts: a seal on the locked weapon itself does not keep it open.

const ALL: Array[WeaponUnlockData] = [
	preload("res://data/unlocks/enamel_mirror.tres"),
	preload("res://data/unlocks/prophylaxis_polisher.tres"),
	preload("res://data/unlocks/cavity_grinder.tres"),
	preload("res://data/unlocks/interdental_brush.tres"),
	preload("res://data/unlocks/floss_garrote.tres"),
	preload("res://data/unlocks/crown_launcher.tres"),
	preload("res://data/unlocks/mouthwash_mortar.tres"),
	preload("res://data/unlocks/uv_lamp.tres"),
	preload("res://data/unlocks/water_turbine.tres"),
	preload("res://data/unlocks/fluoride_rocket.tres"),
]


static func rule(id: StringName) -> WeaponUnlockData:
	for entry in ALL:
		if entry.weapon_id == id: return entry
	return null


static func unlocked(id: StringName, masteries: Dictionary) -> bool:
	var entry := rule(id)
	if entry == null: return true
	var mastery := WeaponMasteries.by_id(entry.mastery_id)
	if mastery == null: return true
	for source in entry.source_ids:
		if int(masteries.get(str(source), 0)) & mastery.flag: return true
	return false


static func newly_unlocked(before: Dictionary, after: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for entry in ALL:
		if not unlocked(entry.weapon_id, before) and unlocked(entry.weapon_id, after):
			result.append(entry.weapon_id)
	return result


static func requirement(id: StringName) -> String:
	var entry := rule(id)
	if entry == null: return ""
	var names: PackedStringArray = []
	for source in entry.source_ids:
		var weapon := WeaponCatalog.by_id(source)
		if weapon != null: names.append(weapon.display_name)
	var mastery := WeaponMasteries.by_id(entry.mastery_id)
	return "%s · %s" % [mastery.display_name if mastery != null else "", " oder ".join(names)]
