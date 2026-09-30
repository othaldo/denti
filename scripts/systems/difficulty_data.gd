class_name DifficultyData
extends Resource

@export var id: StringName = &"normal"
@export var display_name: String = "Normal"
@export_multiline var description: String = ""
@export var spawn_interval_multiplier: float = 1.0
@export var horde_size_multiplier: float = 1.0
@export var extra_burst_first_wave: int = 0
@export var elite_wave_offset: int = 0
@export var elite_group_bonus: int = 0
@export var enemy_damage_multiplier: float = 1.0
@export var ranged_interval_multiplier: float = 1.0
@export var boss_volley_bonus: int = 0
@export var reward_chance_multiplier: float = 1.0
