extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_wave_pressure_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	if not is_equal_approx(game.wave.duration, 35.0) or not is_equal_approx(WaveController.duration_for_wave(4), 44.0) or not is_equal_approx(WaveController.duration_for_wave(8), 42.0) or not is_equal_approx(WaveController.duration_for_wave(12), 46.0) or not is_equal_approx(WaveController.duration_for_wave(19), 50.0) or not is_equal_approx(WaveController.duration_for_wave(20), 45.0):
		_fail("wave-length progression or boss-wave duration is wrong")
		return
	var times: Array[float] = game.wave.burst_times.duplicate()
	if times.size() != 2 or times[0] < game.wave.duration * 0.22 or times[0] > game.wave.duration * 0.31 or times[1] < game.wave.duration * 0.58 or times[1] > game.wave.duration * 0.67:
		_fail("wave did not plan two separated burst windows")
		return
	game.wave.spawn_cooldown = 100.0
	game.wave.remaining = game.wave.duration - times[0] + 0.01
	game.wave._process(0.02)
	var first_spawns: int = game.telemetry.wave_spawns
	if game.wave.burst_index != 1 or first_spawns != game.wave._burst_count(0):
		_fail("first scheduled burst did not spawn exactly once")
		return
	game._save_run()
	var saved: Dictionary = session.load_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.wave.burst_index != 1 or not is_equal_approx(game.wave.duration, 35.0) or not is_equal_approx(game.wave.burst_times[0], times[0]) or not is_equal_approx(game.wave.burst_times[1], times[1]) or game.telemetry.wave_spawns != first_spawns:
		_fail("save/resume lost burst timing or replayed a burst: index %d, times %s / %s, spawns %d / %d" % [game.wave.burst_index, str(game.wave.burst_times), str(times), game.telemetry.wave_spawns, first_spawns])
		return
	game.wave._process(0.1)
	if game.wave.burst_index != 1 or game.telemetry.wave_spawns != first_spawns:
		_fail("burst replayed before the next scheduled slot")
		return
	game.wave.remaining = game.wave.duration - times[1] + 0.01
	game.wave._process(0.02)
	if game.wave.burst_index != 2 or game.telemetry.wave_spawns != first_spawns + game.wave._burst_count(1):
		_fail("second burst was skipped or duplicated")
		return
	saved.erase("burst_times")
	saved.erase("burst_index")
	saved.erase("duration")
	saved["remaining"] = 25.0
	session.save_run(saved)
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.wave.burst_index != 1 or not is_equal_approx(game.wave.duration, WaveController.DURATION) or game.telemetry.wave_spawns != first_spawns:
		_fail("older save replayed a burst whose time had already passed")
		return
	game.wave.current_wave = 11
	game.wave.start_next_wave()
	var late_times: Array[float] = game.wave.burst_times
	if late_times.size() != 4 or late_times[1] < game.wave.duration * 0.40 or late_times[1] > game.wave.duration * 0.47 or late_times[2] < game.wave.duration * 0.58 or late_times[2] > game.wave.duration * 0.67 or game.wave._burst_count(2) < 7:
		_fail("late wave is missing its additional ranged-pressure burst")
		return
	game.wave.current_wave = 18
	game.wave.start_next_wave()
	game.wave.remaining = 49.0
	game.wave.spawn_cooldown = 100.0
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if not is_equal_approx(game.wave.duration, 50.0) or absf(game.wave.remaining - 49.0) > 0.2 or game.wave.burst_times.size() != 4:
		_fail("save/resume shortened a 50-second wave")
		return
	session.clear_run()
	print("Denti wave pressure test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
