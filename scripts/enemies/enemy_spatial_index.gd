class_name EnemySpatialIndex
extends Node2D

# Queries return live enemies passing the precise circle/segment hit test.
const CELL_SIZE := 128.0
var cells: Dictionary[Vector2i, Array] = {}
var membership: Dictionary[int, Vector2i] = {}
var bosses: Array[Enemy] = []
var maximum_radius: float = 0.0
var next_order: int = 0
var shadow_batch := EnemyShadowBatch.new()
var had_attack_visuals := false

func _ready() -> void:
	process_priority = 1
	set_process(not membership.is_empty())

func _process(_delta: float) -> void:
	var has_attack_visuals := shadow_batch.update()
	if has_attack_visuals or had_attack_visuals:
		queue_redraw()
	had_attack_visuals = has_attack_visuals

func _draw() -> void:
	draw_multimesh(shadow_batch.multimesh, shadow_batch.texture)
	# Draw telegraphs together below all sprites instead of alternating between
	# each enemy's primitive geometry and texture. No extra gameplay children.
	for enemy in shadow_batch.enemies:
		if enemy.health <= 0.0 or not enemy.visible or enemy.is_queued_for_deletion():
			continue
		if enemy.special_phase != Enemy.SpecialPhase.COOLDOWN:
			draw_set_transform_matrix(enemy.transform)
			enemy.draw_attack_visuals(self, enemy.transform)
	draw_set_transform_matrix(Transform2D.IDENTITY)

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
	shadow_batch.enemies.append(enemy)
	set_process(true)
	queue_redraw()
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
	shadow_batch.enemies.erase(enemy)
	queue_redraw()
	if membership.is_empty():
		maximum_radius = 0.0
		next_order = 0
		shadow_batch.multimesh.visible_instance_count = 0
		set_process(false)

func _remove_from_cell(enemy: Enemy, cell: Vector2i) -> void:
	cells[cell].erase(enemy)
	if cells[cell].is_empty():
		cells.erase(cell)

func _cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL_SIZE), floori(at.y / CELL_SIZE))

func in_circle(at: Vector2, radius: float, include_radius: bool = true) -> Array[Enemy]:
	var padding := radius + (maximum_radius if include_radius else 0.0)
	var bounds := global_transform.affine_inverse() * Rect2(at - Vector2.ONE * padding, Vector2.ONE * padding * 2.0)
	var first := _cell(bounds.position)
	var last := _cell(bounds.end)
	var result: Array[Enemy] = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			if not cells.has(cell):
				continue
			for enemy: Enemy in cells[cell]:
				if enemy.health <= 0 or enemy.is_queued_for_deletion():
					continue
				var reach := radius + (enemy.data.radius if include_radius else 0.0)
				if at.distance_squared_to(enemy.global_position) <= reach * reach:
					result.append(enemy)
	_sort(result)
	return result

func along_segment(start: Vector2, end: Vector2, radius: float, ordered: bool = true, excluded_ids: Array[int] = []) -> Array[Enemy]:
	var padding := Vector2.ONE * (radius + maximum_radius)
	var bounds := global_transform.affine_inverse() * Rect2(start.min(end) - padding, (end - start).abs() + padding * 2.0)
	var first := _cell(bounds.position)
	var last := _cell(bounds.end)
	var result: Array[Enemy] = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			if not cells.has(cell):
				continue
			for enemy: Enemy in cells[cell]:
				if enemy.health <= 0 or enemy.is_queued_for_deletion() or excluded_ids.has(enemy.get_instance_id()):
					continue
				var position_world := enemy.global_position
				var closest_point := Geometry2D.get_closest_point_to_segment(position_world, start, end)
				var reach := radius + enemy.data.radius
				if closest_point.distance_squared_to(position_world) <= reach * reach:
					result.append(enemy)
	if ordered:
		_sort(result)
	return result

func closest(at: Vector2, radius: float, include_radius: bool = true, excluded: Enemy = null, distance_origin: Vector2 = Vector2.INF) -> Enemy:
	var padding := radius + (maximum_radius if include_radius else 0.0)
	var bounds := Rect2(at - Vector2.ONE * padding, Vector2.ONE * padding * 2.0)
	var local_bounds := global_transform.affine_inverse() * bounds
	var first := _cell(local_bounds.position)
	var last := _cell(local_bounds.end)
	var origin := at if distance_origin == Vector2.INF else distance_origin
	var nearest: Enemy
	var best := INF
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			if not cells.has(cell):
				continue
			for enemy: Enemy in cells[cell]:
				if enemy == excluded or enemy.health <= 0 or enemy.is_queued_for_deletion():
					continue
				var position_world := enemy.global_position
				var reach := radius + (enemy.data.radius if include_radius else 0.0)
				if at.distance_squared_to(position_world) > reach * reach:
					continue
				var distance := origin.distance_squared_to(position_world)
				if distance < best or (distance == best and nearest != null and enemy.spatial_order < nearest.spatial_order):
					best = distance
					nearest = enemy
	return nearest

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
	var result: Array[Enemy] = []
	for enemy in _fallback(tree):
		var reach := radius + (enemy.data.radius if include_radius else 0.0)
		if at.distance_squared_to(enemy.global_position) <= reach * reach:
			result.append(enemy)
	return result

static func segment(tree: SceneTree, index: EnemySpatialIndex, start: Vector2, end: Vector2, radius: float, ordered: bool = true, excluded_ids: Array[int] = []) -> Array[Enemy]:
	if is_instance_valid(index):
		return index.along_segment(start, end, radius, ordered, excluded_ids)
	var result: Array[Enemy] = []
	for enemy in _fallback(tree):
		if excluded_ids.has(enemy.get_instance_id()):
			continue
		var closest_point := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		var reach := radius + enemy.data.radius
		if closest_point.distance_squared_to(enemy.global_position) <= reach * reach:
			result.append(enemy)
	return result

static func nearest(tree: SceneTree, index: EnemySpatialIndex, at: Vector2, radius: float, include_radius: bool = true, excluded: Enemy = null, distance_origin: Vector2 = Vector2.INF) -> Enemy:
	if is_instance_valid(index):
		return index.closest(at, radius, include_radius, excluded, distance_origin)
	var origin := at if distance_origin == Vector2.INF else distance_origin
	var result: Enemy
	var best := INF
	for enemy in circle(tree, null, at, radius, include_radius):
		var distance := origin.distance_squared_to(enemy.global_position)
		if enemy != excluded and distance < best:
			best = distance
			result = enemy
	return result

static func _fallback(tree: SceneTree) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in tree.get_nodes_in_group("enemies"):
		if node is Enemy and node.health > 0.0 and not node.is_queued_for_deletion():
			result.append(node)
	return result
