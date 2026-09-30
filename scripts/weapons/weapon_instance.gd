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
var focus_target_id: int = 0
var focus_hits: int = 0
var focus_time: float = 0.0


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
	focus_time = maxf(focus_time - delta, 0.0)
	attack_time = maxf(attack_time - delta, 0.0)
	var swing := attack_time / 0.2
	var visual_angle := deg_to_rad(data.visual_angle_degrees)
	sprite.rotation = aim.angle() + visual_angle + sin(idle_time * 3.0) * 0.06 + (sin(swing * PI) * 0.55 if data.attack_mode in [&"melee", &"area", &"thrust", &"sweep"] else 0.0)
	sprite.position = aim * (7.0 - swing * 6.0) + Vector2(0.0, sin(idle_time * 3.4) * 1.5)
	if attack_time > 0.0:
		queue_redraw()
	cooldown = maxf(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	var targets: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.health > 0.0 and player.global_position.distance_to(enemy.global_position) <= data.range_at_tier(tier) + enemy.data.radius:
			targets.append(enemy)
	if targets.is_empty():
		focus_target_id = 0
		focus_hits = 0
		return
	targets.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position))
	var nearest := targets[0]
	aim = player.global_position.direction_to(nearest.global_position)
	hit_point = to_local(nearest.global_position)
	if focus_target_id != nearest.get_instance_id() or focus_time <= 0.0:
		focus_target_id = nearest.get_instance_id()
		focus_hits = 0
	var guaranteed := data.crit_cycle > 0 and (focus_hits + 1) % data.crit_cycle == 0
	var attack_damage := player.stats.roll_damage(data.damage_at_tier(tier) / 18.0, data.crit_bonus, data.crit_multiplier, guaranteed)
	attack_damage *= 1.0 + minf(float(focus_hits) * data.focus_step, data.focus_cap)
	focus_hits = mini(focus_hits + 1, 1000)
	focus_time = maxf(data.interval_at_tier(tier) * player.stats.attack_interval / 0.65 * player.items.attack_interval_factor() * 1.5, 0.6)
	var critical := player.stats.last_roll_critical
	match data.attack_mode:
		&"projectile":
			var count := data.projectile_count_at_tier(tier)
			for index in count:
				var angle := 0.0 if index == 0 else (-0.12 if index == 1 else 0.12)
				var projectile: WeaponProjectile = PROJECTILE_SCENE.instantiate()
				get_tree().current_scene.get_node("Projectiles").add_child(projectile)
				projectile.launch(player.global_position + aim * 20.0, aim.rotated(angle), attack_damage if is_zero_approx(angle) else attack_damage * 0.55, data, player.items, critical, tier)
		&"melee", &"beam":
			WeaponAttackShapes.hit(nearest, data, tier, attack_damage, critical, player.items, aim)
		&"area", &"thrust", &"beam_line", &"cone", &"sweep":
			for enemy in targets:
				if WeaponAttackShapes.contains(data, tier, player.global_position, aim, enemy.global_position, enemy.data.radius):
					WeaponAttackShapes.hit(enemy, data, tier, attack_damage, critical, player.items, aim)
	attack_time = 0.2
	cooldown = data.interval_at_tier(tier) * player.stats.attack_interval / 0.65 * player.items.attack_interval_factor()
	var sound_kind: StringName = &"brush"
	if data.attack_mode in [&"area", &"sweep"]:
		sound_kind = &"floss"
	elif data.attack_mode in [&"melee", &"thrust"]:
		sound_kind = &"drill"
	player.play_attack_animation(aim, sound_kind)
	queue_redraw()


func _draw() -> void:
	if attack_time <= 0.0:
		return
	var fade := attack_time / 0.2
	var color := Color(data.projectile_color, fade)
	var origin := to_local(player.global_position)
	match data.attack_mode:
		&"melee":
			draw_line(Vector2.ZERO, hit_point, color, 6.0)
			draw_circle(hit_point, 8.0, color)
		&"beam":
			draw_line(Vector2.ZERO, hit_point, color, 4.0)
			draw_circle(hit_point, 6.0, Color.WHITE * fade)
		&"thrust", &"beam_line":
			var end := origin + aim * data.range_at_tier(tier)
			draw_line(origin, end, Color(color, fade * 0.25), data.attack_width)
			draw_line(origin, end, color, 3.0 if data.attack_mode == &"thrust" else 6.0)
		&"cone", &"sweep":
			var half_angle := deg_to_rad(data.arc_degrees * 0.5)
			var points := PackedVector2Array([origin])
			for index in 17:
				points.append(origin + aim.rotated(-half_angle + float(index) / 16.0 * half_angle * 2.0) * data.range_at_tier(tier))
			draw_colored_polygon(points, Color(color, fade * 0.12))
			draw_arc(origin, data.range_at_tier(tier), aim.angle() - half_angle, aim.angle() + half_angle, 24, color, 3.0)
		&"area":
			draw_arc(Vector2.ZERO, data.range_at_tier(tier), 0.0, TAU, 48, color, 4.0)
