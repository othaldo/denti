class_name HUDPaintedFrame
extends Control

# Only the straight middle repeats. Both end pieces and every tile use one
# uniform scale, determined by height; width never deforms painted artwork.
const CAP_FRACTION := 0.13
const TILE_SOURCE_WIDTH := 64.0
const INSET_MASK: Shader = preload("res://scripts/ui/boss_frame_mask.gdshader")
static var _regions: Dictionary[String, Rect2] = {}

var _texture: Texture2D
var _region: Rect2


func _init(path: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture = load(path)
	if not _regions.has(path):
		# Ignore almost transparent generation haze without editing the PNG.
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(_texture.get_image(), 0.12)
		var region := Rect2(Vector2.ZERO, _texture.get_size())
		var largest := 0.0
		for polygon in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, bitmap.get_size()), 2.0):
			var bounds := Rect2(polygon[0], Vector2.ZERO)
			for point in polygon:
				bounds = bounds.expand(point)
			if bounds.get_area() > largest:
				largest = bounds.get_area()
				region = bounds
		_regions[path] = region.grow(2).intersection(Rect2(Vector2.ZERO, _texture.get_size()))
	_region = _regions[path]
	var mask := ShaderMaterial.new()
	mask.shader = INSET_MASK
	mask.set_shader_parameter("artwork_region", Vector4(_region.position.x, _region.position.y, _region.size.x, _region.size.y))
	material = mask
	resized.connect(queue_redraw)
	resized.connect(_sync_material)
	_sync_material()


func _sync_material() -> void:
	material.set_shader_parameter("frame_width", size.x)
	material.set_shader_parameter("edge_inset", cap_width() * 0.5)


func show_health(ratio: float) -> void:
	material.set_shader_parameter("health_fill", clampf(ratio, 0, 1))


func cap_width() -> float:
	return _region.size.x * CAP_FRACTION * size.y / _region.size.y


func _draw() -> void:
	if size.y <= 0:
		return
	var uniform_scale := size.y / _region.size.y
	var source_cap := _region.size.x * CAP_FRACTION
	var cap := cap_width()
	if size.x < cap * 2:
		return
	var height := _region.size.y
	draw_texture_rect_region(_texture, Rect2(0, 0, cap, size.y), Rect2(_region.position, Vector2(source_cap, height)))
	draw_texture_rect_region(_texture, Rect2(size.x - cap, 0, cap, size.y), Rect2(_region.end.x - source_cap, _region.position.y, source_cap, height))
	var tile_width := TILE_SOURCE_WIDTH * uniform_scale
	var source_x := _region.get_center().x - TILE_SOURCE_WIDTH * 0.5
	var x := cap
	var end := size.x - cap
	while x < end - 0.001:
		var width := minf(tile_width, end - x)
		# Crop the final partial tile; never squeeze it into the leftover space.
		draw_texture_rect_region(_texture, Rect2(x, 0, width, size.y), Rect2(source_x, _region.position.y, width / uniform_scale, height))
		x += width
