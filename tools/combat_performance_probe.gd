extends SceneTree

# Run with rendering enabled and no --fixed-fps; headless measures CPU only.
var game: Node2D
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://combat_performance_probe.json"
	session.resume_requested = false
	session.clear_run()
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	AudioServer.set_bus_mute(0, true)
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	seed(20261003)
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.player.stats.max_health = 1e9
	game.player.stats.health = 1e9
	game.player.loadout.restore([])
	if OS.get_cmdline_user_args().has("--sustained"):
		await _sustained()
		_write_report()
		session.clear_run()
		quit()
		return
	await _measure("idle")
	var center: Vector2 = game.player.global_position
	for index in 400:
		game._create_enemy(WaveController.PLAQUE, center + Vector2(-850 + index % 25 * 70, -480 + index / 25 * 60))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_physics_process(false)
		enemy.health = 1e9
		enemy.max_health = 1e9
	var stress_weapon: WeaponData = WeaponCatalog.by_id(&"water_jet").duplicate()
	stress_weapon.range_tiers = PackedFloat32Array([100000, 100000, 100000, 100000])
	stress_weapon.pierce_tiers = PackedInt32Array([10000, 10000, 10000, 10000])
	stress_weapon.knockback_tiers = PackedFloat32Array([0, 0, 0, 0])
	stress_weapon.projectile_speed = 70
	for index in 360:
		var projectile: WeaponProjectile = load("res://scenes/game/weapon_projectile.tscn").instantiate()
		game.get_node("Projectiles").add_child(projectile)
		projectile.launch(center + Vector2(-580 + index % 30 * 38, -260 + index / 30 * 42), Vector2.RIGHT, 1, stress_weapon, game.items, false, 4)
	await _measure("400_enemies_360_player_projectiles")
	game._clear_combat()
	await process_frame
	for index in 1800:
		game._spawn_loot(center + Vector2(-570 + index % 60 * 19, -300 + index / 60 * 20), &"xp" if index % 2 == 0 else &"coin", 1)
	await _measure("1800_loot")
	for drop in game.get_node("Loot").get_children():
		drop.queue_free()
	await process_frame
	game.wave.current_wave = 20
	game.wave.active = true
	game.wave.set_process(false)
	game.wave.remaining = 1000
	for index in 200:
		game._create_enemy(WaveController.PLAQUE, center + Vector2.RIGHT.rotated(TAU * index / 200.0) * (250 + index % 5 * 30))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 1e9
		enemy.max_health = 1e9
	var loadout: Array[Dictionary] = []
	for id in ["toothpick_spear", "plaque_scaler", "floss_whip", "cavity_grinder", "prophylaxis_polisher", "interdental_brush"]:
		loadout.append({"id": id, "tier": 4})
	game.player.loadout.restore(loadout)
	await _measure("200_moving_enemies_6_contact_weapons")
	# Independent CPU measurement: a large AoE burst, then window expiration.
	var stats := RunTelemetry.new()
	stats.begin_wave(1)
	var started := Time.get_ticks_usec()
	for tick in 10:
		stats.tick(0.5)
		for hit in 400:
			stats.record_damage(1.0, &"probe")
	stats.tick(10)
	results.append({"scenario": "telemetry_4000_hits_and_expiration", "cpu_ms": (Time.get_ticks_usec() - started) / 1000.0, "damage": stats.total_damage, "remaining_dps": stats.recent_dps()})
	_write_report()
	session.clear_run()
	quit()

