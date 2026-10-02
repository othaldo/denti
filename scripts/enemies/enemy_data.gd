class_name EnemyData
extends Resource

enum SpecialAttack { NONE, DASH, PULSE, SHOOT, BOSS, RADIAL, SPACE_ORB, LANE }
enum BossSignature { AIMED_FAN, TRAIL_FAN, LANE, SPACE_ORB }
enum SpriteFacing { FRONT, RIGHT, LEFT }

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
# Direction painted into the source artwork; frontal sprites do not mirror.
@export var sprite_facing: SpriteFacing = SpriteFacing.FRONT
@export_group("Inflicted statuses")
@export var inflicted_statuses: Array[StatusAttackData] = []
@export var allow_random_status_trait: bool = true
@export var projectile_color: Color = Color(0.53, 0.88, 0.13)
@export_range(0, 5) var aimed_projectile_count: int = 0
@export_group("Role")
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

@export_group("Boss overtime inflammation")
@export var inflammation_color: Color = Color(1.0, 0.32, 0.12)
@export_range(0.2, 1.0, 0.05) var inflammation_intensity: float = 0.65
@export_range(2.5, 4.5, 0.1) var inflammation_aura_size: float = 3.2
@export_range(0.0, 1.0, 0.01) var overtime_damage_per_second: float = 0.05
@export_range(0.0, 1.0, 0.01) var overtime_defense_per_second: float = 0.05
@export_range(0.0, 1.0, 0.01) var overtime_speed_per_second: float = 0.03
@export_range(0.0, 1.0, 0.01) var overtime_attack_rate_per_second: float = 0.04
@export_range(0.0, 1.0, 0.01) var overtime_health_per_second: float = 0.02
