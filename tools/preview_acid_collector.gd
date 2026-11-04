extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var session := root.get_node("GameSession")
	session.save_path = "user://preview_acid_collector.json"
	session.resume_requested = false
	session.selected_story_mode = false
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	var output := "res://.godot/acid_collector_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		game._clear_arena(false)
		await process_frame
		await process_frame
		game.run_flow.enter(RunFlow.Phase.COMBAT)
		game.wave.current_wave = 15
		game.wave.difficulty_id = &"hell"
		game.wave.active = true
		game.wave.set_process(false)
		game.player.global_position = game.arena.arena_size * 0.5
		game.player.stats.health = game.player.stats.max_health
		game.player.get_node("Camera2D").force_update_scroll()
		await process_frame
		game._create_enemy(EnemyCatalog.CAVITY_KING, game.player.global_position - Vector2(150, 0))
		var court: AcidKingEncounter = game.boss.acid_king_encounter
		var bounds := court._visible_bounds()
		var visible: Rect2 = game.boss.get_canvas_transform().affine_inverse() * game.boss.get_viewport_rect()
		var art_inset := Vector2(minf(120, visible.size.x * 0.4), minf(125, visible.size.y * 0.4))
		game.boss.global_position = game.boss.global_position.clamp(visible.position + art_inset, visible.end - art_inset)
		court.companion.advance(5.01)
		var actor := court.companion.minion
		actor.health *= 0.7
		actor.global_position = actor.acid_collector._bounded(game.player.global_position + Vector2(155, 60))
		actor.acid_collector.state = AcidCollector.State.FOLLOW
		actor.acid_collector.remaining = 0
		actor.acid_collector.advance(0.01)
		game._refresh_hud()
		await _capture(output.path_join("collector_%dx%d.png" % [extent.x, extent.y]))
		var trial := court.pressure
		game.boss.health = game.boss.max_health * trial.profile.health_thresholds[0]
		court.advance(0.01)
		court.advance(trial.remaining)
		game.player.global_position = trial.stance(0)
		game.player.get_node("Camera2D").force_update_scroll()
		court.advance(trial.remaining)
		game.player.global_position += trial.aim.orthogonal() * 90
		court.advance(trial.remaining + trial.profile.firing_seconds + 0.4)
		trial._process(0)
		game._refresh_hud()
		await _capture(output.path_join("stream_%dx%d.png" % [extent.x, extent.y]))
	session.clear_run()
	finish()

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("Preview: ", path)
