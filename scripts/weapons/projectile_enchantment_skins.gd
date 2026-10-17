class_name ProjectileEnchantmentSkins
extends RefCounted

# Compose on equipment changes, then share ordinary atlas quads in combat.
# No material variants, extra sprites, live emitters, or per-frame rasterization.
const PAGE_SIZE := Vector2i(2048, 1024)
const MAX_STYLES := 6
const MAX_PAGES := 1
static var fallback: ProjectileEnchantmentSkins
var entries: Dictionary[String, Array] = {}
var pages: Array[Dictionary] = []
var base_images: Dictionary[int, Image] = {}
var plain_frames: Dictionary[int, Array] = {}
var page_size := PAGE_SIZE
var prepared_keys: Array[String] = []
var composed_total := 0
var uploads_total := 0
var generation := 0

static func mask(values: Array[Dictionary]) -> int:
	var result := 0
	for value in values:
		var definition := WeaponAffixes.by_id(StringName(str(value.get("id", ""))))
		if definition != null and definition.projectile_effect_index >= 0:
			result |= 1 << definition.projectile_effect_index
	return result

static func base_texture(data: WeaponData, tier: int) -> Texture2D:
	if data.projectile_shape == &"rocket":
		return CombatSpriteTextures.rocket(data.projectile_color)
	var radius := 11.0 if data.splash_at_tier(tier) > 0 or data.pierce_at_tier(tier) > 0 else 7.0
	return CombatSpriteTextures.projectile(data.projectile_color, radius)

static func visual_radius(data: WeaponData, tier: int) -> float:
	return 13.0 if data.projectile_shape == &"rocket" else (11.0 if data.splash_at_tier(tier) > 0 or data.pierce_at_tier(tier) > 0 else 7.0)

static func unmanaged(base: Texture2D, values: Array[Dictionary], radius: float) -> Texture2D:
	return unmanaged_frames(base, values, radius)[0]

static func unmanaged_frames(base: Texture2D, values: Array[Dictionary], radius: float) -> Array[Texture2D]:
	if values.is_empty():
		return [base]
	if fallback == null:
		fallback = ProjectileEnchantmentSkins.new()
	return fallback.frames(base, mask(values), radius)

func _key(base: Texture2D, bits: int, radius: float) -> String:
	return "%d:%d:%s" % [base.get_instance_id(), bits, radius]

func prepare(weapons: Array[WeaponInstance]) -> void:
	var wanted: Dictionary[String, Dictionary] = {}
	var has_enchantment := false
	for weapon in weapons:
		if weapon.data.attack_mode != &"projectile":
			continue
		var bits := mask(weapon.affixes)
		has_enchantment = has_enchantment or bits != 0
		var base := base_texture(weapon.data, weapon.tier)
		var radius := visual_radius(weapon.data, weapon.tier)
		wanted[_key(base, bits, radius)] = {"base": base, "bits": bits, "radius": radius}
	if not has_enchantment:
		wanted.clear()
	var keys: Array[String] = []
	keys.assign(wanted.keys())
	keys.sort()
	if keys == prepared_keys and (not keys.is_empty() or entries.is_empty()):
		return
	clear()
	prepared_keys = keys
	var rectangles: Array[Vector2i] = []
	for spec: Dictionary in wanted.values():
		for frame in (1 if spec.bits == 0 else ProjectileParticleFrames.COUNT):
			rectangles.append(Vector2i(spec.base.get_size()))
	for candidate in [Vector2i(512, 256), Vector2i(1024, 512), PAGE_SIZE]:
		if _fits(rectangles, candidate):
			page_size = candidate
			break
	for spec: Dictionary in wanted.values():
		frames(spec.base, spec.bits, spec.radius, true, true)
	flush()

func clear() -> void:
	# Old in-flight sprites retain immutable textures from the old generation.
	# Never overwrite an atlas page still displayed by those projectiles.
	entries.clear()
	pages.clear()
	base_images.clear()
	plain_frames.clear()
	prepared_keys.clear()
	page_size = PAGE_SIZE
	generation += 1

