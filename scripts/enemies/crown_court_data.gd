class_name CrownCourtData
extends Resource

@export var warning_seconds: float = 1.05
@export var impact_seconds: float = 0.22
@export var portal_warning_seconds: float = 1.0
@export var nerve_warning_seconds: float = 1.05
@export var turn_seconds: float = 0.7
@export var position_seconds: float = 0.65
@export var recovery_seconds: float = 0.6
@export var open_seconds: float = 1.8
@export var court_radius: float = 390.0
@export var court_half_angle: float = 30.0
@export var court_step_degrees: float = 60.0
@export var court_cycle_degrees: float = 37.0
@export var verdict_damage_factor: float = 0.7
@export var guard_turn_degrees: float = 90.0
@export var portal_angle_step_radians: float = 0.3
@export var nerve_cycle_radians: float = 0.31
@export var nerve_step_radians: float = 0.19
@export var guard_half_angle: float = 70.0
@export var guard_damage_factor: float = 0.55
@export var open_damage_factor: float = 1.2
@export var portal_half_length: float = 230.0
@export var preferred_distance: float = 320.0
@export var movement_factor: float = 1.1
@export var portal_drift_factor: float = 0.16
@export var shots: BossProjectileData = preload("res://data/encounters/emperor_shots.tres")
@export var lance: BossProjectileData = preload("res://data/encounters/emperor_lance.tres")
@export var action_bonus: int = 0

func for_difficulty(difficulty: DifficultyData) -> CrownCourtData:
	var result := duplicate(true) as CrownCourtData
	result.shots = shots.duplicate() as BossProjectileData
	result.lance = lance.duplicate() as BossProjectileData
	result.action_bonus = clampi(difficulty.boss_volley_bonus, -1, 2)
	result.portal_drift_factor = 0.10 + 0.06 * (result.action_bonus + 1)
	result.movement_factor *= 0.75 + 0.25 * (result.action_bonus + 1)
	result.position_seconds *= difficulty.boss_recovery_multiplier
	result.recovery_seconds *= difficulty.boss_recovery_multiplier
	result.shots.speed *= difficulty.boss_projectile_speed_multiplier
	result.lance.speed *= difficulty.boss_projectile_speed_multiplier
	return result

func verdicts(phase: int) -> int: return 2 + action_bonus + (1 if phase >= 2 else 0)
func portals(phase: int) -> int: return 2 + action_bonus + (1 if phase >= 2 else 0)
func pulses(phase: int) -> int: return 2 + action_bonus + (1 if phase >= 1 else 0)
func rays(phase: int) -> int: return 12 + action_bonus * 2 + (4 if phase >= 2 else 0)
func fan_count() -> int: return 5 + action_bonus * 2
