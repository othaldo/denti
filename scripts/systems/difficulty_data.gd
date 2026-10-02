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
@export_group("Player ailments")
@export var poison_first_wave: int = 6
@export var bleed_first_wave: int = 8
@export var status_trait_first_wave: int = 9
@export var status_trait_chance_step: float = 0.012
@export var status_trait_chance_cap: float = 0.18
@export var status_damage_multiplier: float = 1.0
@export var status_duration_multiplier: float = 1.0
@export var status_specialist_weight: float = 1.0
