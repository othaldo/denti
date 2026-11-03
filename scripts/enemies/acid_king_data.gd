class_name AcidKingData
extends Resource

@export var pressure_profile: KingPressureData

@export var warning_seconds: float = 1.0
@export var shift_warning_seconds: float = 1.0
@export var flow_seconds: float = 1.55
@export var shift_flow_seconds: float = 1.0
@export var recall_seconds: float = 0.65
@export var open_seconds: float = 1.15
@export var recovery_seconds: float = 0.45
@export var approach_seconds: float = 0.45
@export var recovery_settle_seconds: float = 0.20
@export var recovery_move_factor: float = 0.55
@export var channel_half_width: float = 24.0
@export var channel_spacing: float = 150.0
@export var old_channel_fade: float = 0.30
@export var field_damage_factor: float = 0.5
@export var field_tick_seconds: float = 0.65
@export var preferred_distance: float = 220.0
@export var move_factor: float = 2.05
@export var flow_movement_factor: float = 0.22
@export var pursuit_seconds: float = 0.45
@export var pursuit_move_factor: float = 1.0
@export var pursuit_distance: float = 190.0
@export var shift_lead_seconds: float = 0.30
@export var shift_lead_distance: float = 80.0
@export var alternate_shift_axis: bool = true
@export_range(0, 2) var combined_phase: int = 1
@export var stomp_warning_seconds: float = 1.0
@export var combined_stomp_warning_seconds: float = 1.4
@export var combined_near_warning_seconds: float = 1.4
@export var stomp_row_interval: float = 0.24
@export var stomp_active_seconds: float = 0.16
@export var stomp_spacing: float = 105.0
@export var stomp_start: float = 180.0
@export var stomp_near_start: float = 48.0
@export var stomp_near_half_span: float = 64.0
@export var stomp_widen_per_row: float = 40.0
@export var stomp_near_warning_seconds: float = 1.4
@export var stomp_near_radius: float = 145.0
@export var stomp_near_follow_delay: float = 0.35
@export var stomp_near_shard_half_angle_degrees: float = 60.0
@export var stomp_half_span: float = 160.0
@export var stomp_radius: float = 20.0
@export var closed_damage_factor: float = 0.85
@export var open_damage_factor: float = 1.25
@export var shards: BossProjectileData = preload("res://data/encounters/king_shards.tres")
@export var spit: BossProjectileData = preload("res://data/encounters/king_spit.tres")
@export var spit_warning_seconds: float = 0.75
@export var spit_lead_seconds: float = 0.50
@export var spit_lead_distance: float = 120.0
@export var spit_ray_spacing: float = 0.18
@export var attack_distance: float = 330.0
@export var stomp_chase_seconds: float = 0.32
@export var stomp_sequences: int = 1
@export var action_bonus: int = 0
@export var channel_count: int = 2
@export var shifts: int = 1

func for_difficulty(difficulty: DifficultyData) -> AcidKingData:
	var result := duplicate(true) as AcidKingData
	if pressure_profile != null: result.pressure_profile = pressure_profile.for_difficulty(difficulty)
	# External Resource references are shared even by duplicate(true).
	result.shards = shards.duplicate() as BossProjectileData
	result.spit = spit.duplicate() as BossProjectileData
	result.action_bonus = clampi(difficulty.boss_volley_bonus, -1, 2)
	result.channel_count = 1 if result.action_bonus < 0 else 2
	result.shifts = maxi(1, 1 + result.action_bonus)
	result.stomp_sequences = 2 if result.action_bonus >= 1 else 1
	var rank := result.action_bonus + 1
	result.stomp_warning_seconds = [1.1, 1.05, 1.0, 0.9][rank]
	result.stomp_near_warning_seconds = [1.1, 0.85, 0.72, 0.60][rank]
	result.combined_near_warning_seconds = [1.35, 1.15, 1.0, 0.9][rank]
	result.flow_movement_factor = 0.20 + (result.action_bonus + 1) * 0.14
	result.pursuit_move_factor *= 0.75 + 0.25 * (result.action_bonus + 1)
	result.alternate_shift_axis = alternate_shift_axis and result.action_bonus >= 0
	result.combined_phase = maxi(combined_phase, 2) if result.action_bonus < 0 else combined_phase
	result.recovery_seconds *= difficulty.boss_recovery_multiplier
	result.approach_seconds *= difficulty.boss_recovery_multiplier
	result.shards.speed *= difficulty.boss_projectile_speed_multiplier
	result.spit.speed *= difficulty.boss_projectile_speed_multiplier
	return result

func spit_count() -> int:
	return 5 + action_bonus * 2

func rows(phase: int) -> int:
	return clampi(3 + action_bonus + (1 if phase >= 1 else 0), 2, 6)

func shard_count(phase: int) -> int:
	return 5 + action_bonus * 2 + (2 if phase >= 2 else 0)
