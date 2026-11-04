extends "res://tests/support/test_runtime.gd"
## Paired full Hell fights: real weapons/physics, a pilot that hugs the Don.

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const PROBE_GAME = preload("res://tools/balance/comparison_game.gd")
const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var rows: Array = []
	for enabled in [false, true]:
		for build in ["ranged_single", "melee_single"]:
			var session := root.get_node("GameSession")
			session.save_path = "user://caramel_enforcer_combat.json"
			session.resume_requested = false
			session.selected_story_mode = false
			session.selected_difficulty_id = &"hell"
			var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
			game.set_script(PROBE_GAME)
			game.get_node("Player").set_script(PROBE_PLAYER)
			root.add_child(game)
			current_scene = game
			paused = true
			var setup: Dictionary = PROFILES.setup(build, 10, "base")
			game.player.loadout.restore(setup.equipment)
			for stat: String in setup.stats: game.player.stats.set(stat, setup.stats[stat])
			game.player.stats.max_health = 10000 # Diagnostic; not human survivability.
			game.player.stats.health = 10000
			game.debug_start_wave(10)
			paused = true
			await process_frame
			var boss: Enemy = game.boss
			var court := boss.caramel_encounter
			court.bodyguard.legacy = not enabled
			if not enabled: court.profile.guard_recharge_multiplier = 1.0
			var events: Array[int] = []
			var guard_frames := 0
			var guard_trial_frames := 0
			var frames := 0
			while frames < 5400 and game.probe_outcome == "":
				var goal := boss.global_position
				var reach := 75.0 # Deliberately hug, including the ranged build.
				if court.overload.busy():
					var nearest: Enemy
					for heart in court.overload.live_pylons():
						if nearest == null or heart.global_position.distance_to(game.player.global_position) < nearest.global_position.distance_to(game.player.global_position): nearest = heart
					if nearest != null: goal = nearest.global_position; reach = 60
					if not events.has(court.overload.trial_index): events.append(court.overload.trial_index)
				if not court.bodyguard.live_minions().is_empty() and not court.bodyguard.minion.caramel_enforcer.suspended():
					guard_frames += 1
					if court.overload.busy(): guard_trial_frames += 1
				game.player.probe_direction = game.player.global_position.direction_to(goal) if game.player.global_position.distance_to(goal) > reach else Vector2.ZERO
				paused = false
				await physics_frame
				await process_frame
				frames += 1
			paused = true
			var row := {"build": build, "bodyguard": enabled, "difficulty": "hell", "seconds": snappedf(frames / 60.0, 0.01), "outcome": game.probe_outcome, "trials": events.size(), "summons": court.bodyguard.spawned, "guard_combat_seconds": snappedf(guard_frames / 60.0, 0.01), "damage_taken": 10000 - game.player.stats.health}
			rows.append(row)
			row["guard_trial_seconds"] = snappedf(guard_trial_frames / 60.0, 0.01)
			if game.probe_outcome != "boss_killed" or events.size() != 2 or enabled and (court.bodyguard.spawned < 1 or guard_frames < 180 or guard_trial_frames < 30):
				failures.append(JSON.stringify(row))
				push_error("full Hell fight lost its trials or sustained bodyguard pressure: " + JSON.stringify(row))
			game._clear_arena(false)
			await process_frame
			_stop_audio(game)
			game.queue_free()
			await process_frame
			await process_frame
	var file := FileAccess.open("res://.godot/caramel_enforcer_combat.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	file.close()
	root.get_node("GameSession").clear_run()
	print("CARAMEL ENFORCER COMBAT ", JSON.stringify(rows))
	finish(0 if failures.is_empty() else 1)
