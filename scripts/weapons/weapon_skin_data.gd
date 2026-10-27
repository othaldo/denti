class_name WeaponSkinData
extends Resource

## Painted appearance and rig only; combat values belong to WeaponData.
const FIELDS := ["sprite", "held_sprite", "grip_anchor", "tip_anchor",
	"working_head_texture", "working_head_radius", "working_head_aspect",
	"working_head_angle_degrees", "pull_texture", "fork_left_anchor",
	"fork_right_anchor", "pouch_anchor", "pouch_width", "floss_left_texture",
	"floss_right_texture", "floss_left_tip", "floss_right_tip"]

@export var sprite: Texture2D
@export var held_sprite: Texture2D
@export var grip_anchor: Vector2
@export var tip_anchor: Vector2
@export var working_head_texture: Texture2D
@export var working_head_radius: float = 0.0
@export var working_head_aspect: float = 0.65
@export var working_head_angle_degrees: float = -25.0
@export var pull_texture: Texture2D
@export var fork_left_anchor: Vector2
@export var fork_right_anchor: Vector2
@export var pouch_anchor: Vector2
@export var pouch_width: float = 0.0
@export var floss_left_texture: Texture2D
@export var floss_right_texture: Texture2D
@export var floss_left_tip: Vector2
@export var floss_right_tip: Vector2


func apply_to(data: WeaponData) -> void:
	for field in FIELDS:
		data.set(field, get(field))
