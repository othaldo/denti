extends Node2D

const RANGE := 108.0
const INTERVAL := 1.8

@onready var player: Player = get_parent() as Player
var cooldown: float = 0.0
var ring_time: float = 0.0


func _physics_process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if ring_time > 0.0:
		ring_time = maxf(ring_time - delta, 0.0)
		queue_redraw()
	if cooldown > 0.0:
		return
	var targets: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and player.global_position.distance_to(enemy.global_position) <= RANGE + enemy.data.radius:
			targets.append(enemy)
	if targets.is_empty():
		return
	for enemy in targets:
		enemy.take_damage(player.stats.roll_damage(0.8))
	player.play_attack_animation(Vector2.UP, &"floss")
	cooldown = INTERVAL
	ring_time = 0.22
	queue_redraw()


func _draw() -> void:
	if ring_time > 0.0:
		draw_arc(Vector2.ZERO, RANGE, 0.0, TAU, 64, Color(0.77, 0.94, 1.0, ring_time / 0.22), 5.0)
