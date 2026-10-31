extends "res://tests/support/test_runtime.gd"
func _initialize() -> void: call_deferred("_run")
func _capture(a: AcidKingEncounter, name: String) -> void:
	var saved := a.save_data()
	for frame in 6: await process_frame
	await RenderingServer.frame_post_draw
	assert(saved == a.save_data())
	root.get_texture().get_image().save_png("res://docs/screenshots/king_assault/" + name + ".png")
func _run() -> void:
	if DisplayServer.get_name() == "headless": finish(1); return
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://king_assault_preview.json"
	session.resume_requested = false
	session.selected_difficulty_id = &"hell"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.wave.current_wave = 15
	game.wave.difficulty_id = &"hell"
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.global_position = Vector2(1050, 650)
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.get_node("Enemies").set_physics_process(false)
	game._create_enemy(EnemyCatalog.CAVITY_KING, Vector2(770, 620))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 2
	game.hud.visible = false
	var a := boss.acid_king_encounter
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots/king_assault"))
	paused = true
	game.player.get_node("Camera2D").force_update_scroll()
	a.begin(a.Attack.CHANNELS)
	# Dodge the first river; the fan then acquires this new bank position.
	game.player.global_position += Vector2(0, 110)
	game.player.get_node("Camera2D").force_update_scroll()
	a.advance(a.profile.warning_seconds + 0.55)
	assert(a.state == a.State.WARN_SPIT)
	await _capture(a, "fan_warning")
	a.advance(0.45)
	assert(not a.spit.entries.is_empty())
	await _capture(a, "fan_release")
	a.cancel()
	boss.global_position = Vector2(770, 620)
	game.player.global_position = Vector2(1050, 650)
	game.player.get_node("Camera2D").force_update_scroll()
	a.begin(a.Attack.STOMP)
	a.advance(a.stomp_warning_duration() + a._stomp_duration())
	game.player.global_position += Vector2(30, 160)
	game.player.get_node("Camera2D").force_update_scroll()
	a.advance(a.profile.stomp_chase_seconds + 0.6)
	assert(a.state == a.State.WARN_STOMP and a.stomp_index == 1)
	await _capture(a, "second_stomp")
	session.clear_run()
	print("PASS native King assault: aimed warning/release and retargeted second stomp, real Hell profile, pause frozen")
	finish()
