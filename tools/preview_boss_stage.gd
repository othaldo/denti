extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://boss_stage_preview.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.pending_start_weapon_id = &"magic_toothbrush"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	paused = true
	game.player.loadout.restore([])
	game.hud.fps_label.visible = false
	var output := "res://.godot/boss_stage_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		game._clear_arena(false)
		await process_frame
		game.run_flow.enter(RunFlow.Phase.COMBAT)
		game.wave.current_wave = 10
		game.wave.active = true
		game.wave.remaining = 25
		game.player.global_position = game.arena.arena_size * 0.5
		game.player.get_node("Camera2D").force_update_scroll()
		await process_frame
		game._create_enemy(EnemyCatalog.CAVITY_PRINCE, game.player.global_position + Vector2(0, -90))
		var boss: Enemy = game.boss
		boss.boss_phase = 2
		boss.health = boss.max_health / 3
		boss.boss_phase_timer = 0
		var attack := boss.caramel_encounter
		attack.advance(0.01)
		attack.advance(attack.overload.profile.warning_seconds + 1.8)
		game._refresh_hud()
		await _capture(output.path_join("hearts_%dx%d.png" % [extent.x, extent.y]))
		if extent.x == 1280:
			for heart in attack.overload.live_pylons():
				game.player.global_position = heart.global_position + Vector2(60, 0)
				heart.take_damage(1000)
			attack.advance(0.01)
			game.player.global_position = boss.global_position + Vector2(90, 50)
			game.player.get_node("Camera2D").force_update_scroll()
			game._refresh_hud()
			await _capture(output.path_join("success.png"))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	for sample in [[&"normal", 0.5, "lesson"], [&"hard", 2.0 / 3, "couriers"]]:
		game._clear_arena(false)
		await process_frame
		game.run_flow.enter(RunFlow.Phase.COMBAT)
		game.wave.difficulty_id = sample[0]
		game.player.stats.health = game.player.stats.max_health
		game.player.global_position = game.arena.arena_size * 0.5
		game.player.get_node("Camera2D").force_update_scroll()
		await process_frame
		game._create_enemy(EnemyCatalog.CAVITY_PRINCE, game.player.global_position + Vector2(0, -90))
		var boss: Enemy = game.boss
		boss.boss_phase = 1
		boss.health = boss.max_health * sample[1]
		boss.boss_phase_timer = 0
		boss.caramel_encounter.advance(0.01)
		boss.caramel_encounter.advance(boss.caramel_encounter.overload.profile.warning_seconds + 0.75)
		game._refresh_hud()
		await _capture(output.path_join(str(sample[2]) + ".png"))
	session.clear_run()
	finish()

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("Preview: ", path)
