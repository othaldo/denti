extends "res://tests/support/test_runtime.gd"

const STEP := 1.0 / 60.0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://pillow_measurement.json"
	session.resume_requested = false
	session.clear_run()
	var results: Array[Dictionary] = []
	for legacy in [true, false]:
		for melee in [true, false]:
			for avoid in [false, true]:
				seed(52026)
				var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
				root.add_child(game)
				current_scene = game
				game.choice_panel._on_choice_pressed(0)
				if game.choice_panel.mode == &"starter": game.choice_panel.starter_selection.confirm_selection()
				game.set_process(false)
				game.wave.set_process(false)
				game.wave.current_wave = 5
				var player: Player = game.player
				player.set_physics_process(false)
				player.loadout.restore([])
				player.global_position = Vector2(900, 650)
				player.stats.max_health = 10000
				player.stats.health = 10000
				var data := EnemyCatalog.CAVITY_COUNT.duplicate() as EnemyData
				data.boss_phase_adds = 0
				data.cloak_profile = null
				data.pillow_profile = null if legacy else load("res://data/encounters/count_pillow.tres")
				game._create_enemy(data, player.global_position + Vector2(250, 0))
				var boss: Enemy = game.boss
				game.get_node("Enemies").set_physics_process(false)
				boss.set_simulation_enabled(false)
				var seconds := 0.0
				var attack_seconds := 0.0
				var peak_projectiles := 0
				for frame in 5400:
					player.hurt_time = maxf(player.hurt_time - STEP, 0)
					var destination := player.global_position
					if avoid:
						if boss.pillow_encounter != null and boss.pillow_encounter.active:
							var attack := boss.pillow_encounter
							var side := Vector2(attack.forward.y, attack.forward.x)
							var sign_side := -1.0 if attack.second_offset > 0 else 1.0
							var coordinate := (attack.origin + side * sign_side * 115).dot(side)
							if coordinate < DentiArena.PLAYER_MARGIN + 20 or coordinate > player.arena.arena_size.dot(side) - DentiArena.PLAYER_MARGIN - 20:
								sign_side = -sign_side
							destination = player.global_position + side * ((attack.origin - player.global_position).dot(side) + sign_side * 115)
						elif legacy and boss.special_phase == Enemy.SpecialPhase.WARNING:
							destination += boss.special_direction.orthogonal() * 200
						elif melee:
							destination = boss.global_position + boss.global_position.direction_to(player.global_position) * 120
						player.global_position = player.global_position.move_toward(destination, PlayerStats.BASE_MOVE_SPEED * STEP)
					boss._physics_process(STEP)
					for shot in game.get_node("EnemyProjectiles").get_children(): shot._physics_process(STEP)
					peak_projectiles = maxi(peak_projectiles, game.get_node("EnemyProjectiles").get_child_count())
					var in_range := player.global_position.distance_to(boss.global_position) <= (148 if melee else 600)
					if in_range:
						boss.take_damage(120 * STEP)
						attack_seconds += STEP
					seconds += STEP
					if boss.dying: break
				results.append({"profile": "legacy shared charge" if legacy else "pillow count", "attack": "melee 148" if melee else "ranged 600", "movement": "read warnings, base speed" if avoid else "stationary", "raw_dps_in_range": 120, "ttk_seconds": snappedf(seconds, 0.01), "attack_uptime": snappedf(attack_seconds / seconds, 0.001), "damage_taken": snappedf(10000 - player.stats.health, 0.1), "peak_projectiles": peak_projectiles, "defeated": boss.dying})
				game.free()
	var report := {"date": "2026-10-20", "method": "Isolated wave-5 Normal fixture with seeded setup; 120 raw DPS only within attack range, no items/adds/dash, fixed 60 Hz. Stationary dummy versus scripted base-speed warning avoidance. This is a pressure/uptime comparison, not a human playtest, full-wave balance result or win rate.", "results": results}
	var file := FileAccess.open("res://docs/count_pillow_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	for row in results: print(JSON.stringify(row))
	session.clear_run()
	finish()
