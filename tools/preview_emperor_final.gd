extends "res://tests/support/test_runtime.gd"
func _initialize() -> void: call_deferred("_run")
func _capture(a: CrownCourtEncounter, label: String) -> void:
	var saved := a.save_data()
	for frame in 6: await process_frame
	await RenderingServer.frame_post_draw
	assert(a.save_data() == saved)
	root.get_texture().get_image().save_png("res://docs/screenshots/emperor_final/" + label + ".png")
func _run() -> void:
	if DisplayServer.get_name() == "headless": finish(1); return
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://emperor_final_preview.json"
	session.selected_difficulty_id = &"hell"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.wave.current_wave = 20
	game.wave.difficulty_id = &"hell"
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.get_node("Enemies").set_physics_process(false)
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, Vector2(770, 650))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 2
	game.hud.visible = false
	game.get_node("DamageNumbers").visible = false
	var a := boss.crown_court_encounter
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots/emperor_final"))
	paused = true
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		await process_frame
		await process_frame
		for study in ["edict", "intercept", "nerve", "release", "guard"]:
			a.cancel()
			game.player.global_position = Vector2(1010, 650)
			boss.global_position = game.player.global_position + (Vector2(-60, 180) if extent.x < extent.y else (Vector2(-160, 75) if extent.x < 1000 else Vector2(-240, 0)))
			game.player.velocity = Vector2.ZERO
			game.player.hurt_time = 0
			game.player.sprite.modulate = Color.WHITE
			game.player.get_node("Camera2D").force_update_scroll()
			if study in ["nerve", "release"]:
				a.begin(a.Attack.NERVE)
				a.advance(a.remaining + 0.40 if study == "release" else 0.85)
			elif study == "guard":
				a._open()
				a.advance(a.profile.recovery_settle_seconds + a.profile.turn_seconds * 0.55)
			else:
				a.begin(a.Attack.EDICT)
				if study == "edict": a.advance(0.78)
				else:
					a.step_index = a.profile.verdicts(2) - 1
					a._edict()
					game.player.global_position += Vector2(0, 100)
					game.player.velocity = Vector2(140, 0)
					game.player.get_node("Camera2D").force_update_scroll()
					a.advance(a.remaining + a.profile.impact_seconds + 0.65)
					assert(a.state == a.State.PORTAL_WARN and a.portal_followup)
			await _capture(a, "%s_%d" % [study, extent.x])
	print("PASS native Emperor finale: three viewports, actual Hell verdict/intercept/nerve/release/overlapping guard, fixed pause geometry")
	session.clear_run()
	finish()
