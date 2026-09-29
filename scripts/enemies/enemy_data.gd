class_name EnemyData
extends Resource

enum SpecialAttack { NONE, DASH, PULSE, SHOOT, BOSS }

@export var display_name: String
@export var max_health: float = 25.0
@export_range(0.0, 0.6, 0.01) var damage_reduction: float = 0.0
@export_range(0.0, 1.0, 0.01) var knockback_resistance: float = 0.0
@export var move_speed: float = 90.0
@export var contact_damage: float = 9.0
@export var radius: float = 18.0
@export var xp_drop: int = 1
@export var coin_drop: int = 1
@export_range(0.0, 1.0, 0.01) var coin_drop_chance: float = 1.0
@export var sprite: Texture2D
@export var sprite_tint: Color = Color.WHITE
@export var is_boss: bool = false
@export_group("Special attack")
@export var special_attack: SpecialAttack = SpecialAttack.NONE
@export var special_interval: float = 0.0
@export var warning_time: float = 0.0
@export var trigger_range: float = 0.0
@export var preferred_range: float = 0.0
@export var attack_radius: float = 0.0
@export var attack_speed: float = 0.0
@export var attack_duration: float = 0.0
@export var attack_damage: float = 0.0
