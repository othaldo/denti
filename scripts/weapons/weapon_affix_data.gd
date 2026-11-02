class_name WeaponAffixData
extends Resource

@export_group("Element visuals")
@export_enum("Water", "Light", "Rocket", "Acid", "Blood", "Ember", "Paste", "Mint", "Metal") var projectile_art_kind: int = 0
@export_enum("Beam", "Thread", "Slash", "Lane", "Aim", "Flash", "Spray", "Trail", "UV") var attack_stream_art: int = 0
@export_enum("Beam", "Thread", "Slash", "Lane", "Aim", "Flash", "Spray", "Trail", "UV") var attack_trail_art: int = 2
@export_enum("Beam", "Thread", "Slash", "Lane", "Aim", "Flash", "Spray", "Trail", "UV") var attack_spray_art: int = 6
@export_range(0.25, 3.0) var visual_animation_rate: float = 1.0

@export_group("Effect")

@export var id: StringName
@export var display_name: String
@export var name_suffix: String
@export_multiline var description: String
@export var build_tags: Array[StringName] = []
@export var elemental: bool = false
@export var selectable: bool = true
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
@export var utility_soft_threshold: float = 0.0
@export_range(0.0, 1.0) var utility_soft_factor: float = 1.0
@export var buildup_limit: int = 0
@export var buildup_interval: float = 0.0
@export var buildup_bonus: float = 0.0
@export var mark_threshold: int = 0
@export var mark_duration: float = 0.0
@export var color: Color = Color.WHITE
@export var icon_index: int = 0
@export var projectile_effect_index: int = -1
@export var damage_steps: PackedFloat32Array = PackedFloat32Array([3, 4, 5, 7, 9, 11, 14, 17, 20, 25, 30, 35])
@export var upgrade_steps: PackedFloat32Array = PackedFloat32Array([3, 5, 7, 10, 14, 18, 22, 26, 30, 35])
@export var stat_key: StringName = &""
@export var stat_unit: String = "%"
@export var dot_duration: float = 0.0
@export var slow_fraction: float = 0.0
@export var slow_duration: float = 0.0
