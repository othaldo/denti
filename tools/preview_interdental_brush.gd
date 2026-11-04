extends "res://tests/support/test_runtime.gd"
## Native close/outer sweep and six-root readability captures; isolated userdata.

const OUTPUT := "res://.godot/interdental_brush_preview/"
var game: Node2D

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_interdental_brush.json"
	session.resume_requested = false
	session.clear_run()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.stats.crit_chance = 0
	game.player.global_position = Vector2(960, 540)
	game.hud.get_node("Root").visible = false
	game.mobile_controls.visible = false
	game.get_node("DamageNumbers").visible = false
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * 1.6
	camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for setup in [{"tier": 1, "count": 1}, {"tier": 4, "count": 1}, {"tier": 4, "count": 6}]:
		for enemy in game.get_node("Enemies").get_children(): enemy.free()
		var equipment: Array[Dictionary] = []
		for index in int(setup.count): equipment.append({"id": "interdental_brush", "tier": setup.tier})
		game.player.loadout.restore(equipment)
		var reach: float = game.player.loadout.equipped()[0].data.range_at_tier(int(setup.tier))
		for offset in [Vector2(35, 0), Vector2(-reach, 0), Vector2(0, -reach), Vector2(0, reach)]:
			game._create_enemy(EnemyCatalog.PLAQUE, game.player.global_position + offset)
			var enemy: Enemy = game.get_node("Enemies").get_child(-1)
			enemy.set_simulation_enabled(false)
			enemy.health = 10000
			enemy.max_health = 10000
		for weapon: WeaponInstance in game.player.loadout.equipped(): weapon.set_physics_process(false)
		for frame in 24:
			for weapon: WeaponInstance in game.player.loadout.equipped(): weapon._physics_process(1.0 / 60)
			if frame in [2, 6, 10, 14, 20]:
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUTPUT + "mk%d_count%d_%02d.png" % [setup.tier, setup.count, frame])
	session.clear_run()
	print("PASS brush native preview: " + OUTPUT)
	finish(0)
