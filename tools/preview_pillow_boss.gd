extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://.godot/pillow_preview"
var game: Node2D
var boss: Enemy

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://pillow_boss_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	if game.choice_panel.mode == &"starter": game.choice_panel.starter_selection.confirm_selection()
	game.wave.set_process(false)
	game.wave.current_wave = 5
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.global_position = Vector2(900, 600)
	game.player.stats.max_health = 1000
	game.player.stats.health = 1000
	var legacy := EnemyCatalog.CAVITY_COUNT.duplicate() as EnemyData
	legacy.cloak_profile = null
	legacy.pillow_profile = load("res://data/encounters/count_pillow.tres")
	legacy.sprite = load("res://assets/enemies/cavity_count_pillow.png")
	game._create_enemy(legacy, Vector2(1040, 530))
	boss = game.boss
	boss.boss_phase = 1
	game.get_node("Enemies").set_physics_process(false)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		boss.pillow_encounter.cycle = 0
		boss.pillow_encounter.begin()
		boss.pillow_encounter.elapsed = 0.85
		await _capture("warning_%d" % extent.x)
		boss.pillow_encounter.elapsed = 2.3
		await _capture("fold_%d" % extent.x)
	if "--animate" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(960, 600)
		root.size = Vector2i(960, 600)
		DisplayServer.window_set_size(root.size)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.path_join("frames")))
		boss.pillow_encounter.cycle = 0
		boss.pillow_encounter.begin()
		for frame in 180:
			# Arranged demonstration: ordinary movement leaves the first lane.
			if frame >= 15 and frame < 30:
				game.player.global_position += Vector2(boss.pillow_encounter.forward.y, boss.pillow_encounter.forward.x) * 6
			boss.pillow_encounter.advance(1.0 / 30.0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT.path_join("frames/%03d.png" % frame))
	session.clear_run()
	finish()

func _capture(label: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label + ".png"))
