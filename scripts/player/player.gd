class_name Player
extends CharacterBody2D

const ARENA_MARGIN := 28.0
const HURT_COOLDOWN := 0.65
const ATTACK_ANIMATION_DURATION := 0.18

@onready var stats: PlayerStats = $Stats
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_base_scale: Vector2 = sprite.scale

var hurt_time: float = 0.0
var animation_time: float = 0.0
var attack_time: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * stats.move_speed
	move_and_slide()
	global_position = global_position.clamp(Vector2.ONE * ARENA_MARGIN, DentiArena.SIZE - Vector2.ONE * ARENA_MARGIN)
	_animate_sprite(direction, delta)
	if hurt_time > 0.0:
		hurt_time -= delta
		sprite.modulate = Color(1.0, 0.55, 0.55) if hurt_time > 0.0 else Color.WHITE


func _animate_sprite(direction: Vector2, delta: float) -> void:
	var moving := direction.length_squared() > 0.01
	animation_time += delta * (10.0 if moving else 3.0)
	attack_time = maxf(attack_time - delta, 0.0)
	var attack_pulse := sin(attack_time / ATTACK_ANIMATION_DURATION * PI)
	var sway := sin(animation_time)
	var stretch := sway * (0.035 if moving else 0.012)
	sprite.position.y = -2.0 - absf(sway) * (2.5 if moving else 1.4) - attack_pulse * 4.0
	sprite.scale = sprite_base_scale * Vector2(1.0 + stretch + attack_pulse * 0.12, 1.0 - stretch - attack_pulse * 0.09)
	var target_rotation := -direction.x * 0.08 + sway * 0.025 + attack_direction.x * attack_pulse * 0.14
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, minf(delta * 14.0, 1.0))


func play_attack_animation(aim: Vector2) -> void:
	attack_time = ATTACK_ANIMATION_DURATION
	attack_direction = aim


func take_hit(amount: float) -> void:
	if hurt_time > 0.0 or stats.health <= 0.0:
		return
	hurt_time = HURT_COOLDOWN
	stats.take_damage(amount)
