class_name WeaponAffixData
extends Resource

@export var id: StringName
@export var display_name: String
@export var name_suffix: String
@export_multiline var description: String
@export var build_tags: Array[StringName] = []
@export_enum("damage", "wet", "holy", "leech") var effect_kind: String = "damage"
@export var damage_factor: float = 1.0
@export var proc_factor: float = 0.0
@export var proc_radius: float = 0.0
@export var proc_cooldown: float = 0.0
@export var proc_targets: int = 0
@export var proc_target_cap: int = 0
@export var utility_base: float = 0.0
@export var utility_scale: float = 0.0
@export var utility_cap: float = 0.0
@export var buildup_limit: int = 0
@export var buildup_interval: float = 0.0
@export var buildup_bonus: float = 0.0
@export var mark_threshold: int = 0
@export var mark_duration: float = 0.0
@export var color: Color = Color.WHITE
@export var icon_index: int = 0
@export var projectile_effect_index: int = -1
@export var damage_steps: PackedFloat32Array = PackedFloat32Array([3, 4, 5, 7, 9, 11, 14, 17, 20, 25, 30, 35])
@export var stat_key: StringName = &""
@export var dot_duration: float = 0.0
@export var slow_fraction: float = 0.0
@export var slow_duration: float = 0.0
