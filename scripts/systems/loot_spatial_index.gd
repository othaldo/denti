class_name LootSpatialIndex
extends Node2D

# Ground loot is stationary until Denti enters its pickup/magnet range.
# Only nearby cells need a per-tick distance test; the wave sweep visits all drops.
const CELL_SIZE := 128.0
@onready var player: Player = get_node("../Player")
var cells: Dictionary[Vector2i, Array] = {}
var membership: Dictionary[int, Vector2i] = {}
var collecting: Dictionary[int, Loot] = {}
var next_order: int = 0
var last_candidates: int = 0

func _ready() -> void:
	set_physics_process(not membership.is_empty())

func register(drop: Loot) -> void:
	var id := drop.get_instance_id()
	drop.spatial_order = next_order
	next_order += 1
	var cell := _cell(drop.position)
	membership[id] = cell
	if not cells.has(cell):
		cells[cell] = []
	cells[cell].append(drop)
	if drop.wave_collecting:
		collecting[id] = drop
	set_physics_process(true)

func update(drop: Loot) -> void:
	var id := drop.get_instance_id()
	if not membership.has(id):
		return
	var cell := _cell(drop.position)
	var previous := membership[id]
	if cell == previous:
		return
	_remove(drop, previous)
	membership[id] = cell
	if not cells.has(cell):
		cells[cell] = []
	cells[cell].append(drop)

func unregister(drop: Loot) -> void:
	var id := drop.get_instance_id()
	if membership.has(id):
		_remove(drop, membership[id])
		membership.erase(id)
	collecting.erase(id)
	if membership.is_empty():
		next_order = 0
		last_candidates = 0
		set_physics_process(false)

func _remove(drop: Loot, cell: Vector2i) -> void:
	cells[cell].erase(drop)
	if cells[cell].is_empty():
		cells.erase(cell)

func _cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL_SIZE), floori(at.y / CELL_SIZE))

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var at := player.global_position
	var magnet := player.items.cached_pickup_range
	var reach := maxf(magnet, Loot.PICKUP_DISTANCE)
	var bounds := global_transform.affine_inverse() * Rect2(at - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)
	var first := _cell(bounds.position)
	var last := _cell(bounds.end)
	var candidates: Array[Loot] = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			if cells.has(cell):
				for drop: Loot in cells[cell]:
					if not drop.wave_collecting:
						candidates.append(drop)
	candidates.append_array(collecting.values())
	# Preserve pickup order, fractional item rewards and chest/XP event ordering.
	if candidates.size() > 1:
		candidates.sort_custom(func(a: Loot, b: Loot) -> bool: return a.spatial_order < b.spatial_order)
	last_candidates = candidates.size()
	for drop in candidates:
		if not drop.is_queued_for_deletion() and drop.target != null:
			drop.advance_collection(delta, at, magnet * magnet)
