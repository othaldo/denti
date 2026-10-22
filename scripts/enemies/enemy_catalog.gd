class_name EnemyCatalog
extends RefCounted

const PLAQUE: EnemyData = preload("res://data/enemies/plaque.tres")
const BACTERIA: EnemyData = preload("res://data/enemies/bacteria.tres")
const SUGAR: EnemyData = preload("res://data/enemies/sugar.tres")
const ACID_SPITTER: EnemyData = preload("res://data/enemies/acid_spitter.tres")
const POISON_GERM: EnemyData = preload("res://data/enemies/poison_germ.tres")
const GUM_BITER: EnemyData = preload("res://data/enemies/gum_biter.tres")
const ACID_CROWN: EnemyData = preload("res://data/enemies/acid_crown.tres")
const HUNT_GERM: EnemyData = preload("res://data/enemies/hunt_germ.tres")
const LOOT_GOBLIN: EnemyData = preload("res://data/enemies/loot_goblin.tres")
const CAVITY_COUNT: EnemyData = preload("res://data/enemies/cavity_count.tres")
const CAVITY_PRINCE: EnemyData = preload("res://data/enemies/cavity_prince.tres")
const CAVITY_KING: EnemyData = preload("res://data/enemies/cavity_king.tres")
const CAVITY_EMPEROR: EnemyData = preload("res://data/enemies/cavity_emperor.tres")

const ALL: Array[EnemyData] = [PLAQUE, BACTERIA, SUGAR, ACID_SPITTER, POISON_GERM, GUM_BITER, ACID_CROWN, HUNT_GERM, CAVITY_COUNT, CAVITY_PRINCE, CAVITY_KING, CAVITY_EMPEROR, LOOT_GOBLIN]


static func by_path(path: String) -> EnemyData:
	for data in ALL:
		if data.resource_path == path:
			return data
	return null
