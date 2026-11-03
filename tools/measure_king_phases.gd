extends "res://tests/support/test_runtime.gd"
## Diagnostic full fights; compare defenses with the same shield rules/builds.

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const PROBE_GAME = preload("res://tools/balance/comparison_game.gd")
const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var results: Array = []
	for defense in ["previous", "armored"]:
		for difficulty in [&"normal", &"hell"]:
			for build in ["ranged_single", "melee_single"]:
				paused = true
				var session := root.get_node("GameSession")
				session.save_path = "user://measure_king_unused.json"
				session.resume_requested = false
				session.selected_story_mode = false
				session.selected_difficulty_id = difficulty
				var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
				game.set_script(PROBE_GAME)
				game.get_node("Player").set_script(PROBE_PLAYER)
				root.add_child(game)
				current_scene = game
				var setup: Dictionary = PROFILES.setup(build, 15, "base")
				game.player.loadout.restore(setup.equipment)
				for stat: String in setup.stats: game.player.stats.set(stat, setup.stats[stat])
				game.player.stats.max_health = 10000
				game.player.stats.health = 10000
				game.debug_start_wave(15)
				game._clear_arena(false)
				await process_frame
				await process_frame
				var data := EnemyCatalog.CAVITY_KING.duplicate() as EnemyData
				data.acid_king_profile = data.acid_king_profile.duplicate() as AcidKingData
				if defense == "previous":
					data.damage_reduction = 0.18
					data.boss_guard_recharge_seconds = 28
					data.boss_guard_burst_fraction = 0.10
					data.acid_king_profile.closed_damage_factor = 0.85
				game._create_enemy(data, game.player.global_position + Vector2(-250, -100))
				var boss: Enemy = game.boss
				var trial := boss.acid_king_encounter.pressure
				var goal := -1
				var previous_state := -1
				var previous_trial := -1
				var escape := Vector2.ZERO
				var frames := 0
				var shield_seconds := 0.0
				var opening_seconds := 0.0
				var last_opening_end := 0.0
				var events: Array = []
				while frames < 9000 and game.probe_outcome == "":
					if previous_state == KingPressureTrial.State.EXPOSED and not trial.busy(): last_opening_end = frames / 60.0
					if trial.state == KingPressureTrial.State.EXPOSED: opening_seconds += 1.0 / 60
					var destination: Vector2 = boss.global_position
					var reach := 75.0 if build == "melee_single" else 220.0
					if trial.busy() and trial.state != KingPressureTrial.State.EXPOSED:
						shield_seconds += 1.0 / 60
						if trial.trial_index != previous_trial:
							previous_trial = trial.trial_index
							goal = -1
							events.append({"seconds": snappedf(frames / 60.0, 0.01), "normal_since_opening": snappedf(frames / 60.0 - last_opening_end, 0.01), "hp": snappedf(boss.health / boss.max_health, 0.001), "valves": trial.valves.size()})
						if goal < 0 or goal >= trial.valves.size() or trial.valves[goal].broken:
							goal = -1
							for index in trial.valves.size():
								if trial.valves[index].broken: continue
								if goal < 0 or game.player.position.distance_to(trial.stance(index)) < game.player.position.distance_to(trial.stance(goal)): goal = index
						if goal >= 0:
							destination = trial.stance(goal)
							reach = 4
						if trial.state in [KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING]:
							if previous_state not in [KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING]:
								var sideways := trial.aim.orthogonal()
								var side := signf((destination - trial.origin).dot(sideways))
								if is_zero_approx(side): side = 1
								escape = Geometry2D.get_closest_point_to_segment(game.player.position, trial.origin, trial.destination) + sideways * side * 70
							destination = escape
							reach = 4
					previous_state = trial.state
					game.player.probe_direction = game.player.position.direction_to(destination) if game.player.position.distance_to(destination) > reach else Vector2.ZERO
					paused = false
					await physics_frame
					await process_frame
					frames += 1
				paused = true
				var row := {"defense": defense, "difficulty": str(difficulty), "build": build, "seconds": snappedf(frames / 60.0, 0.01), "shield_seconds": snappedf(shield_seconds, 0.01), "opening_seconds": snappedf(opening_seconds, 0.01), "normal_seconds": snappedf(frames / 60.0 - shield_seconds - opening_seconds, 0.01), "outcome": game.probe_outcome, "max_hp": boss.max_health, "shields": events, "damage_taken": 10000 - game.player.stats.health}
				results.append(row)
				print("KING PHASES ", JSON.stringify(row))
				game._clear_arena(false)
				_stop_audio(game)
				game.queue_free()
				await process_frame
				await process_frame
	var file := FileAccess.open("res://.godot/king_phases.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	finish()
