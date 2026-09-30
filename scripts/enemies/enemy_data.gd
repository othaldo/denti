class_name EnemyData
extends Resource

enum SpecialAttack { NONE, DASH, PULSE, SHOOT, BOSS, RADIAL, SPACE_ORB, LANE }
enum BossSignature { AIMED_FAN, TRAIL_FAN, LANE, SPACE_ORB }

@export var display_name: String
@export var max_health: float = 25.0
@export var health_per_wave: float = 0.0
@export var late_health_acceleration: float = 0.0
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
@export var is_elite: bool = false
@export_group("Elite")
@export var aura_radius: float = 0.0
@export_range(0.0, 1.0, 0.01) var aura_move_bonus: float = 0.0
@export var escort_data: EnemyData
@export var escort_count: int = 0
@export_range(0.0, 1.0, 0.01) var elite_guard_fraction: float = 0.0
@export var elite_guard_recharge_seconds: float = 0.0
@export_group("Special attack")
@export var special_attack: SpecialAttack = SpecialAttack.NONE
@export var advanced_special_wave: int = 0
@export var advanced_special_attack: SpecialAttack = SpecialAttack.NONE
@export var advanced_trigger_range: float = 0.0
@export var special_interval: float = 0.0
@export var warning_time: float = 0.0
@export var trigger_range: float = 0.0
@export var preferred_range: float = 0.0
@export var attack_radius: float = 0.0
@export var attack_speed: float = 0.0
@export var attack_duration: float = 0.0
@export var attack_damage: float = 0.0
@export var radial_count: int = 0
@export_range(1, 7, 1) var lane_projectile_count: int = 3
@export var lane_projectile_spacing: float = 48.0
@export var space_orb_radius: float = 31.0
@export var dash_impact_radius: float = 0.0
@export_group("Boss pressure")
@export var boss_signature: BossSignature = BossSignature.AIMED_FAN
@export var boss_signature_projectile_count: int = 3
@export var boss_signature_projectile_spacing: float = 54.0
@export var boss_signature_orb_radius: float = 42.0
@export_range(1, 9, 1) var boss_radial_volley_count: int = 1
@export var boss_radial_volley_interval: float = 0.22
@export var boss_radial_angle_step_degrees: float = 8.0
@export var boss_guard_recharge_seconds: float = 0.0
@export_range(0.0, 1.0, 0.01) var boss_guard_burst_fraction: float = 0.0
@export var boss_phase_duration: float = 0.0
@export var boss_radial_count: int = 0
@export var boss_fan_count: int = 0
@export var boss_projectile_speed: float = 0.0
@export var boss_phase_adds: int = 0
