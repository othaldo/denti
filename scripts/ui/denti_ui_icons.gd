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
const POISON_ATLAS: Texture2D = preload("res://assets/items/item_icons_poison.png")
const TALENT_ATLAS: Texture2D = preload("res://assets/classes/talent_icons.webp")
const TALENT_COLUMNS := 8
const TALENT_ROWS := 4
const MOLAR_TALENT_ATLAS: Texture2D = preload("res://assets/classes/molar_talent_icons.webp")
const MOLAR_TALENT_COLUMNS := 5
const MOLAR_TALENT_ROWS := 3
const ASSASSIN_TALENT_ATLAS: Texture2D = preload("res://assets/classes/assassin_talent_icons.webp")
const ASSASSIN_TALENT_COLUMNS := 7
const ASSASSIN_TALENT_ROWS := 2
const ASSASSIN_TALENT_COUNT := 13
const ROSTER_TALENT_COLUMNS := 8
const ROSTER_TALENT_ROWS := 3
# Atlas order matches ATLAS_BASE in tools/generate_class_roster.py.
const ROSTER_TALENT_ATLASES: Array[Texture2D] = [
	preload("res://assets/classes/tooth_fairy_talent_icons.webp"),
	preload("res://assets/classes/ember_talent_icons.webp"),
	preload("res://assets/classes/rinser_talent_icons.webp"),
	preload("res://assets/classes/frost_warden_talent_icons.webp"),
]
const NECRO_TALENT_ATLAS: Texture2D = preload("res://assets/classes/necrodent_talent_icons.png")
const NECRO_TALENT_FIRST := 157
const NECRO_TALENT_REGIONS: Array[Rect2] = [
	Rect2(26, 50, 314, 289), Rect2(418, 70, 246, 254), Rect2(758, 70, 255, 249), Rect2(1104, 47, 318, 290),
	Rect2(45, 398, 267, 297), Rect2(395, 407, 285, 266), Rect2(745, 403, 314, 274), Rect2(1134, 388, 268, 306),
	Rect2(7, 788, 348, 242), Rect2(436, 760, 217, 274), Rect2(744, 746, 311, 298), Rect2(1108, 740, 316, 306),
	Rect2(95, 50, 177, 79),
]
const HUD_ATLAS: Texture2D = preload("res://assets/ui/hud_icons_atlas.png")
const STAT_ATLAS: Texture2D = preload("res://assets/ui/stat_icons_atlas.png")
const RANGE: Texture2D = preload("res://assets/ui/range.svg")
const STAMINA: Texture2D = preload("res://assets/ui/stamina_icon.png")
const ELEMENT_ATLAS: Texture2D = preload("res://assets/ui/element_icons_atlas.png")
const ELEMENT_ICON_START := 91
# Each painted motif is centered within the same frame; no neighboring pixels.
const ELEMENT_REGIONS: Array[Rect2] = [
	Rect2(86, 42, 406, 452), Rect2(577, 46, 387, 436),
	Rect2(1062, 103, 416, 369), Rect2(109, 535, 383, 420),
	Rect2(618, 525, 310, 429), Rect2(1100, 535, 332, 426),
]
const ELEMENT_FRAME_SIZE := Vector2(512, 512)
const SUPPORT_ATLAS: Texture2D = preload("res://assets/ui/weapon_support_icons_atlas.png")
const SUPPORT_ICON_START := 97
const SUPPORT_REGIONS: Array[Rect2] = [
	Rect2(14, 151, 515, 231), Rect2(556, 85, 440, 366),
	Rect2(1038, 94, 477, 359), Rect2(62, 498, 445, 435),
	Rect2(530, 503, 488, 445), Rect2(1023, 584, 502, 309),
]
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
	if index >= 103 and index <= 105:
		return _poison_icon(index - 103)
	if index >= SUPPORT_ICON_START and index < SUPPORT_ICON_START + SUPPORT_REGIONS.size():
		var region := SUPPORT_REGIONS[index - SUPPORT_ICON_START]
		# Equal visible length for wide arrows, round targets and diagonal slashes.
		var frame := Vector2.ONE * maxf(region.size.x, region.size.y) / 0.86
		return _framed_region(SUPPORT_ATLAS, region, frame)
	if index >= ELEMENT_ICON_START and index < ELEMENT_ICON_START + ELEMENT_REGIONS.size():
		return _framed_region(ELEMENT_ATLAS, ELEMENT_REGIONS[index - ELEMENT_ICON_START], ELEMENT_FRAME_SIZE)
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


