class_name Enemy
extends Node2D

signal defeated(position: Vector2, data: EnemyData)
signal damaged(position: Vector2, amount: float)
signal attack_performed(kind: StringName)

enum SpecialPhase { COOLDOWN, WARNING, ACTIVE }

const PULSE_FLASH_DURATION := 0.18
const ACID_PROJECTILE: PackedScene = preload("res://scenes/enemies/acid_projectile.tscn")

@onready var sprite: Sprite2D = $Sprite2D

var data: EnemyData
var target: Player
var health: float
var max_health: float
var damage_reduction: float
var contact_damage: float
var attack_damage: float
var move_speed: float
var contact_timer: float = 0.0
var animation_time: float = 0.0
var special_phase: SpecialPhase = SpecialPhase.COOLDOWN
var special_timer: float = 0.0
var special_direction: Vector2 = Vector2.ZERO
var pulse_flash_time: float = 0.0


func configure(enemy_data: EnemyData, player: Player, wave_number: int = 1) -> void:
	data = enemy_data
	target = player
	max_health = data.max_health * WaveController.health_multiplier(data, wave_number)
	health = max_health
	damage_reduction = WaveController.damage_reduction(data, wave_number)
	contact_damage = data.contact_damage * (1.0 + (wave_number - 1) * WaveController.ENEMY_DAMAGE_WAVE_STEP)
	attack_damage = data.attack_damage * (1.0 + (wave_number - 1) * WaveController.ENEMY_DAMAGE_WAVE_STEP)
	move_speed = data.move_speed * (1.0 + (wave_number - 1) * 0.025)
	special_phase = SpecialPhase.COOLDOWN
	special_timer = data.special_interval * randf_range(0.65, 1.0)
	queue_redraw()


func _ready() -> void:
	add_to_group("enemies")
	sprite.texture = data.sprite
	sprite.modulate = data.sprite_tint
	var side := maxf(float(data.sprite.get_width()), float(data.sprite.get_height()))
	sprite.scale = Vector2.ONE * (data.radius * 2.35 / side)
	animation_time = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	animation_time += delta * (2.5 if data.is_boss else 5.0)
	sprite.position.y = sin(animation_time) * (2.2 if data.is_boss else 1.2)
	sprite.rotation = sin(animation_time * 0.7) * (0.025 if data.is_boss else 0.045)
	if data.special_attack == EnemyData.SpecialAttack.SHOOT and target != null:
		sprite.flip_h = target.global_position.x < global_position.x
	if pulse_flash_time > 0.0:
		pulse_flash_time = maxf(pulse_flash_time - delta, 0.0)
		queue_redraw()


func _physics_process(delta: float) -> void:
	if target == null or target.stats.health <= 0.0:
		return
	var direction := global_position.direction_to(target.global_position)
	contact_timer = maxf(contact_timer - delta, 0.0)
	if data.special_attack == EnemyData.SpecialAttack.NONE:
		global_position += direction * move_speed * delta
	else:
		_process_special(delta, direction)
	if global_position.distance_to(target.global_position) < data.radius + 20.0 and contact_timer <= 0.0:
		var damage := attack_damage if special_phase == SpecialPhase.ACTIVE and data.special_attack == EnemyData.SpecialAttack.DASH else contact_damage
		contact_timer = 0.8
		target.take_hit(damage)


func _process_special(delta: float, direction: Vector2) -> void:
	match special_phase:
		SpecialPhase.COOLDOWN:
			special_timer = maxf(special_timer - delta, 0.0)
			if special_timer <= 0.0 and global_position.distance_to(target.global_position) <= data.trigger_range:
				special_phase = SpecialPhase.WARNING
				special_timer = data.warning_time
				special_direction = direction
				queue_redraw()
			else:
				if data.special_attack == EnemyData.SpecialAttack.SHOOT:
					var distance := global_position.distance_to(target.global_position)
					if distance > data.preferred_range + 30.0:
						global_position += direction * move_speed * delta
					elif distance < data.preferred_range - 50.0:
						global_position -= direction * move_speed * 0.7 * delta
					else:
						global_position += direction.orthogonal() * move_speed * 0.4 * delta
				else:
					global_position += direction * move_speed * delta
		SpecialPhase.WARNING:
			special_timer -= delta
			queue_redraw()
			if special_timer <= 0.0:
				_activate_special()
		SpecialPhase.ACTIVE:
			global_position += special_direction * data.attack_speed * delta
			special_timer -= delta
			queue_redraw()
			if special_timer <= 0.0:
				_reset_special()


