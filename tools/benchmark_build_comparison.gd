extends "res://tests/support/test_runtime.gd"

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const PROBE_GAME = preload("res://tools/balance/comparison_game.gd")
const PROBE_PLAYER = preload("res://tools/balance/comparison_player.gd")
const PROBE_SOUND = preload("res://tools/balance/comparison_sound.gd")
const MAX_BOSS_SECONDS := 90.0
const DANGER_DISTANCE := 120.0
const ORBIT_RADIUS := Vector2(480, 280)
var _combat_seed := 0


func _initialize() -> void:
	call_deferred("_run")


func _arguments(key: String, defaults: Array) -> Array:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--" + key + "="):
			return Array(argument.get_slice("=", 1).split(",", false))
	return defaults


func _run() -> void:
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string,
		"hz": 60, "difficulty": "normal", "setups": {}, "samples": []}
	var waves := _arguments("waves", PROFILES.WAVES)
	var builds := _arguments("builds", PROFILES.BUILDS.keys())
	var modes := _arguments("modes", PROFILES.MODES)
	var movements := _arguments("movements", PROFILES.MOVEMENTS)
	var seeds := _arguments("seeds", PROFILES.SEEDS)
	for wave_value in waves:
		var number := int(wave_value)
		if number not in PROFILES.WAVES:
			push_error("Unsupported checkpoint: " + str(number))
			finish(1)
			return
		for build_value in builds:
			var build := str(build_value)
			if not PROFILES.BUILDS.has(build):
				push_error("Unknown build: " + build)
				finish(1)
				return
			for mode_value in modes:
				var mode := str(mode_value)
				if mode not in PROFILES.MODES:
					push_error("Unknown mode: " + mode)
					finish(1)
					return
				var config: Dictionary = PROFILES.setup(build, number, mode)
				var key := "%d/%s/%s" % [number, build, mode]
				report.setups[key] = config
				for movement_value in movements:
					var movement := str(movement_value)
					if movement not in PROFILES.MOVEMENTS:
						push_error("Unknown movement: " + movement)
						finish(1)
						return
					for seed_value in seeds:
						var sample := await sample_combat(config, movement, int(seed_value))
						sample["setup"] = key
						report.samples.append(sample)
						print("%s %s seed %d: %s %.1fs; HP %.1f; taken %.1f; healed %.1f" % [key, movement, int(seed_value), sample.outcome, sample.seconds, sample.health_end, sample.damage_taken, sample.healing])
	var output := str(_arguments("output", ["res://docs/balance_build_comparison.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write " + output)
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	finish()


func make_game(config: Dictionary):
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://build_comparison_unused.json"
	session.resume_requested = false
	session.pending_start_weapon_id = &""
	session.selected_story_mode = false
	session.selected_difficulty_id = &"normal"
	session.test_scenario_id = &""
	session.graphics_mode = session.GraphicsMode.FULL
	session.ui_sounds = false
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var game = load("res://scenes/game/game.tscn").instantiate()
	game.set_script(PROBE_GAME)
	game.probe_seed = _combat_seed
	game.get_node("Player").set_script(PROBE_PLAYER)
	game.get_node("Sound").set_script(PROBE_SOUND)
	root.add_child(game)
	current_scene = game
	paused = true
	game.choice_panel.hide()
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.weapon_mastery.eligible = false
	game.wave.set_process(false)
	game.wave.current_wave = int(config.wave)
	game.wave.difficulty_id = &"normal"
	game.wave.elite_counts.assign(WaveController.elite_groups_for_wave(int(config.wave)))
	game.wave.duration = WaveController.duration_for_wave(int(config.wave))
	game.wave.remaining = game.wave.duration
	game.wave.active = true
	game.rewards.begin_wave()
	game.player.position = game.arena.arena_size / 2.0
	game.player.loadout.restore(config.equipment)
	for key: String in config.stats:
		game.player.stats.set(key, config.stats[key])
	for id: String in config.items:
		assert(game.items.acquire(ItemCatalog.by_id(StringName(id))), "Invalid item package")
	game.player.stats.health = game.player.stats.max_health
	config["effective_stats"] = game.player.stats.to_save_data().duplicate(true)
	game.player.stats.dodge_rng.seed = 987654321
	game.items.on_wave_start()
	game.player.dash.reset_wave()
	game.music.stop_music()
	game.player.attack_performed.disconnect(game.sound.play_attack)
	return game


func sample_combat(config: Dictionary, movement: String, sample_seed: int, seconds_limit: float = -1.0) -> Dictionary:
	var plan: Dictionary = PROFILES.spawn_plan(int(config.wave), sample_seed)
	_combat_seed = sample_seed + 1000003
	seed(_combat_seed)
	var game = make_game(config)
	if movement == "orbit": game.player.position += Vector2(ORBIT_RADIUS.x, 0)
	game.wave.current_profile_id = StringName(plan.profile)
	game.telemetry.begin_wave(int(config.wave), StringName(plan.profile))
	var healing := {"actual": 0.0, "overheal": 0.0}
	game.player.stats.healed.connect(func(amount: float, overheal: float):
		healing.actual += amount
		healing.overheal += overheal)
	var start_health: float = game.player.stats.health
	var minimum_health := start_health
	var close_frames := 0
	var target_frames := 0.0
	var distance_travelled := 0.0
	var max_step_distance := 0.0
	var event_index := 0
	var frames := 0
	var limit := MAX_BOSS_SECONDS if WaveController.is_boss_wave(int(config.wave)) else float(plan.duration)
	if seconds_limit > 0: limit = minf(limit, seconds_limit)
	var events: Array = plan.events
	while frames < roundi(limit * 60.0):
		await physics_frame
		var elapsed := float(frames) / 60.0
		game.wave.remaining = maxf(float(plan.duration) - elapsed, 0.0)
		game.wave.goblin_checked = game.wave.remaining <= game.wave.goblin_profile.arrival_remaining
		var before: Vector2 = game.player.position
		game.player.probe_direction = movement_direction(game, movement, elapsed)
		while event_index < events.size() and int(events[event_index].frame) <= frames:
			# Per-request seeding prevents a different kill/crit count changing placement rolls.
			seed(sample_seed + event_index * 104729)
			var event: Dictionary = events[event_index]
			match event.kind:
				"enemy": game._spawn_enemy(event.data)
				"horde": game._spawn_horde(event.data, int(event.count))
				"elite": game._spawn_elite(event.data)
				"goblin": game._spawn_loot_goblin()
			event_index += 1
		paused = false
		await process_frame
		frames += 1
		if OS.get_cmdline_user_args().has("--trace") and frames % 60 == 0:
			print("Probe frame ", frames, " HP ", game.player.stats.health, " boss ", game.boss.health if is_instance_valid(game.boss) else -1)
		var step_distance := before.distance_to(game.player.position)
		distance_travelled += step_distance
		max_step_distance = maxf(max_step_distance, step_distance)
		minimum_health = minf(minimum_health, game.player.stats.health)
		var nearest := INF
		for enemy: Enemy in game.get_node("Enemies").get_children():
			if enemy.health > 0:
				nearest = minf(nearest, game.player.position.distance_to(enemy.position) - enemy.data.radius)
		if nearest <= DANGER_DISTANCE: close_frames += 1
		for weapon: WeaponInstance in game.player.loadout.equipped():
			if nearest <= weapon.data.range_at_tier(weapon.tier): target_frames += weapon.data.hands
		# Finish after physics, like WaveController._process. Queuing bullets for
		# deletion before their last physics step could recycle soon-freed nodes.
		if game.wave.active and frames >= roundi(float(plan.duration) * 60.0) and str(game.probe_outcome).is_empty():
			game.wave.remaining = 0.0
			game.wave.active = false
			game._on_wave_finished(int(config.wave))
		if not str(game.probe_outcome).is_empty(): break
	paused = true
	var elapsed := float(frames) / 60.0
	var summary: Dictionary = game.telemetry.current_wave_summary()
	var result := {"wave": config.wave, "build": config.build, "mode": config.mode,
		"movement": movement, "seed": sample_seed, "spawn_plan": plan.digest,
		"outcome": game.probe_outcome if not str(game.probe_outcome).is_empty() else ("wave_complete" if not WaveController.is_boss_wave(int(config.wave)) and elapsed >= float(plan.duration) else "timeout"),
		"seconds": elapsed, "health_start": start_health, "health_end": game.player.stats.health,
		"health_min": minimum_health, "damage_taken": summary.damage_taken,
		"healing": healing.actual, "overheal": healing.overheal,
		"leech_healing": game.telemetry.enchantment_support.get("leech_healing", 0.0),
		"near_enemy_seconds": float(close_frames) / 60.0,
		"near_enemy_fraction": float(close_frames) / maxi(frames, 1),
		"target_in_range_fraction": target_frames / (maxi(frames, 1) * config.roots),
		"distance_travelled": distance_travelled, "max_step_distance": max_step_distance,
		"kills": summary.kills, "spawns": summary.spawns,
		"spawns_blocked": summary.spawns_blocked, "peak_enemies": summary.peak_enemies_alive,
		"peak_enemy_projectiles": summary.peak_enemy_projectiles,
		"damage_dealt": summary.damage_dealt, "weapon_damage": game.telemetry.weapon_damage.duplicate(),
		"dps": summary.damage_dealt / maxf(elapsed, PROFILES.STEP),
		"proc_damage": game.telemetry.proc_damage.duplicate(),
		"boss_ttk": game.telemetry.last_boss_ttk if game.probe_outcome == "boss_killed" else null,
		"boss_health_fraction": clampf(game.boss.health / game.boss.max_health, 0, 1) if is_instance_valid(game.boss) else 0.0,
		"coins_collected": summary.coins_collected, "xp_collected": summary.xp_collected,
		"pending_levels": game.rewards.pending_levels, "chests_collected": summary.chests_found}
	_stop_audio(game)
	if OS.get_cmdline_user_args().has("--trace"): print("Probe cleanup: ", result.outcome)
	game.wave.active = false
	game.run_flow.enter(RunFlow.Phase.ENDED)
	game._clear_arena(false)
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.queue_free()
	# Let physics/render callbacks release the scene before constructing another.
	await process_frame
	await process_frame
	return result


func movement_direction(game, movement: String, _elapsed: float) -> Vector2:
	if movement == "stationary": return Vector2.ZERO
	# Full-speed ellipse following, with no reaction to enemies/projectiles or dash.
	var center: Vector2 = game.arena.arena_size / 2.0
	var offset: Vector2 = (game.player.position - center) / ORBIT_RADIUS
	var phase := offset.angle() + 0.25
	var desired := center + Vector2(cos(phase), sin(phase)) * ORBIT_RADIUS
	return game.player.position.direction_to(desired)
