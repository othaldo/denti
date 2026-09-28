class_name Enemy
extends Node2D

signal defeated(position: Vector2, data: EnemyData)

@onready var sprite: Sprite2D = $Sprite2D

var data: EnemyData
var target: Player
var health: float
var max_health: float
var contact_damage: float
var move_speed: float
var contact_timer: float = 0.0
var animation_time: float = 0.0


func configure(enemy_data: EnemyData, player: Player, wave_number: int = 1) -> void:
	data = enemy_data
	target = player
	max_health = data.max_health * (1.0 + (wave_number - 1) * 0.14)
	health = max_health
	contact_damage = data.contact_damage * (1.0 + (wave_number - 1) * 0.09)
	move_speed = data.move_speed * (1.0 + (wave_number - 1) * 0.025)
	queue_redraw()


func _ready() -> void:
	add_to_group("enemies")
	sprite.texture = data.sprite
	var side := maxf(float(data.sprite.get_width()), float(data.sprite.get_height()))
	sprite.scale = Vector2.ONE * (data.radius * 2.35 / side)
	animation_time = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	animation_time += delta * (2.5 if data.is_boss else 5.0)
	sprite.position.y = sin(animation_time) * (2.2 if data.is_boss else 1.2)
	sprite.rotation = sin(animation_time * 0.7) * (0.025 if data.is_boss else 0.045)


func _physics_process(delta: float) -> void:
	if target == null or target.stats.health <= 0.0:
		return
	var direction := global_position.direction_to(target.global_position)
	global_position += direction * move_speed * delta
	contact_timer = maxf(contact_timer - delta, 0.0)
	if global_position.distance_to(target.global_position) < data.radius + 20.0 and contact_timer <= 0.0:
		target.take_hit(contact_damage)
		contact_timer = 0.8


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
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
	draw_circle(Vector2(0.0, data.radius * 0.7), data.radius * 0.7, Color(0.17, 0.13, 0.17, 0.17))
	if data.is_boss:
		draw_rect(Rect2(Vector2(-data.radius, data.radius + 11.0), Vector2(data.radius * 2.0, 8.0)), Color(0.18, 0.13, 0.2))
		draw_rect(Rect2(Vector2(-data.radius + 1.0, data.radius + 12.0), Vector2((data.radius * 2.0 - 2.0) * health / max_health, 6.0)), Color(0.92, 0.49, 0.25))
