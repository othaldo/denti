extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://dash_preview.json"
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.player.loadout.restore([])
	game.wave.set_process(false)
	var screenshots := "res://.godot/dash_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(screenshots))
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		game.mobile_controls.visible = extent.x < 1100
		game.player.dash.reset_wave()
		game.mobile_controls.set_combat_active(true)
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(screenshots.path_join("hud_%dx%d.png" % [extent.x, extent.y]))
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	DisplayServer.window_set_size(Vector2i(960, 540))
	game.mobile_controls.visible = false
	var frames := screenshots.path_join("frames")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames))
	game.player.dash.reset_wave()
	for frame in 180:
		if frame == 12:
			Input.action_press("move_right")
			game.player.try_dash()
			Input.action_release("move_right")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(frames.path_join("frame_%03d.png" % frame))
	session.clear_run()
	finish()
