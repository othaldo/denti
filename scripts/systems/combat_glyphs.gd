class_name CombatGlyphs
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/vfx/combat_glyphs.png")
const PREPARED = preload("res://scripts/systems/prepared_combat_glyphs.gd")
const EXTENT := 38.0
const RADIUS := 32.0
const NO_RING: Array[AtlasTexture] = []
static var regions: Dictionary[String, AtlasTexture] = {}
static var warning_rings: Dictionary[int, Array] = {}
static var marks: Dictionary[int, AtlasTexture] = {}
static var line_texture: AtlasTexture
static var solid_texture: AtlasTexture
static var circle_texture: AtlasTexture

static func prepare() -> void:
	if not regions.is_empty():
		return
	for key: String in PREPARED.REGIONS:
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = PREPARED.REGIONS[key]
		regions[key] = texture
		var parts := key.split(":")
		if parts.size() == 2:
			if parts[0] == "mark":
				marks[int(parts[1])] = texture
			else:
				var radius := int(parts[0])
				if not warning_rings.has(radius):
					var steps: Array[AtlasTexture] = []
					steps.resize(65)
					warning_rings[radius] = steps
				warning_rings[radius][int(parts[1])] = texture
	# The white line tile's interior stays opaque even on very wide lane fills.
	var solid := AtlasTexture.new()
	solid.atlas = ATLAS
	solid.region = PREPARED.REGIONS["line"].grow(-1.0)
	regions["solid"] = solid
	line_texture = regions["line"]
	solid_texture = solid
	circle_texture = regions["circle"]

static func region(key: String) -> AtlasTexture:
	prepare()
	return regions.get(key)
