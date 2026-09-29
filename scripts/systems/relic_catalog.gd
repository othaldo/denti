class_name RelicCatalog
extends RefCounted

const CATALOG: Array[RelicData] = [
	preload("res://data/relics/blood_moon_tooth.tres"),
	preload("res://data/relics/tidal_seal.tres"),
	preload("res://data/relics/shattered_halo.tres"),
	preload("res://data/relics/sun_mark.tres"),
	preload("res://data/relics/pilgrim_compass.tres"),
]


static func by_id(id: StringName) -> RelicData:
	for relic in CATALOG:
		if relic.id == id:
			return relic
	return null


static func choices(owned: Array[String]) -> Array[String]:
	var available: Array[String] = []
	for relic in CATALOG:
		if not owned.has(str(relic.id)):
			available.append(str(relic.id))
	available.shuffle()
	available.resize(mini(available.size(), 3))
	return available
