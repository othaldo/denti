class_name HUDProgressionFrame
extends Control

# Small-size variant: broad rim, smooth tooth crown and larger clear inset.
# The original ornate atlas remains untouched as a reference.
const ART: Texture2D = preload("res://assets/ui/level_seal_compact.png")
const SEAL := Rect2(62, 85, 1213, 986)
static var _filtered_art: ImageTexture


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if _filtered_art == null:
		var image := ART.get_image()
		image.generate_mipmaps()
		_filtered_art = ImageTexture.create_from_image(image)
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var extent := SEAL.size * minf(size.x / SEAL.size.x, size.y / SEAL.size.y)
	draw_texture_rect_region(_filtered_art, Rect2((size - extent) * 0.5, extent), SEAL)