static func talent(index: int) -> Texture2D:
	if index < 0: return null
	if index >= NECRO_TALENT_FIRST:
		var cell_index := index - NECRO_TALENT_FIRST
		if cell_index >= NECRO_TALENT_REGIONS.size(): return null
		var region := NECRO_TALENT_REGIONS[cell_index]
		var frame := Vector2.ONE * maxf(region.size.x, region.size.y) / 0.83
		return _framed_region(NECRO_TALENT_ATLAS, region, frame)
	var base_count := TALENT_COLUMNS * TALENT_ROWS
	if index < base_count:
		return _region(TALENT_ATLAS, index, TALENT_COLUMNS, TALENT_ROWS)
	var cell := index - base_count
	var molar_count := MOLAR_TALENT_COLUMNS * MOLAR_TALENT_ROWS
	if cell < molar_count:
		return _region(MOLAR_TALENT_ATLAS, cell, MOLAR_TALENT_COLUMNS, MOLAR_TALENT_ROWS)
	cell -= molar_count
	var assassin_capacity := ASSASSIN_TALENT_COLUMNS * ASSASSIN_TALENT_ROWS
	if cell < assassin_capacity:
		return _region(ASSASSIN_TALENT_ATLAS, cell, ASSASSIN_TALENT_COLUMNS, ASSASSIN_TALENT_ROWS) if cell < ASSASSIN_TALENT_COUNT else null
	cell -= assassin_capacity
	var atlas_capacity := ROSTER_TALENT_COLUMNS * ROSTER_TALENT_ROWS
	@warning_ignore("integer_division")
	var atlas_index := cell / atlas_capacity
	if atlas_index >= ROSTER_TALENT_ATLASES.size(): return null
	return _region(ROSTER_TALENT_ATLASES[atlas_index], cell % atlas_capacity, ROSTER_TALENT_COLUMNS, ROSTER_TALENT_ROWS)


static func stat(index: int) -> Texture2D:
	if index == 11:
		return STAMINA
	if index == 10:
		var dodge := _region(DODGE_ATLAS, 5, 3, 2) as AtlasTexture
		dodge.filter_clip = true
		return dodge
	return _framed_region(STAT_ATLAS, STAT_REGIONS[clampi(index, 0, STAT_REGIONS.size() - 1)], STAT_FRAME_SIZE)


## Painted 4 x 3 atlas for relics 6-17. Until it exists, those relics borrow
## an item icon (`RelicData.placeholder_item_icon`).
const RELIC_EXPANSION_PATH := "res://assets/relics/relic_icons_expansion.png"
const RELIC_EXPANSION_COLUMNS := 4
const RELIC_EXPANSION_ROWS := 3
const RELIC_EXPANSION_FIRST := 6


static func relic_icon(relic: RelicData) -> Texture2D:
	if relic.icon_index >= RELIC_EXPANSION_FIRST:
		if ResourceLoader.exists(RELIC_EXPANSION_PATH):
			return _region(load(RELIC_EXPANSION_PATH), relic.icon_index - RELIC_EXPANSION_FIRST, RELIC_EXPANSION_COLUMNS, RELIC_EXPANSION_ROWS)
		return item(maxi(relic.placeholder_item_icon, 0))
	return relic(relic.icon_index)


static func relic(index: int) -> Texture2D:
	if index == 5: return _poison_icon(2)
	return _region(RELIC_ATLAS, clampi(index, 0, 4), 3, 2)


static func _poison_icon(index: int) -> Texture2D:
	var size := POISON_ATLAS.get_size()
	var cell := Vector2(size.x / 3.0, size.y)
	return _framed_region(POISON_ATLAS, Rect2(Vector2(cell.x * index, 0), cell), Vector2.ONE * maxf(cell.x, cell.y))


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
