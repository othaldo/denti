extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--fixed-fps"):
		push_error("Run startup timing requires a native window and real frame timing (no --headless/--fixed-fps).")
		finish(1)
		return
	Engine.max_fps = 60
	root.content_scale_size = Vector2i(960, 540)
	DisplayServer.window_set_size(Vector2i(960, 540))
	root.size = Vector2i(960, 540)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://scene_delay_probe.json"
	session.report_dir = "user://scene_delay_reports"
	session.selected_story_mode = false
	session.resume_requested = false
	session.reduced_ui_motion = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _idle(20)
	await _measure("new_run", menu._start_new_game.bind(&"normal"))
	var game: Node2D = current_scene
	game.choice_panel._on_choice_pressed(0)
	await _idle(48)
	game._save_run()
	game.game_menu._to_main_menu()
	await _idle(48)
	menu = current_scene
	await _measure("continue_run", menu._continue_game)
	session.clear_run()
	finish()

func _idle(frames: int) -> void:
	for frame in frames:
		await process_frame
		await RenderingServer.frame_post_draw

func _measure(id: String, action: Callable) -> void:
	var service: DentiSceneTransition = root.get_node("SceneTransitions")
	var started := Time.get_ticks_usec()
	action.call()
	var handler_ms := (Time.get_ticks_usec() - started) / 1000.0
	var first_render := 0.0
	var scene_frame := 0.0
	var worst := 0.0
	var previous := started
	var samples: Array = []
	for frame in 48:
		await process_frame
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var delta := (now - previous) / 1000.0
		worst = maxf(worst, delta)
		previous = now
		if frame == 0:
			first_render = (now - started) / 1000.0
		if scene_frame == 0.0 and current_scene != null and current_scene.name == "Game":
			scene_frame = (now - started) / 1000.0
		if frame < 6:
			samples.append({"ms": snappedf((now-started)/1000.0, 0.1), "progress": service.snapshot.material.get_shader_parameter("progress")})
	print(JSON.stringify({"case": id, "handler_ms": handler_ms, "first_feedback_ms": first_render, "scene_frame_ms": scene_frame, "worst_frame_ms": worst, "samples": samples}))
