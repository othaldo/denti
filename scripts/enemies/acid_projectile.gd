class_name AcidProjectile
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 290.0
var damage: float = 8.0
var target: Player
var lifetime: float = 2.2
var animation_time: float = 0.0
var projectile_color: Color = Color(0.53, 0.88, 0.13)
var hit_radius: float = 21.0
var visual_radius: float = 9.0


func launch(at: Vector2, aim: Vector2, projectile_speed: float, amount: float, player: Player, tint: Color = Color(0.53, 0.88, 0.13), collision_radius: float = 21.0, draw_radius: float = 9.0) -> void:
	global_position = at
	direction = aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	speed = projectile_speed
	damage = amount
	target = player
	projectile_color = tint
	hit_radius = collision_radius
	visual_radius = draw_radius
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	animation_time += delta * 15.0
	queue_redraw()
	if target != null and global_position.distance_to(target.global_position) < hit_radius:
		var hit_target := target
		queue_free()
		hit_target.take_hit(damage)
		return
	elif lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var pulse := sin(animation_time) * 1.5
	draw_circle(Vector2(-14.0, 0.0), 4.0, Color(projectile_color, 0.35))
	draw_circle(Vector2(-7.0, 0.0), 5.0, Color(projectile_color, 0.55))
	draw_circle(Vector2.ZERO, visual_radius + pulse, Color(0.20, 0.12, 0.17))
	draw_circle(Vector2.ZERO, visual_radius * 0.72 + pulse, projectile_color)
	draw_circle(Vector2(-visual_radius * 0.22, -visual_radius * 0.3), maxf(2.0, visual_radius * 0.22), Color(0.92, 1.0, 0.68))
	if visual_radius > 13.0:
		draw_arc(Vector2.ZERO, hit_radius, 0.0, TAU, 40, Color(projectile_color, 0.42), 3.0)
