class_name AcidProjectile
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 290.0
var damage: float = 8.0
var target: Player
var lifetime: float = 2.2
var animation_time: float = 0.0


func launch(at: Vector2, aim: Vector2, projectile_speed: float, amount: float, player: Player) -> void:
	global_position = at
	direction = aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	speed = projectile_speed
	damage = amount
	target = player
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	animation_time += delta * 15.0
	queue_redraw()
	if target != null and global_position.distance_to(target.global_position) < 21.0:
		var hit_target := target
		queue_free()
		hit_target.take_hit(damage)
		return
	elif lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var pulse := sin(animation_time) * 1.5
	draw_circle(Vector2(-14.0, 0.0), 4.0, Color(0.43, 0.73, 0.11, 0.35))
	draw_circle(Vector2(-7.0, 0.0), 5.0, Color(0.59, 0.83, 0.13, 0.55))
	draw_circle(Vector2.ZERO, 9.0 + pulse, Color(0.20, 0.12, 0.17))
	draw_circle(Vector2.ZERO, 6.5 + pulse, Color(0.53, 0.88, 0.13))
	draw_circle(Vector2(-2.0, -2.5), 2.0, Color(0.92, 1.0, 0.68))
