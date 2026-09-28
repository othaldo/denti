extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameSession").save_path = "user://test_enemy_run.json"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	paused = true
	var player: Player = game.player
	var enemies: Node2D = game.get_node("Enemies")
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")

	var bacterium: Enemy = enemy_scene.instantiate()
	bacterium.configure(load("res://data/enemies/bacteria.tres"), player)
	enemies.add_child(bacterium)
	bacterium.global_position = player.global_position + Vector2(150.0, 0.0)
	bacterium.special_timer = 0.0
	bacterium._physics_process(0.01)
	if bacterium.special_phase != Enemy.SpecialPhase.WARNING:
		_fail("bacterium did not announce its dash")
		return
	var dash_start := bacterium.global_position
	player.global_position += Vector2(0.0, 100.0)
	bacterium._physics_process(bacterium.data.warning_time)
	if bacterium.special_phase != Enemy.SpecialPhase.ACTIVE or bacterium.global_position != dash_start:
		_fail("bacterium moved before its warning ended")
		return
	bacterium._physics_process(bacterium.data.attack_duration)
	if bacterium.global_position.x >= dash_start.x - 100.0 or absf(bacterium.global_position.y - dash_start.y) > 1.0:
		_fail("bacterium did not dash along the announced path")
		return

	player.global_position = DentiArena.SIZE / 2.0
	var sugar: Enemy = enemy_scene.instantiate()
	sugar.configure(load("res://data/enemies/sugar.tres"), player)
	enemies.add_child(sugar)
	sugar.global_position = player.global_position + Vector2(80.0, 0.0)
	sugar.special_timer = 0.0
	var health_before := player.stats.health
	sugar._physics_process(0.01)
	if sugar.special_phase != Enemy.SpecialPhase.WARNING:
		_fail("sugar did not announce its pulse")
		return
	player.global_position += Vector2(0.0, 150.0)
	sugar._physics_process(sugar.data.warning_time)
	if player.stats.health != health_before:
		_fail("sugar pulse hit Denti outside its marked area")
		return
	player.global_position = DentiArena.SIZE / 2.0
	sugar.special_timer = 0.0
	sugar._physics_process(0.01)
	sugar._physics_process(sugar.data.warning_time)
	if player.stats.health >= health_before:
		_fail("sugar pulse did not damage Denti inside its marked area")
		return

	paused = false
	print("Denti enemy behavior test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
