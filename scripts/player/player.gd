class_name Player
extends CharacterBody2D

signal attack_performed(kind: StringName)
signal damaged(position: Vector2, amount: float)

const MIN_IFRAMES := 0.2
const MAX_IFRAMES := 0.4
const FULL_IFRAMES_DAMAGE_FRACTION := 0.15
const ATTACK_ANIMATION_DURATION := 0.18
const DODGE_IFRAMES := 0.15

@onready var stats: PlayerStats = $Stats
@onready var loadout: WeaponLoadout = $Weapons
@onready var items: ItemInventory = get_node("../Items")
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_base_scale: Vector2 = sprite.scale
@onready var expressions: DentiExpressions = $Sprite2D/Expressions
@onready var status_effects: PlayerStatusEffects = $StatusEffects
@onready var arena: DentiArena = get_node("../Arena")
@onready var mobile_controls: MobileControls = get_node("../MobileControls/Root")

var hurt_time: float = 0.0
var dodge_time: float = 0.0
var animation_time: float = 0.0
var attack_time: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false


func _ready() -> void:
	expressions.configure(stats)
	status_effects.configure(self)
	stats.dodged.connect(_on_dodged)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if mobile_controls.visible and mobile_controls.combat_active and mobile_controls.direction != Vector2.ZERO:
		direction = mobile_controls.direction
	var before_move := global_position
	velocity = direction * stats.move_speed
	move_and_slide()
	global_position = global_position.clamp(Vector2.ONE * DentiArena.PLAYER_MARGIN, arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN)
	is_moving = global_position.distance_squared_to(before_move) > 0.01
	_animate_sprite(direction, delta)
	hurt_time = maxf(hurt_time - delta, 0.0)
	dodge_time = maxf(dodge_time - delta, 0.0)
	sprite.modulate = Color(1.0, 0.55, 0.55) if hurt_time > 0.0 else (Color(0.72, 0.94, 1.0) if dodge_time > 0.0 else Color.WHITE)


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


func play_attack_animation(aim: Vector2, kind: StringName = &"brush") -> void:
	attack_time = ATTACK_ANIMATION_DURATION
	attack_direction = aim
	attack_performed.emit(kind)


func take_hit(amount: float, inflicted_statuses: Array[Dictionary] = []) -> float:
	if hurt_time > 0.0 or dodge_time > 0.0 or stats.health <= 0.0:
		return 0.0
	var actual := stats.take_damage(amount)
	if actual > 0.0:
		hurt_time = clampf(MAX_IFRAMES * actual / (stats.max_health * FULL_IFRAMES_DAMAGE_FRACTION), MIN_IFRAMES, MAX_IFRAMES)
		damaged.emit(global_position + Vector2(0.0, -28.0), actual)
		status_effects.apply_attacks(inflicted_statuses)
	return actual


func _on_dodged() -> void:
	dodge_time = DODGE_IFRAMES
