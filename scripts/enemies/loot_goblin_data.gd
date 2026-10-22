class_name LootGoblinData
extends Resource

@export var first_wave: int = 8
@export_range(0, 1) var spawn_chance: float = 0.25
@export var arrival_remaining: float = 25.0
@export var capacity: int = 30
@export var panic_range: float = 250.0
@export var loot_search_range: float = 650.0
@export var cover_search_range: float = 520.0
@export var grab_radius: float = 80.0
@export var grab_seconds: float = 0.12
@export var planning_interval: float = 0.25
@export var sprint_seconds: float = 0.55
@export var sprint_cooldown: float = 3.0
@export var breather_seconds: float = 0.65
@export var sprint_factor: float = 1.28
@export var full_bag_speed_factor: float = 0.90

func speed_factor(id: StringName) -> float:
	match id:
		&"easy": return 0.90
		&"hard": return 1.08
		&"hell": return 1.15
	return 1.0
