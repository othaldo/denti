extends "res://tests/support/test_runtime.gd"

var output := "res://.godot/emperor_preview_"
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var tier := "normal"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--difficulty="): tier = argument.trim_prefix("--difficulty=")
	tier = str(DifficultyCatalog.by_id(StringName(tier)).id)
	output += tier
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.path_join("frames")))
	if "--portrait" in OS.get_cmdline_user_args():
		root.size = Vector2i(384, 384)
		root.content_scale_size = root.size
		root.transparent_bg = true
		var rig := EmperorCourtRig.new()
		root.add_child(rig)
		rig.position = Vector2(192, 300)
		rig.scale = Vector2.ONE * 1.15
		await _capture("res://assets/enemies/emperor_court/portrait.png")
		finish()
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://emperor_preview_%s.json" % tier
	session.selected_difficulty_id = StringName(tier)
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	if game.choice_panel.mode == &"starter": game.choice_panel.starter_selection.confirm_selection()
	game.wave.set_process(false)
	game.wave.current_wave = 20
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.hud.fps_label.visible = false
	game.player.stats.max_health = 2000
	game.player.stats.health = 2000
	game.player.global_position = Vector2(1050, 650)
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, Vector2(770, 620))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 1
	boss.health = boss.max_health * 0.6
	var attack := boss.crown_court_encounter
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.player.get_node("Camera2D").force_update_scroll()
	for study in [["edict", 0, 0.7], ["portal", 1, 0.75], ["lance", 1, 1.18], ["nerve", 2, 1.5], ["open", 2, 0.5]]:
		attack.cancel()
		attack.cycle = 0
		boss.global_position = Vector2(770, 620)
		game.player.global_position = Vector2(1050, 650)
		attack.begin(study[1])
		attack.advance(study[2])
		if study[0] == "open":
			attack.state = CrownCourtEncounter.State.OPEN
			attack.sync_visual()
		await _capture(output.path_join(study[0] + ".png"))
	attack.cancel()
	boss.boss_phase = 2
	attack.begin(CrownCourtEncounter.Attack.NERVE)
	attack.advance(0.65)
	await _capture(output.path_join("combined.png"))
	boss.boss_phase = 1
	for extent in [Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		game.player.global_position = Vector2(1050, 650)
		boss.global_position = Vector2(1050, 500) if extent.x < extent.y else Vector2(890, 680)
		game.player.get_node("Camera2D").force_update_scroll()
		attack.cancel()
		attack.begin(CrownCourtEncounter.Attack.PORTAL)
		attack.advance(0.75)
		await _capture(output.path_join("mobile_%d.png" % extent.x))
	if "--stills-only" in OS.get_cmdline_user_args():
		session.clear_run()
		finish()
		return
	root.size = Vector2i(960, 600)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	for frame in 1080:
		var player: Player = game.player
		if frame % 360 == 0:
			attack.cancel()
			attack.cycle = 0
			boss.global_position = Vector2(770, 620)
			player.global_position = Vector2(1050, 650)
			player.velocity = Vector2.ZERO
			player.get_node("Camera2D").force_update_scroll()
			attack.begin(frame / 360)
		player.hurt_time = maxf(player.hurt_time - 1.0 / 30, 0)
		var goal := preload("res://tools/support/crown_court_pilot.gd").goal(player, boss, attack)
		var before := player.global_position
		player.global_position = before.move_toward(goal, PlayerStats.BASE_MOVE_SPEED / 30).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
		player.velocity = (player.global_position - before) * 30
		player.get_node("Camera2D").force_update_scroll()
		boss._physics_process(1.0 / 30)
		await _capture(output.path_join("frames/%04d.png" % frame))
	session.clear_run()
	finish()


func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
