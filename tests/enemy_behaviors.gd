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

	player.global_position = DentiArena.SIZE / 2.0
	var late_sugar: Enemy = enemy_scene.instantiate()
	late_sugar.configure(WaveController.SUGAR, player, 7)
	enemies.add_child(late_sugar)
	late_sugar.global_position = player.global_position + Vector2(550.0, 0.0)
	late_sugar.special_timer = 0.0
	late_sugar._physics_process(0.01)
	if late_sugar.active_special_attack != EnemyData.SpecialAttack.DASH or late_sugar.special_phase != Enemy.SpecialPhase.WARNING:
		_fail("wave 7 sugar did not announce a charge from outside pulse range")
		return
	var charge_start := late_sugar.global_position
	health_before = player.stats.health
	player.global_position += Vector2(0.0, 150.0)
	late_sugar._physics_process(late_sugar.data.warning_time)
	if late_sugar.special_phase != Enemy.SpecialPhase.ACTIVE or player.stats.health != health_before:
		_fail("sugar charge hit during its warning")
		return
	late_sugar._physics_process(late_sugar.data.attack_duration)
	if late_sugar.global_position.x > charge_start.x - 450.0 or player.stats.health != health_before:
		_fail("sugar did not charge along its announced dodgeable path")
		return
	player.global_position = DentiArena.SIZE / 2.0
	player.hurt_time = 0.0
	late_sugar.global_position = player.global_position + Vector2(550.0, 0.0)
	late_sugar.special_timer = 0.0
	late_sugar._physics_process(0.01)
	var landing := late_sugar.global_position + late_sugar.special_direction * late_sugar.data.attack_speed * late_sugar.data.attack_duration
	player.global_position = landing + Vector2(0.0, 60.0)
	late_sugar._physics_process(late_sugar.data.warning_time)
	late_sugar._physics_process(late_sugar.data.attack_duration)
	if player.stats.health >= health_before:
		_fail("sugar charge impact missed Denti inside its marked landing area")
		return
	player.global_position = Vector2(80.0, DentiArena.SIZE.y * 0.5)
	late_sugar.global_position = player.global_position + Vector2(200.0, 0.0)
	late_sugar.special_timer = 0.0
	late_sugar._physics_process(0.01)
	late_sugar._physics_process(late_sugar.data.warning_time)
	late_sugar._physics_process(late_sugar.data.attack_duration)
	if late_sugar.global_position.x < DentiArena.WALL_WIDTH + late_sugar.data.radius + 6.0:
		_fail("sugar charge left the arena near its wall")
		return

	var spitter: Enemy = enemy_scene.instantiate()
	spitter.configure(WaveController.ACID_SPITTER, player, 12)
	enemies.add_child(spitter)
	spitter.global_position = player.global_position + Vector2(200.0, 0.0)
	spitter.special_direction = Vector2.LEFT
	spitter._activate_special()
	var projectiles: Node2D = game.get_node("EnemyProjectiles")
	if projectiles.get_child_count() != 3 or spitter.special_timer >= spitter.data.special_interval:
		_fail("late ranged enemy did not fire its faster three-shot fan before the lane upgrade")
		return
	var first: AcidProjectile = projectiles.get_child(0)
	var last: AcidProjectile = projectiles.get_child(2)
	if first.direction.distance_to(last.direction) < 0.25 or first.projectile_color.g < 0.8:
		_fail("late fan lacks spread or visible enemy projectile color")
		return
	if not is_equal_approx(first.damage, spitter.data.attack_damage * WaveController.enemy_damage_multiplier(spitter.data, 12)) or first.damage <= 8.0 * WaveController.enemy_damage_multiplier(spitter.data, 12):
		_fail("normal ranged projectile damage did not increase")
		return
	for projectile in projectiles.get_children():
		projectile.queue_free()
	await process_frame

	var advanced_spitter: Enemy = enemy_scene.instantiate()
	advanced_spitter.configure(WaveController.ACID_SPITTER, player, 14)
	enemies.add_child(advanced_spitter)
	advanced_spitter.global_position = player.global_position + Vector2(200.0, 0.0)
	advanced_spitter.special_direction = Vector2.LEFT
	advanced_spitter._activate_special()
	if advanced_spitter.active_special_attack != EnemyData.SpecialAttack.LANE or projectiles.get_child_count() != advanced_spitter.data.lane_projectile_count:
		_fail("wave 14 ranged enemy did not switch to its three-shot lane pattern")
		return
	first = projectiles.get_child(0)
	last = projectiles.get_child(projectiles.get_child_count() - 1)
	if first.direction.distance_to(last.direction) > 0.01 or first.global_position.distance_to(last.global_position) < advanced_spitter.data.lane_projectile_spacing:
		_fail("advanced lane pattern lacks parallel spacing")
		return

	paused = false
	print("Denti enemy behavior test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
