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
	# Class relics: each changes one class verb and is offered only to that class.
	preload("res://data/relics/molar_root_weave.tres"),
	preload("res://data/relics/molar_crown_echo.tres"),
	preload("res://data/relics/assassin_midnight_blade.tres"),
	preload("res://data/relics/assassin_nightshade.tres"),
	preload("res://data/relics/fairy_dreamcatcher.tres"),
	preload("res://data/relics/fairy_crescent.tres"),
	preload("res://data/relics/ember_volcano_heart.tres"),
	preload("res://data/relics/ember_tongs.tres"),
	preload("res://data/relics/rinser_whirlpool.tres"),
	preload("res://data/relics/rinser_tap_water.tres"),
	preload("res://data/relics/frost_glacier_heart.tres"),
	preload("res://data/relics/frost_ice_flower.tres"),
]


static func by_id(id: StringName) -> RelicData:
	for relic in CATALOG:
		if relic.id == id:
			return relic
	return null


## Relics a class may receive: every general relic plus its own class relics.
static func offered_to(relic: RelicData, class_id: StringName) -> bool:
	return relic.class_id == &"" or relic.class_id == class_id


## Up to `count` unowned relics. One class relic is always among them while the
## class has one left, and one relic matching the build tags if any exists.
static func choices(owned: Array[String], preferred: Array[StringName] = [], class_id: StringName = &"", count: int = OFFER_COUNT) -> Array[String]:
	var available: Array[String] = []
	var own_class: Array[String] = []
	var relevant: Array[String] = []
	for relic in CATALOG:
		if owned.has(str(relic.id)) or not offered_to(relic, class_id):
			continue
		available.append(str(relic.id))
		if relic.class_id != &"":
			own_class.append(str(relic.id))
		elif relic.tags.any(func(tag: StringName) -> bool: return preferred.has(tag)):
			relevant.append(str(relic.id))
	var result: Array[String] = []
	for pool in [own_class, relevant]:
		if not pool.is_empty() and result.size() < count:
			result.append(pool.pick_random())
	available.shuffle()
	for id in available:
		if result.size() >= count: break
		if not result.has(id): result.append(id)
	result.shuffle()
	return result
