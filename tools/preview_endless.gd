extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_endless.json"
	session.report_dir = "user://preview_endless_reports"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots/endless"))
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	game.coins = 120
	game.level = 40
	game.wave.current_wave = 20
	game.wave.remaining = 0.0
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}, {"id": "turbo_drill", "tier": 4}, {"id": "water_jet", "tier": 4}])
	game.telemetry.elapsed = 960.0
	game.telemetry.kills = 2200
	game.telemetry.bosses_defeated = 4
	game.telemetry.coins_collected = 1200
	game.telemetry.xp_collected = 2500
	game.telemetry.total_damage = 250000.0
	game._finish_run()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		await _capture("victory_%dx%d.png" % [extent.x, extent.y])
	game.choice_panel.buttons[3].pressed.emit()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	game._on_shop_continue()
	paused = true
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	game.wave.current_wave = 29
	game.telemetry.begin_wave(30)
	game.rewards.begin_wave()
	game.wave.start_next_wave()
	var members := BossEncounter.remaining(game.get_node("Enemies"))
	members[0].position = game.player.position + Vector2(-150, -110)
	members[1].position = game.player.position + Vector2(200, -20)
	game._refresh_hud()
	await _capture("double_boss_wave30.png")
	game.wave.active = false
	game._on_wave_finished(30)
	for member in members:
		member.sync_inflammation_aura(0.0)
	game._refresh_hud()
	await _capture("double_boss_inflamed.png")
	session.clear_run()
	quit(0)

func _capture(filename: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/endless/" + filename)
