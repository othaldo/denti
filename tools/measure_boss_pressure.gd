extends "res://tests/support/test_runtime.gd"
## Reproducible current full encounters. Run with -- --seeds=13579,24680,112233.
const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const GAME = preload("res://tools/balance/comparison_game.gd")
const PLAYER = preload("res://tools/balance/boss_pressure_player.gd")
const PILOT = preload("res://tools/balance/boss_pressure_pilot.gd")
const SENSOR = preload("res://tools/balance/boss_pressure_observation.gd")
const SOUND = preload("res://tools/balance/boss_pressure_sound.gd")
const KING_PILOT = preload("res://tools/balance/king_pressure_pilot.gd")
var frame := 0
var hits: Array[Dictionary] = []
var warnings: Array[float] = []
var damage_by_source: Dictionary = {}
var seen_actors: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func argument(key: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--" + key + "="): return arg.get_slice("=", 1)
	return fallback

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	if argument("attack-only", "false") == "true":
		for wave_text in argument("waves", "5,10,15,20").split(","):
			if int(wave_text) != 10:
				push_error("--attack-only is a Don-only control; use --waves=10")
				finish(1)
				return
	var rows: Array = []
	for wave_text in argument("waves", "5,10,15,20").split(","):
		for difficulty in argument("difficulties", "normal,hell").split(","):
			for build in argument("builds", "melee_single,ranged_single").split(","):
				for policy in argument("policies", "seeker,reactive").split(","):
					for seed_text in argument("seeds", "13579,24680,112233").split(","):
						var row := await sample(int(wave_text), difficulty, build, policy, int(seed_text))
						rows.append(row)
						print("BOSS PRESSURE ", JSON.stringify(row))
						var file := FileAccess.open(argument("output", "res://.godot/boss_pressure.json"), FileAccess.WRITE)
						file.store_string(JSON.stringify({"schema": 1, "engine": Engine.get_version_info().string, "hz": Engine.physics_ticks_per_second, "time_scale": Engine.time_scale,
							"method": "Full real encounters; six stage-tier weapons, base profile, no items/affixes, armor retained. Open arena, 280-unit start. Diagnostic 100000 HP reserve with reference max HP used for normal hit protection. No dash. Real-time SFX callbacks suppressed to keep their throttling out of global combat RNG. Objective knowledge explicit; King beam uses a dedicated route pilot in every policy. Seeker does not dodge outside that puzzle; circle only orbits; reactive reads visible warnings with regular-profile delay. Gross damage is not a human survival rate. Threatened fraction is the regular pilot's standing risk >= 1 sampled at 10 Hz; a bot-specific proxy, not an objective difficulty score.",
							"control_method": "When attack_only is true, the control replaces full combat: no player weapons, fixed boss phase 2, all trials disabled, 30-second observation when --seconds=30; companions remain alive and attack. Build metadata describes the original positioning/stats profile.",
							"arguments": OS.get_cmdline_user_args(), "samples": rows}, "\t") + "\n")
						file.close()
	root.get_node("GameSession").clear_run()
	finish()

func sample(wave: int, difficulty: String, build: String, policy: String, sample_seed: int) -> Dictionary:
	paused = true
	var session := root.get_node("GameSession")
	session.save_path = "user://boss_pressure_unused.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.selected_difficulty_id = StringName(difficulty)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	game.set_script(GAME)
	game.probe_seed = sample_seed
	game.get_node("Player").set_script(PLAYER)
	game.get_node("Sound").set_script(SOUND)
	root.add_child(game)
	current_scene = game
	var setup: Dictionary = PROFILES.setup(build, wave, "base")
	game.player.loadout.restore(setup.equipment)
	for stat: String in setup.stats: game.player.stats.set(stat, setup.stats[stat])
	var normal_hp: float = game.player.stats.max_health
	game.player.reference_max_health = normal_hp
	game.player.stats.max_health = 100000
	game.player.stats.health = 100000
	game.debug_start_wave(wave)
	paused = true
	await process_frame
	var boss: Enemy = game.boss
	var attack_only := argument("attack-only", "false") == "true"
	if attack_only:
		# A fixed-duration pressure control: all late normal patterns, no health
		# progression or objective interruption, and no minion kills by weapons.
		boss.caramel_encounter.overload.used = true
		boss.boss_phase = 2
		game.player.loadout.restore([])
	if boss.acid_king_encounter != null and argument("king-guard-seconds", "") != "":
		# Optional measurement-only candidate. Never mutates the shared Resource.
		boss.data = boss.data.duplicate()
		boss.data.boss_guard_recharge_seconds = float(argument("king-guard-seconds", "60"))
	# Identical legal open-arena starts; never inside the boss's contact circle.
	boss.global_position = game.player.global_position - Vector2(0, 280)
	var boss_name := boss.data.display_name
	var boss_hp := boss.max_health
	var pilot := PILOT.new()
	pilot.configure("regular", "boss", sample_seed)
	pilot.profile = pilot.profile.duplicate()
	# Both policies walk; dash is a separate human skill, not a hidden advantage.
	pilot.profile.uses_dash = false
	var sensor := SENSOR.new()
	var king_pilot := KING_PILOT.new()
	frame = 0
	hits.clear()
	warnings.clear()
	damage_by_source.clear()
	seen_actors.clear()
	game.player.stats.damage_taken.connect(_record_damage)
	var trials: Dictionary = {}
	var task_frames := 0
	var immune_frames := 0
	var minion_frames := 0
	var minion_task_frames := 0
	var moving_frames := 0
	var threatened_frames := 0
	var trial_failures := 0
	var max_frames := int(float(argument("seconds", "150")) * 60)
	var world: Dictionary = {}
	while frame < max_frames and game.probe_outcome == "":
		var task: Node2D
		if boss.caramel_encounter != null: task = boss.caramel_encounter.overload
		elif boss.acid_king_encounter != null: task = boss.acid_king_encounter.pressure
		elif boss.crown_court_encounter != null: task = boss.crown_court_encounter.retinue
		var task_active: bool = task != null and task.busy()
		if task_active:
			task_frames += 1
			var key := str(task.trial_index)
			if not trials.has(key): trials[key] = {"start": frame / 60.0, "seconds": 0.0}
			trials[key].seconds += 1.0 / 60.0
			if task is CaramelOverload and task.state == CaramelOverload.State.BLAST: trials[key].failed = true
			if task is KingPressureTrial and task.state == KingPressureTrial.State.BLAST_WARNING: trials[key].failed = true
			if task is ImperialRetinue and task.state == ImperialRetinue.State.FAILURE: trials[key].failed = true
		if not boss.is_targetable(): immune_frames += 1
		var live_minions := 0
		for enemy: Enemy in game.get_node("Enemies").get_children():
			if enemy.health <= 0 or enemy.is_queued_for_deletion(): continue
			if not seen_actors.has(enemy.get_instance_id()):
				seen_actors[enemy.get_instance_id()] = true
				enemy.attack_performed.connect(_record_warning)
			if enemy.imperial_vassal != null or enemy.caramel_enforcer != null or enemy.acid_collector != null: live_minions += 1
		if live_minions > 0:
			minion_frames += 1
			if task_active: minion_task_frames += 1
		set_goal(game, boss, pilot, build, task)
		var direction := Vector2.ZERO
		if boss.acid_king_encounter != null and boss.acid_king_encounter.pressure.busy() and boss.acid_king_encounter.pressure.remaining_valves() > 0:
			# Beam alignment is a puzzle; use its dedicated geometry-aware walker.
			var goal: Vector2 = king_pilot.destination(boss.acid_king_encounter.pressure)
			direction = game.player.global_position.direction_to(goal) if game.player.global_position.distance_to(goal) > 4 else Vector2.ZERO
		elif policy == "seeker":
			var offset: Vector2 = pilot.target - game.player.global_position
			direction = offset.normalized() * clampf((offset.length() - pilot.stopping_distance) / 35.0, -1, 1)
		elif policy == "circle":
			direction = pilot.goal_direction({"position": game.player.global_position})
		else:
			world = sensor.capture(game, frame) if frame % pilot.profile.decision_ticks == 0 else {}
			direction = pilot.step(frame, world)
		if frame % 6 == 0:
			var pressure_world: Dictionary = sensor.capture(game, frame)
			if pilot.danger(pressure_world, Vector2.ZERO) >= 1.0: threatened_frames += 6
		game.player.probe_direction = direction
		if direction.length() > 0.05: moving_frames += 1
		paused = false
		await physics_frame
		await process_frame
		frame += 1
	paused = true
	var total := 0.0
	for amount: float in damage_by_source.values(): total += amount
	for trial: Dictionary in trials.values():
		if trial.get("failed", false): trial_failures += 1
	var seconds := frame / 60.0
	var row := {"wave": wave, "boss": boss_name, "difficulty": difficulty, "build": build, "tier": setup.tier, "policy": policy, "seed": sample_seed,
		"seconds": seconds, "outcome": game.probe_outcome if game.probe_outcome != "" else ("observed" if attack_only else "timeout"), "attack_only": attack_only, "boss_hp": boss_hp, "boss_hp_remaining": maxf(boss.health, 0), "boss_health_phases": boss.boss_phase + 1, "reference_player_hp": normal_hp, "build_setup": setup,
		"damage": total, "damage_per_second": total / maxf(seconds, 0.01), "hp_bars_lost": total / normal_hp, "damage_by_source": damage_by_source.duplicate(), "hits": hits.duplicate(true),
		"trials": trials.duplicate(true), "trial_failures": trial_failures, "task_seconds": task_frames / 60.0, "immune_seconds": immune_frames / 60.0,
		"minion_seconds": minion_frames / 60.0, "minion_task_seconds": minion_task_frames / 60.0, "moving_fraction": moving_frames / float(maxi(frame, 1)), "threatened_fraction": minf(threatened_frames / float(maxi(frame, 1)), 1), "warning_count": warnings.size()}
	game._clear_arena(false)
	_stop_audio(game)
	game.queue_free()
	await process_frame
	await process_frame
	return row

func set_goal(game, boss: Enemy, pilot: RefCounted, build: String, task: Node2D) -> void:
	var target := boss
	var objective := false
	if task is CaramelOverload:
		for pylon in task.live_pylons():
			if not objective or game.player.global_position.distance_to(pylon.global_position) < game.player.global_position.distance_to(target.global_position):
				target = pylon
				objective = true
	elif task is ImperialRetinue:
		for minion in task.live_minions():
			if not objective or minion.imperial_vassal.profile.role == ImperialVassalData.Role.KEEPER:
				target = minion
				objective = true
	pilot.target = target.global_position
	pilot.stopping_distance = maxf(target.data.radius + 28, 135.0 if build == "melee_single" else 250.0)
	if objective: pilot.stopping_distance = 90.0 if build == "melee_single" else 150.0
	pilot.circle_target = not objective

func _record_warning(kind: StringName) -> void:
	if kind == &"boss_warning": warnings.append(frame / 60.0)

func _record_damage(amount: float) -> void:
	var source := "other"
	for entry in get_stack():
		var path := str(entry.source)
		if str(entry.function) == "try_contact_hit": source = "contact"; break
		if path.ends_with("acid_collector.gd"): source = "Schlacko"; break
		if path.ends_with("caramel_enforcer.gd"): source = "Broesel"; break
		if path.ends_with("imperial_vassal.gd"): source = "retinue"; break
		if path.ends_with("king_acid_wake.gd"): source = "acid_wake"; break
		if path.ends_with("king_pressure_trial.gd"): source = "shield_beam"; break
		if path.ends_with("cloak_encounter.gd"): source = "cloak"; break
		if path.ends_with("caramel_heart_volley.gd"): source = "heart_projectiles"; break
		if path.ends_with("caramel_overload.gd"): source = "ritual_lanes"; break
		if path.ends_with("caramel_encounter.gd") or path.ends_with("caramel_bomb_volley.gd"): source = "caramel"; break
		if path.ends_with("acid_king_encounter.gd"): source = "acid_king"; break
		if path.ends_with("crown_court_encounter.gd"): source = "emperor"; break
		if path.ends_with("player_status_effects.gd"): source = "status"; break
	damage_by_source[source] = float(damage_by_source.get(source, 0)) + amount
	hits.append({"seconds": frame / 60.0, "damage": amount, "source": source})
