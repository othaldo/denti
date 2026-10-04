extends SceneTree

var game: Node2D
var samples: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/enemy_attack_probe.json"
	session.resume_requested = false
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.health = 1e9
	game.player.stats.max_health = 1e9
	for index in 110:
		game._create_enemy(WaveController.BACTERIA, game.player.global_position + Vector2(-400 + index % 22 * 38, -160 + index / 22 * 70))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_physics_process(false)
		enemy.set_process(false)
		enemy.inflicted_statuses.clear()
		enemy.special_direction = Vector2.RIGHT
		enemy.special_phase = Enemy.SpecialPhase.WARNING
		enemy.special_timer = enemy.data.warning_time * 0.5
	await _measure("110_bacteria_warning")
	for enemy: Enemy in game.get_node("Enemies").get_children():
		enemy._activate_special()
	await _measure("110_bacteria_active")
	# Repeated volleys exercise acquisition, launch, retirement and reuse.
	var parent: Node2D = game.get_node("EnemyProjectiles")
	var started := Time.get_ticks_usec()
	for cycle in 100:
		EnemyProjectilePatterns.fire_aimed_fan(parent, Vector2.ZERO, Vector2.RIGHT, 9, 100, 1, null)
		for shot: AcidProjectile in parent.get_children():
			shot.lifetime = 0.0
			shot._physics_process(0.0)
		await process_frame
	samples.append({"scenario": "100_nine_shot_volleys", "elapsed_ms": float(Time.get_ticks_usec() - started) / 1000.0})
	for pooled in [false, true]:
		var comparison: Node2D = EnemyProjectilePool.new() if pooled else Node2D.new()
		root.add_child(comparison)
		started = Time.get_ticks_usec()
		for cycle in 250:
			EnemyProjectilePatterns.fire_aimed_fan(comparison, Vector2.ZERO, Vector2.RIGHT, 9, 100, 1, null)
			for shot: AcidProjectile in comparison.get_children():
				shot.lifetime = 0.0
				shot._physics_process(0.0)
			await process_frame
		samples.append({"scenario": "250_volleys_%s" % ("pooled" if pooled else "allocated"), "elapsed_ms": float(Time.get_ticks_usec() - started) / 1000.0})
		comparison.free()
	var label := "local"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):
			label = arg.trim_prefix("--label=").validate_filename()
	var file := FileAccess.open("res://docs/enemy_attack_%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "samples": samples}, "\t"))
	game.free()
	quit()

func _measure(label: String) -> void:
	var frames: Array[float] = []
	var draws := 0.0
	var started := Time.get_ticks_usec()
	var previous := started
	while Time.get_ticks_usec() - started < 3500000:
		for enemy: Enemy in game.get_node("Enemies").get_children():
			enemy._process_special(0.0, Vector2.RIGHT)
		await process_frame
		var now := Time.get_ticks_usec()
		if now - started > 500000:
			frames.append(float(now - previous) / 1000.0)
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		previous = now
	frames.sort()
	var sum := 0.0
	for frame in frames:
		sum += frame
	var result := {"scenario": label, "frame_ms_mean": sum / frames.size(), "frame_ms_p95": frames[floori(frames.size() * 0.95)], "draw_calls_mean": draws / frames.size(), "frames": frames.size()}
	samples.append(result)
	print(JSON.stringify(result))
