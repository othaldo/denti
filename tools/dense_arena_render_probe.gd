extends SceneTree

var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/dense_arena_probe.json"
	session.test_save_path = session.save_path
	session.test_scenario_id = &"dense_combat"
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for mode in ["full", "no_enemy_overlays", "no_item_evolution_visuals", "no_damage_text"]:
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		var samples: Array[float] = []
		var calls := 0.0
		var started := Time.get_ticks_usec()
		var previous := started
		while Time.get_ticks_usec() - started < 4500000:
			await process_frame
			if mode == "no_enemy_overlays":
				for enemy: Enemy in game.get_node("Enemies").get_children():
					RenderingServer.canvas_item_clear(enemy.get_canvas_item())
			elif mode == "no_item_evolution_visuals":
				game.items.visible = false
				for weapon: WeaponInstance in game.player.loadout.get_children():
					if weapon.evolution != null:
						weapon.evolution.visible = false
			elif mode == "no_damage_text":
				game.get_node("DamageNumbers").visible = false
			var now := Time.get_ticks_usec()
			if now - started > 1500000:
				samples.append(float(now - previous) / 1000.0)
				calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			previous = now
		var total := 0.0
		for sample in samples:
			total += sample
		samples.sort()
		var result := {"scenario": mode, "frame_ms_mean": total / samples.size(), "frame_ms_p95": samples[floori(samples.size() * 0.95)], "draw_calls_mean": calls / samples.size()}
		results.append(result)
		print(JSON.stringify(result))
		game.free()
	var label := "local"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=").validate_filename()
	var file := FileAccess.open("res://docs/dense_arena_render_%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify({"samples": results, "adapter": RenderingServer.get_video_adapter_name()}, "\t"))
	session.test_scenario_id = &""
	quit()
