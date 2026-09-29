class_name Enemy
extends Node2D

signal defeated(position: Vector2, data: EnemyData)
signal damaged(position: Vector2, amount: float)
signal weapon_hit(enemy: Enemy, amount: float, weapon: WeaponData, critical: bool)
signal attack_performed(kind: StringName)
signal death_started(position: Vector2)
signal enraged(position: Vector2)

enum SpecialPhase { COOLDOWN, WARNING, ACTIVE }
enum BossMove { CHARGE, PULSE }

const PULSE_FLASH_DURATION := 0.18
const BOSS_DEATH_DURATION := 0.9
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
var boss_move: BossMove = BossMove.CHARGE
var boss_charge_next: bool = true
var boss_dash_end: Vector2 = Vector2.ZERO
var boss_dash_origin: Vector2 = Vector2.ZERO
var pulse_flash_time: float = 0.0
var dying: bool = false
var death_elapsed: float = 0.0
var is_enraged: bool = false
var sprite_base_scale: Vector2 = Vector2.ONE
var bleed_stacks: int = 0
var bleed_dps: float = 0.0
var bleed_time: float = 0.0
var bleed_tick: float = 1.0


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
	special_timer = data.special_interval * randf_range(0.35, 0.5) if data.special_attack == EnemyData.SpecialAttack.BOSS else data.special_interval * randf_range(0.65, 1.0)
	queue_redraw()


func _ready() -> void:
	add_to_group("enemies")
	sprite.texture = data.sprite
	sprite.modulate = data.sprite_tint
	var side := maxf(float(data.sprite.get_width()), float(data.sprite.get_height()))
	sprite.scale = Vector2.ONE * (data.radius * 2.35 / side)
	sprite_base_scale = sprite.scale
	animation_time = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	if dying:
		death_elapsed += delta
		var progress := clampf(death_elapsed / BOSS_DEATH_DURATION, 0.0, 1.0)
		sprite.position.y = -18.0 * progress
		sprite.rotation += delta * 2.2
		sprite.scale = sprite_base_scale * (1.0 + 0.28 * sin(progress * PI) - 0.45 * progress)
		sprite.modulate = Color(1.45, 1.27, 0.95, 1.0) if progress < 0.2 else data.sprite_tint.lerp(Color(0.50, 0.25, 0.57, 0.0), (progress - 0.2) / 0.8)
		queue_redraw()
		if death_elapsed >= BOSS_DEATH_DURATION:
			defeated.emit(global_position, data)
			queue_free()
		return
	animation_time += delta * (2.5 if data.is_boss else 5.0)
	sprite.position.y = sin(animation_time) * (2.2 if data.is_boss else 1.2)
	sprite.rotation = sin(animation_time * 0.7) * (0.025 if data.is_boss else 0.045)
	if data.special_attack == EnemyData.SpecialAttack.SHOOT and target != null:
		sprite.flip_h = target.global_position.x < global_position.x
	if pulse_flash_time > 0.0:
		pulse_flash_time = maxf(pulse_flash_time - delta, 0.0)
		queue_redraw()


func _physics_process(delta: float) -> void:
	if bleed_time > 0.0 and health > 0.0:
		bleed_time = maxf(bleed_time - delta, 0.0)
		bleed_tick -= delta
		if bleed_tick <= 0.0:
			bleed_tick += 1.0
			take_damage(bleed_dps * float(bleed_stacks))
		if bleed_time <= 0.0:
			bleed_stacks = 0
			bleed_dps = 0.0
			queue_redraw()
	if health <= 0.0:
		return
	if target == null or target.stats.health <= 0.0:
		return
	var direction := global_position.direction_to(target.global_position)
	var before_move := global_position
	var charging := special_phase == SpecialPhase.ACTIVE and (data.special_attack == EnemyData.SpecialAttack.DASH or data.special_attack == EnemyData.SpecialAttack.BOSS and boss_move == BossMove.CHARGE)
	contact_timer = maxf(contact_timer - delta, 0.0)
	if data.special_attack == EnemyData.SpecialAttack.NONE:
		global_position += direction * move_speed * delta
	else:
		_process_special(delta, direction)
	var closest := Geometry2D.get_closest_point_to_segment(target.global_position, before_move, global_position)
	if closest.distance_to(target.global_position) < data.radius + 20.0 and contact_timer <= 0.0:
		var damage := attack_damage if charging else contact_damage
		contact_timer = 0.8
		target.take_hit(damage)


