extends SceneTree

var games: Array[Node2D] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_motion_preview.json"
	session.resume_requested = false
	session.clear_run()
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var board := Node2D.new()
	root.add_child(board)
	current_scene = board
	var examples := [
		{"id": "toothpick_spear", "title": "Speer · Stich", "target": Vector2(160, 0)},
		{"id": "plaque_scaler", "title": "Kratzer · Schwung", "target": Vector2(85, 0)},
		{"id": "amalgam_slingshot", "title": "Zwille · aufrechter Griff", "target": Vector2(160, 0)},
		{"id": "water_jet", "title": "Wasserflosser · Seitenwechsel", "target": Vector2(-160, 0)}
	]
	var heads := OS.get_cmdline_user_args().has("--working-heads")
	if heads:
		examples[0] = {"id": "cavity_grinder", "title": "Fräse · rotierender Kopf", "target": Vector2(70, 0)}
		examples[1] = {"id": "prophylaxis_polisher", "title": "Polierer · rotierender Kopf", "target": Vector2(75, 0)}
	for index in examples.size():
		var container := SubViewportContainer.new()
		container.position = Vector2(index % 2 * 640, index / 2 * 360)
		board.add_child(container)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(640, 360)
		viewport.world_2d = World2D.new()
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		container.add_child(viewport)
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		viewport.add_child(game)
		game.choice_panel.buttons[0].pressed.emit()
		game.wave.active = false
		game.player.loadout.restore([{"id": examples[index].id, "tier": 1}])
		game.hud.get_node("Root").visible = false
		game.get_node("DamageNumbers").visible = false
		game.mobile_controls.visible = false
		game.player.stats.crit_chance = 0
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(examples[index].target))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 10000
		enemy.max_health = 10000
		enemy.set_physics_process(false)
		var camera: Camera2D = game.player.get_node("Camera2D")
		camera.zoom = Vector2.ONE * 1.5
		camera.offset = Vector2(-15 if index == 3 else 30, 0)
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		games.append(game)
		var title := Label.new()
		title.position = container.position + Vector2(18, 10)
		title.text = examples[index].title
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color("fff9e9"))
		title.add_theme_color_override("font_outline_color", Color("302833"))
		title.add_theme_constant_override("outline_size", 5)
		board.add_child(title)
	paused = true
	var frame_directory := "res://.godot/weapon_motion_heads" if heads else "res://.godot/weapon_motion_frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frame_directory))
	for frame in 48:
		for index in games.size():
			var game := games[index]
			# Isolate targeting groups while manually stepping these four paused worlds.
			for other in games:
				for enemy: Enemy in other.get_node("Enemies").get_children():
					if enemy.is_in_group("enemies"):
						enemy.remove_from_group("enemies")
			for enemy: Enemy in game.get_node("Enemies").get_children():
				enemy.add_to_group("enemies")
			if index == 3 and frame == 24:
				game.get_node("Enemies").get_child(0).global_position = game.player.global_position + Vector2(160, 0)
				game.player.loadout.equipped()[0].cooldown = 0
			game.player._animate_sprite(Vector2.ZERO, 1.0 / 30.0)
			game.player.loadout.equipped()[0]._physics_process(1.0 / 30.0)
			for enemy: Enemy in game.get_node("Enemies").get_children():
				enemy._physics_process(1.0 / 30.0)
				enemy._process(1.0 / 30.0)
				enemy.modulate = Color.WHITE
			for bullet: WeaponProjectile in game.get_node("Projectiles").get_children():
				bullet._physics_process(1.0 / 30.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(frame_directory + "/frame_%02d.png" % frame)
	current_scene = board
	session.clear_run()
	paused = false
	quit()
