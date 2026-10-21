extends "res://tests/support/test_runtime.gd"

const STEP := 1.0 / 60.0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	var hell := "--hell" in OS.get_cmdline_user_args()
	session.selected_difficulty_id = &"hell" if hell else &"normal"
	session.save_path = "user://caramel_measure.json"
	session.resume_requested = false
	session.clear_run()
	var rows: Array[Dictionary] = []
	for old in [true, false]:
		for melee in [true, false]:
			for movement in ["stationary", "circle", "read warning"]:
				seed(102026)
				var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
				root.add_child(game)
				current_scene = game
				game.choice_panel._on_choice_pressed(0)
				game.set_process(false)
				game.wave.set_process(false)
				game.wave.current_wave = 10
				var player: Player = game.player
				player.set_physics_process(false)
				player.loadout.restore([])
				player.global_position = Vector2(1050, 650)
				player.stats.max_health = 10000
				player.stats.health = 10000
				player.stats.dodge_chance = 0
				player.stats.shield_charges = 0
				var data := EnemyCatalog.CAVITY_PRINCE.duplicate() as EnemyData
				data.boss_phase_adds = 0
				if old: data.caramel_profile = null
				game._create_enemy(data, Vector2(780, 620))
				var boss: Enemy = game.boss
				game.get_node("Enemies").set_physics_process(false)
				boss.set_simulation_enabled(false)
				var warnings := [0]
				boss.attack_performed.connect(func(kind: StringName):
					if kind == &"boss_warning": warnings[0] += 1
				)
				var seconds := 0.0
				var slow_seconds := 0.0
				var peak_pools := 0
				var peak_hearts := 0
				var attacks_seen := {}
				for frame in 5400:
					player.hurt_time = maxf(player.hurt_time - STEP, 0)
					var goal := player.global_position
					var slow := player.floor_movement_factor()
					if slow < 1: slow_seconds += STEP
					if movement == "circle":
						goal += boss.global_position.direction_to(player.global_position).orthogonal() * 300
					elif movement == "read warning":
						if not old:
							goal = _variant_goal(player, boss, boss.caramel_encounter, melee)
						elif old and boss.special_phase == Enemy.SpecialPhase.WARNING:
							goal += boss.special_direction.orthogonal() * 160
						elif melee:
							goal = boss.global_position + boss.global_position.direction_to(player.global_position) * 120
					var before := player.global_position
					player.global_position = player.global_position.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * slow * STEP).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
					player.velocity = (player.global_position - before) / STEP
					player.get_node("Camera2D").force_update_scroll()
					boss._physics_process(STEP)
					for projectile: AcidProjectile in game.get_node("EnemyProjectiles").get_children():
						projectile._physics_process(STEP)
					if boss.caramel_encounter != null:
						peak_pools = maxi(peak_pools, boss.caramel_encounter.pools.size())
						peak_hearts = maxi(peak_hearts, boss.caramel_encounter.hearts.entries.size())
						if boss.caramel_encounter.active: attacks_seen[str(boss.caramel_encounter.attack_kind)] = true
					if player.global_position.distance_to(boss.global_position) <= (148 if melee else 600): boss.take_damage(120 * STEP)
					seconds += STEP
					if boss.dying: break
				rows.append({"profile": "old generic" if old else "caramel repertoire", "range": "melee 148" if melee else "ranged 600", "movement": movement, "seconds": snappedf(seconds, 0.01), "defeated": boss.dying, "damage_taken": snappedf(10000 - player.stats.health, 0.1), "warnings": warnings[0], "peak_pools": peak_pools, "peak_hearts": peak_hearts, "attacks_seen": attacks_seen.keys(), "slow_seconds": snappedf(slow_seconds, 0.01)})
				game.free()
	var report := {"date": "2026-10-20", "method": "Isolated wave 10 %s, 120 raw DPS when in range, no weapons/items/adds/dash, seed 102026, fixed 60 Hz, maximum 90 seconds. Camera scroll explicitly updated. Scripted movement; not a human playtest or full-wave balance approval. defeated=false is not a kill time. Stationary melee is intentionally a range failure case." % ("Hell" if hell else "Normal"), "results": rows}
	var file := FileAccess.open("res://docs/prince_caramel_hell_measurements.json" if hell else "res://docs/prince_caramel_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	for row in rows: print(JSON.stringify(row))
	session.clear_run()
	finish()

func _escape(player: Player, boss: Enemy, attack: CaramelEncounter, melee: bool) -> Vector2:
	var safe := attack.profile.impact_radius + 30
	if player.global_position.distance_to(attack.destination) >= safe and (not melee or player.global_position.distance_to(boss.global_position) <= 148): return player.global_position
	var best := player.global_position
	var shortest := INF
	for index in 64:
		var ray := Vector2.from_angle(index * TAU / 32)
		var candidate := boss.global_position + ray * 128 if index >= 32 and melee else attack.destination + ray * safe
		candidate = candidate.clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
		if candidate.distance_to(attack.destination) < safe - 0.01: continue
		var closest := Geometry2D.get_closest_point_to_segment(boss.global_position, player.global_position, candidate)
		if closest.distance_to(boss.global_position) <= boss.data.radius + 25: continue
		var cost := player.global_position.distance_to(candidate)
		if melee: cost += maxf(candidate.distance_to(boss.global_position) - 148, 0) * 2
		if cost < shortest:
			shortest = cost
			best = candidate
	return best

func _variant_goal(player: Player, boss: Enemy, attack: CaramelEncounter, melee: bool) -> Vector2:
	var goal := player.global_position
	match attack.state:
		CaramelEncounter.State.WINDUP, CaramelEncounter.State.FLIGHT:
			goal = _escape(player, boss, attack, melee)
		CaramelEncounter.State.HEART_WINDUP, CaramelEncounter.State.HEART_RELEASE:
			var radius := maxf(player.global_position.distance_to(boss.global_position), 240)
			var shortest := INF
			for side in [-1, 1]:
				var candidate := boss.global_position + attack.aim.rotated(deg_to_rad(attack.profile.fan_step_degrees * 0.5 * side)) * radius
				candidate = candidate.clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
				var cost := candidate.distance_to(player.global_position)
				if cost < shortest:
					shortest = cost
					goal = candidate
		CaramelEncounter.State.RUSH_WINDUP, CaramelEncounter.State.RUSH_ACTIVE:
			var near := Geometry2D.get_closest_point_to_segment(player.global_position, attack.rush_origin, attack.rush_end)
			var a := near + attack.aim.orthogonal() * (boss.data.radius + 55)
			var b := near - attack.aim.orthogonal() * (boss.data.radius + 55)
			goal = a if player.global_position.distance_to(a) < player.global_position.distance_to(b) else b
		CaramelEncounter.State.BURST_WINDUP, CaramelEncounter.State.BURST_RELEASE:
			var step := TAU / attack.rays.size()
			var from := attack.rays[0].angle()
			var toward := boss.global_position.angle_to_point(player.global_position)
			var angle := from + (roundf((toward - from) / step - 0.5) + 0.5) * step
			goal = boss.global_position + Vector2.from_angle(angle) * maxf(280, boss.global_position.distance_to(player.global_position))
		_:
			if melee: goal = boss.global_position + boss.global_position.direction_to(player.global_position) * 120
	# Reactions are illustrative, not an optimal solver: avoid currently flying
	# hearts by choosing a short safe velocity, including waiting in a gap.
	var speed := PlayerStats.BASE_MOVE_SPEED * player.floor_movement_factor()
	var desired := player.global_position.direction_to(goal) * speed
	var best := desired
	var best_cost := INF
	for option in [desired, Vector2.ZERO, desired.orthogonal(), -desired.orthogonal()]:
		var cost: float = option.distance_to(desired)
		for heart in attack.hearts.entries:
			var a: Vector2 = heart.at - player.global_position
			var b: Vector2 = a + (heart.velocity - option) * 0.45
			var clearance := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, a, b).length()
			if clearance < 40: cost += (40 - clearance) * 500
		var closest := Geometry2D.get_closest_point_to_segment(boss.global_position, player.global_position, player.global_position + option * 0.3)
		if closest.distance_to(boss.global_position) < boss.data.radius + 22: cost += 10000
		if cost < best_cost:
			best_cost = cost
			best = option
	return player.global_position + best * 0.45
