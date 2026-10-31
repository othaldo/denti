extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _painted_pixels(image: Image) -> int:
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var count := 0
	for offset in range(3, bytes.size(), 4):
		if bytes[offset] > 0:
			count += 1
	return count


func _solid_components(image: Image) -> int:
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var bytes := image.get_data()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var count := 0
	for start in width * height:
		if seen[start] or bytes[start * 4 + 3] < 128:
			continue
		seen[start] = 1
		var pending: Array[int] = [start]
		var area := 0
		while not pending.is_empty():
			var at := pending.pop_back() as int
			area += 1
			for neighbor in [at - width, at + width, at - 1 if at % width > 0 else -1, at + 1 if at % width < width - 1 else -1]:
				if neighbor >= 0 and neighbor < seen.size() and not seen[neighbor] and bytes[neighbor * 4 + 3] >= 128:
					seen[neighbor] = 1
					pending.append(neighbor)
		if area >= 16:
			count += 1
	return count


func _run() -> void:
	var counts := {}
	var regions := {}
	for item in ItemCatalog.ALL:
		var icon: Texture2D = item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index)
		if item.icon_texture == null:
			_check(icon is AtlasTexture and icon.filter_clip, "item atlas filtering is not isolated: " + str(item.id))
	# Check every legacy motif, including the original scaler not currently sold.
	for index in 28:
		var icon := DentiUIIcons.item(index) as AtlasTexture
		var source := icon.atlas.get_image()
		for previous: Rect2 in regions.get(icon.atlas, []):
			var overlap := icon.region.intersection(previous)
			if overlap.has_area():
				_check(_painted_pixels(source.get_region(Rect2i(overlap))) == 0, "neighboring icons share painted source pixels")
		if not regions.has(icon.atlas):
			regions[icon.atlas] = []
		regions[icon.atlas].append(icon.region)
		var selected := source.get_region(Rect2i(icon.region))
		var used := selected.get_used_rect()
		_check(icon.get_size().x == icon.get_size().y, "item frame is not square: %d" % index)
		var visible := Rect2(used).grow(4)
		visible.position += icon.margin.position
		_check(Rect2(Vector2.ZERO, icon.get_size()).encloses(visible), "item is cut off or lacks breathing room: %d" % index)
		counts[icon.atlas] = int(counts.get(icon.atlas, 0)) + _painted_pixels(selected)
		if index == 7:
			_check(_solid_components(selected) == 1, "ceramic shell contains a fragment from another motif")
	for atlas: Texture2D in counts:
		_check(int(counts[atlas]) == _painted_pixels(atlas.get_image()), "source artwork was omitted or selected twice: " + atlas.resource_path)
	for index in 6:
		_check((DentiUIIcons.hud(index) as AtlasTexture).filter_clip, "HUD atlas filtering is not isolated")
	for index in 5:
		_check((DentiUIIcons.relic(index) as AtlasTexture).filter_clip, "relic atlas filtering is not isolated")
	print("Denti item icon isolation and complete artwork test passed" if failures.is_empty() else "%d icon region failures" % failures.size())
	finish(0 if failures.is_empty() else 1)
