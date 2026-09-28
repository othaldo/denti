extends Node

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/toothpaste_projectile.tscn")
const ATTACK_RANGE := 410.0

@onready var player: Player = get_parent() as Player
var cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	var nearest: Enemy
	var nearest_distance := ATTACK_RANGE
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
	var projectile: ToothpasteProjectile = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.get_node("Projectiles").add_child(projectile)
	var aim := player.global_position.direction_to(nearest.global_position)
	projectile.launch(player.global_position, aim, player.stats.roll_damage())
	player.play_attack_animation(aim)
	cooldown = player.stats.attack_interval
