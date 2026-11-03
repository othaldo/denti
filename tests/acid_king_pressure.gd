extends "res://tests/support/test_runtime.gd"
## The new pursuit must preserve warnings, old saves and combined escape routes.

const STEP := 1.0 / 60
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
var game: Node2D
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _spawn(difficulty: DifficultyData) -> Enemy:
	var player: Player = game.player
	player.global_position = Vector2(1050, 650)
	player.velocity = Vector2.ZERO
	player.stats.health = player.stats.max_health
	player.hurt_time = 0
	player.get_node("Camera2D").force_update_scroll()
	var boss: Enemy = ENEMY_SCENE.instantiate()
	boss.position = Vector2(770, 620)
	boss.configure(EnemyCatalog.CAVITY_KING, player, 15, difficulty.id)
	game.get_node("Enemies").add_child(boss)
	boss.set_simulation_enabled(false)
	boss.acid_king_encounter.pressure.used = true # Isolate original pursuit/combined routes.
	return boss

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://acid_king_pressure_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.current_wave = 15
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.loadout.restore([])
	game.player.stats.max_health = 10000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	paused = true
	var route_cases := 0
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss := _spawn(difficulty)
		var attack := boss.acid_king_encounter
		boss.boss_phase = 1
		attack.begin(AcidKingEncounter.Attack.TIDE)
		attack.advance(attack.profile.warning_seconds + attack.profile.shift_flow_seconds)
		_check(attack.state == AcidKingEncounter.State.PURSUE and attack.pending.is_empty(), "pursuit announced lanes before acquiring its new target")
		game.player.global_position += Vector2(180, 100)
		game.player.velocity = Vector2(200, 50)
		game.player.get_node("Camera2D").force_update_scroll()
		var distance := boss.global_position.distance_to(game.player.global_position)
		attack.advance(attack.profile.pursuit_seconds * 0.5)
		_check(boss.global_position.distance_to(game.player.global_position) < distance, "pursuit did not close distance to a moving target")
		var mid := attack.save_data()
		EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
		_check(attack.save_data() == mid and attack.state == AcidKingEncounter.State.PURSUE, "snapshot lost the appended pursuit state")
		var old_axis := attack.axis
		attack.advance(attack.remaining)
		var expected: Vector2 = game.player.global_position + (game.player.velocity * attack.profile.shift_lead_seconds).limit_length(attack.profile.shift_lead_distance)
		_check(attack.state == AcidKingEncounter.State.WARN_SHIFT and attack.anchor.is_equal_approx(expected), "shift retained an obsolete target instead of reacquiring before its warning")
		_check(attack.axis == (1 - old_axis if attack.profile.alternate_shift_axis else old_axis), "shift ignored its difficulty-specific axis change")
		var fixed := attack.pending.duplicate(true)
		var origin := boss.global_position
		game.player.global_position += Vector2(-160, 120)
		game.player.velocity = Vector2(-200, 0)
		attack.advance(attack.profile.shift_warning_seconds - 0.001)
		_check(attack.pending == fixed and boss.global_position == origin and attack.fields.is_empty(), "reacquired warning tracked Denti, moved the boss or activated early")
		attack.advance(0.001)
		_check(attack.fields[0].at == fixed[0].at, "reacquired river differs from the geometry that was warned")
		for phase in [0, 1, 2]:
			for kind in [AcidKingEncounter.Attack.CHANNELS, AcidKingEncounter.Attack.TIDE]:
				attack.cancel()
				boss.boss_phase = phase
				game.player.velocity = Vector2.ZERO
				attack.begin(kind)
				var saw_combo := false
				for tick in 1200:
					attack.advance(STEP)
					if attack.state == AcidKingEncounter.State.WARN_STOMP:
						saw_combo = not attack.fields.is_empty() and attack.remaining > attack.stomp_warning_duration() - STEP
						break
					if attack.state == AcidKingEncounter.State.RECALL: break
				_check(saw_combo == (phase >= attack.profile.combined_phase), "combined stomp entered the wrong health phase or lost its full warning/rivers")
		for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
			root.size = extent
			root.content_scale_size = extent
			# Viewport resize updates arena bounds/camera limits via deferred UI work.
			await process_frame
			await process_frame
			for phase in [1, 2]:
				if phase < attack.profile.combined_phase: continue
				boss.boss_phase = phase
				for corner: Vector2 in [Vector2(48, 48), Vector2(game.arena.arena_size.x - 48, 48), Vector2(48, game.arena.arena_size.y - 48), game.arena.arena_size - Vector2.ONE * 48]:
					for axis in [0, 1]:
						route_cases += 1
						_check(_combined_route(boss, corner, axis), "%s phase %d combined stomp has no slowed bank route from %s, axis %d at %s" % [difficulty.id, phase, corner, axis, extent])
		root.size = Vector2i(1280, 720)
		root.content_scale_size = root.size
		await process_frame
		await process_frame
		boss.free()
		var capped := _spawn(difficulty)
		var combined_releases := [0]
		capped.attack_performed.connect(func(kind: StringName):
			if kind == &"boss_pulse" and capped.acid_king_encounter.state == AcidKingEncounter.State.STOMP and not capped.acid_king_encounter.fields.is_empty(): combined_releases[0] += 1)
		# Enough time for the deliberately slower armor budget plus both transitions.
		var kill_frames := ceili((capped.data.boss_guard_recharge_seconds + 2 * capped.data.boss_phase_duration + 2) / STEP)
		for tick in kill_frames:
			capped._physics_process(STEP)
			if tick % 6 == 0: capped.take_damage(100000)
			if capped.dying: break
		_check(capped.dying and combined_releases[0] > 0, "%s maximum-DPS probe: dying=%s health=%.2f/%.2f combined_impacts=%d phase=%d state=%d seconds=%.2f" % [difficulty.id, capped.dying, capped.health, capped.max_health, combined_releases[0], capped.boss_phase, capped.acid_king_encounter.state, kill_frames * STEP])
		capped.free()
	# Real scene reload must retain the new state, not only its RefCounted snapshot.
	game.wave.difficulty_id = &"hell"
	game._create_enemy(EnemyCatalog.CAVITY_KING, Vector2(770, 620))
	var saved_boss: Enemy = game.boss
	saved_boss.set_simulation_enabled(false)
	var pursuit := saved_boss.acid_king_encounter
	pursuit.begin(AcidKingEncounter.Attack.TIDE)
	pursuit.advance(pursuit.profile.warning_seconds + pursuit.profile.shift_flow_seconds + 0.1)
	var before := pursuit.save_data()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.boss.set_simulation_enabled(false)
	paused = true
	var restored: Dictionary = game.boss.acid_king_encounter.save_data()
	# The real scene can run one native physics tick during the unpaused reload.
	var advanced := float(restored.elapsed) - float(before.elapsed)
	_check(restored.state == AcidKingEncounter.State.PURSUE and advanced >= 0 and advanced <= STEP * 2 and absf(restored.remaining - before.remaining + advanced) < 0.00001, "actual reload lost pursuit timing")
	_check(restored.anchor == before.anchor and restored.axis == before.axis and restored.shift_index == before.shift_index and restored.fields.size() == before.fields.size(), "actual reload lost the pursuit target or hazards")
	for index in restored.fields.size():
		_check(restored.fields[index].at == before.fields[index].at and absf(restored.fields[index].life - before.fields[index].life + advanced) < 0.00001, "reload moved or restarted a draining river")
	session.clear_run()
	if failures.is_empty(): print("PASS acid_king_pressure: reacquisition, fixed full warnings, earlier combos, pursuit reload and %d slowed corner/bank routes" % route_cases)
	finish(0 if failures.is_empty() else 1)

