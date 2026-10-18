extends SceneTree

# Derived shader data only; the painted tooth source is never modified.
var _side := 512
const PADDING := 0.25
const LARGE := 1.0e12


func _initialize() -> void:
	var transition := "--transition" in OS.get_cmdline_user_args()
	if transition:
		_side = 2048
	var source := load("res://assets/ui/tooth_vessel_frame.png") as Texture2D
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(source.get_image(), 0.3)
	var contour := PackedVector2Array()
	var largest := 0.0
	for polygon in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, bitmap.get_size()), 1.5):
		var area := 0.0
		for index in polygon.size():
			area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
		if absf(area) > largest:
			largest = absf(area)
			contour = polygon
	var lengths := PackedFloat64Array([0.0])
	for index in contour.size():
		lengths.append(lengths[-1] + contour[index].distance_to(contour[(index + 1) % contour.size()]))
	var smooth := PackedVector2Array()
	var edge := 0
	for index in 128:
		var target := lengths[-1] * index / 128.0
		while edge + 1 < contour.size() and lengths[edge + 1] < target:
			edge += 1
		var weight := (target - lengths[edge]) / maxf(0.001, lengths[edge + 1] - lengths[edge])
		smooth.append(contour[edge].lerp(contour[(edge + 1) % contour.size()], weight) / source.get_size())
	# Chaikin refinement removes raster stair steps while preserving the molar.
	for pass_index in 2:
		var refined := PackedVector2Array()
		for index in smooth.size():
			var a := smooth[index]
			var b := smooth[(index + 1) % smooth.size()]
			refined.append(a.lerp(b, 0.25))
			refined.append(a.lerp(b, 0.75))
		smooth = refined
	var polygon := PackedVector2Array()
	for point in smooth:
		polygon.append((point + Vector2.ONE * PADDING) * _side / (1.0 + PADDING * 2.0))
	var mask := PackedByteArray()
	mask.resize(_side * _side)
	for y in _side:
		var scan_y := y + 0.5
		var hits: Array[float] = []
		for index in polygon.size():
			var a := polygon[index]
			var b := polygon[(index + 1) % polygon.size()]
			if (a.y <= scan_y and b.y > scan_y) or (b.y <= scan_y and a.y > scan_y):
				hits.append(a.x + (scan_y - a.y) * (b.x - a.x) / (b.y - a.y))
		hits.sort()
		for pair in range(0, hits.size() - 1, 2):
			for x in range(maxi(0, ceili(hits[pair] - 0.5)), mini(_side, floori(hits[pair + 1] - 0.5) + 1)):
				mask[y * _side + x] = 1
	var outside := _distance(mask, 1)
	var inside := _distance(mask, 0)
	var pixels := PackedByteArray()
	pixels.resize(_side * _side * 2)
	for index in mask.size():
		var distance := -sqrt(inside[index]) if mask[index] == 1 else sqrt(outside[index])
		# Store signed distance in source-tooth units, packed as 16-bit RG.
		var encoded := clampi(roundi((0.5 + distance * 1.5 / _side * 2.0) * 65535.0), 0, 65535)
		pixels[index * 2] = encoded >> 8
		pixels[index * 2 + 1] = encoded & 255
	var image := Image.create_from_data(_side, _side, false, Image.FORMAT_RG8, pixels)
	var texture := ImageTexture.create_from_image(image)
	var path := "res://assets/ui/tooth_transition_distance.res" if transition else "res://assets/ui/tooth_shield_distance.res"
	var error := ResourceSaver.save(texture, path, ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		push_error("Could not save shield distance data: %s" % error)
		quit(1)
		return
	print("Baked smooth shield distance field: " + path)
	quit()


func _distance(mask: PackedByteArray, feature: int) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	result.resize(_side * _side)
	for y in _side:
		var row := PackedFloat64Array()
		row.resize(_side)
		for x in _side:
			row[x] = 0.0 if mask[y * _side + x] == feature else LARGE
		var transformed := _edt(row)
		for x in _side:
			result[y * _side + x] = transformed[x]
	for x in _side:
		var column := PackedFloat64Array()
		column.resize(_side)
		for y in _side:
			column[y] = result[y * _side + x]
		var transformed := _edt(column)
		for y in _side:
			result[y * _side + x] = transformed[y]
	return result


func _edt(values: PackedFloat64Array) -> PackedFloat64Array:
	var sites := PackedInt32Array()
	sites.resize(_side)
	var breaks := PackedFloat64Array()
	breaks.resize(_side + 1)
	breaks[0] = -INF
	breaks[1] = INF
	var k := 0
	for q in range(1, _side):
		var p := sites[k]
		var boundary := ((values[q] + q * q) - (values[p] + p * p)) / (2.0 * (q - p))
		while boundary <= breaks[k]:
			k -= 1
			p = sites[k]
			boundary = ((values[q] + q * q) - (values[p] + p * p)) / (2.0 * (q - p))
		k += 1
		sites[k] = q
		breaks[k] = boundary
		breaks[k + 1] = INF
	var result := PackedFloat64Array()
	result.resize(_side)
	k = 0
	for q in _side:
		while breaks[k + 1] < q:
			k += 1
		var offset := q - sites[k]
		result[q] = offset * offset + values[sites[k]]
	return result