func _activate_special() -> void:
	if data.special_attack == EnemyData.SpecialAttack.DASH:
		special_phase = SpecialPhase.ACTIVE
		special_timer = data.attack_duration
	elif data.special_attack == EnemyData.SpecialAttack.SHOOT:
		var projectile: AcidProjectile = ACID_PROJECTILE.instantiate()
		var projectile_root := get_tree().current_scene.get_node_or_null("EnemyProjectiles")
		if projectile_root == null:
			projectile_root = get_parent()
		projectile_root.add_child(projectile)
		projectile.launch(global_position, special_direction, data.attack_speed, attack_damage, target)
		attack_performed.emit(&"acid")
		_reset_special()
	else:
		if global_position.distance_to(target.global_position) <= data.attack_radius:
			target.take_hit(attack_damage)
		pulse_flash_time = PULSE_FLASH_DURATION
		_reset_special()
	queue_redraw()


func _reset_special() -> void:
	special_phase = SpecialPhase.COOLDOWN
	special_timer = data.special_interval
	queue_redraw()


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	var applied := maxf(amount * (1.0 - damage_reduction), 1.0)
	health -= applied
	damaged.emit(global_position + Vector2(0.0, -data.radius), applied)
	if health <= 0.0:
		health = 0.0
		remove_from_group("enemies")
		defeated.emit(global_position, data)
		queue_free()
	else:
		queue_redraw()
		modulate = Color(1.6, 1.6, 1.6)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)


func _draw() -> void:
	if data == null:
		return
	if special_phase == SpecialPhase.WARNING:
		var warning_color := Color(0.73, 0.20, 0.19, 0.85)
		var warning_progress := 1.0 - clampf(special_timer / maxf(data.warning_time, 0.01), 0.0, 1.0)
		if data.special_attack == EnemyData.SpecialAttack.DASH:
			var dash_path := special_direction * data.attack_speed * data.attack_duration
			draw_line(Vector2.ZERO, dash_path, warning_color, 5.0)
			draw_circle(dash_path, 6.0, warning_color)
			draw_arc(Vector2.ZERO, data.radius + 7.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, Color(1.0, 0.72, 0.27), 4.0)
		elif data.special_attack == EnemyData.SpecialAttack.SHOOT:
			var shot_color := Color(0.50, 0.88, 0.14, 0.9)
			draw_line(Vector2.ZERO, special_direction * 150.0, shot_color, 3.0)
			draw_arc(Vector2.ZERO, data.radius + 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, shot_color, 4.0)
		else:
			draw_circle(Vector2.ZERO, data.attack_radius, Color(0.95, 0.36, 0.28, 0.13))
			draw_arc(Vector2.ZERO, data.attack_radius, 0.0, TAU, 64, warning_color, 4.0)
			draw_arc(Vector2.ZERO, data.attack_radius - 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 64, Color(1.0, 0.72, 0.27), 4.0)
	elif special_phase == SpecialPhase.ACTIVE and data.special_attack == EnemyData.SpecialAttack.DASH:
		draw_line(-special_direction * data.radius, Vector2.ZERO, Color(1.0, 0.72, 0.27, 0.7), 7.0)
	if pulse_flash_time > 0.0:
		draw_arc(Vector2.ZERO, data.attack_radius, 0.0, TAU, 64, Color(1.0, 0.72, 0.27, pulse_flash_time / PULSE_FLASH_DURATION), 8.0)
	draw_circle(Vector2(0.0, data.radius * 0.7), data.radius * 0.7, Color(0.17, 0.13, 0.17, 0.17))
	if data.is_boss:
		draw_rect(Rect2(Vector2(-data.radius, data.radius + 11.0), Vector2(data.radius * 2.0, 8.0)), Color(0.18, 0.13, 0.2))
		draw_rect(Rect2(Vector2(-data.radius + 1.0, data.radius + 12.0), Vector2((data.radius * 2.0 - 2.0) * health / max_health, 6.0)), Color(0.92, 0.49, 0.25))
