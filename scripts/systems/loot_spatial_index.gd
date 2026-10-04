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
var _activity_revision: int = 0
var _membership_revision: int = 0
var _evaluated_revision: int = -1
var _last_position := Vector2.ZERO
var _last_magnet: float = -1.0
var _last_transform := Transform2D.IDENTITY
var _advancing: bool = false
var _cached_candidates: Array[Loot] = []
var _cached_revision: int = -1
var _cached_first := Vector2i.ZERO
var _cached_last := Vector2i.ZERO

func _ready() -> void:
	set_physics_process(not membership.is_empty())

func register(drop: Loot) -> void:
	_activity_revision += 1
	_membership_revision += 1
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
	# Teleports inside one cell must also wake the query.
	_activity_revision += 1
	var cell := _cell(drop.position)
	var previous := membership[id]
	if cell == previous:
		return
	_membership_revision += 1
	_remove(drop, previous)
	membership[id] = cell
	if not cells.has(cell):
		cells[cell] = []
	cells[cell].append(drop)

func unregister(drop: Loot) -> void:
	_activity_revision += 1
	_membership_revision += 1
	var id := drop.get_instance_id()
	if membership.has(id):
		_remove(drop, membership[id])
		membership.erase(id)
	collecting.erase(id)
	if membership.is_empty():
		_cached_candidates.clear()
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
	var transform := global_transform
	if not _advancing and collecting.is_empty() and _evaluated_revision == _activity_revision and at == _last_position and magnet == _last_magnet and transform == _last_transform:
		last_candidates = 0
		return
	# Capture before pickups: callbacks can register or move another drop.
	_evaluated_revision = _activity_revision
	_last_position = at
	_last_magnet = magnet
	_last_transform = transform
	var reach := maxf(magnet, Loot.PICKUP_DISTANCE)
	var bounds := transform.affine_inverse() * Rect2(at - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)
	var first := _cell(bounds.position)
	var last := _cell(bounds.end)
	if _cached_revision != _membership_revision or first != _cached_first or last != _cached_last or not collecting.is_empty():
		var nearby: Array[Loot] = []
		for y in range(first.y, last.y + 1):
			for x in range(first.x, last.x + 1):
				var cell := Vector2i(x, y)
				if cells.has(cell):
					for drop: Loot in cells[cell]:
						if not drop.wave_collecting:
							nearby.append(drop)
		nearby.append_array(collecting.values())
		# Preserve fractional rewards and chest/XP event ordering.
		if nearby.size() > 1:
			nearby.sort_custom(func(a: Loot, b: Loot) -> bool: return a.spatial_order < b.spatial_order)
		_cached_candidates = nearby
		_cached_revision = _membership_revision
		_cached_first = first
		_cached_last = last
	var candidates := _cached_candidates
	_advancing = false
	last_candidates = candidates.size()
	for drop in candidates:
		if not drop.is_queued_for_deletion() and drop.target != null:
			_advancing = drop.advance_collection(delta, at, magnet * magnet) or _advancing
