extends Node2D

const RANGE := 175.0
const INTERVAL := 1.35

@onready var player: Player = get_parent() as Player
var cooldown: float = 0.0
var flash_time: float = 0.0
var hit_point: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if flash_time > 0.0:
		flash_time = maxf(flash_time - delta, 0.0)
		queue_redraw()
	if cooldown > 0.0:
		return
	var nearest: Enemy
	var nearest_distance := RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		var distance := player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	if nearest == null:
		return
	hit_point = to_local(nearest.global_position)
	nearest.take_damage(player.stats.roll_damage(1.8))
	player.play_attack_animation(player.global_position.direction_to(nearest.global_position), &"drill")
	cooldown = INTERVAL
	flash_time = 0.16
	queue_redraw()


func _draw() -> void:
	if flash_time <= 0.0:
		return
	var color := Color(1.0, 0.75, 0.28, flash_time / 0.16)
	draw_line(Vector2(0.0, -8.0), hit_point, color, 7.0)
	draw_circle(hit_point, 9.0, color)
