extends "res://tests/support/test_runtime.gd"

const STEP := 1.0 / 60.0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://cloak_measure.json"
	session.resume_requested = false
	session.clear_run()
	var results: Array[Dictionary] = []
	for old in [true, false]:
		for melee in [true, false]:
			for movement in ["stationary", "one sidestep", "each warning"]:
				seed(52026)
				var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
				root.add_child(game)
				current_scene = game
				game.choice_panel._on_choice_pressed(0)
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
				if old:
					data.cloak_profile = null
					data.pillow_profile = load("res://data/encounters/count_pillow.tres")
				game._create_enemy(data, player.global_position + Vector2(150, 0))
				var boss: Enemy = game.boss
				game.get_node("Enemies").set_physics_process(false)
				boss.set_simulation_enabled(false)
				var seconds := 0.0
				var uptime := 0.0
				var count := [0]
				boss.attack_performed.connect(func(kind: StringName):
					if kind == &"boss_warning": count[0] += 1
				)
				for frame in 5400:
					player.hurt_time = maxf(player.hurt_time - STEP, 0)
					var destination := player.global_position
					if movement != "stationary":
						if old and boss.pillow_encounter.active:
							var attack := boss.pillow_encounter
							var side := Vector2(attack.forward.y, attack.forward.x)
							var side_sign := -1.0 if attack.second_offset > 0 else 1.0
							destination += side * ((attack.origin - player.global_position).dot(side) + side_sign * 115)
						elif not old and boss.cloak_encounter.state == CloakEncounter.State.WARNING:
							var attack := boss.cloak_encounter
							if movement == "each warning" or attack.strike_index == 0:
								destination = _escape(attack, player.global_position)
						elif melee and (old and not boss.pillow_encounter.active or not old and boss.cloak_encounter.state != CloakEncounter.State.WARNING):
							destination = boss.global_position + boss.global_position.direction_to(player.global_position) * 120
						player.global_position = player.global_position.move_toward(destination, PlayerStats.BASE_MOVE_SPEED * STEP).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
					boss._physics_process(STEP)
					if player.global_position.distance_to(boss.global_position) <= (148 if melee else 600):
						boss.take_damage(120 * STEP)
						uptime += STEP
					seconds += STEP
					if boss.dying: break
				results.append({"profile": "old pillow" if old else "cloak", "range": "melee 148" if melee else "ranged 600", "movement": movement, "ttk_seconds": snappedf(seconds, 0.01), "attack_uptime": snappedf(uptime / seconds, 0.001), "damage_taken": snappedf(10000 - player.stats.health, 0.1), "warnings": count[0], "defeated": boss.dying})
				game.free()
	var report := {"date": "2026-10-20", "method": "Isolated wave 5 Normal; 120 raw DPS while in range, no weapons/items/adds/dash; seeded setup, fixed 60 Hz, capped at 90 seconds (defeated=false is not a kill time). Scripted movement, not human play or full-wave balance. One sidestep reacts only to the first cloak warning per combo; each warning uses the nearest radial/edge-normal exit including body radius. Melee closes to 120 outside warnings. Old pillow movement leaves its original parallel lanes.", "results": results}
	var file := FileAccess.open("res://docs/count_cloak_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	for row in results: print(JSON.stringify(row))
	session.clear_run()
	finish()

func _escape(attack: CloakEncounter, point: Vector2) -> Vector2:
	var shape := attack.profile.strike(attack.variant)
	if attack.variant == CloakStrikeData.Kind.RING:
		if not HazardGeometry.circle_ring(point, attack.origin, shape.inner_radius, shape.reach): return point
		var away_direction := attack.origin.direction_to(point)
		var inside := attack.origin + away_direction * (shape.inner_radius - HazardGeometry.PLAYER_RADIUS - 5)
		var outside := attack.origin + away_direction * (shape.reach + HazardGeometry.PLAYER_RADIUS + 5)
		return inside if point.distance_to(inside) < point.distance_to(outside) else outside
	var alpha := attack.half_angle
	if not HazardGeometry.circle_sector(point, attack.origin, attack.direction, shape.reach, alpha): return point
	var away := attack.origin + attack.origin.direction_to(point) * (shape.reach + 35)
	var candidates := [away]
	for side in [-1, 1]:
		var normal: Vector2 = attack.direction.rotated(alpha * side).orthogonal() * side
		candidates.append(point - normal * ((point - attack.origin).dot(normal) + HazardGeometry.PLAYER_RADIUS + 5))
	var best: Vector2 = candidates[0]
	for candidate: Vector2 in candidates:
		if point.distance_to(candidate) < point.distance_to(best): best = candidate
	return best
