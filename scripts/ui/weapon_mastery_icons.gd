class_name WeaponMasteryIcons
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/ui/weapon_mastery_badges.png")
static var cache: Dictionary = {}


static func icon(index: int) -> Texture2D:
	index = clampi(index, 0, 3)
	if not cache.has(index):
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = Rect2(index % 2 * 512, index / 2 * 512, 512, 512)
		texture.filter_clip = true
		cache[index] = texture
	return cache[index]
