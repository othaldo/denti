class_name DentiUIIcons
extends RefCounted

const ITEM_ATLAS: Texture2D = preload("res://assets/items/item_icons_atlas.png")
const ITEM_EXPANSION: Texture2D = preload("res://assets/items/item_icons_expansion.png")
const ITEM_EXPANSION_2: Texture2D = preload("res://assets/items/item_icons_expansion_2.png")
const ITEM_ECONOMY: Texture2D = preload("res://assets/items/item_icons_economy.png")
const ITEM_FAMILIES: Array[Texture2D] = [
	preload("res://assets/items/item_icons_families_1_packed.png"),
	preload("res://assets/items/item_icons_families_2_packed.png"),
	preload("res://assets/items/item_icons_families_3_packed.png"),
]
const ITEM_MYTHIC: Texture2D = preload("res://assets/items/item_icons_mythic_packed.png")
const DODGE_ATLAS: Texture2D = preload("res://assets/items/item_icons_dodge_packed.png")
const RELIC_ATLAS: Texture2D = preload("res://assets/relics/relic_icons_atlas.png")
const HUD_ATLAS: Texture2D = preload("res://assets/ui/hud_icons_atlas.png")
const STAT_ATLAS: Texture2D = preload("res://assets/ui/stat_icons_atlas.png")
const RANGE: Texture2D = preload("res://assets/ui/range.svg")
const STAMINA: Texture2D = preload("res://assets/ui/stamina_icon.png")
# Generated motifs are not exactly aligned to a uniform grid. Select each full
# motif, then center it in the same transparent frame instead of cutting a cell.
const STAT_REGIONS: Array[Rect2] = [
	Rect2(35, 33, 391, 338), Rect2(458, 26, 306, 351),
	Rect2(814, 61, 356, 313), Rect2(1208, 51, 347, 328),
	Rect2(1604, 33, 343, 341), Rect2(43, 407, 352, 345),
	Rect2(426, 437, 384, 294), Rect2(837, 432, 312, 319),
	Rect2(1189, 426, 379, 335), Rect2(1575, 416, 366, 347),
]
const STAT_FRAME_SIZE := Vector2(512, 512)
# These painted sheets have uneven gutters: a uniform grid cuts motifs and
# includes fragments from neighboring rows. Keep their source pixels intact.
const ITEM_FRAME_SIZE := Vector2(384, 384)
const EXPANSION_FRAME_SIZE := Vector2(480, 480)
const ITEM_REGIONS: Array[Rect2] = [
	Rect2(46, 48, 296, 282), Rect2(401, 14, 323, 348), Rect2(724, 77, 334, 265), Rect2(1151, 15, 237, 347),
	Rect2(77, 368, 236, 343), Rect2(362, 368, 362, 345), Rect2(767, 368, 285, 349), Rect2(1121, 395, 281, 292),
	Rect2(62, 724, 294, 328), Rect2(369, 722, 331, 318), Rect2(754, 725, 329, 316), Rect2(1119, 699, 314, 357),
]

const EXPANSION_REGIONS: Array[Rect2] = [
	Rect2(31, 30, 400, 397), Rect2(480, 44, 372, 364), Rect2(900, 0, 430, 426), Rect2(1330, 15, 416, 411),
	Rect2(23, 458, 384, 385), Rect2(461, 450, 414, 423), Rect2(916, 444, 380, 431), Rect2(1349, 440, 400, 435),
]

const EXPANSION_2_REGIONS: Array[Rect2] = [
	Rect2(53, 0, 368, 422), Rect2(443, 27, 436, 398), Rect2(908, 29, 431, 392), Rect2(1350, 10, 381, 428),
	Rect2(59, 433, 360, 424), Rect2(448, 447, 435, 411), Rect2(883, 421, 446, 440), Rect2(1342, 450, 419, 406),
]

const ITEM_COLUMNS := 4
const ITEM_ROWS := 3
const HUD_COLUMNS := 3
const HUD_ROWS := 2


static func item(index: int) -> Texture2D:
	if index >= 86:
		return _region(DODGE_ATLAS, clampi(index - 86, 0, 4), 3, 2)
	if index >= 78:
		return _region(ITEM_MYTHIC, clampi(index - 78, 0, 7), 4, 2)
	if index >= 30:
		return _region(ITEM_FAMILIES[(index - 30) / 16], (index - 30) % 16, 4, 4)
	if index >= 28:
		return _region(ITEM_ECONOMY, clampi(index - 28, 0, 1), 2, 1)
	if index >= 20:
		return _framed_region(ITEM_EXPANSION_2, EXPANSION_2_REGIONS[clampi(index - 20, 0, 7)], EXPANSION_FRAME_SIZE)
	if index >= ITEM_COLUMNS * ITEM_ROWS:
		return _framed_region(ITEM_EXPANSION, EXPANSION_REGIONS[clampi(index - ITEM_COLUMNS * ITEM_ROWS, 0, 7)], EXPANSION_FRAME_SIZE)
	return _framed_region(ITEM_ATLAS, ITEM_REGIONS[clampi(index, 0, ITEM_COLUMNS * ITEM_ROWS - 1)], ITEM_FRAME_SIZE)


static func hud(index: int) -> Texture2D:
	return _region(HUD_ATLAS, clampi(index, 0, HUD_COLUMNS * HUD_ROWS - 1), HUD_COLUMNS, HUD_ROWS)


static func stat(index: int) -> Texture2D:
	if index == 11:
		return STAMINA
	if index == 10:
		var dodge := _region(DODGE_ATLAS, 5, 3, 2) as AtlasTexture
		dodge.filter_clip = true
		return dodge
	return _framed_region(STAT_ATLAS, STAT_REGIONS[clampi(index, 0, STAT_REGIONS.size() - 1)], STAT_FRAME_SIZE)


static func relic(index: int) -> Texture2D:
	return _region(RELIC_ATLAS, clampi(index, 0, 4), 3, 2)


static func _region(atlas: Texture2D, index: int, columns: int, rows: int) -> Texture2D:
	var size := Vector2(atlas.get_size()) / Vector2(columns, rows)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(index % columns, floori(float(index) / float(columns))) * size, size)
	texture.filter_clip = true
	return texture


static func _framed_region(atlas: Texture2D, region: Rect2, frame_size: Vector2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	var padding := frame_size - region.size
	texture.margin = Rect2(padding * 0.5, padding)
	texture.filter_clip = true
	return texture
