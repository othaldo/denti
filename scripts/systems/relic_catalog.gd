class_name RelicCatalog
extends RefCounted

## Relics offered after a milestone boss.
const OFFER_COUNT := 4

const CATALOG: Array[RelicData] = [
	preload("res://data/relics/blood_moon_tooth.tres"),
	preload("res://data/relics/tidal_seal.tres"),
	preload("res://data/relics/shattered_halo.tres"),
	preload("res://data/relics/sun_mark.tres"),
	preload("res://data/relics/pilgrim_compass.tres"),
	preload("res://data/relics/venom_fang.tres"),
	# Synergy relics: general mechanics that some classes use especially well.
	preload("res://data/relics/dental_brace.tres"),
	preload("res://data/relics/bell_crown.tres"),
	preload("res://data/relics/shadow_floss.tres"),
	preload("res://data/relics/belladonna.tres"),
	preload("res://data/relics/milk_tooth_tin.tres"),
	preload("res://data/relics/lucky_penny.tres"),
	preload("res://data/relics/tinder_tooth.tres"),
	preload("res://data/relics/heat_stone.tres"),
	preload("res://data/relics/copper_crown.tres"),
	preload("res://data/relics/rinse_whirl.tres"),
	preload("res://data/relics/ice_flower.tres"),
	preload("res://data/relics/glacier_heart.tres"),
]


static func by_id(id: StringName) -> RelicData:
	for relic in CATALOG:
		if relic.id == id:
			return relic
	return null


## Up to `count` unowned relics. One of them matches the build tags (weapons,
## items and class preferences) whenever such a relic is left.
static func choices(owned: Array[String], preferred: Array[StringName] = [], count: int = OFFER_COUNT) -> Array[String]:
	var available: Array[String] = []
	var relevant: Array[String] = []
	for relic in CATALOG:
		if owned.has(str(relic.id)):
			continue
		available.append(str(relic.id))
		if relic.tags.any(func(tag: StringName) -> bool: return preferred.has(tag)):
			relevant.append(str(relic.id))
	var result: Array[String] = []
	if not relevant.is_empty() and count > 0:
		result.append(relevant.pick_random())
	available.shuffle()
	for id in available:
		if result.size() >= count: break
		if not result.has(id): result.append(id)
	result.shuffle()
	return result
