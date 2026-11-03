class_name ImperialVassalData
extends Resource

enum Role { LANCER, KEEPER, JUSTICIAR }
@export var role := Role.LANCER
@export var visual_scale: float = 1.0
@export var warning_seconds: float = 0.9
@export var cooldown_seconds: float = 1.4
@export var active_seconds: float = 0.30
@export var minimum_lifetime: float = 7.0
@export var burst_fraction: float = 0.22
@export var preferred_distance: float = 180.0
@export var dash_distance: float = 320.0
@export var lane_radius: float = 27.0
@export var slam_radius: float = 85.0
@export var damage_factor: float = 0.8
@export var projectile_profile: BossProjectileData = preload("res://data/encounters/emperor_shots.tres")

func for_difficulty(difficulty: DifficultyData) -> ImperialVassalData:
	var result := duplicate() as ImperialVassalData
	if difficulty.boss_volley_bonus < 0: result.minimum_lifetime *= 0.8
	result.warning_seconds = maxf(0.72, warning_seconds - maxi(difficulty.boss_volley_bonus, 0) * 0.06)
	result.cooldown_seconds *= maxf(difficulty.boss_recovery_multiplier, 0.75)
	result.projectile_profile = projectile_profile.duplicate() as BossProjectileData
	result.projectile_profile.speed *= difficulty.boss_projectile_speed_multiplier
	result.projectile_profile.maximum = 24
	return result
