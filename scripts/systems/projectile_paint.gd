class_name ProjectilePaint
extends RefCounted

# Artist source is only read by atlas bakers or the nonstandard-data fallback.
# Normal combat reads the already packed enemy/player atlases.
const SOURCE := "res://assets/vfx/projectile_art_source.png"
const EXTRA_SOURCE := "res://assets/vfx/projectile_art_extra_source.png"
enum Kind { WATER, LIGHT, ROCKET, ACID, BLOOD, EMBER, PASTE, MINT, METAL }
const ANCHORS := [Vector2(385, 285), Vector2(380, 285), Vector2(370, 285), Vector2(390, 258), Vector2(365, 258), Vector2(370, 258), Vector2(390, 247), Vector2(370, 247), Vector2(388, 247)]
const CORE_RADII := [110.0, 90.0, 100.0, 110.0, 85.0, 105.0, 96.0, 94.0, 96.0]
static var source_images: Dictionary[String, Image] = {}

static func player_kind(tint: Color) -> Kind:
	if absf(tint.r - tint.g) < 0.13 and absf(tint.g - tint.b) < 0.13:
		return Kind.METAL
	if tint.r > 0.9 and tint.b < 0.85:
		return Kind.LIGHT
	if tint.r > 0.6 and tint.g > 0.9 and tint.b > 0.85:
		return Kind.PASTE
	return Kind.MINT if tint.g > 0.8 and tint.b < 0.8 else Kind.WATER

static func enemy_kind(tint: Color) -> Kind:
	if tint.g > tint.r and tint.g > tint.b:
		return Kind.ACID
	return Kind.BLOOD if tint.b > tint.g else Kind.EMBER

static func image(kind: Kind, radius: float) -> Image:
	var path := EXTRA_SOURCE if kind >= Kind.PASTE else SOURCE
	if not source_images.has(path):
		# Load imported textures too: the raw PNG need not exist in exported PCKs.
		var source := load(path) as Texture2D
		source_images[path] = source.get_image()
	var source_image := source_images[path]
	var cell_size := source_image.get_width() / 3
	var slot := int(kind) - int(Kind.PASTE) if kind >= Kind.PASTE else int(kind)
	var cell := source_image.get_region(Rect2i((slot % 3) * cell_size, (slot / 3) * cell_size, cell_size, cell_size))
	var factor: float = radius * 2.0 / CORE_RADII[kind]
	var size := maxi(1, roundi(512.0 * factor))
	cell.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var anchor: Vector2i = Vector2i((ANCHORS[kind] * size / 512.0).round())
	# Symmetric canvas places the painted solid head on the collision origin.
	var extent := anchor.max(Vector2i.ONE * size - anchor) + Vector2i(3, 3)
	var result := Image.create(extent.x * 2, extent.y * 2, false, Image.FORMAT_RGBA8)
	result.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), extent - anchor)
	return result
