class_name ToothpasteProjectile
extends Node2D

const SPEED := 540.0
const MAX_DISTANCE := 450.0
const HIT_RADIUS := 10.0
const IMPACT_DURATION := 0.16

var direction: Vector2
var damage: float
var traveled: float = 0.0
var animation_time: float = 0.0
var impact_time: float = 0.0


func launch(start: Vector2, travel_direction: Vector2, attack_damage: float) -> void:
	global_position = start
	direction = travel_direction.normalized()
	damage = attack_damage


func _physics_process(delta: float) -> void:
	if impact_time > 0.0:
		impact_time = maxf(impact_time - delta, 0.0)
		queue_redraw()
		if impact_time <= 0.0:
			queue_free()
		return
	animation_time += delta
	var step := direction * SPEED * delta
	global_position += step
	traveled += step.length()
	queue_redraw()
	if traveled >= MAX_DISTANCE:
		queue_free()
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and global_position.distance_to(enemy.global_position) <= enemy.data.radius + HIT_RADIUS:
			enemy.take_damage(damage)
			impact_time = IMPACT_DURATION
			return


func _draw() -> void:
	if impact_time > 0.0:
		var progress := 1.0 - impact_time / IMPACT_DURATION
		draw_arc(Vector2.ZERO, HIT_RADIUS + progress * 20.0, 0.0, TAU, 28, Color(0.63, 0.94, 1.0, 1.0 - progress), 3.0)
		draw_circle(Vector2.ZERO, 5.0 + progress * 7.0, Color(0.8, 0.98, 1.0, (1.0 - progress) * 0.6))
		return
	var perpendicular := Vector2(-direction.y, direction.x)
	for index in range(4, 0, -1):
		var offset := -direction * float(index) * 8.0 + perpendicular * sin(animation_time * 19.0 + float(index)) * 2.0
		draw_circle(offset, 5.0 - float(index) * 0.8, Color(0.58, 0.87, 0.96, 0.15 + (4.0 - float(index)) * 0.16))
	var pulse := 1.0 + sin(animation_time * 21.0) * 0.12
	draw_circle(Vector2.ZERO, HIT_RADIUS * pulse + 3.0, Color(0.09, 0.29, 0.35, 0.28))
	draw_circle(Vector2.ZERO, HIT_RADIUS * pulse, Color(0.72, 0.96, 0.99))
	var highlight := Vector2(cos(animation_time * 12.0), sin(animation_time * 12.0)) * 4.0
	draw_circle(highlight, 3.0, Color.WHITE)
