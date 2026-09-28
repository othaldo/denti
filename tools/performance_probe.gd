extends SceneTree

const SAMPLE_MS := 2000


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://performance_probe_run.json"
	session.clear_run()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	print("Anzeigetreiber: ", DisplayServer.get_name())

	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._new_game()
	await process_frame
	await process_frame
	var game: Node2D = current_scene
	game.wave.active = false
	await create_timer(0.5).timeout
	await _measure("Fenster, frisches Spiel")

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	await create_timer(0.5).timeout
	await _measure("Vollbild, frisches Spiel")

	game.player.stats.max_health = 1000000.0
	game.player.stats.health = 1000000.0
	for index in 100:
		var angle := TAU * float(index) / 100.0
		game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2.RIGHT.rotated(angle) * 360.0)
	await _measure("Vollbild, 100 Gegner")

	session.clear_run()
	current_scene = null
	game.queue_free()
	await process_frame
	quit()


func _measure(label: String) -> void:
	var start_ms := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - start_ms < SAMPLE_MS:
		await process_frame
		frames += 1
	var elapsed_ms := Time.get_ticks_msec() - start_ms
	print("%s (%s): %.1f FPS gemessen, %.0f FPS laut Godot" % [label, DisplayServer.window_get_size(), float(frames) * 1000.0 / float(elapsed_ms), Engine.get_frames_per_second()])
