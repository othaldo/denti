extends "res://tests/support/test_runtime.gd"
## New royal combos keep fixed warnings, reachable exits and resumable ownership.

const STEP := 1.0 / 60
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
var game: Node2D
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _spawn(difficulty: DifficultyData, wave: int) -> Enemy:
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.stats.health = game.player.stats.max_health
	game.player.hurt_time = 0
	game.player.get_node("Camera2D").force_update_scroll()
	var boss: Enemy = ENEMY_SCENE.instantiate()
	boss.position = Vector2(770, 620)
	boss.configure(WaveController.boss_for_wave(wave), game.player, wave, difficulty.id)
	game.get_node("Enemies").add_child(boss)
	boss.set_simulation_enabled(false)
	if wave == 20: boss.global_position = Vector2(game.player.global_position) - Vector2(240, 0)
	return boss

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://royal_pressure_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.loadout.restore([])
	game.player.stats.max_health = 100000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	paused = true
	var prince_routes := 0
	var court_routes := 0
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var prince := _spawn(difficulty, 10)
		var caramel := prince.caramel_encounter
		prince.boss_phase = caramel.profile.bomb_fan_phase
		caramel.begin(-1, CaramelEncounterData.Attack.BOMBS)
		for tick in 600:
			caramel.advance(STEP)
			if caramel.state == CaramelEncounter.State.HEART_WINDUP: break
		_check(caramel.state == CaramelEncounter.State.HEART_WINDUP and not caramel.pools.is_empty() and caramel.throw_index == caramel.count, "short bomb sequence did not lead to a fully warned fan over live puddles")
		var saved := caramel.save_data()
		EnemySnapshot.restore(prince, EnemySnapshot.capture(prince))
		_check(caramel.save_data() == saved, "bomb/fan transition lost its warning or puddles on resume")
		var origin := prince.global_position
		var rays := caramel.rays.duplicate()
		game.player.global_position += Vector2(200, -100)
		game.player.velocity = Vector2(1000, 0)
		caramel.advance(caramel.remaining - 0.001)
		_check(caramel.rays == rays and prince.global_position == origin and caramel.hearts.entries.is_empty(), "combined fan moved or shot before its full fixed warning")
		# Already warned pre-cap five-bomb/four-salvo Hell sequences still resume.
		if difficulty == DifficultyCatalog.HELL:
			caramel.cancel()
			caramel.begin(-1, CaramelEncounterData.Attack.BOMBS)
			caramel.count = 5
			caramel.throw_index = 4
			caramel._warn(-1)
			var legacy := caramel.save_data()
			caramel.restore(legacy)
			_check(caramel.save_data() == legacy, "shorter new bomb chains truncated an already warned legacy throw")
		var emperor := _spawn(difficulty, 20)
		var court := emperor.crown_court_encounter
		emperor.boss_phase = court.profile.combo_phase
		court.begin(CrownCourtEncounter.Attack.EDICT)
		# Preserve the simultaneous v1 combination alongside the new sequential tests.
		court.legacy_sequence = true
		court.step_index = court.profile.verdicts(emperor.boss_phase) - 1
		court._edict()
		_check(court.portal_combo and court.remaining >= maxf(court.profile.warning_seconds, court.profile.portal_warning_seconds), "verdict/portal combo shortened either reaction window")
		var before := court.save_data()
		EnemySnapshot.restore(emperor, EnemySnapshot.capture(emperor))
		_check(court.save_data() == before, "combo snapshot lost its portal ownership or world geometry")
		origin = emperor.global_position
		game.player.global_position += Vector2(170, -100)
		var fired := court.portals_fired
		court.advance(court.remaining - 0.001)
		_check(court.portal_a == SnapshotValues.read_vector(before.portal_a) and court.portal_b == SnapshotValues.read_vector(before.portal_b) and court.edict_angle == before.edict_angle and emperor.global_position == origin and court.portals_fired == fired, "combined court warning moved, tracked Denti or launched early")
		court.advance(0.001)
		_check(court.portals_fired == fired + 1 and court.state == CrownCourtEncounter.State.EDICT_HIT, "combined verdict did not release exactly one warned portal")
		court.advance(court.remaining)
		_check(court.state == CrownCourtEncounter.State.REPOSITION, "combined verdict did not reposition before the next pattern")
		before = court.save_data()
		EnemySnapshot.restore(emperor, EnemySnapshot.capture(emperor))
		_check(court.save_data() == before, "new reposition state failed to resume exactly")
		# An old last-verdict warning must not gain an unseen portal on load.
		game.player.global_position = emperor.global_position + Vector2(240, 0)
		court.begin(CrownCourtEncounter.Attack.EDICT)
		court.legacy_sequence = true
		court.step_index = court.profile.verdicts(emperor.boss_phase) - 1
		court._edict()
		_check(court.state == CrownCourtEncounter.State.EDICT_WARN, "legacy-warning fixture never reached casting range")
		var old := court.save_data()
		old.erase("portal_combo")
		court.restore(old)
		fired = court.portals_fired
		court.advance(court.remaining)
		_check(not court.portal_combo and court.portals_fired == fired, "old verdict save gained a portal that had never been warned")
		for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
			root.size = extent
			root.content_scale_size = extent
			await process_frame
			await process_frame
			for phase in [0, 1, 2]:
				for corner: Vector2 in [Vector2(48, 48), Vector2(game.arena.arena_size.x - 48, 48), Vector2(48, game.arena.arena_size.y - 48), game.arena.arena_size - Vector2.ONE * 48]:
					prince.boss_phase = phase
					prince_routes += 1
					_check(_route(prince, corner, 0), "%s prince phase %d has no slowed puddle/fan route at %s, %s" % [difficulty.id, phase, corner, extent])
					if phase < court.profile.combo_phase: continue
					emperor.boss_phase = phase
					for cycle in [0, 2]:
						court_routes += 1
						_check(_route(emperor, corner, cycle), "%s emperor phase %d has no slowed verdict/portal route at %s, %s cycle %d" % [difficulty.id, phase, corner, extent, cycle])
		root.size = Vector2i(1280, 720)
		root.content_scale_size = root.size
		await process_frame
		await process_frame
		prince.free()
		emperor.free()
		for wave in [10, 20]:
			var boss := _spawn(difficulty, wave)
			var impacts := [0]
			if wave == 10:
				boss.attack_performed.connect(func(kind: StringName):
					var a := boss.caramel_encounter
					if kind == &"boss_pulse" and a.state == CaramelEncounter.State.HEART_WINDUP and a.throw_index >= a.count and not a.pools.is_empty(): impacts[0] += 1)
			for tick in 4200:
				var previous := boss.crown_court_encounter.portals_fired if wave == 20 else 0
				boss._physics_process(STEP)
				if wave == 20 and boss.crown_court_encounter.portal_followup and boss.crown_court_encounter.portals_fired > previous: impacts[0] += 1
				if tick % 6 == 0: boss.take_damage(100000)
				if boss.dying: break
			_check(boss.dying, "saturated damage could not finish the royal encounter")
			if difficulty.boss_volley_bonus >= 1:
				_check(impacts[0] > 0, "strong build skipped every new royal combo on %s wave %d" % [difficulty.id, wave])
			boss.free()
	await _actual_reload_tests(session)
	session.clear_run()
	if failures.is_empty(): print("PASS royal_boss_pressure: fixed combo warnings, legacy saves, new-state snapshots, capped-build combos, %d slowed prince routes and %d combined court routes" % [prince_routes, court_routes])
	finish(0 if failures.is_empty() else 1)

