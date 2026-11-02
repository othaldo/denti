extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://.godot/contact_pressure_preview/"


func _initialize() -> void: call_deferred("_run")


func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_drill_contact.json"
	session.resume_requested = false
	session.clear_run()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.stats.crit_chance = 0
	game.hud.get_node("Root").visible = false
	game.mobile_controls.visible = false
	game.get_node("DamageNumbers").visible = false
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * 1.8
	camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var offsets := {
		&"turbo_drill": [Vector2(80, 0), Vector2(125, 0), Vector2(160, 0), Vector2(105, 70)],
		&"cavity_grinder": [Vector2(100, 0)],
		&"plaque_scaler": [Vector2(70, 0), Vector2.RIGHT.rotated(deg_to_rad(20)) * 95, Vector2.RIGHT.rotated(deg_to_rad(28)) * 100, Vector2(70, 90)],
		&"prophylaxis_polisher": [Vector2(108, 0)],
	}
	for id in offsets:
		for enemy in game.get_node("Enemies").get_children(): enemy.free()
		game.player.loadout.restore([{"id": str(id), "tier": 1}])
		var targets: Array[Enemy] = []
		for offset in offsets[id]:
			game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
			var enemy: Enemy = game.get_node("Enemies").get_child(-1)
			enemy.set_simulation_enabled(false)
			enemy.health = 10000
			enemy.max_health = 10000
			targets.append(enemy)
		var weapon: WeaponInstance = game.player.loadout.equipped()[0]
		weapon.set_physics_process(false)
		weapon._begin_attack([targets[0]])
		for index in 8:
			weapon._physics_process(weapon.attack_duration / 10)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT + str(id) + "_%d.png" % index)
	session.clear_run()
	print("PASS native short-contact preview: " + OUTPUT)
	finish()
