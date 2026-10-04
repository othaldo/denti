class_name TestArenaCatalog
extends RefCounted

const ALL: Array[TestArenaData] = [
	preload("res://data/test_arenas/dense_combat.tres"),
	preload("res://data/test_arenas/boss_charge.tres"),
]

static func by_id(id: StringName) -> TestArenaData:
	for arena in ALL:
		if arena.id == id:
			return arena
	return null

static func by_code(code: String) -> TestArenaData:
	var normalized := " ".join(code.strip_edges().to_lower().split(" ", false))
	for arena in ALL:
		if arena.code == normalized:
			return arena
	return null