func _write_report() -> void:
	var label := "local"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=").validate_filename()
	var report := {"label": label, "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "display": DisplayServer.get_name(), "viewport": str(root.size), "samples": results}
	var file := FileAccess.open("res://docs/combat_performance_%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))

func _sustained() -> void:
	var session: Node = root.get_node("GameSession")
	DisplayServer.window_set_size(Vector2i(2400, 1080))
	root.content_scale_size = Vector2i(1040, 600)
	session.graphics_mode = session.GraphicsMode.ECONOMY if OS.get_cmdline_user_args().has("--economy") else session.GraphicsMode.FULL
	session.apply_graphics()
	game.wave.difficulty_id = &"hard"
	game.wave.current_wave = 18
	var loadout: Array[Dictionary] = []
	var trinity := OS.get_cmdline_user_args().has("--trinity")
	if trinity:
		game.wave.difficulty_id = &"normal"
		game.wave.current_wave = 16
		loadout.append({"id": "trinity_brush", "tier": 4})
		for index in 2:
			loadout.append({"id": "magic_toothbrush", "tier": 4})
	else:
		for index in 6:
			loadout.append({"id": "water_jet", "tier": 4})
	game.player.loadout.restore(loadout)
	for item in ShopController.CATALOG:
		var wanted := item.effect_kind in [&"chain", &"water_puddle", &"conductive_wet", &"splash", &"magnet"] or trinity and item.effect_kind in [&"crit_beam", &"crit_burst"]
		if item.weapon_data == null and item.rarity_tier <= 2 and wanted:
			game.items.acquire(item)
	game.player.stats.damage_bonus = 100
	game.player.stats.ranged_damage = 35
	game.player.stats.attack_speed = 80
	game.player.stats.crit_chance = 0.35
	game._start_combat_wave()
	if trinity:
		# Keep the arena crowded rather than benchmarking an already-cleared wave.
		for number in 110:
			var data: EnemyData = WaveController.ACID_SPITTER if number % 4 == 0 else WaveController.PLAQUE
			game._create_enemy(data, game.player.global_position + Vector2.RIGHT.rotated(number * TAU / 110) * (280 + number % 5 * 40))
			var enemy: Enemy = game.get_node("Enemies").get_child(-1)
			enemy.health = 1e9
			enemy.max_health = 1e9
		for number in 1200:
			game._spawn_loot(game.player.global_position + Vector2(-750 + number % 60 * 25, -400 + number / 60 * 40), &"xp" if number % 2 == 0 else &"coin", 1)
	var scenario := "dense_wave_17_trinity" if trinity else "sustained_wave_19_hard"
	await _measure("%s_%s" % [scenario, "economy" if session.economy_graphics() else "full"], 20000000)
	var started := Time.get_ticks_usec()
	game._save_run()
	var save_ms := (Time.get_ticks_usec() - started) / 1000.0
	var saved: Dictionary = session.load_run()
	results.append({"scenario": "sustained_save", "save_ms": save_ms, "bytes": FileAccess.get_file_as_string(session.save_path).length(), "pending_levels": game.rewards.pending_levels, "damage_buckets": game.telemetry.damage_events.size(), "kills": game.telemetry.kills, "damage": game.telemetry.total_damage, "peak_enemies": game.telemetry.wave_peak_enemies, "owned_items": game.items.owned, "saved_enemies": saved.get("enemies", []).size(), "saved_loot": saved.get("loot", []).size()})

func _measure(label: String, duration_us: int = 4000000) -> void:
	var warmup := Time.get_ticks_msec()
	while Time.get_ticks_msec() - warmup < 500:
		await process_frame
	var frames: Array[float] = []
	var draw_calls := 0.0
	var process_ms := 0.0
	var physics_ms := 0.0
	var started := Time.get_ticks_usec()
	var previous := started
	while Time.get_ticks_usec() - started < duration_us:
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - previous) / 1000.0)
		previous = now
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000
		physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
	frames.sort()
	var mean := 0.0
	for frame in frames:
		mean += frame
	var record := {"scenario": label, "frames": frames.size(), "frame_ms_mean": mean / frames.size(), "frame_ms_p95": frames[floori((frames.size() - 1) * 0.95)], "frame_ms_max": frames[-1], "draw_calls_mean": draw_calls / frames.size(), "process_ms_mean": process_ms / frames.size(), "physics_ms_mean": physics_ms / frames.size(), "enemies": game.get_node("Enemies").get_child_count(), "player_projectiles": game.get_node("Projectiles").get_child_count(), "loot": game.get_node("Loot").get_child_count()}
	results.append(record)
	print(JSON.stringify(record))
