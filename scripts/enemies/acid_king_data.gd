class_name AcidKingData
extends Resource

@export var warning_seconds: float = 1.0
@export var shift_warning_seconds: float = 1.0
@export var flow_seconds: float = 2.2
@export var shift_flow_seconds: float = 1.25
@export var recall_seconds: float = 0.95
@export var open_seconds: float = 1.6
@export var recovery_seconds: float = 0.7
@export var approach_seconds: float = 0.65
@export var channel_half_width: float = 24.0
@export var channel_spacing: float = 150.0
@export var shift_distance: float = 145.0
@export var old_channel_fade: float = 0.30
@export var field_damage_factor: float = 0.5
@export var field_tick_seconds: float = 0.65
@export var preferred_distance: float = 260.0
@export var move_factor: float = 1.6
@export var flow_movement_factor: float = 0.22
@export var stomp_warning_seconds: float = 1.0
@export var stomp_row_interval: float = 0.24
@export var stomp_active_seconds: float = 0.16
@export var stomp_spacing: float = 105.0
@export var stomp_start: float = 180.0
@export var stomp_half_span: float = 160.0
@export var stomp_radius: float = 20.0
@export var closed_damage_factor: float = 0.85
@export var open_damage_factor: float = 1.25
@export var shards: BossProjectileData = preload("res://data/encounters/king_shards.tres")
@export var action_bonus: int = 0
@export var channel_count: int = 2
@export var shifts: int = 1

func for_difficulty(difficulty: DifficultyData) -> AcidKingData:
	var result := duplicate(true) as AcidKingData
	# External Resource references are shared even by duplicate(true).
	result.shards = shards.duplicate() as BossProjectileData
	result.action_bonus = clampi(difficulty.boss_volley_bonus, -1, 2)
	result.channel_count = 1 if result.action_bonus < 0 else 2
	result.shifts = maxi(1, 1 + result.action_bonus)
	result.flow_movement_factor = 0.12 + (result.action_bonus + 1) * 0.10
	result.recovery_seconds *= difficulty.boss_recovery_multiplier
	result.approach_seconds *= difficulty.boss_recovery_multiplier
	result.shards.speed *= difficulty.boss_projectile_speed_multiplier
	return result

func rows(phase: int) -> int:
	return clampi(3 + action_bonus + (1 if phase >= 1 else 0), 2, 6)

func shard_count(phase: int) -> int:
	return 5 + action_bonus * 2 + (2 if phase >= 2 else 0)
