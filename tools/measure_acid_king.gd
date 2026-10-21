extends "res://tests/support/test_runtime.gd"
## Repeatable encounter instrumentation, not an automatic balance verdict.
const STEP := 1.0 / 60.0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://acid_king_measure.json"
	session.resume_requested = false
	session.clear_run()
	var results: Array[Dictionary] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		session.selected_difficulty_id = difficulty.id
		for melee in [true, false]:
			for movement in ["stationary", "circle", "read warning"]:
				seed(102026)
				var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
				root.add_child(game)
				current_scene = game
				game.choice_panel._on_choice_pressed(0)
				game.set_process(false)
				game.wave.set_process(false)
				game.wave.current_wave = 15
				var player: Player = game.player
				player.set_physics_process(false)
				player.loadout.restore([])
				player.stats.max_health = 10000
				player.stats.health = 10000
				player.stats.dodge_chance = 0
				player.stats.shield_charges = 0
				player.global_position = Vector2(1050, 650)
				var data := EnemyCatalog.CAVITY_KING.duplicate() as EnemyData
				data.boss_phase_adds = 0
				game._create_enemy(data, Vector2(780, 620))
				var boss: Enemy = game.boss
				var attack := boss.acid_king_encounter
				game.get_node("Enemies").set_physics_process(false)
				boss.set_simulation_enabled(false)
				var warnings := [0]
				boss.attack_performed.connect(func(kind: StringName):
					if kind == &"boss_warning": warnings[0] += 1)
				var seconds := 0.0
				var open_seconds := 0.0
				var open_damage := 0.0
				var peak_fields := 0
				var peak_shards := 0
				var kinds := {}
				for frame in 5400:
					player.hurt_time = maxf(player.hurt_time - STEP, 0)
					var goal := player.global_position
					if movement == "circle": goal += boss.global_position.direction_to(player.global_position).orthogonal() * 300
					elif movement == "read warning": goal = _react(player, boss, attack, melee)
					var before := player.global_position
					player.global_position = before.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * player.floor_movement_factor() * STEP).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
					player.velocity = (player.global_position - before) / STEP
					player.get_node("Camera2D").force_update_scroll()
					boss._physics_process(STEP)
					peak_fields = maxi(peak_fields, attack.fields.size())
					peak_shards = maxi(peak_shards, attack.volley.entries.size())
					if attack.active: kinds[attack.attack_kind] = true
					var exposed := attack.state == AcidKingEncounter.State.OPEN
					if exposed: open_seconds += STEP
					if player.global_position.distance_to(boss.global_position) <= (168 if melee else 600):
						var dealt := boss.take_damage(150 * STEP)
						if exposed: open_damage += dealt
					seconds += STEP
					if boss.dying: break
				results.append({"difficulty": str(difficulty.id), "range": "melee 168" if melee else "ranged 600", "movement": movement, "seconds": snappedf(seconds, 0.01), "defeated": boss.dying, "damage_taken": snappedf(10000 - player.stats.health, 0.1), "damage_acid": snappedf(attack.damage_by_source.acid, 0.1), "damage_stomp": snappedf(attack.damage_by_source.stomp, 0.1), "damage_shards": snappedf(attack.volley.damage_dealt, 0.1), "warnings": warnings[0], "channels": attack.channels_created, "projectiles": attack.volley.fired, "peak_fields": peak_fields, "peak_shards": peak_shards, "kinds": kinds.keys(), "open_seconds": snappedf(open_seconds, 0.01), "open_damage": snappedf(open_damage, 0.1)})
				game.free()
	var report := {"date": "2026-10-21", "method": "Isolated wave 15 on all four difficulties, actual boss phases/guard and 150 raw DPS when within range. No weapons/items/adds/dash; 10000 player HP only to accumulate damage. Seed 102026, fixed 60 Hz, maximum 90 seconds; defeated=false is not a kill time. Three scripted movement policies; read-warning is a simple reaction, not an optimal solver or human/full-wave balance approval. Stationary melee intentionally measures range failure. Acid end caps are finite world-space capsules.", "results": results}
	var file := FileAccess.open("res://docs/king_acid_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	for row in results: print(JSON.stringify(row))
	session.clear_run()
	finish()

func _react(player: Player, boss: Enemy, attack: AcidKingEncounter, melee: bool) -> Vector2:
	var goal := player.global_position
	if attack.state in [AcidKingEncounter.State.WARN_CHANNEL, AcidKingEncounter.State.WARN_SHIFT, AcidKingEncounter.State.FLOW]:
		var channels: Array[Dictionary] = attack.pending if not attack.pending.is_empty() else attack.fields
		var threatened := false
		for channel in channels:
			if HazardGeometry.circle_box(goal, Rect2(channel.at - channel.half_size, channel.half_size * 2)): threatened = true
		if threatened:
			var shortest := INF
			for side in [-1, 1]:
				var candidate := player.global_position
				candidate[attack.axis] += side * 110
				candidate = candidate.clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
				var safe := true
				for channel in channels:
					if HazardGeometry.circle_box(candidate, Rect2(channel.at - channel.half_size, channel.half_size * 2)): safe = false
				if safe and candidate.distance_to(player.global_position) < shortest:
					shortest = candidate.distance_to(player.global_position)
					goal = candidate
	elif attack.state in [AcidKingEncounter.State.WARN_STOMP, AcidKingEncounter.State.STOMP]:
		var tangent := attack.aim.orthogonal()
		if absf((player.global_position - boss.global_position).dot(tangent)) < attack.profile.stomp_half_span + 45:
			goal += tangent * 160
	elif melee: goal = boss.global_position + boss.global_position.direction_to(player.global_position) * 145
	# Do not deliberately cross the King's body to reach a nearby bank.
	if Geometry2D.get_closest_point_to_segment(boss.global_position, player.global_position, goal).distance_to(boss.global_position) < boss.data.radius + 22:
		return player.global_position
	return goal