func _process_special(delta: float, direction: Vector2) -> void:
	match special_phase:
		SpecialPhase.COOLDOWN:
			special_timer = maxf(special_timer - delta, 0.0)
			var distance := global_position.distance_to(target.global_position)
			if special_timer <= 0.0 and distance <= data.trigger_range:
				special_phase = SpecialPhase.WARNING
				special_timer = data.warning_time
				special_direction = direction
				if data.special_attack == EnemyData.SpecialAttack.BOSS:
					boss_move = BossMove.CHARGE if distance > data.attack_radius + 45.0 or boss_charge_next else BossMove.PULSE
					boss_charge_next = boss_move != BossMove.CHARGE
					if boss_move == BossMove.CHARGE:
						boss_dash_end = _boss_dash_target(direction)
					attack_performed.emit(&"boss_warning")
				queue_redraw()
			else:
				if data.special_attack == EnemyData.SpecialAttack.SHOOT:
					if distance > data.preferred_range + 30.0:
						global_position += direction * move_speed * delta
					elif distance < data.preferred_range - 50.0:
						global_position -= direction * move_speed * 0.7 * delta
					else:
						global_position += direction.orthogonal() * move_speed * 0.4 * delta
				else:
					global_position += direction * move_speed * (1.25 if is_enraged else 1.0) * delta
		SpecialPhase.WARNING:
			special_timer -= delta
			queue_redraw()
			if special_timer <= 0.0:
				_activate_special()
		SpecialPhase.ACTIVE:
			if data.special_attack == EnemyData.SpecialAttack.BOSS:
				global_position = global_position.move_toward(boss_dash_end, data.attack_speed * delta)
			else:
				global_position += special_direction * data.attack_speed * delta
			special_timer -= delta
			queue_redraw()
			if special_timer <= 0.0 or data.special_attack == EnemyData.SpecialAttack.BOSS and global_position.distance_to(boss_dash_end) < 1.0:
				_reset_special()


func _boss_dash_target(direction: Vector2) -> Vector2:
	var margin := DentiArena.WALL_WIDTH + data.radius + 6.0
	return (global_position + direction * data.attack_speed * data.attack_duration).clamp(Vector2.ONE * margin, target.arena.arena_size - Vector2.ONE * margin)


func _activate_special() -> void:
	if data.special_attack == EnemyData.SpecialAttack.BOSS:
		if boss_move == BossMove.CHARGE:
			special_phase = SpecialPhase.ACTIVE
			special_timer = data.attack_duration
			boss_dash_origin = global_position
			contact_timer = 0.0
			attack_performed.emit(&"boss_charge")
		else:
			if global_position.distance_to(target.global_position) <= data.attack_radius:
				target.take_hit(attack_damage)
			pulse_flash_time = PULSE_FLASH_DURATION
			attack_performed.emit(&"boss_pulse")
			_reset_special()
	elif data.special_attack == EnemyData.SpecialAttack.DASH:
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
	special_timer = data.special_interval * (0.72 if is_enraged else 1.0)
	queue_redraw()


func apply_bleed(dps: float, duration: float) -> void:
	bleed_stacks = mini(bleed_stacks + 1, 3)
	bleed_dps = maxf(bleed_dps, dps)
	bleed_time = maxf(bleed_time, duration)
	queue_redraw()


func take_damage(amount: float, weapon: WeaponData = null, critical: bool = false) -> void:
	if health <= 0.0:
		return
	var applied := maxf(amount * (1.0 - damage_reduction), 1.0)
	health -= applied
	damaged.emit(global_position + Vector2(0.0, -data.radius), applied)
	if weapon != null:
		weapon_hit.emit(self, applied, weapon, critical)
	if data.is_boss and not is_enraged and health > 0.0 and health <= max_health * 0.5:
		is_enraged = true
		enraged.emit(global_position)
	if health <= 0.0:
		health = 0.0
		remove_from_group("enemies")
		if data.is_boss:
			dying = true
			death_elapsed = 0.0
			death_started.emit(global_position)
			queue_redraw()
		else:
			defeated.emit(global_position, data)
			queue_free()
	else:
		queue_redraw()
		modulate = Color(1.6, 1.6, 1.6)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)


