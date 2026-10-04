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
var body_sprite: Sprite2D
var halo_sprite: Sprite2D
var inflicted_statuses: Array[Dictionary] = []
var pool: EnemyProjectilePool


func launch(at: Vector2, aim: Vector2, projectile_speed: float, amount: float, player: Player, tint: Color = Color(0.53, 0.88, 0.13), collision_radius: float = 21.0, draw_radius: float = 9.0, statuses: Array[Dictionary] = []) -> void:
	global_position = at
	lifetime = 2.2
	animation_time = 0.0
	direction = aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	speed = projectile_speed
	damage = amount
	target = player
	inflicted_statuses = DentiStatus.sanitize_attacks(statuses).duplicate(true)
	projectile_color = DentiStatus.COLORS[int(inflicted_statuses[0]["kind"])] if not inflicted_statuses.is_empty() else tint
	hit_radius = collision_radius
	visual_radius = draw_radius
	rotation = direction.angle()
	if body_sprite == null:
		body_sprite = Sprite2D.new()
		add_child(body_sprite)
	body_sprite.texture = EnemyProjectileVisuals.body(projectile_color, draw_radius)
	body_sprite.scale = Vector2.ONE / EnemyProjectileVisuals.RESOLUTION
	if draw_radius > 13.0:
		if halo_sprite == null:
			halo_sprite = Sprite2D.new()
			add_child(halo_sprite)
		halo_sprite.texture = EnemyProjectileVisuals.halo(projectile_color, collision_radius)
		halo_sprite.scale = Vector2.ONE / EnemyProjectileVisuals.RESOLUTION
		halo_sprite.visible = true
	elif halo_sprite != null:
		halo_sprite.visible = false


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	animation_time += delta * 15.0
	if body_sprite != null:
		body_sprite.scale = Vector2.ONE * (1.0 + sin(animation_time) * 1.5 / maxf(visual_radius, 1.0)) / EnemyProjectileVisuals.RESOLUTION
	if target != null and global_position.distance_squared_to(target.global_position) < hit_radius * hit_radius:
		var hit_target := target
		var hit_statuses := inflicted_statuses
		var hit_damage := damage
		_retire()
		hit_target.take_hit(hit_damage, hit_statuses)
		return
	elif lifetime <= 0.0:
		_retire()

func _retire() -> void:
	if is_instance_valid(pool) and get_parent() == pool:
		pool.recycle(self)
	else:
		queue_free()
