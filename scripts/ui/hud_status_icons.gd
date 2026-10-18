class_name HUDStatusIcons
extends RefCounted

# Painted source images stay intact. Trim only transparent padding at runtime,
# then center each complete motif in a square frame for the small HUD slots.
const SOURCES: Dictionary = {
	&"poison": preload("res://assets/ui/status/poison.png"),
	&"bleed": preload("res://assets/ui/status/bleed.png"),
	&"shield": preload("res://assets/ui/status/shield.png"),
	&"inflammation": preload("res://assets/ui/status/inflammation.png"),
	&"pause": preload("res://assets/ui/status/pause.png"),
}
static var _frames: Dictionary[StringName, AtlasTexture] = {}


static func texture(id: StringName) -> AtlasTexture:
	if _frames.has(id):
		return _frames[id]
	var source := SOURCES[id] as Texture2D
	var image := source.get_image()
	var region := Rect2(image.get_used_rect().grow(2).intersection(Rect2i(Vector2i.ZERO, image.get_size())))
	var side := maxf(region.size.x, region.size.y)
	var padding := Vector2.ONE * side - region.size
	var frame := AtlasTexture.new()
	frame.atlas = source
	frame.region = region
	frame.margin = Rect2(padding * 0.5, padding)
	frame.filter_clip = true
	_frames[id] = frame
	return frame