func _actual_reload_tests(session: Node) -> void:
	for stage in [0, 1, 2]:
		for child in game.get_node("Enemies").get_children(): child.free()
		game.boss = null
		game.wave.current_wave = 10 if stage == 0 else 20
		game.wave.difficulty_id = &"hell"
		game.player.global_position = Vector2(1050, 650)
		game.player.velocity = Vector2.ZERO
		game.player.get_node("Camera2D").force_update_scroll()
		game._create_enemy(WaveController.boss_for_wave(game.wave.current_wave), Vector2(770, 620))
		var boss: Enemy = game.boss
		boss.set_simulation_enabled(false)
		if stage > 0: boss.global_position = game.player.global_position - Vector2(240, 0)
		boss.boss_phase = 1
		var before: Dictionary
		if stage == 0:
			var a := boss.caramel_encounter
			a.begin(-1, CaramelEncounterData.Attack.BOMBS)
			for tick in 600:
				a.advance(STEP)
				if a.state == CaramelEncounter.State.FOLLOWUP and a.attack_kind == CaramelEncounterData.Attack.HEART_FAN: break
			before = a.save_data()
		else:
			var a := boss.crown_court_encounter
			a.begin(CrownCourtEncounter.Attack.EDICT)
			a.legacy_sequence = true
			a.step_index = a.profile.verdicts(1) - 1
			a._edict()
			if stage == 1: a.advance(0.35)
			else: a.advance(a.remaining + a.profile.impact_seconds)
			before = a.save_data()
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
		var after: Dictionary = game.boss.caramel_encounter.save_data() if stage == 0 else game.boss.crown_court_encounter.save_data()
		_check(after.state == before.state and absf(after.remaining - before.remaining) <= STEP * 2 + 0.000001, "real reload lost the new royal transition clock, stage %d: state %s/%s, remaining %s/%s" % [stage, before.state, after.state, before.remaining, after.remaining])
		if stage == 0:
			_check(after.attack_kind == CaramelEncounterData.Attack.HEART_FAN and after.pools.size() == before.pools.size(), "real reload lost the queued fan or its puddles")
		elif stage == 1:
			_check(after.portal_combo and after.portal_a == before.portal_a and after.portal_b == before.portal_b, "real reload lost the combined portal's fixed warning")
		else:
			_check(after.state == CrownCourtEncounter.State.REPOSITION and after.lances.size() == before.lances.size(), "real reload lost repositioning or its flying lance")

