class_name DifficultyCatalog
extends RefCounted

const EASY: DifficultyData = preload("res://data/difficulties/easy.tres")
const NORMAL: DifficultyData = preload("res://data/difficulties/normal.tres")
const HARD: DifficultyData = preload("res://data/difficulties/hard.tres")
const HELL: DifficultyData = preload("res://data/difficulties/hell.tres")
const ALL: Array[DifficultyData] = [EASY, NORMAL, HARD, HELL]


static func by_id(id: StringName) -> DifficultyData:
	for difficulty in ALL:
		if difficulty.id == id:
			return difficulty
	return NORMAL
