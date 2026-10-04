extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var parent := Node2D.new()
	root.add_child(parent)
	var colors: Array[Color] = [EnemyProjectilePatterns.ACID_COLOR, DentiStatus.COLORS[0], DentiStatus.COLORS[1]]
	var started := Time.get_ticks_usec()
	for index in 600:
		var projectile: AcidProjectile = EnemyProjectilePatterns.PROJECTILE.instantiate()
		parent.add_child(projectile)
		projectile.launch(Vector2(40 + index % 30 * 39, 40 + index / 30 * 31), Vector2.RIGHT, 0, 1, null, colors[index % colors.size()])
		projectile.lifetime = 100000
	var spawn_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var frames: Array[float] = []
	var calls := 0.0
	var begin := Time.get_ticks_usec()
	var previous := begin
	while Time.get_ticks_usec() - begin < 5000000:
		await process_frame
		var now := Time.get_ticks_usec()
		if now - begin > 500000:
			frames.append(float(now - previous) / 1000.0)
			calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		previous = now
	var sum := 0.0
	for frame in frames:
		sum += frame
	frames.sort()
	var report := {"scenario": "600_stationary_enemy_projectiles_3_status_colors", "spawn_cpu_ms": spawn_ms, "frame_ms_mean": sum / frames.size(), "frame_ms_p95": frames[floori(frames.size() * 0.95)], "draw_calls_mean": calls / frames.size(), "frames": frames.size(), "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name()}
	var label := "local"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=").validate_filename()
	var file := FileAccess.open("res://docs/projectile_pressure_%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	parent.free()
	quit()