func _draw() -> void:
	if data == null:
		return
	if dying:
		var progress := clampf(death_elapsed / BOSS_DEATH_DURATION, 0.0, 1.0)
		var fade := 1.0 - progress
		draw_circle(Vector2.ZERO, data.radius * (1.0 + progress * 3.0), Color(0.56, 0.15, 0.42, 0.18 * fade))
		draw_arc(Vector2.ZERO, data.radius * (0.8 + progress * 3.4), 0.0, TAU, 48, Color(1.0, 0.78, 0.38, 0.95 * fade), 11.0 * fade + 2.0)
		for index in 12:
			var ray := Vector2.RIGHT.rotated(TAU * float(index) / 12.0 + 0.2)
			var shard_at := ray * (data.radius * 0.7 + progress * 180.0)
			draw_line(shard_at, shard_at + ray * (16.0 + 26.0 * fade), Color(1.0, 0.76, 0.35, fade), 6.0 * fade + 1.0)
		return
	if special_phase == SpecialPhase.WARNING:
		var warning_color := Color(0.73, 0.20, 0.19, 0.85)
		var warning_progress := 1.0 - clampf(special_timer / maxf(data.warning_time, 0.01), 0.0, 1.0)
		if data.special_attack == EnemyData.SpecialAttack.DASH or data.special_attack == EnemyData.SpecialAttack.BOSS and boss_move == BossMove.CHARGE:
			var dash_path := boss_dash_end - global_position if data.special_attack == EnemyData.SpecialAttack.BOSS else special_direction * data.attack_speed * data.attack_duration
			if data.special_attack == EnemyData.SpecialAttack.BOSS:
				var side := special_direction.orthogonal() * (data.radius + 19.0)
				var start := special_direction * data.radius * 0.5
				draw_colored_polygon(PackedVector2Array([start - side, dash_path - side, dash_path + side, start + side]), Color(0.95, 0.20, 0.29, 0.18 + warning_progress * 0.22))
				draw_line(start - side, dash_path - side, warning_color, 3.0 + warning_progress * 3.0)
				draw_line(start + side, dash_path + side, warning_color, 3.0 + warning_progress * 3.0)
			draw_line(Vector2.ZERO, dash_path, warning_color, 5.0)
			draw_circle(dash_path, data.radius * 0.55 if data.is_boss else 6.0, Color(0.95, 0.20, 0.29, 0.20 + warning_progress * 0.25))
			draw_arc(Vector2.ZERO, data.radius + 7.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, Color(1.0, 0.72, 0.27), 4.0)
		elif data.special_attack == EnemyData.SpecialAttack.SHOOT:
			var shot_color := Color(0.50, 0.88, 0.14, 0.9)
			draw_line(Vector2.ZERO, special_direction * 150.0, shot_color, 3.0)
			draw_arc(Vector2.ZERO, data.radius + 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, shot_color, 4.0)
		else:
			draw_circle(Vector2.ZERO, data.attack_radius, Color(0.95, 0.36, 0.28, 0.13))
			draw_arc(Vector2.ZERO, data.attack_radius, 0.0, TAU, 64, warning_color, 4.0)
			draw_arc(Vector2.ZERO, data.attack_radius - 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 64, Color(1.0, 0.72, 0.27), 4.0)
	elif special_phase == SpecialPhase.ACTIVE and (data.special_attack == EnemyData.SpecialAttack.DASH or data.special_attack == EnemyData.SpecialAttack.BOSS and boss_move == BossMove.CHARGE):
		draw_line(boss_dash_origin - global_position if data.is_boss else -special_direction * data.radius, Vector2.ZERO, Color(1.0, 0.72, 0.27, 0.7), 15.0 if data.is_boss else 7.0)
	if pulse_flash_time > 0.0:
		draw_arc(Vector2.ZERO, data.attack_radius, 0.0, TAU, 64, Color(1.0, 0.72, 0.27, pulse_flash_time / PULSE_FLASH_DURATION), 8.0)
	if bleed_stacks > 0:
		draw_arc(Vector2.ZERO, data.radius + 4.0, 0.0, TAU, 24, Color(0.78, 0.25, 0.48, 0.85), 2.5 + bleed_stacks)
	if is_enraged:
		draw_arc(Vector2.ZERO, data.radius + 12.0, 0.0, TAU, 40, Color(1.0, 0.26, 0.23, 0.85), 4.0)
	draw_circle(Vector2(0.0, data.radius * 0.7), data.radius * 0.7, Color(0.17, 0.13, 0.17, 0.17))
	if data.is_boss:
		draw_rect(Rect2(Vector2(-data.radius, data.radius + 11.0), Vector2(data.radius * 2.0, 8.0)), Color(0.18, 0.13, 0.2))
		draw_rect(Rect2(Vector2(-data.radius + 1.0, data.radius + 12.0), Vector2((data.radius * 2.0 - 2.0) * health / max_health, 6.0)), Color(0.92, 0.49, 0.25))
