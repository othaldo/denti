extends "res://tests/support/test_runtime.gd"
const STEP := 1.0 / 60.0
var failures: Array[String] = []
var game: Node2D
func _initialize() -> void: call_deferred("_run")
func _check(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _wait_for_warning(boss: Enemy, moving := false) -> float:
	var a := boss.crown_court_encounter
	for tick in 1800:
		if a.state in [CrownCourtEncounter.State.EDICT_WARN, CrownCourtEncounter.State.NERVE_WARN]: return tick * STEP
		if moving: game.player.global_position += Vector2(0, 40 * STEP)
		game.player.get_node("Camera2D").force_update_scroll()
		a.advance(STEP)
	return -1.0
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://court_positioning_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.max_health = 100000
	game.player.stats.health = 100000
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var cases := 0
	var slowest := 0.0
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		boss.configure(EnemyCatalog.CAVITY_EMPEROR, game.player, 20, difficulty.id)
		game.get_node("Enemies").add_child(boss)
		boss.set_simulation_enabled(false)
		boss.boss_phase = 2
		var a := boss.crown_court_encounter
		for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
			root.size = extent
			root.content_scale_size = extent
			await process_frame
			for kind in [CrownCourtEncounter.Attack.EDICT, CrownCourtEncounter.Attack.NERVE]:
				for moving in [false, true]:
					a.cancel()
					a.cycle = 0
					boss.global_position = Vector2(120, 650)
					game.player.global_position = Vector2(1050, 650)
					game.player.dash_moved = false
					game.player.get_node("Camera2D").force_update_scroll()
					var warned := a.warnings
					if kind == CrownCourtEncounter.Attack.NERVE: a.begin(kind)
					a.advance(a.profile.position_seconds)
					_check(a.state == CrownCourtEncounter.State.REPOSITION and a.warnings == warned, "distant Emperor started an ineffective AoE: %s %s" % [difficulty.id, extent])
					var pending := a.save_data()
					var pending_position := boss.global_position
					await process_frame
					_check(a.save_data() == pending and boss.global_position == pending_position, "pause advanced pending AoE pursuit")
					a.restore(pending)
					_check(a.save_data() == pending, "approach snapshot lost pending attack or sequence index")
					var wait := await _wait_for_warning(boss, moving)
					_check(wait >= 0, "Emperor never closed into AoE range: %s %s" % [difficulty.id, extent])
					_check(a.warnings == warned + 1 and boss.global_position.distance_to(game.player.global_position) <= a.court_start_distance() + 0.01, "warning started before the Emperor reached Denti")
					_check(boss.global_position.distance_to(game.player.global_position) > boss.data.radius + HazardGeometry.PLAYER_RADIUS, "approach ran through Denti")
					_check(a.cycle == 1 and a.step_index == 0, "approach consumed attacks instead of pursuing")
					var locked_origin := a.origin
					var locked_angle := a.edict_angle
					game.player.global_position += Vector2(200, 0)
					a.advance(0.2)
					_check(boss.global_position == locked_origin and a.origin == locked_origin and a.edict_angle == locked_angle, "Emperor continued closing during its fixed warning")
					slowest = maxf(slowest, wait)
					cases += 1
			# Leaving range between two verdicts must extend movement, not waste the next AoE.
			a.cancel()
			a.cycle = 0
			boss.global_position = Vector2(770, 620)
			game.player.global_position = Vector2(1010, 650)
			game.player.get_node("Camera2D").force_update_scroll()
			a.begin(CrownCourtEncounter.Attack.EDICT)
			a.advance(a.remaining + a.profile.impact_seconds)
			if a.portal_followup:
				# Finish the newly warned intercept before judging the next AoE approach.
				a.advance(a.remaining + a.portal_a.distance_to(a.portal_b) / a.profile.lance.speed)
			var warned := a.warnings
			var step_index := a.step_index
			game.player.global_position = Vector2(1650, 650)
			game.player.get_node("Camera2D").force_update_scroll()
			a.advance(a.profile.reposition_seconds)
			_check(a.state == CrownCourtEncounter.State.REPOSITION and a.warnings == warned and a.step_index == step_index, "follow-up verdict fired outside range")
			var wait := await _wait_for_warning(boss)
			_check(wait >= 0 and a.warnings == warned + 1 and boss.global_position.distance_to(game.player.global_position) <= a.court_start_distance() + 0.01, "follow-up verdict failed to close back into range")
		boss.free()
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty(): print("PASS crown_court_positioning: %d distant/strafing approaches, four tiers/three viewports, follow-up pursuit, snapshots, no body crossing and fixed warning; longest approach %.2f s" % [cases, slowest])
	finish(0 if failures.is_empty() else 1)
