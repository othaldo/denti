class_name KingAcidArt
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/enemies/king_acid/parts.png")
const STREAM: Texture2D = preload("res://assets/enemies/king_acid/acid_stream.png")
const REGIONS: Array[Rect2] = [Rect2(30, 3, 470, 600), Rect2(510, 40, 390, 568), Rect2(900, 100, 340, 490), Rect2(36, 622, 402, 329), Rect2(492, 622, 402, 329), Rect2(918, 630, 318, 312), Rect2(20, 1027, 600, 182), Rect2(630, 965, 360, 280), Rect2(1043, 989, 194, 246)]
static var textures: Array[AtlasTexture] = []

static func texture(index: int) -> AtlasTexture:
	if textures.is_empty():
		for region in REGIONS:
			var tile := AtlasTexture.new()
			tile.atlas = ATLAS
			tile.region = region
			tile.filter_clip = true
			textures.append(tile)
	return textures[index]
