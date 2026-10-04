class_name TestArenaData
extends Resource

@export var id: StringName
@export var code: String
@export var display_name: String
@export var wave_number: int = 17
@export var random_seed: int = 88817
@export var enemy_count: int = 110
@export var loot_count: int = 1200
@export var enemy_health: float = 1000000000.0
@export var enemies: Array[EnemyData] = []
@export var boss: EnemyData
@export var weapons: Array[StringName] = []
@export var weapon_tier: int = 4
@export var items: Array[StringName] = []
