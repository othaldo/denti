extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D
var boss: Enemy
var attack: CrownCourtEncounter

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if ok: return
	failures.append(message)
	push_error(message)

func _fresh(kind: int = 0, phase: int = 0) -> void:
	attack.cancel()
	attack.cycle = 0
	boss.boss_phase = phase
	boss.boss_phase_timer = 0
	boss.global_position = Vector2(770, 620)
	game.player.global_position = Vector2(1050, 650)
	game.player.stats.health = 100000
	game.player.hurt_time = 0
	game.player.dash_moved = false
	game.player.get_node("Camera2D").force_update_scroll()
	attack.begin(kind)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://crown_court_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.current_wave = 20
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.loadout.restore([])
	game.player.stats.max_health = 100000
	game.player.stats.health = 100000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, Vector2(770, 620))
	boss = game.boss
	attack = boss.crown_court_encounter
	boss.set_simulation_enabled(false)
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	_check(attack != null and attack.rig.bones.size() == 8, "Emperor modular court was not connected")
	for bone: Bone2D in attack.rig.bones.values(): _check(bone.scale == Vector2.ONE, "Emperor art was stretched")
	_fresh()
	var fixed_angle := attack.edict_angle
	game.player.global_position = attack.origin + Vector2.from_angle(fixed_angle) * 250
	attack.advance(attack.profile.warning_seconds - 0.001)
	_check(game.player.stats.health == 100000 and attack.shots.entries.is_empty(), "court hit during its warning")
	attack.advance(0.011)
	_check(game.player.stats.health < 100000 and attack.verdict_hit, "announced court sector missed stationary Denti")
	for entry in attack.shots.entries:
		var angular_distance := minf(absf(Vector2.from_angle(fixed_angle).angle_to(entry.velocity)), absf(Vector2.from_angle(fixed_angle + PI).angle_to(entry.velocity)))
		_check(angular_distance <= deg_to_rad(attack.profile.court_half_angle) + 0.0001, "court fan exceeded its announced angular footprint")
	var health: float = game.player.stats.health
	attack.shots.clear()
	var save := attack.save_data()
	attack.restore(save)
	game.player.hurt_time = 0
	attack.advance(0.02)
	_check(game.player.stats.health == health, "resume replayed a resolved verdict hit")
	_fresh()
	game.player.global_position += Vector2(-280, 180)
	attack.advance(0.5)
	_check(attack.edict_angle == fixed_angle, "court put a safety gap at Denti's changing location")
	_fresh(CrownCourtEncounter.Attack.PORTAL)
	var a := attack.portal_a
	var b := attack.portal_b
	attack.advance(attack.profile.portal_warning_seconds - 0.001)
	_check(attack.lances.entries.is_empty() and game.player.stats.health == 100000, "portal fired prematurely")
	game.player.global_position += Vector2(0, 400)
	attack.advance(0.121)
	_check(attack.portal_a == a and attack.portal_b == b, "portal warning retargeted after Denti moved")
	_check(attack.lances.entries[0].at.is_equal_approx(a + a.direction_to(b) * attack.profile.lance.speed * 0.12), "long frame advanced a portal lance before birth")
	var flight_save := attack.save_data()
	attack.restore(flight_save)
	_check(attack.save_data() == flight_save, "portal resume changed lance speed, destination or pose")
	_fresh(CrownCourtEncounter.Attack.PORTAL)
	attack.advance(1.0 + 0.35)
	_check(game.player.stats.health < 100000, "portal lance did not hit Denti on its announced path")
	# A dash crossing a live verdict must not tunnel through both clear endpoints.
	_fresh()
	attack.advance(attack.profile.warning_seconds)
	var center := attack.origin + Vector2.from_angle(attack.edict_angle) * 230
	var cross := Vector2.from_angle(attack.edict_angle).orthogonal() * 230
	game.player.motion_start = center - cross
	game.player.motion_end = center + cross
	game.player.global_position = game.player.motion_end
	game.player.motion_tick = Engine.get_physics_frames()
	game.player.dash_motion_seconds = 0.16
	game.player.dash_moved = true
	attack.advance(0.16)
	_check(game.player.stats.health < 100000, "dash tunneled through a court sector")
	_fresh(CrownCourtEncounter.Attack.NERVE)
	var shots_before := attack.shots.fired
	attack.advance(attack.profile.nerve_warning_seconds + 0.01)
	_check(attack.shots.fired - shots_before == attack.profile.rays(0), "nerve ring omitted rays or silently capped its volley")
	var pulse_before := attack.pulses_fired
	boss.boss_phase = 2
	boss.health = boss.max_health
	boss.boss_damage_budget = boss.max_health
	for hit in 40: boss.take_damage(1)
	_check(attack.pulses_fired == pulse_before, "individual weapon hits manufactured extra nerve pulses")
	_fresh()
	boss.boss_phase = 2
	boss.health = boss.max_health
	boss.boss_damage_budget = boss.max_health
	attack.facing = Vector2.RIGHT
	var front := boss.take_damage(20, null, false, &"", [], Vector2.LEFT)
	var rear := boss.take_damage(20, null, false, &"", [], Vector2.RIGHT)
	attack.state = CrownCourtEncounter.State.OPEN
	var open_hit := boss.take_damage(20, null, false, &"", [], Vector2.LEFT)
	_check(rear > front * 1.7 and open_hit > rear, "crown guard ignores real hit direction or core exposure")
	# Each difficulty owns independent data and all three attack clocks survive pause.
	var previous_projectiles := -1
	var measurements: Array[Dictionary] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		game.wave.difficulty_id = difficulty.id
		boss.configure(EnemyCatalog.CAVITY_EMPEROR, game.player, 20, difficulty.id)
		attack.profile = EnemyCatalog.CAVITY_EMPEROR.crown_court_profile.for_difficulty(difficulty)
		attack.shots.profile = attack.profile.shots
		attack.lances.profile = attack.profile.lance
		_check(attack.profile.shots != EnemyCatalog.CAVITY_EMPEROR.crown_court_profile.shots and attack.profile.shots.speed == 225 * difficulty.boss_projectile_speed_multiplier, "Emperor shared projectile data across difficulties")
		_check(attack.profile.warning_seconds == 1.05 and attack.profile.portal_warning_seconds == 1 and attack.profile.nerve_warning_seconds == 1.05, "difficulty shortened Emperor reaction windows")
		for kind in [0, 1, 2]:
			_fresh(kind, 2)
			for seconds in [0.2, 0.8, 0.3, 0.5, 1.0, 1.2]:
				attack.advance(seconds)
				var before := attack.save_data()
				EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
				_check(before == attack.save_data(), "difficulty-specific court snapshot changed live hazards")
		_fresh(0, 2)
		var fired := attack.shots.fired
		var warned := attack.warnings
		var portaled := attack.portals_fired
		var stepped := attack.movement
		var peak := 0
		var kinds := {}
		for tick in 3600:
			game.player.hurt_time = maxf(game.player.hurt_time - 1.0 / 60, 0)
			attack.advance(1.0 / 60)
			kinds[attack.attack_kind] = true
			peak = maxi(peak, attack.shots.entries.size())
			_check(peak <= attack.profile.shots.maximum and attack.lances.entries.size() <= attack.profile.lance.maximum, "court exceeded its hazard budgets")
		var total := attack.shots.fired - fired
		_check(kinds.size() == 3 and total > previous_projectiles, "actual Emperor repertoire/pressure did not scale between difficulties")
		previous_projectiles = total
		measurements.append({"difficulty": str(difficulty.id), "seconds": 60, "projectiles": total, "portals": attack.portals_fired - portaled, "warnings": attack.warnings - warned, "movement": snappedf(attack.movement - stepped, 0.1), "peak_shots": peak})
	print("EMPEROR PRESSURE: ", JSON.stringify(measurements))
	var frozen := attack.save_data()
	await process_frame
	await process_frame
	_check(attack.save_data() == frozen, "pause advanced the court clock")
	for bad in [{"combo": []}, {"state": "bad"}, {"portal_a": [1]}, {"shots": [{"position": [1, 2], "velocity": [0, "bad"], "life": 1, "damage": 1}]}]:
		_check(RunSaveData.normalize({"wave": 20, "player": {}, "enemies": [{"crown_court": bad}]}).is_empty(), "invalid Emperor save entered runtime")
	attack.restore({})
	_check(attack.state == CrownCourtEncounter.State.POSITION and attack.shots.entries.is_empty(), "legacy Emperor save immediately unleashed new hazards")
	# Two Emperors sharing a player cannot layer independent court sequences.
	_fresh()
	var second: Enemy = preload("res://scenes/enemies/enemy.tscn").instantiate()
	second.configure(EnemyCatalog.CAVITY_EMPEROR, game.player, 20, &"hell")
	game.get_node("Enemies").add_child(second)
	second.set_simulation_enabled(false)
	_check(second.crown_court_encounter._reserved(), "double Emperors did not reserve the active court sequence")
	second.crown_court_encounter.advance(0.8)
	_check(not second.crown_court_encounter.active, "second Emperor ignored a reserved warning")
	second.free()
	# Actual load during a warning, not just in-memory serialization.
	_fresh(CrownCourtEncounter.Attack.PORTAL)
	attack.profile = EnemyCatalog.CAVITY_EMPEROR.crown_court_profile.for_difficulty(boss.difficulty)
	attack.shots.profile = attack.profile.shots
	attack.lances.profile = attack.profile.lance
	attack.advance(0.35)
	var actual_save := attack.save_data()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	boss = game.boss
	attack = boss.crown_court_encounter
	game.get_node("Enemies").set_physics_process(false)
	game.player.set_physics_process(false)
	paused = true
	_check(attack.state == CrownCourtEncounter.State.PORTAL_WARN and attack.portal_a == SnapshotValues.read_vector(actual_save.portal_a), "actual continue lost the portal's locked warning")
	BossAttackController.start_boss_phase(boss)
	_check(attack.shots.entries.is_empty() and attack.lances.entries.is_empty() and boss.boss_phase_burst_fired, "phase retained court hazards or added generic salvos")
	_fresh(CrownCourtEncounter.Attack.NERVE, 2)
	attack.advance(attack.profile.nerve_warning_seconds + 0.1)
	boss.health = 1
	boss.boss_damage_budget = boss.max_health
	boss.take_damage(1000)
	_check(boss.dying and attack.shots.entries.is_empty() and attack.lances.entries.is_empty(), "dead Emperor retained damaging owned projectiles")
	session.clear_run()
	if failures.is_empty(): print("PASS crown_court_encounter: directional guard, fixed judgments, portals, full nerve rings, cadence, all tiers, snapshots, real continue, pause and legacy migration")
	finish(0 if failures.is_empty() else 1)
