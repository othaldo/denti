class_name CaramelTrialData
extends Resource

enum Kind { HEARTS, COURIERS }
@export var enabled: bool = true
@export var kind: Kind = Kind.HEARTS
@export_range(0.0, 1.0) var health_fraction: float = 0.5
@export_range(-1, 2) var minimum_rank: int = 0
@export_range(1, 4) var objectives: int = 2
@export var aimed_lanes: bool = false
@export var shots_per_heart: int = 1
@export var courier_arrival_seconds: float = 10.0

func enabled_for_rank(rank: int) -> bool:
	return enabled and rank >= minimum_rank

