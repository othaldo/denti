extends SceneTree

var game: Node2D
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://projectile_performance_probe.json"
	session.resume_requested = false
	session.clear_run()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	seed(20261001)
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.player.loadout.restore([])
	game.player.stats.max_health = 1e9
	game.player.stats.health = 1e9
	game.player.stats.armor = 1e6
	var center: Vector2 = game.player.global_position
	var projectile_scene: PackedScene = load("res://scenes/enemies/acid_projectile.tscn")
	for count in [0, 200, 600, 1000]:
		game._clear_combat()
		for index in count:
			var projectile: AcidProjectile = projectile_scene.instantiate()
			game.get_node("EnemyProjectiles").add_child(projectile)
			var at := center + Vector2(-590 + (index % 35) * 34, -270 + (index / 35) * 18)
			projectile.launch(at, Vector2.RIGHT, 0, 1, game.player, EnemyProjectilePatterns.BOSS_COLOR)
			projectile.lifetime = 1000
		await _measure("visible_bullets_%d" % count)
	game._clear_combat()
	game.wave.current_wave = 20
	game.wave.active = true
	game.wave.remaining = 1000
	game.wave.set_process(false)
	game.player.loadout.restore([{"id": "water_jet", "tier": 4}, {"id": "water_jet", "tier": 4}, {"id": "water_jet", "tier": 4}, {"id": "water_jet", "tier": 4}, {"id": "water_jet", "tier": 4}, {"id": "water_jet", "tier": 4}])
	for index in 200:
		game._create_enemy(WaveController.PLAQUE, center + Vector2.RIGHT.rotated(TAU * index / 200.0) * (250 + index % 5 * 30))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 1e8
		enemy.max_health = 1e8
	game._create_enemy(WaveController.boss_for_wave(20), center + Vector2(300, 0))
	game.boss.health = 1e8
	game.boss.max_health = 1e8
	game.boss.boss_phase = 1
	game.boss._start_boss_phase()
	await _measure("emperor_9_volleys_200_enemies_6_weapons", 4500000)
	var label := "baseline"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=")
	var report := {"label": label, "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "display": DisplayServer.get_name(), "vsync": "disabled", "viewport": str(root.size), "samples": results}
	var file := FileAccess.open("res://docs/projectile_performance_%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	session.clear_run()
	quit()

func _measure(label: String, duration_us: int = 2500000) -> void:
	var warmup := Time.get_ticks_msec()
	while Time.get_ticks_msec() - warmup < 400:
		await process_frame
	var samples: Array[float] = []
	var draw_calls: Array[float] = []
	var peak_bullets := 0
	var start := Time.get_ticks_usec()
	var previous := start
	while Time.get_ticks_usec() - start < duration_us:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		peak_bullets = maxi(peak_bullets, game.get_node("EnemyProjectiles").get_child_count())
	samples.sort()
	var record := {"scenario": label, "frames": samples.size(), "frame_ms_mean": _mean(samples), "frame_ms_p95": samples[floori((samples.size()-1) * 0.95)], "frame_ms_max": samples[-1], "fps": samples.size() * 1e6 / (Time.get_ticks_usec() - start), "draw_calls": _mean(draw_calls), "peak_enemy_bullets": peak_bullets}
	results.append(record)
	print(JSON.stringify(record))

func _mean(values: Array[float]) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / maxi(values.size(), 1)
