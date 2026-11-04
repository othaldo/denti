class_name CaramelOverloadData
extends Resource

@export var objective: EnemyData
@export var trials: Array[CaramelTrialData] = []
@export var rank: int = 0
@export_range(1, 2) var trigger_phase: int = 2
@export var warning_seconds: float = 1.2
@export var minimum_seconds: float = 18.0
@export var maximum_seconds: float = 40.0
@export var opening_distance: float = 190.0
@export var layout_extent := Vector2(640, 360)
@export var recovery_seconds: float = 4.0
@export var vulnerability: float = 1.75
@export_range(0.01, 0.25) var opening_damage_fraction: float = 0.08
@export var lane_warning_seconds: float = 1.0
@export var lane_active_seconds: float = 0.25
@export var lane_pause_seconds: float = 1.5
@export var lane_half_width: float = 20.0
@export var blast_warning_seconds: float = 1.25
@export var heart_warning_seconds: float = 0.95
@export var heart_pause_seconds: float = 2.0
@export var heart_stagger_seconds: float = 0.22
@export var heart_fan_degrees: float = 20.0

func for_difficulty(difficulty: DifficultyData) -> CaramelOverloadData:
	var result := duplicate() as CaramelOverloadData
	result.rank = clampi(difficulty.boss_volley_bonus, -1, 2)
	result.heart_warning_seconds = 0.95 - maxi(result.rank, 0) * 0.05
	result.heart_pause_seconds = 2.3 - maxi(result.rank, 0) * 0.35
	result.lane_pause_seconds = 1.1 - maxi(result.rank, 0) * 0.20
	return result

func enabled_mask() -> int:
	var mask := 0
	for index in trials.size():
		if trials[index].enabled_for_rank(rank): mask |= 1 << index
	return mask

