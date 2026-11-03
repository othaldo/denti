class_name CaramelEncounterData
extends Resource

@export var overload_profile: CaramelOverloadData

enum Attack { BOMBS, HEART_FAN, SUGAR_RUSH }
@export var attack_order: Array[int] = [Attack.BOMBS, Attack.HEART_FAN, Attack.SUGAR_RUSH]

@export var windup_seconds: float = 0.50
@export var flight_seconds: float = 0.60
@export var followup_seconds: float = 0.18
@export var bomb_frequency: float = 1.0
@export var recovery_seconds: float = 0.90
@export var approach_seconds: float = 0.45
@export var preferred_distance: float = 260.0
@export var move_factor: float = 1.85
@export var impact_radius: float = 96.0
@export var pool_radius: float = 104.0
@export var pool_seconds: float = 5.0
@export_range(1, 6) var max_pools: int = 4
@export_range(0.5, 1) var movement_factor: float = 0.72
@export var arc_height: float = 115.0
@export var followup_lead_seconds: float = 0.8
@export var maximum_lead: float = 180.0
@export var visual_scale: float = 1.0

@export_group("Caramel hearts")
@export var heart_warning_seconds: float = 0.85
@export var heart_followup_warning: float = 0.75
@export var heart_release_seconds: float = 0.18
@export var heart_speed: float = 245.0
@export var heart_lifetime: float = 3.0
@export var heart_radius: float = 10.0
@export var heart_visual_width: float = 30.0
@export var heart_damage_factor: float = 0.55
@export var fan_step_degrees: float = 18.0
@export var max_hearts: int = 28

@export_group("Sugar rush")
@export var rush_warning_seconds: float = 0.90
@export var rush_seconds: float = 0.45
@export var rush_distance: float = 255.0
@export var rush_overshoot: float = 65.0
@export var burst_warning_seconds: float = 0.80
@export var burst_release_seconds: float = 0.25
@export var burst_rotation_degrees: float = 11.0

@export_group("Encounter pressure")
@export var action_bonus: int = 0
@export var reposition_bias: float = 0.0
@export var move_between_volleys: bool = false
@export var reposition_speed_factor: float = 1.0
@export var recovery_settle_seconds: float = 0.12
@export var max_bomb_throws: int = 3
@export var max_fan_salvos: int = 3
@export var bomb_fan_phase: int = 1
@export var combo_fan_salvos: int = 2
@export var fan_lead_seconds: float = 0.25
@export var fan_lead_distance: float = 90.0
@export var fan_preferred_distance: float = 280.0

func for_difficulty(difficulty: DifficultyData) -> CaramelEncounterData:
	var result := duplicate() as CaramelEncounterData
	if overload_profile != null: result.overload_profile = overload_profile.for_difficulty(difficulty)
	result.action_bonus = clampi(difficulty.boss_volley_bonus, -1, 2)
	result.heart_speed *= difficulty.boss_projectile_speed_multiplier
	result.recovery_seconds *= difficulty.boss_recovery_multiplier
	result.approach_seconds *= difficulty.boss_recovery_multiplier
	result.rush_distance *= difficulty.boss_movement_multiplier
	result.rush_overshoot *= difficulty.boss_movement_multiplier
	result.max_hearts += maxi(result.action_bonus, 0) * 14
	result.reposition_bias = 0.35 + maxi(result.action_bonus, 0) * 0.325
	result.move_between_volleys = result.action_bonus >= 0
	result.reposition_speed_factor = 0.65 + maxi(result.action_bonus, 0) * 0.30
	result.bomb_fan_phase = 0 if result.action_bonus >= 1 else (2 if result.action_bonus < 0 else bomb_fan_phase)
	result.fan_lead_seconds *= maxi(result.action_bonus, 0)
	result.fan_preferred_distance -= maxi(result.action_bonus, 0) * 30.0
	# Moving between salvos is visible; every subsequent aim is warned afresh.
	result.heart_release_seconds += maxi(result.action_bonus, 0) * 0.10
	result.followup_seconds += maxi(result.action_bonus, 0) * 0.04
	result.bomb_frequency *= 0.75 if result.action_bonus < 0 else 1.0 + result.action_bonus * 0.5
	return result

func bomb_interval() -> float:
	return (windup_seconds + flight_seconds + followup_seconds) / maxf(bomb_frequency, 0.01)

func bomb_pause_seconds() -> float:
	# Serial/legacy throws keep full warnings; Easy waits longer between throws.
	return maxf(followup_seconds, bomb_interval() - windup_seconds - flight_seconds)

func throws_for_phase(phase: int) -> int:
	return mini((3 if phase >= 1 else 2) + action_bonus, max_bomb_throws)

func attack_for_cycle(cycle: int) -> int:
	return clampi(attack_order[posmod(cycle, attack_order.size())], 0, 2) if not attack_order.is_empty() else Attack.BOMBS

func fan_count(phase: int) -> int:
	return 5 + clampi(phase, 0, 2) * 2 + action_bonus * 2

func salvos_for_phase(phase: int) -> int:
	return mini(maxi((2 if phase >= 1 else 1) + action_bonus, 1), max_fan_salvos)

func burst_count(phase: int) -> int:
	return 12 + clampi(phase, 0, 2) * 2 + action_bonus * 4

func burst_salvos() -> int:
	return 1 + maxi(action_bonus - 1, 0)
