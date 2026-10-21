extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://court_routes_test.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.current_wave = 20
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.loadout.restore([])
	game.player.stats.max_health = 100000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var failures: Array[String] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		game.wave.difficulty_id = difficulty.id
		game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, Vector2(770, 620))
		var boss: Enemy = game.boss
		boss.set_simulation_enabled(false)
		boss.boss_phase = 2
		var attack := boss.crown_court_encounter
		for corner: Vector2 in [Vector2(48, 48), Vector2(game.arena.arena_size.x - 48, 48), Vector2(48, game.arena.arena_size.y - 48), game.arena.arena_size - Vector2.ONE * 48]:
			for kind in [0, 1, 2]:
				var safe := false
				for route in 64:
					attack.cancel()
					attack.cycle = 0
					boss.global_position = corner + corner.direction_to(game.arena.arena_size * 0.5) * 280
					game.player.global_position = corner
					game.player.hurt_time = 0
					game.player.stats.health = 100000
					game.player.get_node("Camera2D").force_update_scroll()
					attack.begin(kind)
					var goal := (corner + Vector2.from_angle(route * TAU / 64) * 220).clamp(Vector2.ONE * 48, game.arena.arena_size - Vector2.ONE * 48)
					var body := false
					# First complete warned event, including outgoing projectiles.
					for tick in 110:
						game.player.global_position = game.player.global_position.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * 0.72 / 60)
						if game.player.global_position.distance_to(boss.global_position) < boss.data.radius + 20:
							body = true
							break
						attack.advance(1.0 / 60)
						if game.player.stats.health < 100000: break
					if not body and game.player.stats.health == 100000:
						safe = true
						break
				if not safe: failures.append("%s court attack %d has no slowed first-event route from %s" % [difficulty.id, kind, corner])
		boss.free()
	session.clear_run()
	for message in failures: push_error(message)
	if failures.is_empty(): print("PASS crown_court_routes: four tiers/corners, 72% movement, actual court/portal/combined-nerve first events; no body crossing")
	finish(0 if failures.is_empty() else 1)
