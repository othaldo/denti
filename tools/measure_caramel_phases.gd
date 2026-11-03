extends "res://tests/support/test_runtime.gd"

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const PROBE_GAME = preload("res://tools/balance/comparison_game.gd")
const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var rows: Array = []
	for difficulty in [&"normal", &"hard", &"hell"]:
		for build in ["ranged_single", "melee_single"]:
			var session := root.get_node("GameSession")
			session.save_path = "user://caramel_phases_unused.json"
			session.resume_requested = false
			session.pending_start_weapon_id = &"magic_toothbrush"
			session.selected_story_mode = false
			session.selected_difficulty_id = difficulty
			var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
			game.set_script(PROBE_GAME)
			game.get_node("Player").set_script(PROBE_PLAYER)
			root.add_child(game)
			current_scene = game
			paused = true
			var setup: Dictionary = PROFILES.setup(build, 10, "base")
			game.player.loadout.restore(setup.equipment)
			for stat: String in setup.stats: game.player.stats.set(stat, setup.stats[stat])
			game.player.stats.max_health = 10000
			game.player.stats.health = 10000
			game.debug_start_wave(10)
			await process_frame
			var boss: Enemy = game.boss
			var ritual := boss.caramel_encounter.overload
			var events: Array = []
			var previous_trial := -1
			var frames := 0
			while frames < 5400 and game.probe_outcome == "":
				await physics_frame
				var goal := boss.global_position
				var reach := 75.0 if build == "melee_single" else 250.0
				if ritual.busy():
					var nearest: Enemy
					for pylon in ritual.live_pylons():
						if nearest == null or pylon.global_position.distance_to(game.player.global_position) < nearest.global_position.distance_to(game.player.global_position): nearest = pylon
					if nearest != null:
						goal = nearest.global_position
						reach = 60
				if ritual.state in [CaramelOverload.State.WARNING, CaramelOverload.State.ACTIVE] and previous_trial != ritual.trial_index:
					previous_trial = ritual.trial_index
					events.append({"seconds": frames / 60.0, "objectives": ritual.trial().objectives, "kind": "couriers" if ritual.trial().kind == CaramelTrialData.Kind.COURIERS else "hearts"})
				game.player.probe_direction = game.player.global_position.direction_to(goal) if game.player.global_position.distance_to(goal) > reach else Vector2.ZERO
				paused = false
				await process_frame
				frames += 1
			paused = true
			var row := {"difficulty": str(difficulty), "build": build, "seconds": frames / 60.0, "outcome": game.probe_outcome, "trials": events, "damage_taken": 10000 - game.player.stats.health}
			rows.append(row)
			print("CARAMEL PHASES ", JSON.stringify(row))
			game._clear_arena(false)
			_stop_audio(game)
			game.queue_free()
			await process_frame
			await process_frame
	var file := FileAccess.open("res://.godot/caramel_phases.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	file.close()
	finish()
