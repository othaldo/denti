class_name CloakEncounterData
extends Resource

@export var warning_seconds := 0.85
@export var followup_warning_seconds := 0.75
@export var strike_seconds := 0.24
@export var hit_start := 0.04
@export var hit_end := 0.14
@export var step_seconds := 0.32
@export var recovery_seconds := 1.05
@export var recovery_settle_seconds := 0.35
@export var recovery_move_factor := 0.55
@export var edge_margin := 90.0
@export var position_tolerance := 18.0
@export var position_seconds := 0.65
@export var position_samples := 24
@export var chase_factor := 2.5
@export var visual_scale := 1.0
@export var strikes: Array[CloakStrikeData] = [preload("res://data/encounters/count_fan.tres"), preload("res://data/encounters/count_thrust.tres"), preload("res://data/encounters/count_ring.tres")]

var reach: float:
	get: return strike(0).reach
var half_angle_degrees: float:
	get: return strike(0).half_angle_degrees
var edge_half_angle_degrees: float:
	get: return strike(0).edge_half_angle_degrees

func warning(index: int) -> float:
	return warning_seconds if index == 0 else followup_warning_seconds

func strike(kind: int) -> CloakStrikeData:
	return strikes[clampi(kind, 0, strikes.size() - 1)]

func half_angle_at(target: Vector2, arena: Vector2, kind := 0) -> float:
	var wall_distance := minf(minf(target.x, target.y), minf(arena.x - target.x, arena.y - target.y)) - DentiArena.PLAYER_MARGIN
	return strike(kind).half_angle(wall_distance < edge_margin)

func placement_distance(target: Vector2, arena: Vector2, kind := 0) -> float:
	# On the sector centreline, side and outer-arc exits are equally far here.
	# Moving nearer shortens the side exit; moving farther shortens the arc exit.
	return strike(kind).placement_distance(half_angle_at(target, arena, kind))
