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
@onready var enemy_index: EnemySpatialIndex = get_node("../Enemies") as EnemySpatialIndex

var hurt_time: float = 0.0
var dodge_time: float = 0.0
var animation_time: float = 0.0
var attack_time: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false
var dash := PlayerDash.new()
var motion_start := Vector2.ZERO
var motion_end := Vector2.ZERO
var motion_tick := -1
var motion_serial := 0
var dash_motion_seconds := 0.0
var dash_moved := false
var _dash_held := false
var dash_trail: DashTrail


func nearby_enemies(at: Vector2, radius: float, include_radius: bool = true) -> Array[Enemy]:
	return EnemySpatialIndex.circle(get_tree(), enemy_index, at, radius, include_radius)


func enemies_on_segment(start: Vector2, end: Vector2, radius: float) -> Array[Enemy]:
	return EnemySpatialIndex.segment(get_tree(), enemy_index, start, end, radius)


func _ready() -> void:
	mobile_controls.player = self
	expressions.configure(stats)
	status_effects.configure(self)
	stats.dodged.connect(_on_dodged)
	loadout.stats = stats
	dash.stats = stats
	stats.changed.connect(dash.clamp_charge)
	dash_trail = DashTrail.new()
	dash_trail.z_index = -1
	add_child(dash_trail)


func _physics_process(delta: float) -> void:
	var direction := movement_direction()
	if not direction.is_zero_approx():
		dash.last_direction = direction.normalized()
	var before_move := global_position
	motion_serial += 1
	motion_tick = Engine.get_physics_frames()
	motion_start = before_move
	dash_moved = false
	dash_motion_seconds = 0.0
	var was_dashing := dash.active
	if combat_active():
		dash_moved = was_dashing
		dash.advance(self, delta)
	else:
		dash.finish()
	if not was_dashing:
		velocity = direction * stats.move_speed
		move_and_slide()
	global_position = global_position.clamp(Vector2.ONE * DentiArena.PLAYER_MARGIN, arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN)
	motion_end = global_position
	if dash_moved:
		dash_trail.add_segment(motion_start, motion_end)
	is_moving = global_position.distance_squared_to(before_move) > 0.01
	_animate_sprite(dash.direction if was_dashing else direction, delta)
	hurt_time = maxf(hurt_time - delta, 0.0)
	dodge_time = maxf(dodge_time - delta, 0.0)
	sprite.modulate = Color(1.0, 0.55, 0.55) if hurt_time > 0.0 else (Color(0.72, 0.94, 1.0) if dodge_time > 0.0 else Color.WHITE)


func movement_direction() -> Vector2:
	if mobile_controls.visible and mobile_controls.combat_active and mobile_controls.touch_index >= 0:
		return mobile_controls.movement_direction(0.0)
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func combat_active() -> bool:
	var game := get_parent()
	return not get_tree().paused and stats.health > 0.0 and game.run_flow.is_combat() and (game.wave.active or game.boss_pending)


func try_dash() -> bool:
	return dash.request(movement_direction(), combat_active())


func _input(event: InputEvent) -> void:
	if event.is_action_released("dash"):
		_dash_held = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and not _dash_held:
		_dash_held = true
		try_dash()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_UNPAUSED]:
		_dash_held = Input.is_action_pressed("dash")


func swept_dash_this_frame() -> bool:
	return dash_moved and motion_tick == Engine.get_physics_frames()


func damage_circle_at(centre: Vector2, radius: float, seconds_into_frame: float = -1.0) -> bool:
	var at := global_position
	if seconds_into_frame >= 0.0 and swept_dash_this_frame():
		at = motion_start.lerp(motion_end, clampf(seconds_into_frame / maxf(dash_motion_seconds, 0.000001), 0, 1))
	return at.distance_squared_to(centre) <= radius * radius


func projectile_crosses(start: Vector2, end: Vector2, radius: float, delta: float, launch_serial: int) -> bool:
	if not swept_dash_this_frame() or launch_serial == motion_serial:
		return Geometry2D.get_closest_point_to_segment(global_position, start, end).distance_squared_to(global_position) <= radius * radius
	# Split at dash end/contact: the player can stop early in a long frame.
	var middle := start.lerp(end, clampf(dash_motion_seconds / maxf(delta, 0.000001), 0, 1))
	var relative := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, start - motion_start, middle - motion_end)
	var after := Geometry2D.get_closest_point_to_segment(motion_end, middle, end)
	return relative.length_squared() <= radius * radius or after.distance_squared_to(motion_end) <= radius * radius


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
