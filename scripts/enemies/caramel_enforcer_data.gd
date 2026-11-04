class_name CaramelEnforcerData
extends Resource

@export var summon_delay: float = 4.0
@export var reinforcement_delay: float = 12.0
@export var max_summons: int = 0
@export var spawn_distance: float = 260.0
@export var preferred_distance: float = 105.0
@export var punch_trigger_distance: float = 175.0
@export var punch_offset: float = 38.0
@export var follow_seconds: float = 0.45
@export var resume_seconds: float = 0.8
@export var retreat_offset := Vector2(160, 60)
@export var arrival_seconds: float = 1.1
@export var charge_warning: float = 1.0
@export var charge_seconds: float = 0.42
@export var charge_distance: float = 340.0
@export var charge_radius: float = 30.0
@export var punch_warning: float = 0.95
@export var punch_seconds: float = 0.18
@export var punch_radius: float = 90.0
@export var punches: int = 1
@export var recovery_seconds: float = 1.4
@export var minimum_lifetime: float = 8.0
@export var burst_fraction: float = 0.18
@export var damage_factor: float = 0.8

func for_difficulty(difficulty: DifficultyData) -> CaramelEnforcerData:
	var result := duplicate() as CaramelEnforcerData
	var rank := clampi(difficulty.boss_volley_bonus, -1, 2)
	result.max_summons = 0 if rank <= 0 else rank + 1
	if rank >= 2:
		result.punches = 2
		result.punch_warning = 0.90
		result.charge_warning = 0.90
		result.recovery_seconds = 1.1
	return result
