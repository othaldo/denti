extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var session := root.get_node("GameSession")
	session.save_path = "user://preview_caramel_enforcer.json"
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
	var output := "res://.godot/caramel_enforcer_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		game._clear_arena(false)
		await process_frame
		await process_frame
		game.run_flow.enter(RunFlow.Phase.COMBAT)
		game.wave.current_wave = 10
		game.wave.difficulty_id = &"hell"
		game.wave.active = true
		game.wave.set_process(false)
		game.player.global_position = game.arena.arena_size * 0.5
		game.player.stats.health = game.player.stats.max_health
		game.player.get_node("Camera2D").force_update_scroll()
		await process_frame
		game._create_enemy(EnemyCatalog.CAVITY_PRINCE, game.player.global_position - Vector2(150, 0))
		var court: CaramelEncounter = game.boss.caramel_encounter
		var bounds := court._cooking_bounds()
		game.boss.global_position = game.boss.global_position.clamp(bounds.position, bounds.end)
		court.bodyguard.advance(court.bodyguard.remaining + 0.01)
		var actor := court.bodyguard.minion
		actor.health *= 0.7
		actor.global_position = actor.caramel_enforcer._bounded(game.player.global_position + Vector2(120, 35))
		actor.caramel_enforcer.state = CaramelEnforcer.State.FOLLOW
		actor.caramel_enforcer.remaining = 0
		actor.caramel_enforcer.advance(0.01)
		court.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
		game._refresh_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join("punch_%dx%d.png" % [extent.x, extent.y])))
		print("Preview: ", extent)
	session.clear_run()
	finish()
