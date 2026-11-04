extends "res://tests/support/test_runtime.gd"
## Full before/after Hell duels with real weapons and a shield-aware pilot.

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const PROBE_GAME = preload("res://tools/balance/comparison_game.gd")
const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")
const PILOT = preload("res://tools/balance/king_pressure_pilot.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var rows: Array = []
	for enabled in [false, true]:
		for build in ["ranged_single", "melee_single"]:
			var session := root.get_node("GameSession")
			session.save_path = "user://acid_collector_combat.json"
			session.resume_requested = false
			session.selected_story_mode = false
			session.selected_difficulty_id = &"hell"
			var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
			game.set_script(PROBE_GAME)
			game.get_node("Player").set_script(PROBE_PLAYER)
			root.add_child(game)
			current_scene = game
			paused = true
			var setup: Dictionary = PROFILES.setup(build, 15, "base")
			game.player.loadout.restore(setup.equipment)
			for stat: String in setup.stats: game.player.stats.set(stat, setup.stats[stat])
			game.player.stats.max_health = 10000 # Diagnostic, not human survivability.
			game.player.stats.health = 10000
			game.debug_start_wave(15)
			paused = true
			await process_frame
			var boss: Enemy = game.boss
			var court := boss.acid_king_encounter
			court.companion.legacy = not enabled
			court.acid_wake.legacy = not enabled
			var pilot := PILOT.new()
			var trials: Array[int] = []
			var guard_frames := 0
			var guard_trial_frames := 0
			var max_streams := 0
			var frames := 0
			while frames < 7200 and game.probe_outcome == "":
				var goal := boss.global_position
				var reach := 75.0 if build == "melee_single" else 250.0
				if court.pressure.busy():
					goal = pilot.destination(court.pressure)
					reach = 4
					if not trials.has(court.pressure.trial_index): trials.append(court.pressure.trial_index)
				if not court.companion.live_minions().is_empty() and not court.companion.minion.acid_collector.suspended():
					guard_frames += 1
					if court.pressure.busy(): guard_trial_frames += 1
				max_streams = maxi(max_streams, court.acid_wake.streams.size())
				game.player.probe_direction = game.player.global_position.direction_to(goal) if game.player.global_position.distance_to(goal) > reach else Vector2.ZERO
				paused = false
				await physics_frame
				await process_frame
				frames += 1
			paused = true
			var row := {"build": build, "new_mechanics": enabled, "difficulty": "hell", "seconds": snappedf(frames / 60.0, 0.01), "outcome": game.probe_outcome, "shields": trials.size(), "summons": court.companion.spawned, "max_streams": max_streams, "collector_combat_seconds": snappedf(guard_frames / 60.0, 0.01), "damage_taken": 10000 - game.player.stats.health}
			rows.append(row)
			row["collector_trial_seconds"] = snappedf(guard_trial_frames / 60.0, 0.01)
			if game.probe_outcome != "boss_killed" or trials.size() != 3 or enabled and (court.companion.spawned < 1 or guard_frames < 180 or guard_trial_frames < 30 or max_streams < 1):
				failures.append(JSON.stringify(row))
				push_error("full Hell Korrodon fight lost shields, stream or minion pressure: " + JSON.stringify(row))
			game._clear_arena(false)
			await process_frame
			_stop_audio(game)
			game.queue_free()
			await process_frame
			await process_frame
	var file := FileAccess.open("res://.godot/acid_collector_combat.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	file.close()
	root.get_node("GameSession").clear_run()
	print("ACID COLLECTOR COMBAT ", JSON.stringify(rows))
	finish(0 if failures.is_empty() else 1)
