class_name WeaponAffixData
extends Resource

@export var id: StringName
@export var display_name: String
@export var color: Color = Color.WHITE
@export var icon_index: int = 0
@export var damage_steps: PackedFloat32Array = PackedFloat32Array([3, 4, 5, 7, 9, 11, 14, 17, 20, 25, 30, 35])
@export var stat_key: StringName = &""
@export var dot_duration: float = 0.0
@export var slow_fraction: float = 0.0
@export var slow_duration: float = 0.0
