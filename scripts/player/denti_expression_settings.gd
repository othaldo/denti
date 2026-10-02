class_name DentiExpressionSettings
extends Resource

@export var hurt_duration: float = 0.45
@export var heal_duration: float = 0.65
@export var heal_cooldown: float = 2.5
@export var minimum_heal: float = 0.5
@export var block_duration: float = 0.55
@export var dodge_duration: float = 0.45
@export var celebrate_duration: float = 1.2
@export var blink_duration: float = 0.12
@export var blink_interval: Vector2 = Vector2(2.8, 6.2)
@export_range(0.0, 1.0) var low_health_fraction: float = 0.25

# Register each painted frame to a common mouth anchor on the body. This keeps
# expressions aligned despite the different whitespace around closed eyes.
@export var face_frame_size := Vector2(720, 560)
@export var mouth_position := Vector2(-10, 70)
@export var face_anchors: Array[Vector2] = [
	Vector2(185, 267), Vector2(195, 271), Vector2(176, 269), Vector2(181, 276),
	Vector2(188, 243), Vector2(198, 245), Vector2(186, 247), Vector2(174, 260),
	Vector2(196, 202), Vector2(193, 199), Vector2(182, 203), Vector2(187, 205),
]
