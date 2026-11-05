class_name RelicCatalog
extends RefCounted

const CATALOG: Array[RelicData] = [
	preload("res://data/relics/blood_moon_tooth.tres"),
	preload("res://data/relics/tidal_seal.tres"),
	preload("res://data/relics/shattered_halo.tres"),
	preload("res://data/relics/sun_mark.tres"),
	preload("res://data/relics/pilgrim_compass.tres"),
	preload("res://data/relics/venom_fang.tres"),
]


static func by_id(id: StringName) -> RelicData:
	for relic in CATALOG:
		if relic.id == id:
			return relic
	return null


static func choices(owned: Array[String], preferred: Array[StringName] = []) -> Array[String]:
	var available: Array[String] = []
	var relevant: Array[String] = []
	for relic in CATALOG:
		if not owned.has(str(relic.id)):
			available.append(str(relic.id))
			for tag in relic.tags:
				if preferred.has(tag):
					relevant.append(str(relic.id))
					break
	available.shuffle()
	available.resize(mini(available.size(), 3))
	if not relevant.is_empty() and not available.any(func(id: String) -> bool: return relevant.has(id)):
		available[randi_range(0, available.size() - 1)] = relevant.pick_random()
	return available
