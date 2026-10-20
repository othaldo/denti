extends "res://tests/support/test_runtime.gd"
## Real sugar charge clock and movement, captured on the actual arena floor.

const OUTPUT := "res://.godot/charge_ribbon_preview"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1120, 700)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://charge_ribbon_preview.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.set_process(false)
	game.wave.current_wave = 8
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.global_position = Vector2(1050, 650)
	game.hud.visible = false
	game._create_enemy(EnemyCatalog.SUGAR, Vector2(730, 650))
	var enemy: Enemy = game.get_node("Enemies").get_child(0)
	var index: EnemySpatialIndex = game.get_node("Enemies")
	index.set_physics_process(false)
	enemy.set_simulation_enabled(false)
	enemy.special_timer = 0
	enemy._process_special(0, Vector2.RIGHT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.path_join("frames")))
	for frame in 120:
		if frame < 26:
			if frame > 8: game.player.global_position.y -= PlayerStats.BASE_MOVE_SPEED / 30.0
			enemy._physics_process(1.0 / 30.0)
		elif frame < 53:
			enemy._physics_process(1.0 / 30.0)
		index.queue_redraw()
		for tick in 2: await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.save_png(OUTPUT.path_join("frames/%03d.png" % frame))
		if frame == 18: shot.save_png(OUTPUT.path_join("charge.png"))
	session.clear_run()
	finish()
