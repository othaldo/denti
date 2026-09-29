class_name WaveProfileData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(1, 20) var first_wave: int = 1
@export var enemy_weight_multipliers: Dictionary = {}


func multiplier_for(enemy: EnemyData) -> float:
	return maxf(float(enemy_weight_multipliers.get(enemy.display_name, 1.0)), 0.0)
