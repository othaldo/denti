class_name WeaponInstance
extends Node2D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/weapon_projectile.tscn")

var data: WeaponData
var tier: int = 1
var invested_coins: int = 0
var cooldown: float = 0.0
var attack_time: float = 0.0
var idle_time: float = 0.0
var aim: Vector2 = Vector2.RIGHT
var hit_point: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var player: Player


func configure(weapon: WeaponData, weapon_tier: int = 1) -> void:
	data = weapon
	tier = clampi(weapon_tier, 1, 4)
	name = "%s_%d" % [str(data.id), get_instance_id()]


func _ready() -> void:
	player = get_parent().get_parent() as Player
	sprite = Sprite2D.new()
	sprite.texture = data.sprite
	sprite.offset = (Vector2(0.5, 0.5) - data.grip_anchor) * data.sprite.get_size()
	var extent := maxf(float(data.sprite.get_width()), float(data.sprite.get_height()))
	sprite.scale = Vector2.ONE * ((70.0 if data.hands == 2 else 58.0) / extent)
	add_child(sprite)
	z_index = 1


func _physics_process(delta: float) -> void:
	idle_time += delta
	attack_time = maxf(attack_time - delta, 0.0)
	var swing := attack_time / 0.2
	var visual_angle := deg_to_rad(data.visual_angle_degrees)
	sprite.rotation = aim.angle() + visual_angle + sin(idle_time * 3.0) * 0.06 + (sin(swing * PI) * 0.55 if data.attack_mode == &"melee" or data.attack_mode == &"area" else 0.0)
	sprite.position = aim * (7.0 - swing * 6.0) + Vector2(0.0, sin(idle_time * 3.4) * 1.5)
	if attack_time > 0.0:
		queue_redraw()
	cooldown = maxf(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	var targets: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and player.global_position.distance_to(enemy.global_position) <= data.attack_range + enemy.data.radius:
			targets.append(enemy)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position))
	var nearest := targets[0]
	aim = player.global_position.direction_to(nearest.global_position)
	hit_point = to_local(nearest.global_position)
	var attack_damage := player.stats.roll_damage(data.damage_at_tier(tier) / 18.0)
	var critical := player.stats.last_roll_critical
	match data.attack_mode:
		&"projectile":
			var projectile: WeaponProjectile = PROJECTILE_SCENE.instantiate()
			get_tree().current_scene.get_node("Projectiles").add_child(projectile)
			projectile.launch(player.global_position + aim * 20.0, aim, attack_damage, data, player.items, critical)
		&"melee", &"beam":
			nearest.take_damage(data.damage_against(nearest, player.items.modify_damage(nearest, data, attack_damage)), data, critical)
		&"area":
			for enemy in targets:
				enemy.take_damage(data.damage_against(enemy, player.items.modify_damage(enemy, data, attack_damage)), data, critical)
	attack_time = 0.2
	cooldown = data.interval_at_tier(tier) * player.stats.attack_interval / 0.65 * player.items.attack_interval_factor()
	var sound_kind: StringName = &"brush"
	if data.attack_mode == &"area":
		sound_kind = &"floss"
	elif data.attack_mode == &"melee":
		sound_kind = &"drill"
	player.play_attack_animation(aim, sound_kind)
	queue_redraw()


func _draw() -> void:
	if attack_time <= 0.0:
		return
	var fade := attack_time / 0.2
	var color := Color(data.projectile_color, fade)
	match data.attack_mode:
		&"melee":
			draw_line(Vector2.ZERO, hit_point, color, 6.0)
			draw_circle(hit_point, 8.0, color)
		&"beam":
			draw_line(Vector2.ZERO, hit_point, color, 4.0)
			draw_circle(hit_point, 6.0, Color.WHITE * fade)
		&"area":
			draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 48, color, 4.0)
