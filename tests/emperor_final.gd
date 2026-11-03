extends "res://tests/support/test_runtime.gd"
const STEP := 1.0 / 60
var game: Node2D
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _place(boss: Enemy) -> void:
	boss.crown_court_encounter.retinue.used = true # Isolate original court attacks.
	boss.crown_court_encounter.cancel()
	boss.boss_phase_timer = 0
	boss.global_position = Vector2(770, 650)
	game.player.global_position = Vector2(1010, 650)
	game.player.velocity = Vector2.ZERO
	game.player.stats.health = 100000
	game.player.hurt_time = 0
	game.player.get_node("Camera2D").force_update_scroll()
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://emperor_final_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.current_wave = 20
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.loadout.restore([])
	game.player.stats.max_health = 100000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game.player.dash_moved = false
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		boss.configure(EnemyCatalog.CAVITY_EMPEROR, game.player, 20, difficulty.id)
		game.get_node("Enemies").add_child(boss)
		boss.set_simulation_enabled(false)
		var a := boss.crown_court_encounter
		var p := a.profile
		var extra := 1 if difficulty == DifficultyCatalog.HELL else 0
		_check(p.max_verdicts == 3 + extra and p.max_portals == 3 + extra and p.max_pulses == 3 + extra, "Hell did not receive its extra repetition")
		_check(p.needles != EnemyCatalog.CAVITY_EMPEROR.crown_court_profile.needles and EnemyCatalog.CAVITY_EMPEROR.crown_court_profile.needles.speed == 560 and is_equal_approx(p.needles.speed, 560 * difficulty.boss_projectile_speed_multiplier), "needle scaling mutated or ignored its resource")
		_place(boss)
		boss.boss_phase = p.combo_phase
		a.begin(a.Attack.EDICT)
		a.step_index = p.verdicts(boss.boss_phase) - 1
		a._edict()
		_check(not a.portal_combo and not a.portal_followup and a.remaining >= 0.9, "new verdict retained the obsolete simultaneous portal")
		game.player.global_position += Vector2(0, 120)
		game.player.velocity = Vector2(120, 0)
		game.player.get_node("Camera2D").force_update_scroll()
		a.advance(a.remaining + p.impact_seconds)
		_check(a.state == a.State.PORTAL_WARN and a.portal_followup and is_equal_approx(a.remaining, p.portal_warning_seconds), "verdict did not reacquire a fully warned portal")
		var predicted: Vector2 = game.player.global_position + (game.player.velocity * (p.portal_warning_seconds + p.portal_half_length / p.lance.speed)).limit_length(p.portal_lead_distance)
		_check(Geometry2D.get_closest_point_to_segment(predicted, a.portal_a, a.portal_b).distance_to(predicted) < 0.01, "portal failed to intercept the newly sampled movement")
		var saved := a.save_data()
		a.restore(saved)
		_check(a.save_data() == saved, "follow-up ownership or geometry changed on restore")
		var portals := a.portals_fired
		var first := a.portal_a
		var last := a.portal_b
		game.player.global_position += Vector2(-400, 200)
		a.advance(a.remaining - 0.001)
		_check(a.portal_a == first and a.portal_b == last and a.portals_fired == portals, "intercept tracked Denti or launched early")
		a.advance(0.001 + first.distance_to(last) / p.lance.speed)
		_check(a.state == a.State.REPOSITION and a.attack_kind == a.Attack.NERVE and a.portals_fired == portals + 1, "intercept replayed or failed to continue its nerve chain")
		_place(boss)
		boss.boss_phase = 1
		game.player.velocity = Vector2(150, 0)
		a.begin(a.Attack.NERVE)
		var rays := a.needle_rays.duplicate()
		var source := a.origin
		_check(not a.combo and rays.size() == p.needle_count(), "nerve warning omitted its fast aimed fan")
		saved = a.save_data()
		a.restore(saved)
		_check(a.save_data() == saved, "aimed needle warning failed snapshot roundtrip")
		game.player.global_position += Vector2(500, 200)
		a.advance(a.remaining - 0.001)
		_check(a.needle_rays == rays and a.needles.entries.is_empty() and boss.global_position == source, "needles retargeted, moved origin or fired early")
		a.advance(0.201)
		_check(a.needles.entries.size() == p.needle_count(), "long frame lost fast fan projectiles")
		for entry in a.needles.entries:
			_check(is_equal_approx(entry.life, p.needles.lifetime - 0.2) and is_equal_approx(entry.at.distance_to(source), p.needles.speed * 0.2), "fast projectile advanced before its birth")
		saved = a.save_data()
		a.restore(saved)
		_check(a.save_data() == saved, "flying needles changed on restore")
		a.advance(a.remaining + p.reposition_seconds)
		_check(a.state == a.State.NERVE_WARN and a.step_index == 1 and a.needle_rays.is_empty() and is_equal_approx(a.remaining, p.nerve_warning_seconds), "aimed fan did not alternate with a fully warned plain ring")
		BossAttackController.start_boss_phase(boss)
		_check(a.needles.entries.is_empty() and a.needle_rays.is_empty() and a.guard_remaining == 0, "phase change left new hazards active")
		_place(boss)
		a._open()
		var facing := a.facing
		var position := boss.global_position
		a.advance(p.recovery_settle_seconds)
		_check(boss.global_position == position and a.facing == facing, "core opening omitted its initial breath")
		a.advance(p.turn_seconds * 0.5)
		_check(a.state == a.State.OPEN and a.facing != facing and boss.global_position != position and a.exposed, "guard turn failed to overlap exposed pursuit")
		saved = a.save_data()
		a.restore(saved)
		_check(a.save_data() == saved, "moving guard turn did not resume exactly")
		a.advance(a.remaining + p.recovery_seconds)
		_check(a.state == a.State.POSITION and a.guard_remaining == 0 and a.facing.is_equal_approx(Vector2.from_angle(a.turn_to)), "new sequence reintroduced the idle turn state")
		_place(boss)
		a.begin(a.Attack.NERVE)
		var legacy := a.save_data()
		legacy.version = 1
		for key in ["needle_rays", "needles", "portal_followup", "legacy_sequence", "guard_remaining", "guard_delay"]: legacy.erase(key)
		a.restore(legacy)
		a.advance(a.remaining)
		_check(a.legacy_sequence and a.needles.entries.is_empty(), "v1 warning gained an unannounced new fan")
		boss.free()
	# Real continue must preserve an aimed follow-up, not only a direct snapshot.
	game.wave.difficulty_id = &"hell"
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, Vector2(770, 650))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	_place(boss)
	boss.boss_phase = 1
	var a := boss.crown_court_encounter
	a.begin(a.Attack.EDICT)
	a.step_index = a.profile.verdicts(1) - 1
	a._edict()
	a.advance(a.remaining + a.profile.impact_seconds + 0.2)
	var before := a.save_data()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	boss = game.boss
	boss.set_simulation_enabled(false)
	a = boss.crown_court_encounter
	paused = true
	var loaded := a.save_data()
	var advanced: float = loaded.elapsed - before.elapsed
	_check(loaded.state == a.State.PORTAL_WARN and loaded.portal_followup and loaded.portal_a == before.portal_a and loaded.portal_b == before.portal_b and absf(loaded.remaining - before.remaining + advanced) < 0.00001 and advanced >= 0 and advanced <= STEP * 2 + 0.000001, "real continue lost the newly aimed portal")
	for bad in [{"needle_rays": [[0]]}, {"needles": [{}]}, {"guard_delay": "bad"}, {"portal_followup": []}]:
		_check(not CrownCourtSnapshot.valid(bad), "malformed new court data entered runtime")
	_place(boss)
	boss.boss_phase = 1
	a.begin(a.Attack.NERVE)
	a.advance(a.remaining + 0.1)
	boss.health = 1
	boss.boss_damage_budget = boss.max_health
	boss.boss_phase = 2
	boss.take_damage(1000000)
	_check(boss.dying and a.needles.entries.is_empty() and a.needle_rays.is_empty() and a.guard_remaining == 0, "death retained new hazards or guard motion")
	boss.free()
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty(): print("PASS emperor_final: four-tier repetition/speed scaling, reaimed intercept, complete fixed warnings, overlapping guard, projectile birth times, snapshots/real continue, v1 migration and phase/death cleanup")
	finish(0 if failures.is_empty() else 1)
