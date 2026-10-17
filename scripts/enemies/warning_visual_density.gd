class_name WarningVisualDensity
extends RefCounted

# Cosmetic only: normalize the painted fill where several warning strips
# overlap. Timers, impact boundaries and every attack remain fully present.
const SLICES := 8
const REFRESH_SECONDS := 0.1
const OVERLAP_BUDGET := 1.4
const BOSS_MIN_FILL := 0.35
const CELL_SIZE := 32.0
static var NO_SCALES := PackedFloat32Array()
static var FULL_SCALES := PackedFloat32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
var scales: Dictionary[int, PackedFloat32Array] = {}
var remaining := 0.0
var previous_count := -1
var lanes: Array[Enemy] = []
var starts: Array[Vector2] = []
var ends: Array[Vector2] = []
var sides: Array[Vector2] = []
var coverage_cells: Dictionary[Vector2i, int] = {}

func invalidate() -> void:
	remaining = 0.0

func update(delta: float, enemies: Array[Enemy], warning_count: int) -> void:
	remaining -= delta
	if remaining > 0.0 and warning_count == previous_count:
		return
	remaining = REFRESH_SECONDS
	previous_count = warning_count
	scales.clear()
	lanes.clear()
	starts.clear()
	ends.clear()
	sides.clear()
	coverage_cells.clear()
	if warning_count < 3:
		return
	for enemy in enemies:
		if enemy.health <= 0.0 or not enemy.visible or enemy.is_queued_for_deletion() or enemy.special_phase != Enemy.SpecialPhase.WARNING:
			continue
		var width := enemy.warning_lane_half_width()
		if width <= 0.0:
			continue
		var local_end := enemy.warning_lane_end()
		var start := enemy.to_global(enemy.warning_lane_start())
		var end := enemy.to_global(local_end)
		if start.distance_squared_to(end) < 1.0:
			continue
		var side := enemy.global_transform.basis_xform(local_end.normalized().orthogonal() * width)
		lanes.append(enemy)
		starts.append(start)
		ends.append(end)
		sides.append(side)
		var box := Rect2(start - side, Vector2.ZERO).expand(start + side).expand(end - side).expand(end + side)
		_add_coverage(start, end, side.length(), box)
	for index in lanes.size():
		var values := PackedFloat32Array()
		values.resize(SLICES + 1)
		var reduced := false
		for sample in SLICES + 1:
			# Sample both halves as well as the center so oblique intersections
			# cannot become an opaque edge beside an otherwise clear center.
			var point := starts[index].lerp(ends[index], float(sample) / SLICES)
			var overlap := maxi(_coverage(point), maxi(_coverage(point + sides[index] * 0.6), _coverage(point - sides[index] * 0.6)))
			var value := 1.0 if overlap <= 2 else OVERLAP_BUDGET / overlap
			if lanes[index].data.is_boss:
				value = maxf(value, BOSS_MIN_FILL)
			values[sample] = value
			reduced = reduced or value < 1.0
		if reduced:
			scales[lanes[index].get_instance_id()] = values

func _coverage(point: Vector2) -> int:
	return maxi(coverage_cells.get(Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE)), 0), 1)

func _add_coverage(start: Vector2, end: Vector2, half_width: float, box: Rect2) -> void:
	var length := start.distance_to(end)
	var forward := (end - start) / length
	var side := forward.orthogonal()
	# Conservative cell coverage avoids missing a narrow oblique crossing.
	# It only affects cosmetic opacity, never a hit or warning boundary.
	var margin := CELL_SIZE * 0.707107
	var first := Vector2i(floori(box.position.x / CELL_SIZE), floori(box.position.y / CELL_SIZE))
	var last := Vector2i(floori(box.end.x / CELL_SIZE), floori(box.end.y / CELL_SIZE))
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var offset := Vector2((x + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE) - start
			var along := offset.dot(forward)
			if along < -margin or along > length + margin or absf(offset.dot(side)) > half_width + margin:
				continue
			var cell := Vector2i(x, y)
			coverage_cells[cell] = int(coverage_cells.get(cell, 0)) + 1
