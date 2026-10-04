extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _settle() -> void:
	for frame in 3:
		await process_frame

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_attack_batch.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.player.loadout.restore([])
	game.wave.active = false
	paused = true
	var index: EnemySpatialIndex = game.get_node("Enemies")
	game._create_enemy(WaveController.BACTERIA, game.player.global_position + Vector2(150, 0))
	var enemy: Enemy = index.get_child(0)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.special_timer = 0
	enemy._physics_process(0.0)
	_check(enemy.special_phase == Enemy.SpecialPhase.WARNING, "batch test did not enter warning")
	var counts := {"enemy": 0, "batch": 0}
	enemy.draw.connect(func(): counts.enemy += 1)
	index.draw.connect(func(): counts.batch += 1)
	await _settle()
	var own_count := int(counts.enemy)
	for frame in 5:
		enemy._process_special(0, enemy.special_direction)
		index._process(0)
		await _settle()
	_check(counts.enemy == own_count and counts.batch >= 5, "indexed warning still rebuilds each enemy's unrelated status drawing")
	_check(enemy._warning_rays(EnemyData.SpecialAttack.SHOOT, 3) == EnemyProjectilePatterns.fan_directions(enemy.special_direction, 3), "cached fan warning differs from attack spread")
	enemy.special_direction = Vector2.UP
	_check(enemy._warning_rays(EnemyData.SpecialAttack.RADIAL, 12) == EnemyProjectilePatterns.radial_directions(12, enemy.special_direction.angle() + PI), "warning cache retained the wrong mode/direction/count")
	# Exact old swept-contact oracle: include high-speed crossings, distant
	# misses, tangencies and stationary overlaps. Broad phase may only reject.
	game.player.stats.max_health = 1e9
	game.player.stats.health = 1e9
	game.player.stats.armor = 0
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	enemy.inflicted_statuses.clear()
	var data: EnemyData = WaveController.BACTERIA.duplicate()
	enemy.data = data
	var random := RandomNumberGenerator.new()
	random.seed = 88817
	for trial in 120:
		var start: Vector2 = game.player.global_position + Vector2(random.randf_range(-250, 250), random.randf_range(-250, 250))
		var end: Vector2 = game.player.global_position + Vector2(random.randf_range(-250, 250), random.randf_range(-250, 250))
		if trial == 0:
			start = game.player.global_position + Vector2(-200, 0)
			end = game.player.global_position + Vector2(200, 0)
		elif trial == 1:
			start = game.player.global_position + Vector2(-200, 33)
			end = game.player.global_position + Vector2(200, 33)
		elif trial == 2:
			start = game.player.global_position
			end = start
		enemy.global_position = start
		enemy.special_direction = start.direction_to(end)
		enemy.special_phase = Enemy.SpecialPhase.ACTIVE
		enemy.special_timer = 100
		enemy.contact_timer = 0
		data.attack_speed = start.distance_to(end) / 0.1
		game.player.hurt_time = 0
		game.player.dodge_time = 0
		var before: float = game.player.stats.health
		enemy._physics_process(0.1)
		var closest := Geometry2D.get_closest_point_to_segment(game.player.global_position, start, enemy.global_position)
		var expected := closest.distance_squared_to(game.player.global_position) < pow(data.radius + 20, 2)
		_check((game.player.stats.health < before) == expected, "contact broad phase changed swept hit/miss in trial %s" % trial)
	enemy.free()
	index._process(0)
	await _settle()
	_check(index.shadow_batch.enemies.is_empty() and not index.had_attack_visuals and not index.is_processing(), "cleanup left attack geometry processing")
	game.free()
	session.clear_run()
	paused = false
	if failures == 0:
		print("Denti batched attack visuals and swept contacts test passed")
	quit(0 if failures == 0 else 1)
