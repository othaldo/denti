class_name AcidCollectorData
extends Resource

@export var summon_delay: float = 5.0
@export var reinforcement_delay: float = 15.0
@export var max_summons: int = 0
@export var spawn_distance: float = 275.0
@export var arrival_seconds: float = 1.2
@export var preferred_distance: float = 245.0
@export var follow_seconds: float = 0.6
@export var warning_seconds: float = 1.0
@export var flight_seconds: float = 0.6
@export var recovery_seconds: float = 1.7
@export var lead_seconds: float = 0.25
@export var lead_distance: float = 80.0
@export var impact_radius: float = 65.0
@export var pool_seconds: float = 3.0
@export var pool_tick_seconds: float = 0.65
@export var pool_damage_factor: float = 0.4
@export var impact_damage_factor: float = 0.8
@export var max_pools: int = 2
@export var minimum_lifetime: float = 7.0
@export var burst_fraction: float = 0.2
@export var resume_seconds: float = 0.8
@export var retreat_offset := Vector2(-160, 90)

func for_difficulty(difficulty: DifficultyData) -> AcidCollectorData:
	var result := duplicate() as AcidCollectorData
	var rank := clampi(difficulty.boss_volley_bonus, -1, 2)
	result.max_summons = 0 if rank <= 0 else rank + 1
	if rank >= 2:
		result.warning_seconds = 0.9
		result.recovery_seconds = 1.4
	return result
