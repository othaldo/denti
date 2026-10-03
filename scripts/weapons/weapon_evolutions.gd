class_name WeaponEvolutions
extends RefCounted

const ALL: Array[WeaponEvolutionRecipe] = [
	preload("res://data/evolutions/storm_shower.tres"),
	preload("res://data/evolutions/fate_thread.tres"),
	preload("res://data/evolutions/root_breaker.tres"),
	preload("res://data/evolutions/halo.tres"),
	preload("res://data/evolutions/trinity_brush.tres"),
	preload("res://data/evolutions/revelation.tres"),
]

static func by_id(id: StringName) -> WeaponEvolutionRecipe:
	for recipe in ALL:
		if recipe.id == id:
			return recipe
	return null

static func weapon_by_id(id: StringName) -> WeaponData:
	for recipe in ALL:
		if recipe.result.id == id:
			return recipe.result
	return null