func _combined_route(boss: Enemy, corner: Vector2, channel_axis: int) -> bool:
	var attack := boss.acid_king_encounter
	var player: Player = game.player
	var maximum := player.stats.max_health
	attack.cancel()
	boss.global_position = corner + corner.direction_to(game.arena.arena_size * 0.5) * 260
	player.global_position = corner
	player.velocity = Vector2.ZERO
	player.stats.health = maximum
	player.hurt_time = 0
	player.get_node("Camera2D").force_update_scroll()
	attack.axis = channel_axis
	attack.attack_kind = AcidKingEncounter.Attack.TIDE
	attack.anchor = corner
	# Start on a legal bank, not inside an already failed acid warning. Test
	# both river orientations and keep the full row/shard attack unchanged.
	attack.anchor[channel_axis] += 90 * (1 if corner[channel_axis] < game.arena.arena_size[channel_axis] * 0.5 else -1)
	attack._plan_channels(false)
	attack._activate_fields(attack.stomp_warning_duration() + attack._stomp_duration() + attack.profile.recall_seconds)
	attack._warn_stomp(-1)
	var snapshot := EnemySnapshot.capture(boss)
	for radius in [90, 130, 160, 210, 230]:
		for route in 32:
			EnemySnapshot.restore(boss, snapshot)
			player.global_position = corner
			player.velocity = Vector2.ZERO
			player.stats.health = maximum
			player.hurt_time = 0
			var goal: Vector2 = (corner + Vector2.from_angle(route * TAU / 32) * radius).clamp(Vector2.ONE * 48, game.arena.arena_size - Vector2.ONE * 48)
			var safe := true
			for tick in ceili((attack.stomp_warning_duration() + attack._stomp_duration() + attack.profile.shards.lifetime) / STEP):
				var previous := player.global_position
				player.global_position = previous.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * 0.72 * STEP)
				player.velocity = (player.global_position - previous) / STEP
				if Geometry2D.get_closest_point_to_segment(boss.global_position, previous, player.global_position).distance_to(boss.global_position) <= boss.data.radius + 20:
					safe = false
					break
				if attack.state in [AcidKingEncounter.State.WARN_STOMP, AcidKingEncounter.State.STOMP]: attack.advance(STEP)
				else:
					attack._tick_fields(STEP, 0)
					attack.volley.advance(STEP, 0)
				if player.stats.health < maximum:
					safe = false
					break
			if safe: return true
	return false
