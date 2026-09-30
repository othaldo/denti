extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_elite_pressure_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game._clear_combat()
	game.wave.current_wave = 7
	game.wave.start_next_wave()
	game.telemetry.begin_wave(8)
	if game.wave.elite_times.size() != 1 or game.wave.elite_counts != [1] or game.wave.elite_times[0] < game.wave.duration * WaveController.ELITE_TIME_START_FRACTION or game.wave.elite_times[0] > game.wave.duration * WaveController.ELITE_TIME_END_FRACTION:
		_fail("wave 8 did not schedule an elite")
		return
	game.wave.spawn_cooldown = 100.0
	game.wave.burst_index = game.wave.burst_times.size()
	game.wave.horde_spawned = true
	game.wave.remaining = game.wave.duration - game.wave.elite_times[0] + 0.01
	game.wave._process(0.02)
	if game.get_node("Enemies").get_child_count() != 1 or game.wave.elite_index != 1 or game.telemetry.wave_elites_spawned != 1:
		_fail("scheduled elite did not spawn exactly once")
		return
	var elite: Enemy = game.get_node("Enemies").get_child(0)
	if not elite.data.is_elite or elite.data.is_boss or elite.active_special_attack != EnemyData.SpecialAttack.RADIAL or elite.special_timer > 0.55:
		_fail("elite lacks its distinct radial role")
		return
	elite.global_position = game.player.global_position + Vector2(200.0, 0.0)
	elite.special_timer = 0.0
	elite._physics_process(0.01)
	if elite.special_phase != Enemy.SpecialPhase.WARNING or game.get_node("EnemyProjectiles").get_child_count() != 0:
		_fail("elite fired before its warning")
		return
	elite._physics_process(elite.data.warning_time)
	var expected := EnemyProjectilePatterns.radial_directions(elite.data.radial_count, elite.special_direction.angle() + PI).size()
	if game.get_node("EnemyProjectiles").get_child_count() != expected:
		_fail("elite warning did not lead to the advertised projectile ring")
		return
	if ChestRewards.drop_chance(0.0, true) <= ChestRewards.drop_chance(0.0) or ChestRewards.drop_chance(1000.0, true) > 0.20:
		_fail("elite chest bonus is missing or unbounded")
		return
	elite.health = elite.max_health * 0.5
	game._save_run()
	if session.load_run().is_empty():
		_fail("elite run could not be saved")
		return
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.wave.elite_index != 1 or game.telemetry.wave_elites_spawned != 1 or game.get_node("Enemies").get_child_count() != 1:
		_fail("save/resume lost the elite or its spawn state")
		return
	elite = game.get_node("Enemies").get_child(0)
	if not elite.data.is_elite or not is_equal_approx(elite.health, elite.max_health * 0.5):
		_fail("save/resume lost elite health or identity")
		return
	if elite.elite_damage_budget <= 0.0:
		_fail("save/resume lost the elite guard")
		return
	game.wave._process(0.1)
	if game.get_node("Enemies").get_child_count() != 1:
		_fail("save/resume spawned the elite twice")
		return
	var health_before := elite.health
	elite.take_damage(elite.max_health * 2.0)
	if elite.health <= 0.0 or health_before - elite.health > elite.max_health * elite.data.elite_guard_fraction + 0.01:
		_fail("a single hit bypassed the elite guard")
		return
	elite._physics_process(elite.data.elite_guard_recharge_seconds)
	if elite.elite_damage_budget < elite.max_health * elite.data.elite_guard_fraction - 0.01:
		_fail("elite guard did not recover")
		return
	elite.take_damage(elite.max_health * 2.0)
	if game.telemetry.wave_elites_killed != 1 or game.get_node("Loot").get_child_count() < 2:
		_fail("elite defeat did not record its kill and guaranteed XP/coin drops")
		return
	game.wave.active = false
	game._clear_combat()
	game.wave.current_wave = 17
	game.wave.start_next_wave()
	game.telemetry.begin_wave(18)
	if game.wave.elite_counts != [3, 2, 1] or game.wave.elite_times.size() != 3 or WaveController.elite_groups_for_wave(12) != [1, 1] or WaveController.elite_groups_for_wave(14) != [2, 1] or not WaveController.elite_groups_for_wave(20).is_empty() or game.wave.elite_reserved_slots() != 18:
		_fail("elite group sizes do not grow across late waves")
		return
	game.wave.spawn_cooldown = 100.0
	game.wave.burst_index = game.wave.burst_times.size()
	game.wave.horde_spawned = true
	game.wave.remaining = game.wave.duration - game.wave.elite_times[0] + 0.01
	game.wave._process(0.02)
	if game.wave.elite_index != 1 or game.telemetry.wave_elites_spawned != 3:
		_fail("late wave did not spawn three elites in parallel")
		return
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game.wave._process(0.1)
	if game.wave.elite_index != 1 or game.telemetry.wave_elites_spawned != 3:
		_fail("resume repeated the first elite group")
		return
	game.wave.remaining = game.wave.duration - game.wave.elite_times[1] + 0.01
	game.wave._process(0.02)
	if game.wave.elite_index != 2 or game.telemetry.wave_elites_spawned != 5:
		_fail("second elite group was missing")
		return
	game.wave.remaining = game.wave.duration - game.wave.elite_times[2] + 0.01
	game.wave._process(0.02)
	if game.wave.elite_index != 3 or game.telemetry.wave_elites_spawned != 6:
		_fail("third elite group was missing")
		return
	var legacy_save: Dictionary = session.load_run()
	legacy_save["elite_time"] = legacy_save["elite_times"][0]
	legacy_save["elite_spawned"] = true
	legacy_save.erase("elite_times")
	legacy_save.erase("elite_counts")
	legacy_save.erase("elite_index")
	session.save_run(legacy_save)
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.wave.elite_counts != [1] or game.wave.elite_index != 1 or game.wave.elite_reserved_slots() != 4:
		_fail("older save lost its single resolved elite event")
		return
	game.wave.active = false
	game._clear_combat()
	game.wave.current_wave = 17
	game.wave.start_next_wave()
	game.telemetry.begin_wave(18)
	var normal_limit: int = game.MAX_ACTIVE_ENEMIES - game.wave.elite_reserved_slots()
	for index in normal_limit:
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(200.0, 0.0))
	game._spawn_enemy(WaveController.PLAQUE)
	if game.get_node("Enemies").get_child_count() != normal_limit:
		_fail("ordinary spawns used slots reserved for late elites")
		return
	game.wave.spawn_cooldown = 100.0
	game.wave.burst_index = game.wave.burst_times.size()
	game.wave.horde_spawned = true
	for time in game.wave.elite_times:
		game.wave.remaining = game.wave.duration - time + 0.01
		game.wave._process(0.02)
	if game.telemetry.wave_elites_spawned != 6 or game.get_node("Enemies").get_child_count() != game.MAX_ACTIVE_ENEMIES:
		_fail("crowded wave dropped a scheduled elite or escort")
		return
	session.clear_run()
	print("Denti elite pressure test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
