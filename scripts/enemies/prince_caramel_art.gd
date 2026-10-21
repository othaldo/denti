class_name PrinceCaramelArt
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/enemies/prince_caramel/parts.png")
const REGIONS: Array[Rect2] = [
	Rect2(14, 18, 491, 503),
	Rect2(513, 34, 399, 471),
	Rect2(927, 153, 307, 354),
	Rect2(51, 597, 338, 259),
	Rect2(525, 593, 331, 277),
	Rect2(948, 588, 268, 297),
	Rect2(29, 975, 438, 227),
	Rect2(500, 907, 424, 313),
	Rect2(976, 974, 223, 226),
]
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
