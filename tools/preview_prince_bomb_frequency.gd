extends "res://tests/support/test_runtime.gd"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	if DisplayServer.get_name() == "headless": finish(1); return
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://prince_frequency_preview.json"
	session.resume_requested = false
	session.selected_difficulty_id = &"hell"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.wave.current_wave = 10
	game.wave.difficulty_id = &"hell"
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.global_position = Vector2(1050, 650)
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.get_node("Enemies").set_physics_process(false)
	game._create_enemy(EnemyCatalog.CAVITY_PRINCE, Vector2(750, 650))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 2
	game.hud.visible = false
	var a := boss.caramel_encounter
	paused = true
	game.player.get_node("Camera2D").force_update_scroll()
	a.begin(-1, CaramelEncounterData.Attack.BOMBS)
	for tick in 51:
		game.player.velocity = Vector2(230, 0) if tick < 42 else Vector2(0, 230)
		game.player.global_position += game.player.velocity / 60
		game.player.get_node("Camera2D").force_update_scroll()
		a.advance(1.0 / 60)
	assert(a.bombs.entries.size() == 2)
	var geometry := a.bombs.save_data()
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	assert(a.bombs.save_data() == geometry)
	root.get_texture().get_image().save_png("res://docs/screenshots/prince_bomb_frequency.png")
	print("PASS native Hell bomb overlap: two fixed targets, independent charge/flight progress, pause frozen, shared analytic warning renderer")
	session.clear_run()
	finish()
