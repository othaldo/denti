extends "res://tests/support/test_runtime.gd"

var game: Node2D
var boss: Enemy
var attack: AcidKingEncounter
var trial: KingPressureTrial
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _fresh(difficulty: StringName = &"normal") -> void:
	paused = true
	game._clear_arena(false)
	await process_frame
	await process_frame
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.wave.current_wave = 15
	game.wave.active = false
	game.wave.set_process(false)
	game.wave.difficulty_id = difficulty
	game.player.loadout.restore([])
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	game.player.hurt_time = 0
	game.player.dash_moved = false
	game.player.get_node("Camera2D").force_update_scroll()
	await process_frame
	game._create_enemy(EnemyCatalog.CAVITY_KING, game.player.global_position + Vector2(-200, -100))
	boss = game.boss
	attack = boss.acid_king_encounter
	trial = attack.pressure
	boss.health = boss.max_health * trial.profile.health_thresholds[0]
	boss.boss_phase = 1 if trial.profile.health_thresholds[0] < 0.7 else 0
	boss.boss_phase_timer = 0
	boss.set_simulation_enabled(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.set_physics_process(false)
	var player_position: Vector2 = game.player.global_position
	attack.advance(0.01)
	attack.advance(trial.remaining)
	_check(game.player.global_position == player_position and game.player.get_node("Camera2D").position.is_zero_approx(), "shield introduction teleported Denti or snapped the desktop camera")

func _shoot(index: int) -> void:
	_check(trial.state == KingPressureTrial.State.TRACKING, "new shot started outside the tracking window")
	game.player.global_position = trial.stance(index)
	game.player.dash_moved = false
	attack.advance(trial.remaining)
	_check(trial.state == KingPressureTrial.State.LOCKED and trial.hit_valve == index, "stance did not aim the locked ray at its valve")
	game.player.global_position += trial.aim.orthogonal() * 70
	attack.advance(trial.remaining + 0.01)
	_check(trial.valves[index].broken, "the King's own ray did not break the aligned valve")
	attack.advance(trial.remaining + trial.profile.recoil_seconds + 0.001)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_king_pressure.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	for difficulty in [&"easy", &"normal", &"hard", &"hell"]:
		await _fresh(difficulty)
		_check(trial.valves.size() == trial.valve_count(), "wrong difficulty-specific valve count")
		_check(trial.profile.lock_seconds * PlayerStats.MIN_MOVE_SPEED > trial.profile.beam_half_width + HazardGeometry.PLAYER_RADIUS + 5, "slow baseline cannot leave the locked ray before it fires")
		var health := boss.health
		_check(boss.take_damage(1e9) == 0 and boss.health == health and not boss.is_targetable(), "weapons skipped the movement examination")
		var hero_health: float = game.player.stats.health
		for index in trial.valves.size(): _shoot(index)
		_check(trial.state == KingPressureTrial.State.SHATTER and trial.remaining_valves() == 0, "last valve failed to break the shield")
		_check(game.player.stats.health == hero_health, "correctly aimed/dodged shots caused unavoidable damage")
		attack.advance(trial.remaining + 0.01)
		_check(trial.state == KingPressureTrial.State.EXPOSED and boss.is_targetable() and boss.health < health, "shield break omitted backfire or the attack opening")
		boss.boss_damage_budget = 0
		_check(boss.take_damage(10) > 8, "earned exposure window retained the normal guard/closed armor")
		var before := trial.save_data()
		EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
		_check(trial.save_data() == before, "save/resume changed the earned opening or broken valves")
		attack.advance(trial.remaining + 0.01)
		_check(trial.completed_mask == 1 and not trial.busy() and boss.is_targetable(), "completed examination repeated or left permanent immunity")
	# All Hell shields trigger at their exact HP checkpoints, even under huge
	# weapon hits. Ordinary two-thirds/one-third phases remain authoritative.
	await _fresh(&"hell")
	trial.cancel()
	trial.used = false
	trial.completed_mask = 0
	boss.health = boss.max_health
	boss.boss_phase = 0
	for index in 3:
		var threshold: float = trial.profile.health_thresholds[index]
		var hits := 0
		while boss.health > boss.max_health * threshold + 0.01 and hits < 4:
			boss.boss_phase_timer = 0
			boss.boss_damage_budget = boss.max_health
			boss.take_damage(1e9)
			hits += 1
		_check(is_equal_approx(boss.health / boss.max_health, threshold), "burst skipped a Hell shield checkpoint")
		boss.boss_phase_timer = 0
		attack.advance(0.01)
		attack.advance(trial.remaining)
		_check(trial.trial_index == index and trial.valves.size() == index + 2, "Hell did not escalate through two, three and four valves")
		_shoot(0)
		var mid := trial.save_data()
		EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
		_check(trial.save_data() == mid, "reload lost a partially completed repeated shield")
		if index == 2:
			var single := EnemySnapshot.capture(boss)
			single.acid_king.pressure.version = 1
			for key in ["completed_mask", "trial_index", "frame_center"]: single.acid_king.pressure.erase(key)
			EnemySnapshot.restore(boss, single)
			_check(trial.used and trial.trial_index == 2 and trial.valve_count() == 4 and trial.frame_center == trial.anchor, "old single shield save gained extra trials or invalid camera framing")
		for valve in range(1, trial.valves.size()): _shoot(valve)
		attack.advance(trial.remaining + 0.01)
		boss.boss_damage_budget = 0
		var damage := boss.take_damage(10)
		_check(is_equal_approx(damage, 18), "shield-break counterattack retained armor or burst limits")
		var opening_budget := trial.opening_damage_remaining
		var burst := boss.take_damage(1e9)
		_check(is_equal_approx(burst, opening_budget) and boss.take_damage(1e9) == 0, "opening damage skipped directly into the next shield")
		attack.advance(0.01)
		_check(not trial.busy() and boss.boss_damage_budget == 0 and boss.is_targetable(), "spent opening left a dead window or a preloaded burst")
		if index < 2:
			var until_next: float = boss.health / boss.max_health - trial.profile.health_thresholds[index + 1]
			_check(until_next * boss.data.boss_guard_recharge_seconds >= 8, "Hell has no real combat interval between shields")
		var before_recovery := boss.health
		boss._physics_process(0.5)
		boss.take_damage(1e9)
		_check(before_recovery - boss.health <= boss.max_health * 0.5 / boss.data.boss_guard_recharge_seconds + 0.01, "normal armor after a shield allowed another unbounded burst")
		_check(trial.completed_mask == (1 << (index + 1)) - 1 and not trial.busy(), "Hell repeated or omitted a completed shield")
	_check(trial.used, "third Hell shield was not final")
	boss.boss_damage_budget = boss.max_health
	boss.take_damage(1e9)
	_check(boss.health <= 0, "all shields completed but King remained immortal")
	# Tracking follows Denti; the orange lock never follows a subsequent move.
	await _fresh()
	game.player.global_position = trial.stance(0)
	attack.advance(trial.remaining * 0.5)
	var first_aim := trial.aim
	game.player.global_position = trial.stance(1)
	attack.advance(trial.remaining)
	var locked := trial.aim
	var endpoint := trial.destination
	_check(locked != first_aim and trial.hit_valve == 1, "tracking did not react to the second position")
	game.player.global_position += locked.orthogonal() * 70
	attack.advance(trial.profile.lock_seconds * 0.4)
	_check(trial.aim == locked and trial.destination == endpoint and not trial.valves[1].broken, "locked warning moved or broke a valve early")
	# Real root-level reload preserves the already announced beam and valve map.
	game._save_run()
	var remaining := trial.remaining
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	game.get_node("Enemies").set_physics_process(false)
	game.player.set_physics_process(false)
	boss = game.boss
	attack = boss.acid_king_encounter
	trial = attack.pressure
	_check(trial.state == KingPressureTrial.State.LOCKED and trial.aim == locked and trial.destination == endpoint and absf(trial.remaining - remaining) < 0.08, "actual reload changed the locked shot or its warning duration")
	var frozen := trial.save_data()
	await process_frame
	await process_frame
	_check(trial.save_data() == frozen, "pause advanced the aim/beam clock")
	# Hiding behind a valve does not avoid dodging: the ray penetrates the valve.
	await _fresh()
	var ray := trial.anchor.direction_to(trial.valves[0].at)
	game.player.global_position = trial.valves[0].at + ray * 75
	attack.advance(trial.remaining + trial.profile.lock_seconds + 0.01)
	_check(trial.valves[0].broken and game.player.stats.health < 10000, "standing behind a valve incorrectly provided cover from the penetrating ray")
	# A dash crossing a locked ray is tested along the whole movement sweep.
	await _fresh()
	game.player.global_position = trial.stance(0)
	attack.advance(trial.remaining + trial.profile.lock_seconds)
	var center := trial.stance(0)
	game.player.motion_start = center - trial.aim.orthogonal() * 150
	game.player.motion_end = center + trial.aim.orthogonal() * 150
	game.player.global_position = game.player.motion_end
	game.player.motion_tick = Engine.get_physics_frames()
	game.player.dash_motion_seconds = 0.16
	game.player.dash_moved = true
	attack.advance(0.16)
	_check(game.player.stats.health < 10000, "dash tunneled through the active acid ray")
	# Deliberate misses lead to a warned finisher, then return to ordinary combat.
	await _fresh()
	for attempt in trial.profile.valves + trial.profile.extra_attempts:
		game.player.global_position = trial.anchor + Vector2(200, 0)
		attack.advance(trial.remaining)
		_check(trial.hit_valve == -1, "miss fixture unexpectedly aligned with a valve")
		game.player.global_position += Vector2(0, 90)
		attack.advance(trial.remaining + 0.01)
		attack.advance(trial.remaining + trial.profile.recoil_seconds + 0.001)
	_check(trial.state == KingPressureTrial.State.BLAST_WARNING and trial.remaining_valves() == 3, "missed attempts did not announce the finisher")
	attack.advance(trial.remaining + 0.01)
	_check(not trial.blocks_damage() and not attack.spit.entries.is_empty(), "failure stalled the fight instead of releasing the warned finisher")
	# Old combat saves finish their announced original moves without a new task.
	var old := EnemySnapshot.capture(boss)
	old.acid_king.version = 2
	old.acid_king.erase("pressure")
	EnemySnapshot.restore(boss, old)
	_check(trial.used and not trial.blocks_damage(), "legacy King save inserted an unannounced new examination")
	for bad in [{"valves": [{}]}, {"aim": [0]}, {"state": "bad"}, {"used": 1}]:
		_check(RunSaveData.normalize({"wave": 15, "player": {}, "enemies": [{"acid_king": {"pressure": bad}}]}).is_empty(), "malformed pressure state entered the runtime")
	session.clear_run()
	if failures.is_empty(): print("PASS king_pressure_trial: movement-only valve breaks, tracking/locking, readable baseline dodges, penetrating/swept rays, backfire, exposure, root save/resume, failure and legacy transition")
	finish(0 if failures.is_empty() else 1)
