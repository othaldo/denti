class_name CombatGlyphs
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/vfx/combat_glyphs.png")
const PREPARED = preload("res://scripts/systems/prepared_combat_glyphs.gd")
const EXTENT := 38.0
const RADIUS := 32.0
static var regions: Dictionary[String, AtlasTexture] = {}

static func prepare() -> void:
	if not regions.is_empty():
		return
	for key: String in PREPARED.REGIONS:
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = PREPARED.REGIONS[key]
		regions[key] = texture

static func region(key: String) -> AtlasTexture:
	prepare()
	return regions.get(key)
