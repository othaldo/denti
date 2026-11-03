extends "res://tests/support/test_runtime.gd"
const STEP := 1.0 / 60
const SPEED := PlayerStats.BASE_MOVE_SPEED * 0.72
var game: Node2D
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _goal(boss: Enemy) -> Vector2:
	var a := boss.caramel_encounter
	var player: Player = game.player
	var hazards: Array[Vector3] = []
	if a.state == CaramelEncounter.State.BOMB_SEQUENCE:
		for entry in a.bombs.entries: hazards.append(Vector3(entry.at.x, entry.at.y, a.profile.windup_seconds + a.profile.flight_seconds - entry.age))
	elif a.state in [CaramelEncounter.State.WINDUP, CaramelEncounter.State.FLIGHT]:
		hazards.append(Vector3(a.destination.x, a.destination.y, a.remaining + (a.profile.flight_seconds if a.state == CaramelEncounter.State.WINDUP else 0)))
	if hazards.is_empty(): return player.global_position
	var best := player.global_position
	var cost := INF
	for index in 32:
		var direction := Vector2.from_angle(index * TAU / 32)
		var at := player.global_position
		var goal := (at + direction * SPEED * 1.15).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
		var next := at.move_toward(goal, SPEED * 0.12)
		if Geometry2D.get_closest_point_to_segment(boss.global_position, at, next).distance_to(boss.global_position) <= boss.data.radius + 21: continue
		var score := 0.0
		for hazard in hazards:
			var target := Vector2(hazard.x, hazard.y)
			var predicted := at.move_toward(goal, SPEED * maxf(hazard.z, 0))
			var shortfall := maxf(a.profile.impact_radius + HazardGeometry.PLAYER_RADIUS + 5 - predicted.distance_to(target), 0)
			score += shortfall * shortfall / maxf(hazard.z, 0.05)
		if not player.velocity.is_zero_approx(): score += pow(direction.angle_to(player.velocity), 2) * 0.05
		if score < cost: cost = score; best = goal
	return best
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://prince_bomb_routes_test.json"
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
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var cases := 0
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		boss.configure(EnemyCatalog.CAVITY_PRINCE, game.player, 10, difficulty.id)
		game.get_node("Enemies").add_child(boss)
		boss.set_simulation_enabled(false)
		boss.boss_phase = 2
		var a := boss.caramel_encounter
		a.overload.used = true # Measure bomb routes independently of the objective phase.
		for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
			root.size = extent
			root.content_scale_size = extent
			await process_frame
			await process_frame
			for corner: Vector2 in [Vector2(48, 48), Vector2(game.arena.arena_size.x - 48, 48), Vector2(48, game.arena.arena_size.y - 48), game.arena.arena_size - Vector2.ONE * 48]:
				a.cancel()
				game.player.global_position = corner
				game.player.velocity = Vector2.ZERO
				game.player.stats.health = 100000
				game.player.hurt_time = 0
				game.player.dash_moved = false
				boss.global_position = corner + corner.direction_to(game.arena.arena_size * 0.5) * 260
				game.player.get_node("Camera2D").force_update_scroll()
				a.begin(-1, CaramelEncounterData.Attack.BOMBS)
				var safe := true
				var complete := false
				for tick in 480:
					var player: Player = game.player
					var before := player.global_position
					player.global_position = before.move_toward(_goal(boss), SPEED * STEP)
					player.velocity = (player.global_position - before) / STEP
					player.get_node("Camera2D").force_update_scroll()
					if Geometry2D.get_closest_point_to_segment(boss.global_position, before, player.global_position).distance_to(boss.global_position) <= boss.data.radius + 20: safe = false; break
					a.advance(STEP)
					if player.stats.health < 100000: safe = false; break
					if a.attack_kind != CaramelEncounterData.Attack.BOMBS or a.state == CaramelEncounter.State.RECOVERY: complete = true; break
				if not safe or not complete: failures.append("%s bomb sequence has no observed slowed corner route at %s / %s" % [difficulty.id, corner, extent])
				cases += 1
		boss.free()
	game.free()
	paused = false
	session.clear_run()
	for message in failures: push_error(message)
	if failures.is_empty(): print("PASS prince_bomb_routes: %d complete warning-aware bomb sequences at 72%% speed, four tiers/corners, three viewports, real predictive aims and no body crossing" % cases)
	finish(0 if failures.is_empty() else 1)
