class_name HerbElementArt
extends RefCounted

## The plant rows and seed cells follow WeaponElementVisuals.ELEMENTS.
const PLANTS: Texture2D = preload("res://assets/classes/herb_druid_element_plants.png")
const SEEDS: Texture2D = preload("res://assets/vfx/herb_element_seeds.png")
const CELL := Vector2(128, 128)
const SEED_COLUMNS := 3

static var _seed_textures: Dictionary[StringName, AtlasTexture] = {}


static func plant_region(element: StringName, kind: int) -> Rect2:
	var row := WeaponElementVisuals.ELEMENTS.find(element)
	return Rect2(Vector2(kind, row) * CELL, CELL) if row >= 0 else Rect2()


static func seed(element: StringName) -> Texture2D:
	if _seed_textures.has(element):
		return _seed_textures[element]
	var index := WeaponElementVisuals.ELEMENTS.find(element)
	if index < 0:
		return null
	var art := AtlasTexture.new()
	art.atlas = SEEDS
	@warning_ignore("integer_division")
	art.region = Rect2(Vector2(index % SEED_COLUMNS, index / SEED_COLUMNS) * CELL, CELL)
	art.filter_clip = true
	_seed_textures[element] = art
	return art
