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
		return _region(ITEM_EXPANSION_2, clampi(index - 20, 0, 7), 4, 2)
	if index >= ITEM_COLUMNS * ITEM_ROWS:
		return _region(ITEM_EXPANSION, clampi(index - ITEM_COLUMNS * ITEM_ROWS, 0, 7), 4, 2)
	return _region(ITEM_ATLAS, clampi(index, 0, ITEM_COLUMNS * ITEM_ROWS - 1), ITEM_COLUMNS, ITEM_ROWS)


static func hud(index: int) -> Texture2D:
	return _region(HUD_ATLAS, clampi(index, 0, HUD_COLUMNS * HUD_ROWS - 1), HUD_COLUMNS, HUD_ROWS)


static func stat(index: int) -> Texture2D:
	if index == 10:
		var dodge := _region(DODGE_ATLAS, 5, 3, 2) as AtlasTexture
		dodge.filter_clip = true
		return dodge
	var texture := AtlasTexture.new()
	texture.atlas = STAT_ATLAS
	texture.region = STAT_REGIONS[clampi(index, 0, STAT_REGIONS.size() - 1)]
	var padding := STAT_FRAME_SIZE - texture.region.size
	texture.margin = Rect2(padding * 0.5, padding)
	texture.filter_clip = true
	return texture


static func relic(index: int) -> Texture2D:
	return _region(RELIC_ATLAS, clampi(index, 0, 4), 3, 2)


static func _region(atlas: Texture2D, index: int, columns: int, rows: int) -> Texture2D:
	var size := Vector2(atlas.get_size()) / Vector2(columns, rows)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(index % columns, floori(float(index) / float(columns))) * size, size)
	return texture