func texture(base: Texture2D, bits: int, radius: float, deferred_upload: bool = false) -> Texture2D:
	return frames(base, bits, radius, deferred_upload)[0]

func frames(base: Texture2D, bits: int, radius: float, deferred_upload: bool = false, pack_plain: bool = false) -> Array[Texture2D]:
	var key := _key(base, bits, radius)
	if entries.has(key):
		return entries[key]
	if bits == 0 and not pack_plain:
		var id := base.get_instance_id()
		if not plain_frames.has(id):
			var single: Array[Texture2D] = [base]
			plain_frames[id] = single
		return plain_frames[id]
	if entries.size() >= MAX_STYLES:
		clear()
	var rectangles: Array[Vector2i] = []
	var frame_count := 1 if bits == 0 else ProjectileParticleFrames.COUNT
	for frame in frame_count:
		rectangles.append(Vector2i(base.get_size()))
	if not pages.is_empty() and not _fits(rectangles, page_size, pages[-1].cursor, pages[-1].row_height):
		clear()
	var animation: Array[Texture2D] = []
	for frame in frame_count:
		animation.append(_pack(compose(base, bits, radius, frame)))
	entries[key] = animation
	composed_total += 1
	if not deferred_upload:
		flush()
	return animation

func _pack(image: Image) -> AtlasTexture:
	var page := _page_for(image.get_size())
	var at: Vector2i = page.cursor
	page.image.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)
	page.cursor.x += image.get_width() + 4
	page.row_height = maxi(page.row_height, image.get_height())
	page.dirty = true
	var region := AtlasTexture.new()
	region.atlas = page.texture
	region.region = Rect2(at, image.get_size())
	region.filter_clip = true
	return region

func _fits(rectangles: Array[Vector2i], size: Vector2i, cursor: Vector2i = Vector2i(2, 2), row_height: int = 0) -> bool:
	for rect in rectangles:
		if cursor.x + rect.x + 2 > size.x:
			cursor = Vector2i(2, cursor.y + row_height + 4)
			row_height = 0
		if cursor.y + rect.y + 2 > size.y:
			return false
		cursor.x += rect.x + 4
		row_height = maxi(row_height, rect.y)
	return true

func _page_for(size: Vector2i) -> Dictionary:
	if not pages.is_empty():
		var page := pages[-1]
		if page.cursor.x + size.x + 2 > page_size.x:
			page.cursor = Vector2i(2, page.cursor.y + page.row_height + 4)
			page.row_height = 0
		if page.cursor.y + size.y + 2 <= page_size.y:
			return page
	if pages.size() >= MAX_PAGES:
		clear()
	var page := {"image": Image.create(page_size.x, page_size.y, false, Image.FORMAT_RGBA8), "texture": ImageTexture.new(), "cursor": Vector2i(2, 2), "row_height": 0, "dirty": false, "initialized": false}
	pages.append(page)
	return page

func flush() -> void:
	for page in pages:
		if not page.dirty:
			continue
		if page.initialized:
			page.texture.update(page.image)
		else:
			page.texture.set_image(page.image)
			page.initialized = true
		page.dirty = false
		uploads_total += 1

func compose(base: Texture2D, bits: int, radius: float, frame: int = 0) -> Image:
	var id := base.get_instance_id()
	if not base_images.has(id):
		base_images[id] = base.get_image()
	var definitions: Array[WeaponAffixData] = []
	for definition in WeaponAffixes.ALL:
		var index := definition.projectile_effect_index
		if index < 0 or bits & (1 << index) == 0:
			continue
		definitions.append(definition)
		if definitions.size() == WeaponAffixes.MAX_SLOTS:
			break
	return ProjectileParticleFrames.render(base_images[id], definitions, radius, frame)
