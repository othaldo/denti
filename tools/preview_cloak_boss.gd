extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://.godot/cloak_preview"
var game: Node2D
var boss: Enemy

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://cloak_preview.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	if game.choice_panel.mode == &"starter": game.choice_panel.starter_selection.confirm_selection()
	game.wave.set_process(false)
	game.wave.current_wave = 5
	game.player.loadout.restore([])
	game.hud.fps_label.visible = false
	game.player.set_physics_process(false)
	game.player.global_position = Vector2(1050, 650)
	game.player.stats.max_health = 1000
	game.player.stats.health = 1000
	game._create_enemy(EnemyCatalog.CAVITY_COUNT, Vector2(900, 650))
	boss = game.boss
	boss.boss_phase = 1
	game.get_node("Enemies").set_physics_process(false)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		game.player.global_position = Vector2(1050, 650)
		for pose in [["warning", 0.50], ["strike", 0.93], ["thrust_warning", 1.90], ["thrust_strike", 2.24], ["ring_warning", 3.15], ["ring_strike", 3.55]]:
			boss.global_position = Vector2(1050, 560) if extent.x < extent.y else Vector2(900, 650)
			game.player.stats.health = 1000
			game.player.hurt_time = 0
			for popup in game.get_node("DamageNumbers").get_children(): popup.free()
			boss.cloak_encounter.begin()
			boss.cloak_encounter.advance(float(pose[1]))
			# Static shape studies should not display feedback from an earlier hit.
			game.player.stats.health = 1000
			game.player.hurt_time = 0
			for popup in game.get_node("DamageNumbers").get_children(): popup.free()
			await _capture(OUTPUT.path_join("%s_%d.png" % [pose[0], extent.x]))
	if "--animate" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(960, 600)
		root.size = root.content_scale_size
		DisplayServer.window_set_size(root.size)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.path_join("frames")))
		game.player.global_position = Vector2(1050, 650)
		boss.global_position = Vector2(900, 650)
		game.player.stats.health = 1000
		game.player.hurt_time = 0
		for popup in game.get_node("DamageNumbers").get_children(): popup.free()
		boss.cloak_encounter.cancel()
		boss.cloak_encounter.remaining = 0
		for frame in 210:
			var attack := boss.cloak_encounter
			var player: Player = game.player
			var destination := player.global_position
			if attack.state == CloakEncounter.State.WARNING:
				if attack.variant == CloakStrikeData.Kind.RING:
					var shape := attack.profile.strike(attack.variant)
					var away := attack.origin.direction_to(player.global_position)
					var inside := attack.origin + away * (shape.inner_radius - HazardGeometry.PLAYER_RADIUS - 10)
					var outside := attack.origin + away * (shape.reach + HazardGeometry.PLAYER_RADIUS + 10)
					destination = inside if player.global_position.distance_to(inside) < player.global_position.distance_to(outside) else outside
				else:
					var radius := maxf(attack.origin.distance_to(player.global_position), 125)
					var angle := attack.half_angle + deg_to_rad(16)
					var side := -1.0 if attack.strike_index % 2 == 0 else 1.0
					destination = attack.origin + attack.direction.rotated(angle * side) * radius
			elif attack.state == CloakEncounter.State.RECOVERY:
				destination = player.global_position + boss.global_position.direction_to(player.global_position) * 70
			player.global_position = player.global_position.move_toward(destination, PlayerStats.BASE_MOVE_SPEED / 30.0)
			boss._physics_process(1.0 / 30.0)
			await _capture(OUTPUT.path_join("frames/%03d.png" % frame))
	session.clear_run()
	finish()

func _capture(path: String) -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
