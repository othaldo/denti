class_name KingPressureData
extends Resource

@export_range(2, 4) var valves: int = 3
@export var health_thresholds := PackedFloat32Array([2.0 / 3.0])
@export var introduction_seconds: float = 1.5
@export var tracking_seconds: float = 1.35
@export var lock_seconds: float = 0.90
@export var firing_seconds: float = 0.35
@export var recoil_seconds: float = 0.55
@export var shatter_seconds: float = 0.7
@export var exposure_seconds: float = 4.0
@export var blast_warning_seconds: float = 1.4
@export var valve_radius: float = 31.0
@export var beam_half_width: float = 19.0
@export var beam_damage_factor: float = 1.0
@export var backfire_fraction: float = 0.04
@export var opening_damage_fraction: float = 0.08
@export var exposure_damage_factor: float = 1.8
@export var extra_attempts: int = 3
@export var layout_extent := Vector2(680, 380)

func for_difficulty(difficulty: DifficultyData) -> KingPressureData:
	var result := duplicate() as KingPressureData
	var rank := clampi(difficulty.boss_volley_bonus, -1, 2)
	result.valves = 2 if rank < 0 else (4 if rank > 0 else 3)
	if rank == 1: result.health_thresholds = PackedFloat32Array([0.8, 0.4])
	elif rank == 2: result.health_thresholds = PackedFloat32Array([0.9, 0.6, 0.3])
	result.tracking_seconds = 1.55 - (rank + 1) * 0.10
	result.lock_seconds = maxf(0.75, 1.0 - (rank + 1) * 0.10)
	return result

