extends "res://tests/support/test_runtime.gd"
## Real movement at baseline/minimum speed; no dash, weapons or teleports.

const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var results: Array = []
	for setup in [["easy", 0, 1280, 720, 0], ["normal", 0, 1280, 720, 0], ["hard", 0, 1280, 720, 1], ["hell", 0, 1280, 720, 0], ["hell", 0, 1280, 720, 1], ["hell", 0, 1280, 720, 2], ["normal", -100, 1280, 720, 0], ["hell", -100, 1280, 720, 2], ["normal", 0, 320, 568, 0], ["normal", 0, 568, 320, 0]]:
		paused = true
		root.size = Vector2i(setup[2], setup[3])
		root.content_scale_size = root.size
		var session := root.get_node("GameSession")
		session.save_path = "user://king_pressure_combat.json"
		session.resume_requested = false
		session.selected_story_mode = false
		session.selected_difficulty_id = StringName(setup[0])
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		game.get_node("Player").set_script(PROBE_PLAYER)
		root.add_child(game)
		current_scene = game
		choose_panel(game.choice_panel, 0)
		paused = true
		game.player.stats.speed_bonus = setup[1]
		game.player.stats.max_health = 10000 # Diagnostic only; assert no ray hits.
		game.player.stats.health = 10000
		game.player.stats.dodge_chance = 0
		game.player.stats.shield_charges = 0
		game.debug_start_wave(15)
		game.player.loadout.restore([])
		paused = true
		await process_frame
		var boss: Enemy = game.boss
		var trial := boss.acid_king_encounter.pressure
		trial.completed_mask = (1 << int(setup[4])) - 1
		var threshold: float = trial.profile.health_thresholds[setup[4]]
		boss.health = boss.max_health * threshold
		boss.boss_phase = 0 if threshold > 0.7 else (2 if threshold < 0.34 else 1)
		boss.boss_phase_timer = 0
		boss.acid_king_encounter.advance(0.01)
		var goal := -1
		var previous_state := -1
		var escape := Vector2.ZERO
		var frames := 0
		var damage_start: float = game.player.stats.health
		while frames < 3600 and trial.state not in [KingPressureTrial.State.SHATTER, KingPressureTrial.State.BLAST_WARNING, KingPressureTrial.State.FINISHED]:
			if goal < 0 or trial.valves[goal].broken:
				goal = -1
				for index in trial.valves.size():
					if trial.valves[index].broken: continue
					if goal < 0 or game.player.position.distance_to(trial.stance(index)) < game.player.position.distance_to(trial.stance(goal)): goal = index
			var destination: Vector2 = trial.stance(goal) if goal >= 0 else game.player.position
			if trial.state in [KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING]:
				if previous_state not in [KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING]:
					var sideways := trial.aim.orthogonal()
					var side := signf((destination - trial.origin).dot(sideways))
					if is_zero_approx(side): side = 1
					var near := Geometry2D.get_closest_point_to_segment(game.player.position, trial.origin, trial.destination)
					escape = near + sideways * side * 70
				destination = escape
			game.player.probe_direction = game.player.position.direction_to(destination) if game.player.position.distance_to(destination) > 4 else Vector2.ZERO
			previous_state = trial.state
			paused = false
			await physics_frame
			await process_frame
			frames += 1
		paused = true
		var row := {"difficulty": setup[0], "trial": trial.trial_index + 1, "speed": game.player.stats.move_speed, "viewport": [setup[2], setup[3]], "success": trial.state == KingPressureTrial.State.SHATTER, "shots": trial.shots, "seconds": snappedf(frames / 60.0, 0.01), "remaining": trial.remaining_valves(), "damage_taken": damage_start - game.player.stats.health}
		results.append(row)
		if not row.success or row.damage_taken > 0:
			failures.append(str(row))
			push_error("Movement pilot failed: " + JSON.stringify(row))
		# Native camera framing must include every valve, also in small windows.
		var visible: Rect2 = boss.get_canvas_transform().affine_inverse() * boss.get_viewport_rect()
		for valve in trial.valves:
			if not visible.grow(-trial.profile.valve_radius).has_point(valve.at):
				failures.append("valve outside visible framing: " + str(row))
		game._clear_arena(false)
		await process_frame
		if game.player.get_node("Camera2D").zoom != Vector2.ONE or not game.player.get_node("Camera2D").position.is_zero_approx(): failures.append("trial camera was not restored")
		_stop_audio(game)
		game.queue_free()
		await process_frame
		await process_frame
	var file := FileAccess.open("res://.godot/king_pressure_combat.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	print("KING PRESSURE COMBAT ", JSON.stringify(results))
	root.get_node("GameSession").clear_run()
	finish(0 if failures.is_empty() else 1)
