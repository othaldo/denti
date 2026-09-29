class_name DentiUIIcons
extends RefCounted

const ITEM_ATLAS: Texture2D = preload("res://assets/items/item_icons_atlas.png")
const ITEM_EXPANSION: Texture2D = preload("res://assets/items/item_icons_expansion.png")
const HUD_ATLAS: Texture2D = preload("res://assets/ui/hud_icons_atlas.png")
const ITEM_COLUMNS := 4
const ITEM_ROWS := 3
const HUD_COLUMNS := 3
const HUD_ROWS := 2


static func item(index: int) -> Texture2D:
	if index >= ITEM_COLUMNS * ITEM_ROWS:
		return _region(ITEM_EXPANSION, clampi(index - ITEM_COLUMNS * ITEM_ROWS, 0, 7), 4, 2)
	return _region(ITEM_ATLAS, clampi(index, 0, ITEM_COLUMNS * ITEM_ROWS - 1), ITEM_COLUMNS, ITEM_ROWS)


static func hud(index: int) -> Texture2D:
	return _region(HUD_ATLAS, clampi(index, 0, HUD_COLUMNS * HUD_ROWS - 1), HUD_COLUMNS, HUD_ROWS)


static func _region(atlas: Texture2D, index: int, columns: int, rows: int) -> Texture2D:
	var size := Vector2(atlas.get_size()) / Vector2(columns, rows)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(index % columns, floori(float(index) / float(columns))) * size, size)
	return texture