func _route(boss: Enemy, corner: Vector2, cycle: int) -> bool:
	var player: Player = game.player
	player.global_position = corner
	player.velocity = corner.direction_to(game.arena.arena_size * 0.5) * PlayerStats.BASE_MOVE_SPEED * 0.72
	player.hurt_time = 0
	player.stats.health = player.stats.max_health
	player.get_node("Camera2D").force_update_scroll()
	boss.global_position = corner + corner.direction_to(game.arena.arena_size * 0.5) * (250 if boss.crown_court_encounter != null else 260)
	var duration := 0.0
	if boss.caramel_encounter != null:
		var a := boss.caramel_encounter
		a.cancel()
		a.pools.append({"at": corner, "life": a.profile.pool_seconds})
		a.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
		a.salvo_count = 1
		duration = a.profile.heart_warning_seconds + a.profile.heart_lifetime + 0.1
	else:
		var a := boss.crown_court_encounter
		a.cancel()
		a.cycle = cycle
		a.begin(CrownCourtEncounter.Attack.EDICT)
		a.legacy_sequence = true
		a.step_index = a.profile.verdicts(boss.boss_phase) - 1
		a._edict()
		duration = a.edict_warning_duration() + a.profile.shots.lifetime + a.profile.impact_seconds
	var saved := EnemySnapshot.capture(boss)
	for radius in [140, 210, 230]:
		for route in 32:
			EnemySnapshot.restore(boss, saved)
			player.global_position = corner
			player.hurt_time = 0
			player.stats.health = player.stats.max_health
			var goal: Vector2 = (corner + Vector2.from_angle(route * TAU / 32) * radius).clamp(Vector2.ONE * 48, game.arena.arena_size - Vector2.ONE * 48)
			var safe := true
			for tick in ceili(duration / STEP):
				var before := player.global_position
				player.global_position = before.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * 0.72 * STEP)
				player.velocity = (player.global_position - before) / STEP
				if Geometry2D.get_closest_point_to_segment(boss.global_position, before, player.global_position).distance_to(boss.global_position) <= boss.data.radius + 20:
					safe = false
					break
				if boss.caramel_encounter != null:
					var a := boss.caramel_encounter
					if a.state == CaramelEncounter.State.HEART_WINDUP: a.advance(STEP)
					else: a.hearts.advance(STEP, 0)
				else:
					var a := boss.crown_court_encounter
					if a.state in [CrownCourtEncounter.State.EDICT_WARN, CrownCourtEncounter.State.EDICT_HIT]: a.advance(STEP)
					else:
						a.shots.advance(STEP, 0)
						a.lances.advance(STEP, 0)
				if player.stats.health < player.stats.max_health:
					safe = false
					break
			if safe: return true
	return false
