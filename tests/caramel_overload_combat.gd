extends "res://tests/support/test_runtime.gd"
## Actual automatic weapons + normal full-speed player physics, no teleports.

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var results: Array = []
	for case in [["ranged_single", 0, "normal"], ["melee_single", 0, "normal"], ["melee_area", 0, "normal"], ["melee_single", -60, "normal"], ["ranged_single", 0, "hard"], ["ranged_single", 0, "hell"]]:
		var session := root.get_node("GameSession")
		session.save_path = "user://overload_combat.json"
		session.resume_requested = false
		session.pending_start_weapon_id = &"magic_toothbrush"
		session.selected_story_mode = false
		session.selected_difficulty_id = StringName(case[2])
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		game.get_node("Player").set_script(PROBE_PLAYER)
		root.add_child(game)
		current_scene = game
		paused = true
		var config: Dictionary = PROFILES.setup(case[0], 10, "base")
		game.player.loadout.restore(config.equipment)
		for stat: String in config.stats: game.player.stats.set(stat, config.stats[stat])
		game.player.stats.speed_bonus = case[1]
		game.player.stats.max_health = 10000 # Diagnostic: completion, not survivability.
		game.player.stats.health = 10000
		game.debug_start_wave(10)
		await process_frame
		var boss: Enemy = game.boss
		boss.position = game.player.position + Vector2(0, -120)
		boss.boss_phase = 2 if case[2] == "normal" else 1
		boss.health = boss.max_health / 3 if case[2] == "normal" else boss.max_health * 2 / 3
		boss.boss_phase_timer = 0
		var ritual := boss.caramel_encounter.overload
		boss.caramel_encounter.advance(0.01)
		var target: Enemy
		var frames := 0
		var distance := 0.0
		while frames < 3000 and ritual.state not in [CaramelOverload.State.RECOVERY, CaramelOverload.State.BLAST, CaramelOverload.State.FINISHED]:
			await physics_frame
			var live := ritual.live_pylons()
			if not is_instance_valid(target) or target.health <= 0 or target.is_queued_for_deletion():
				target = null
				for pylon in live:
					if target == null or game.player.position.distance_to(pylon.position) < game.player.position.distance_to(target.position): target = pylon
			var before: Vector2 = game.player.position
			game.player.probe_direction = game.player.position.direction_to(target.position) if target != null and game.player.position.distance_to(target.position) > 60 else Vector2.ZERO
			paused = false
			await process_frame
			frames += 1
			distance += before.distance_to(game.player.position)
		paused = true
		var passed := ritual.state == CaramelOverload.State.RECOVERY
		var row := {"build": case[0], "difficulty": case[2], "kind": "hearts" if ritual.trial().kind == CaramelTrialData.Kind.HEARTS else "couriers", "speed_bonus": case[1], "success": passed, "seconds": snappedf(frames / 60.0, 0.01), "deadline": ritual.duration, "distance": snappedf(distance, 1), "remaining_hearts": ritual.live_pylons().size(), "damage_taken": 10000 - game.player.stats.health}
		results.append(row)
		if not passed:
			failures.append(str(row))
			push_error("Real automatic weapon build could not complete the ritual: " + JSON.stringify(row))
		game._clear_arena(false)
		await process_frame
		_stop_audio(game)
		game.queue_free()
		await process_frame
		await process_frame
	var file := FileAccess.open("res://.godot/caramel_overload_combat.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	print("OVERLOAD COMBAT ", JSON.stringify(results))
	root.get_node("GameSession").clear_run()
	finish(0 if failures.is_empty() else 1)
