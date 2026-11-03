extends "res://tests/support/test_runtime.gd"
## Real automatic weapons and player movement; guard/attack clocks stay live.

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const PROBE_GAME = preload("res://tools/balance/comparison_game.gd")
const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var rows: Array = []
	for setup in [["ranged_single", "normal"], ["melee_single", "normal"], ["melee_area", "normal"], ["ranged_single", "hell"], ["melee_single", "hell"]]:
		paused = true
		var session := root.get_node("GameSession")
		session.save_path = "user://imperial_retinue_combat.json"
		session.resume_requested = false
		session.selected_story_mode = false
		session.selected_difficulty_id = StringName(setup[1])
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		game.set_script(PROBE_GAME)
		game.get_node("Player").set_script(PROBE_PLAYER)
		root.add_child(game)
		current_scene = game
		var build: Dictionary = PROFILES.setup(setup[0], 20, "base")
		game.player.loadout.restore(build.equipment)
		for stat: String in build.stats: game.player.stats.set(stat, build.stats[stat])
		game.player.stats.max_health = 10000 # Diagnostic, not a human survival claim.
		game.player.stats.health = 10000
		game.debug_start_wave(20)
		paused = true
		await process_frame
		var boss: Enemy = game.boss
		boss.global_position = game.player.global_position - Vector2(0, 140)
		var retinue := boss.crown_court_encounter.retinue
		boss.health = boss.max_health * retinue.profile.thresholds[0]
		boss.boss_phase = 0
		boss.boss_phase_timer = 0
		var success := [false]
		retinue.court_broken.connect(func(_at: Vector2) -> void: success[0] = true)
		boss.crown_court_encounter.advance(0.01)
		var frames := 0
		while frames < 2700 and not success[0] and retinue.state not in [ImperialRetinue.State.FAILURE, ImperialRetinue.State.FINISHED]:
			var target: Enemy
			for minion in retinue.live_minions():
				if target == null or minion.imperial_vassal.profile.role == ImperialVassalData.Role.KEEPER: target = minion
			var goal: Vector2 = target.global_position if target != null else game.player.global_position
			var reach := 60.0 if setup[0] != "ranged_single" else 180.0
			game.player.probe_direction = game.player.global_position.direction_to(goal) if game.player.global_position.distance_to(goal) > reach else Vector2.ZERO
			paused = false
			await physics_frame
			await process_frame
			frames += 1
		paused = true
		var row := {"build": setup[0], "difficulty": setup[1], "minions": retinue.profile.count, "success": success[0], "seconds": snappedf(frames / 60.0, 0.01), "remaining": retinue.live_minions().size(), "damage_taken": 10000 - game.player.stats.health, "regeneration_remaining": retinue.regeneration_left / boss.max_health}
		rows.append(row)
		if not success[0]:
			failures.append(str(row))
			push_error("real automatic build could not break the retinue: " + JSON.stringify(row))
		game._clear_arena(false)
		await process_frame
		_stop_audio(game)
		game.queue_free()
		await process_frame
		await process_frame
	var file := FileAccess.open("res://.godot/imperial_retinue_combat.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	file.close()
	print("IMPERIAL RETINUE COMBAT ", JSON.stringify(rows))
	root.get_node("GameSession").clear_run()
	finish(0 if failures.is_empty() else 1)
