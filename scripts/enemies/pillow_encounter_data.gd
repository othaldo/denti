class_name PillowEncounterData
extends Resource

@export var warning_seconds: float = 1.25
@export var recovery_seconds: float = 2.4
@export var lane_width: float = 130.0
@export var slam_length: float = 140.0
@export var fold_delay: float = 0.55
@export var fold_length: float = 360.0
@export var fold_seconds: float = 1.3
@export var fold_thickness: float = 36.0
@export var second_lane_offset: float = 250.0
@export var second_slam_delay: float = 0.7
@export var fold_damage_factor: float = 0.7
@export var anchor_distance: float = 130.0

func attack_seconds(count: int) -> float:
	return warning_seconds + (count - 1) * second_slam_delay + fold_delay + fold_seconds
