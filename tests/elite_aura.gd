extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_elite_aura_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game._clear_combat()
	game.wave.current_wave = 11
	game.wave.start_next_wave()
	game.telemetry.begin_wave(12)
	if WaveController.elite_for_wave(11) != WaveController.ACID_CROWN or WaveController.elite_for_wave(12) != WaveController.HUNT_GERM:
		_fail("late waves do not alternate elite roles")
		return
	game.wave.spawn_cooldown = 100.0
	game.wave.burst_index = game.wave.burst_times.size()
	game.wave.horde_spawned = true
	game.wave.remaining = game.wave.duration - game.wave.elite_time + 0.01
	game.wave._process(0.02)
	if game.get_node("Enemies").get_child_count() != 4:
		_fail("wave 12 did not spawn the elite and its escort")
		return
	var leader: Enemy = game.get_node("Enemies").get_child(0)
	if leader.data != WaveController.HUNT_GERM or leader.data.aura_move_bonus <= 0.0:
		_fail("wave 12 elite lacks the movement aura")
		return
	var leader_at: Vector2 = game.player.global_position + Vector2(300.0, 0.0)
	leader.global_position = leader_at
	if leader.data.escort_count != 3:
		_fail("leader has no defined escort")
		return
	game._create_enemy(WaveController.PLAQUE, leader_at + Vector2(500.0, 0.0))
	var near: Enemy = game.get_node("Enemies").get_child(1)
	near.global_position = leader_at + Vector2(100.0, 0.0)
	var far: Enemy = game.get_node("Enemies").get_child(4)
	paused = true
	leader._physics_process(0.01)
	if near.haste_time <= 0.0 or far.haste_time > 0.0:
		_fail("elite aura did not target only nearby ordinary enemies")
		return
	var start := near.global_position
	near._physics_process(0.1)
	if near.global_position.distance_to(start) < near.move_speed * 0.13:
		_fail("aura did not increase nearby enemy movement")
		return
	game._save_run()
	if session.load_run().is_empty():
		_fail("elite aura run could not be saved")
		return
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.get_node("Enemies").get_child_count() != 5:
		_fail("save/resume lost the elite pack")
		return
	leader = game.get_node("Enemies").get_child(0)
	near = game.get_node("Enemies").get_child(1)
	if leader.data != WaveController.HUNT_GERM or near.haste_time <= 0.0 or near.haste_bonus < 0.45:
		_fail("save/resume lost the aura state")
		return
	leader.elite_damage_budget = leader.health
	leader.take_damage(leader.max_health * 3.0)
	near._physics_process(Enemy.AURA_HASTE_DURATION + 0.1)
	if near.haste_time > 0.0 or near.haste_bonus > 0.0:
		_fail("aura remained active after its source died")
		return
	session.clear_run()
	print("Denti elite aura test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
