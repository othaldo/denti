class_name WeaponProjectile
extends Node2D

const HIT_RADIUS := 10.0
const IMPACT_DURATION := 0.18

var data: WeaponData
var direction: Vector2
var damage: float
var traveled: float = 0.0
var animation_time: float = 0.0
var impact_time: float = 0.0
var pierces_left: int = 0
var hit_ids: Array[int] = []


func launch(start: Vector2, aim: Vector2, attack_damage: float, weapon: WeaponData) -> void:
	global_position = start
	direction = aim.normalized()
	damage = attack_damage
	data = weapon
	pierces_left = weapon.pierce


func _physics_process(delta: float) -> void:
	if impact_time > 0.0:
		impact_time -= delta
		queue_redraw()
		if impact_time <= 0.0:
			queue_free()
		return
	animation_time += delta
	var step := direction * data.projectile_speed * delta
	global_position += step
	traveled += step.length()
	if traveled >= data.attack_range + 40.0:
		queue_free()
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or hit_ids.has(enemy.get_instance_id()):
			continue
		if global_position.distance_to(enemy.global_position) > enemy.data.radius + HIT_RADIUS:
			continue
		if data.splash_radius > 0.0:
			_explode()
			return
		hit_ids.append(enemy.get_instance_id())
		if data.knockback > 0.0:
			enemy.global_position += direction * data.knockback
		enemy.take_damage(data.damage_against(enemy, damage))
		if pierces_left <= 0:
			impact_time = IMPACT_DURATION
			break
		pierces_left -= 1
	queue_redraw()


func _explode() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and global_position.distance_to(enemy.global_position) <= data.splash_radius + enemy.data.radius:
			enemy.take_damage(data.damage_against(enemy, damage))
	impact_time = IMPACT_DURATION
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	if impact_time > 0.0:
		var progress := 1.0 - impact_time / IMPACT_DURATION
		var radius := data.splash_radius if data.splash_radius > 0.0 else 20.0
		draw_arc(Vector2.ZERO, radius * progress, 0.0, TAU, 40, Color(data.projectile_color, 1.0 - progress), 4.0)
		return
	var color := data.projectile_color
	var radius := 11.0 if data.splash_radius > 0.0 or data.pierce > 0 else 7.0
	for index in 3:
		var tail := -direction * (float(index) + 1.0) * 8.0
		draw_circle(tail, radius * (0.75 - float(index) * 0.16), Color(color, 0.34 - float(index) * 0.08))
	draw_circle(Vector2.ZERO, radius + sin(animation_time * 20.0) * 1.0, Color(0.11, 0.24, 0.27, 0.42))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(-2.5, -2.5), radius * 0.32, Color.WHITE)
