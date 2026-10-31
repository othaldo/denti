extends "res://tests/support/test_runtime.gd"
const STEP := 1.0 / 60
var game: Node2D
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _place(boss: Enemy) -> void:
	boss.acid_king_encounter.cancel()
	boss.boss_phase_timer = 0
	boss.global_position = Vector2(770, 620)
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2(220, 0)
	game.player.stats.health = 100000
	game.player.hurt_time = 0
	game.player.get_node("Camera2D").force_update_scroll()
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://king_assault_test.json"
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
	game.player.stats.max_health = 100000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game.player.dash_moved = false
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		boss.configure(EnemyCatalog.CAVITY_KING, game.player, 15, difficulty.id)
		game.get_node("Enemies").add_child(boss)
		boss.set_simulation_enabled(false)
		boss.boss_phase = 2
		var a := boss.acid_king_encounter
		var p := a.profile
		_check(p.spit != EnemyCatalog.CAVITY_KING.acid_king_profile.spit and EnemyCatalog.CAVITY_KING.acid_king_profile.spit.speed == 370, "difficulty mutated the shared spit resource")
		_check(p.spit_count() == 5 + difficulty.boss_volley_bonus * 2 and is_equal_approx(p.spit.speed, 370 * difficulty.boss_projectile_speed_multiplier), "spit count/speed ignores difficulty")
		_check(p.stomp_sequences == (2 if difficulty.boss_volley_bonus >= 1 else 1) and p.spit_warning_seconds == 0.75, "stomp pressure or warning scales incorrectly")
		_place(boss)
		a.begin(a.Attack.CHANNELS)
		a.advance(p.warning_seconds)
		_check(a.state == a.State.WARN_SPIT and a.spit.entries.is_empty() and a.spit_rays.size() == p.spit_count(), "river failed to announce its aimed fan")
		var origin := a.spit_origin
		var rays := a.spit_rays.duplicate()
		var lead: Vector2 = game.player.global_position + (game.player.velocity * p.spit_lead_seconds).limit_length(p.spit_lead_distance)
		_check(rays[rays.size() / 2].is_equal_approx(origin.direction_to(lead)), "fan retained an obsolete target")
		var warning := a.save_data()
		a.restore(warning)
		_check(a.save_data() == warning and AcidKingSnapshot.valid(warning), "new fan warning failed snapshot roundtrip")
		game.player.global_position += Vector2(400, 200)
		a.advance(p.spit_warning_seconds - 0.001)
		_check(a.spit.entries.is_empty() and a.spit_rays == rays and boss.global_position == origin, "fan tracked the player, moved origin or fired early")
		a.advance(0.201)
		_check(a.spit.entries.size() == p.spit_count(), "long frame lost fan rays")
		for entry in a.spit.entries:
			_check(is_equal_approx(entry.life, p.spit.lifetime - 0.2) and is_equal_approx(entry.at.distance_to(origin), p.spit.speed * 0.2), "fan projectile advanced before its birth")
		var flying := a.save_data()
		a.restore(flying)
		_check(a.save_data() == flying, "flying acid fan changed on restore")
		# Phase changes cancel both warning geometry and actual projectile batches.
		BossAttackController.start_boss_phase(boss)
		_check(a.spit.entries.is_empty() and a.spit_rays.is_empty() and a.fields.is_empty(), "phase interruption retained fan/river hazards")
		_place(boss)
		a.begin(a.Attack.STOMP)
		a.advance(a.stomp_warning_duration() + a._stomp_duration())
		if p.stomp_sequences == 2:
			_check(a.state == a.State.CHASE_STOMP and a.stomp_index == 1, "Hard/Hell omitted the second stomp")
			var chase := a.save_data()
			a.restore(chase)
			_check(a.save_data() == chase, "follow-up chase failed snapshot roundtrip")
			game.player.global_position += Vector2(90, 130)
			var distance := boss.global_position.distance_to(game.player.global_position)
			a.advance(p.stomp_chase_seconds)
			_check(a.state == a.State.WARN_STOMP and is_equal_approx(a.remaining, a.stomp_warning_duration()) and boss.global_position.distance_to(game.player.global_position) < distance, "second stomp omitted pursuit/full new warning")
			var fixed := a.rows.duplicate(true)
			var retargeted := boss.global_position.direction_to(game.player.global_position)
			_check(a.aim.is_equal_approx(retargeted), "second stomp did not reacquire Denti")
			game.player.global_position += Vector2(150, -90)
			a.advance(a.remaining - 0.001)
			_check(a.rows == fixed, "follow-up stomp tracked Denti during its warning")
			a.advance(0.001 + a._stomp_duration())
		_check(a.state == a.State.RECALL and a.stomp_index == p.stomp_sequences, "stomp chain failed to finish")
		# v1 serial saves complete the announced single sequence as before.
		_place(boss)
		a.begin(a.Attack.STOMP)
		var old := a.save_data()
		old.version = 1
		for key in ["stomp_total", "stomp_index", "spit_origin", "spit_rays", "spit_projectiles"]: old.erase(key)
		a.restore(old)
		a.advance(a.remaining + a._stomp_duration())
		_check(a.state == a.State.RECALL and a.spit.entries.is_empty(), "old save gained an unannounced extra attack")
		_place(boss)
		boss.global_position = game.player.global_position + Vector2(-600, 0)
		a.advance(p.approach_seconds + 0.001)
		_check(a.state == a.State.POSITION, "distant King started an ineffective fan before approaching")
		boss.free()
	# Real save/scene reload with an active aimed warning.
	game.wave.difficulty_id = &"hell"
	game._create_enemy(EnemyCatalog.CAVITY_KING, Vector2(770, 620))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	_place(boss)
	var a := boss.acid_king_encounter
	a.begin(a.Attack.CHANNELS)
	a.advance(a.profile.warning_seconds + 0.2)
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
	a = boss.acid_king_encounter
	paused = true
	var loaded := a.save_data()
	var advanced: float = loaded.elapsed - before.elapsed
	_check(loaded.state == a.State.WARN_SPIT and loaded.spit_origin == before.spit_origin and loaded.spit_rays == before.spit_rays and absf(loaded.remaining - before.remaining + advanced) < 0.00001 and advanced >= 0 and advanced <= STEP * 2 + 0.000001, "real reload lost fixed fan warning/timing")
	for bad in [{"spit_rays": [[0]]}, {"spit_projectiles": [{}]}, {"stomp_total": "bad"}, {"spit_origin": [INF, 0]}]:
		_check(not AcidKingSnapshot.valid(bad), "invalid assault snapshot entered runtime")
	a.advance(a.remaining + 0.1)
	boss.health = 1
	boss.boss_damage_budget = boss.max_health
	boss.boss_phase = 2
	boss.take_damage(1000000)
	_check(boss.dying and a.spit.entries.is_empty() and a.spit_rays.is_empty() and a.fields.is_empty(), "death retained new hazards")
	boss.free()
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty(): print("PASS king_assault: four-tier attacks, fixed full warnings, chase/reaim, projectile birth times, save/real reload, v1 migration, phase/death cleanup")
	finish(0 if failures.is_empty() else 1)
