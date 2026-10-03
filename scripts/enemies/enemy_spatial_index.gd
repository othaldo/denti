class_name EnemySpatialIndex
extends Node2D

# Broad phase only: attacks still apply their original precise hit tests.
const CELL_SIZE := 128.0
var cells: Dictionary[Vector2i, Array] = {}
var membership: Dictionary[int, Vector2i] = {}
var bosses: Array[Enemy] = []
var maximum_radius: float = 0.0
var next_order: int = 0

func register(enemy: Enemy) -> void:
	var id := enemy.get_instance_id()
	if membership.has(id):
		return
	enemy.spatial_order = next_order
	next_order += 1
	maximum_radius = maxf(maximum_radius, enemy.data.radius)
	var cell := _cell(enemy.position)
	membership[id] = cell
	if not cells.has(cell):
		cells[cell] = []
	cells[cell].append(enemy)
	if enemy.data.is_boss:
		bosses.append(enemy)

func update(enemy: Enemy) -> void:
	var id := enemy.get_instance_id()
	if not membership.has(id):
		return
	var cell := _cell(enemy.position)
	var previous := membership[id]
	if cell == previous:
		return
	_remove_from_cell(enemy, previous)
	membership[id] = cell
	if not cells.has(cell):
		cells[cell] = []
	cells[cell].append(enemy)

func unregister(enemy: Enemy) -> void:
	var id := enemy.get_instance_id()
	if membership.has(id):
		_remove_from_cell(enemy, membership[id])
		membership.erase(id)
	bosses.erase(enemy)
	if membership.is_empty():
		maximum_radius = 0.0
		next_order = 0

func _remove_from_cell(enemy: Enemy, cell: Vector2i) -> void:
	cells[cell].erase(enemy)
	if cells[cell].is_empty():
		cells.erase(cell)

func _cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL_SIZE), floori(at.y / CELL_SIZE))

func in_circle(at: Vector2, radius: float, include_radius: bool = true) -> Array[Enemy]:
	var padding := radius + (maximum_radius if include_radius else 0.0)
	var candidates := in_rect(Rect2(at - Vector2.ONE * padding, Vector2.ONE * padding * 2.0), false)
	var result: Array[Enemy] = []
	for enemy in candidates:
		var reach := radius + (enemy.data.radius if include_radius else 0.0)
		if at.distance_squared_to(enemy.global_position) <= reach * reach:
			result.append(enemy)
	_sort(result)
	return result

func along_segment(start: Vector2, end: Vector2, radius: float) -> Array[Enemy]:
	var padding := Vector2.ONE * (radius + maximum_radius)
	var candidates := in_rect(Rect2(start.min(end) - padding, (end - start).abs() + padding * 2.0), false)
	var result: Array[Enemy] = []
	for enemy in candidates:
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		var reach := radius + enemy.data.radius
		if closest.distance_squared_to(enemy.global_position) <= reach * reach:
			result.append(enemy)
	_sort(result)
	return result

func in_rect(bounds: Rect2, ordered: bool = true) -> Array[Enemy]:
	# Store parent-local positions so moving the whole arena cannot stale the grid.
	var local_bounds := global_transform.affine_inverse() * bounds
	var first := _cell(local_bounds.position)
	var last := _cell(local_bounds.end)
	var result: Array[Enemy] = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			if not cells.has(cell):
				continue
			for enemy: Enemy in cells[cell]:
				if enemy.health > 0.0 and not enemy.is_queued_for_deletion():
					result.append(enemy)
	if ordered:
		_sort(result)
	return result

func _sort(enemies: Array[Enemy]) -> void:
	# Preserve spawn order for tied targets and chained item effects.
	if enemies.size() > 1:
		enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.spatial_order < b.spatial_order)

static func circle(tree: SceneTree, index: EnemySpatialIndex, at: Vector2, radius: float, include_radius: bool = true) -> Array[Enemy]:
	if is_instance_valid(index):
		return index.in_circle(at, radius, include_radius)
	return _fallback(tree)

static func segment(tree: SceneTree, index: EnemySpatialIndex, start: Vector2, end: Vector2, radius: float) -> Array[Enemy]:
	if is_instance_valid(index):
		return index.along_segment(start, end, radius)
	return _fallback(tree)

static func _fallback(tree: SceneTree) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in tree.get_nodes_in_group("enemies"):
		if node is Enemy and node.health > 0.0 and not node.is_queued_for_deletion():
			result.append(node)
	return result
