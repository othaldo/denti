extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://king_pressure_preview.json"
	session.resume_requested = false
	session.selected_story_mode = false
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.player.loadout.restore([])
	game.hud.fps_label.visible = false
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	var output := "res://.godot/king_pressure_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		game._clear_arena(false)
		for number in game.get_node("DamageNumbers").get_children(): number.free()
		await process_frame
		game.run_flow.enter(RunFlow.Phase.COMBAT)
		game.wave.current_wave = 15
		game.wave.difficulty_id = &"normal"
		game.wave.active = true
		game.wave.remaining = 25
		game.wave.set_process(false)
		game.player.global_position = game.arena.arena_size * 0.5
		game.player.get_node("Camera2D").force_update_scroll()
		await process_frame
		game._create_enemy(EnemyCatalog.CAVITY_KING, game.player.global_position + Vector2(-200, -100))
		var boss: Enemy = game.boss
		boss.boss_phase = 1
		boss.health = boss.max_health * 2 / 3
		boss.boss_phase_timer = 0
		var attack := boss.acid_king_encounter
		attack.advance(0.01)
		var trial := attack.pressure
		attack.advance(trial.remaining)
		game.player.global_position = trial.stance(0)
		game.player.get_node("Camera2D").force_update_scroll()
		attack.advance(trial.remaining)
		game._refresh_hud()
		await _capture(output.path_join("locked_%dx%d.png" % [extent.x, extent.y]))
		game.player.global_position += trial.aim.orthogonal() * 70
		attack.advance(trial.remaining + 0.10)
		game._refresh_hud()
		await _capture(output.path_join("beam_%dx%d.png" % [extent.x, extent.y]))
		if extent.x == 1280:
			attack.advance(trial.remaining + trial.profile.recoil_seconds + 0.001)
			for index in [1, 2]:
				game.player.global_position = trial.stance(index)
				attack.advance(trial.remaining)
				game.player.global_position += trial.aim.orthogonal() * 70
				attack.advance(trial.remaining + 0.01)
				attack.advance(trial.remaining + trial.profile.recoil_seconds + 0.001)
			attack.advance(trial.remaining + 0.05)
			game._refresh_hud()
			await _capture(output.path_join("shield_break.png"))
	for index in 3:
		root.size = Vector2i(1280, 720)
		root.content_scale_size = root.size
		DisplayServer.window_set_size(root.size)
		game._clear_arena(false)
		for number in game.get_node("DamageNumbers").get_children(): number.free()
		await process_frame
		game.run_flow.enter(RunFlow.Phase.COMBAT)
		game.wave.current_wave = 15
		game.wave.difficulty_id = &"hell"
		game.wave.active = true
		game.wave.remaining = 25
		game.player.global_position = game.arena.arena_size * 0.5
		game.player.get_node("Camera2D").force_update_scroll()
		await process_frame
		game._create_enemy(EnemyCatalog.CAVITY_KING, game.player.global_position + Vector2(-200, -100))
		var boss: Enemy = game.boss
		var trial := boss.acid_king_encounter.pressure
		trial.completed_mask = (1 << index) - 1
		boss.health = boss.max_health * trial.profile.health_thresholds[index]
		boss.boss_phase = index
		boss.boss_phase_timer = 0
		boss.acid_king_encounter.advance(0.01)
		boss.acid_king_encounter.advance(trial.remaining)
		game.player.global_position = trial.stance(0)
		game.player.get_node("Camera2D").force_update_scroll()
		boss.acid_king_encounter.advance(trial.remaining)
		game._refresh_hud()
		await _capture(output.path_join("hell_shield_%d.png" % (index + 1)))
	game._clear_arena(false)
	for number in game.get_node("DamageNumbers").get_children(): number.free()
	await process_frame
	game.wave.difficulty_id = &"normal"
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.get_node("Camera2D").force_update_scroll()
	await process_frame
	game._create_enemy(EnemyCatalog.CAVITY_KING, game.player.global_position - Vector2(100, 0))
	var close_boss: Enemy = game.boss
	close_boss.boss_phase = 2
	var close := close_boss.acid_king_encounter
	close.pressure.used = true
	close.begin(close.Attack.STOMP)
	close.advance(0.45)
	game._refresh_hud()
	await _capture(output.path_join("stone_near_warning.png"))
	close.advance(close.remaining + 0.05)
	game._refresh_hud()
	await _capture(output.path_join("stone_near_impact.png"))
	session.clear_run()
	finish()

func _capture(path: String) -> void:
	var game: Node2D = current_scene
	game.boss.acid_king_encounter.pressure._process(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("Preview: ", path)
