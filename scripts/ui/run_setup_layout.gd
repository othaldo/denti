class_name RunSetupLayout
extends RefCounted

# Undo shrinking below the canvas design size locally, so a 48-unit menu
# target remains usable on phones/small windows. Combat keeps its own scale.
static func ui_scale(viewport: Viewport) -> float:
	var scale := viewport.get_screen_transform().get_scale()
	return 1.0 / clampf(minf(scale.x, scale.y), 0.1, 1.0)

# All measurements are in canvas coordinates, independent of window pixels.
static func stage(safe: Rect2) -> Rect2:
	var compact := safe.size.x < 600 or safe.size.y < 480
	var margin := Vector2(12, 12) if compact else Vector2(48, 36)
	var available := safe.size - margin * 2
	var extent := Vector2(minf(1600, available.x), minf(950, available.y))
	return Rect2(safe.position + (safe.size - extent) * 0.5, extent)

static func body(stage_size: Vector2) -> Rect2:
	var compact := stage_size.x < 600 or stage_size.y < 480
	var header := 44.0 if compact else 60.0
	var gap := 12.0 if compact else 28.0
	var footer := 52.0 if compact else 56.0
	return Rect2(0, header + gap, stage_size.x, maxf(48, stage_size.y - header - footer - gap * 2))

static func difficulty_cells(extent: Vector2) -> Array[Rect2]:
	var columns := 2 if extent.y > extent.x else 4
	var gap := 12.0 if extent.x < 600 else 20.0
	var count_rows := 4 / columns
	var width := (extent.x - gap * (columns - 1)) / columns
	var height := minf((extent.y - gap * (count_rows - 1)) / count_rows, width * 1.1)
	var origin := Vector2(0, (extent.y - height * count_rows - gap * (count_rows - 1)) * 0.5)
	var cells: Array[Rect2] = []
	for index in 4:
		cells.append(Rect2(origin + Vector2(index % columns * (width + gap), (index / columns) * (height + gap)), Vector2(width, height)))
	return cells

static func weapons(extent: Vector2, count: int) -> Dictionary:
	var portrait := extent.y > extent.x
	var gap := 16.0 if extent.x < 600 else 36.0
	var separation := (6.0 if portrait else 4.0) if extent.x < 600 else 10.0
	var columns := 5 if portrait and extent.x < 400 else 6
	var gallery_width := extent.x if portrait else extent.x * 0.58
	var cell := clampf(floorf((gallery_width - (columns - 1) * separation) / columns), 48, 112)
	var rows := ceili(float(count) / columns)
	var gallery_height := rows * cell + maxi(0, rows - 1) * separation
	var preview_height := clampf(extent.x * 0.28, 124, 190) if portrait else extent.y
	var max_gallery := extent.y - preview_height - gap if portrait else extent.y
	gallery_height = minf(gallery_height, max_gallery)
	var group_height := gallery_height + gap + preview_height if portrait else maxf(gallery_height, preview_height)
	var top := maxf(0, (extent.y - group_height) * 0.5)
	var preview := Rect2(0, top + gallery_height + gap, extent.x, preview_height) if portrait else Rect2(gallery_width + gap, 0, extent.x - gallery_width - gap, extent.y)
	return {"gallery": Rect2(0, top if portrait else (extent.y - gallery_height) * 0.5, gallery_width, maxf(48, gallery_height)), "preview": preview,
		"columns": columns, "cell": cell, "separation": separation, "portrait": portrait}
