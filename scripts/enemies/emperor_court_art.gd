class_name EmperorCourtArt
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/enemies/emperor_court/parts.png")
const REGIONS := [Rect2(24, 0, 399, 527), Rect2(430, 32, 503, 436), Rect2(945, 0, 309, 513), Rect2(0, 528, 424, 315), Rect2(441, 512, 427, 359), Rect2(915, 513, 339, 361), Rect2(0, 850, 423, 404), Rect2(426, 934, 512, 215), Rect2(939, 875, 315, 364)]
static var textures: Array[AtlasTexture] = []

static func texture(index: int) -> AtlasTexture:
	if textures.is_empty():
		for region in REGIONS:
			var piece := AtlasTexture.new()
			piece.atlas = ATLAS
			piece.region = region
			piece.filter_clip = true
			textures.append(piece)
	return textures[index]
