extends "res://tests/support/test_runtime.gd"
const STEP := 1.0 / 60
const PILOT = preload("res://tools/support/crown_court_pilot.gd")
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://emperor_measure.json"
	session.resume_requested = false
	session.clear_run()
	var results: Array[Dictionary] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		session.selected_difficulty_id = difficulty.id
		for melee in [true, false]:
			for policy in ["stationary", "circle", "read warning"]:
				seed(102026)
				var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
				root.add_child(game)
				current_scene = game
				game.choice_panel._on_choice_pressed(0)
				game.set_process(false)
				game.wave.set_process(false)
				game.wave.current_wave = 20
				var player: Player = game.player
				player.set_physics_process(false)
				player.loadout.restore([])
				player.stats.max_health = 10000
				player.stats.health = 10000
				player.stats.dodge_chance = 0
				player.stats.shield_charges = 0
				player.global_position = Vector2(1050, 650)
				var data := EnemyCatalog.CAVITY_EMPEROR.duplicate() as EnemyData
				data.boss_phase_adds = 0
				game._create_enemy(data, Vector2(770, 620))
				game.get_node("Enemies").set_physics_process(false)
				var boss: Enemy = game.boss
				boss.set_simulation_enabled(false)
				var attack := boss.crown_court_encounter
				var seconds := 0.0
				var open_damage := 0.0
				var open_seconds := 0.0
				var peak := 0
				var kinds := {}
				for tick in 5400:
					player.hurt_time = maxf(player.hurt_time - STEP, 0)
					var goal := player.global_position
					if policy == "circle": goal += boss.global_position.direction_to(player.global_position).orthogonal() * 300
					elif policy == "read warning": goal = PILOT.goal(player, boss, attack, melee)
					var before := player.global_position
					var candidate := before.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * STEP).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
					if Geometry2D.get_closest_point_to_segment(boss.global_position, before, candidate).distance_to(boss.global_position) >= boss.data.radius + 22: player.global_position = candidate
					player.velocity = (player.global_position - before) / STEP
					player.get_node("Camera2D").force_update_scroll()
					boss._physics_process(STEP)
					peak = maxi(peak, attack.shots.entries.size())
					if attack.active: kinds[attack.attack_kind] = true
					if attack.exposed: open_seconds += STEP
					if player.global_position.distance_to(boss.global_position) <= (180 if melee else 600):
						var dealt := boss.take_damage(350 * STEP)
						if attack.exposed: open_damage += dealt
					seconds += STEP
					if boss.dying: break
				results.append({"difficulty": str(difficulty.id), "range": "melee 180" if melee else "ranged 600", "movement": policy, "seconds": snappedf(seconds, 0.01), "defeated": boss.dying, "damage_taken": snappedf(10000 - player.stats.health, 0.1), "damage_court": snappedf(attack.floor_damage, 0.1), "damage_shards": snappedf(attack.shots.damage_dealt, 0.1), "damage_portals": snappedf(attack.lances.damage_dealt, 0.1), "warnings": attack.warnings, "verdicts": attack.verdicts_fired, "portals": attack.portals_fired, "pulses": attack.pulses_fired, "peak_shots": peak, "kinds": kinds.keys(), "open_seconds": snappedf(open_seconds, 0.01), "open_damage": snappedf(open_damage, 0.1)})
				game.free()
	var report := {"date": "2026-10-21", "method": "Isolated wave 20, all four difficulties, 350 raw DPS only within range, actual guard/health phases. No weapons/items/adds/dash, 10000 player HP only to accumulate damage, seed 102026, fixed 60 Hz, 90-second cutoff. Stationary, circling and simple warning reactions; not an optimal solver or human/full-wave balance approval. defeated=false is not a kill time. No deliberately crossing the boss body.", "results": results}
	var file := FileAccess.open("res://docs/emperor_court_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	for row in results: print(JSON.stringify(row))
	session.clear_run()
	finish()
