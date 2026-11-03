class_name ImperialRetinueData
extends Resource

@export var minions: Array[EnemyData] = []
@export var thresholds := PackedFloat32Array([0.7, 0.3])
@export var count: int = 2
@export var introduction_seconds: float = 1.0
@export var channel_seconds: float = 24.0
@export var regeneration_fraction: float = 0.04
@export var regeneration_seconds: float = 8.0
@export var pulse_cooldown: float = 2.8
@export var pulse_warning: float = 0.9
@export var failure_warning: float = 1.2
@export var opening_seconds: float = 4.0
@export var opening_damage_fraction: float = 0.08
@export var opening_damage_factor: float = 1.65
@export var spawn_extent := Vector2(230, 150)

func for_difficulty(difficulty: DifficultyData) -> ImperialRetinueData:
	var result := duplicate() as ImperialRetinueData
	var rank := clampi(difficulty.boss_volley_bonus, -1, 2)
	result.count = 3 if rank > 0 else 2
	if rank < 0: result.thresholds = PackedFloat32Array([0.5])
	elif rank == 1: result.thresholds = PackedFloat32Array([0.8, 0.5, 0.2])
	elif rank == 2: result.thresholds = PackedFloat32Array([0.85, 0.55, 0.25])
	result.channel_seconds = 24 if result.count == 2 else 30
	result.pulse_cooldown = 3.2 - (rank + 1) * 0.3
	return result
