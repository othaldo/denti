extends "res://tests/support/test_runtime.gd"

var output := "res://.godot/caramel_preview"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var difficulty_id := "hell" if "--hell" in OS.get_cmdline_user_args() else "normal"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--difficulty="): difficulty_id = argument.trim_prefix("--difficulty=")
	difficulty_id = str(DifficultyCatalog.by_id(StringName(difficulty_id)).id)
	if difficulty_id != "normal": output += "_" + difficulty_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.path_join("frames")))
	if "--portrait" in OS.get_cmdline_user_args():
		root.size = Vector2i(384, 384)
		root.content_scale_size = root.size
		root.transparent_bg = true
		var rig := PrinceCaramelRig.new()
		root.add_child(rig)
		rig.position = Vector2(192, 330)
		rig.scale = Vector2.ONE * 1.6
		await _capture("res://assets/enemies/prince_caramel/portrait.png")
		finish()
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://caramel_preview_%s.json" % difficulty_id
	session.resume_requested = false
	session.selected_difficulty_id = StringName(difficulty_id)
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	if game.choice_panel.mode == &"starter": game.choice_panel.starter_selection.confirm_selection()
	game.wave.set_process(false)
	game.wave.current_wave = 10
	game.hud.fps_label.visible = false
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.health = game.player.stats.max_health
	game.player.global_position = Vector2(1050, 650)
	game._create_enemy(EnemyCatalog.CAVITY_PRINCE, Vector2(780, 620))
	var boss: Enemy = game.boss
	boss.boss_phase = 1
	boss.set_simulation_enabled(false)
	game.get_node("Enemies").set_physics_process(false)
	var attack := boss.caramel_encounter
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		boss.global_position = Vector2(1050, 795) if extent.x < extent.y else (Vector2(910, 680) if extent.y < 400 else Vector2(780, 620))
		game.player.global_position = Vector2(1050, 650)
		game.player.get_node("Camera2D").force_update_scroll()
		attack.cancel()
		attack.begin()
		attack.advance(0.80)
		await _capture(output.path_join("flight_%d.png" % extent.x))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.player.global_position = Vector2(1050, 650)
	boss.global_position = Vector2(780, 620)
	var studies := [["heart-fan", CaramelEncounterData.Attack.HEART_FAN, 1.10], ["sugar-rush", CaramelEncounterData.Attack.SUGAR_RUSH, 0.65], ["heart-crown", CaramelEncounterData.Attack.SUGAR_RUSH, 2.40]]
	for study in studies:
		game.player.global_position = Vector2(1050, 650)
		game.player.velocity = Vector2.ZERO
		game.player.get_node("Camera2D").force_update_scroll()
		boss.global_position = Vector2(780, 620)
		attack.cancel()
		attack.begin(-1, study[1])
		if study[0] == "heart-crown":
			game.player.global_position += Vector2(0, 130)
			attack.advance(attack.profile.rush_warning_seconds + attack.profile.rush_seconds)
			game.player.global_position = boss.global_position + attack.aim * 180
			attack.advance(study[2] - attack.profile.rush_warning_seconds - attack.profile.rush_seconds)
		else: attack.advance(study[2])
		game.player.stats.health = game.player.stats.max_health
		game.player.hurt_time = 0
		for popup in game.get_node("DamageNumbers").get_children(): popup.free()
		await _capture(output.path_join(study[0] + ".png"))
		game.player.stats.health = game.player.stats.max_health
		game.player.hurt_time = 0
		for popup in game.get_node("DamageNumbers").get_children(): popup.free()
	if "--stills-only" in OS.get_cmdline_user_args():
		session.clear_run()
		finish()
		return
	root.size = Vector2i(960, 600)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	boss.global_position = Vector2(780, 620)
	attack.cancel()
	attack.cycle = 0
	attack.remaining = 0.1
	var chapters := {}
	var dodge_goal: Vector2 = game.player.global_position
	for frame in 540:
		var player: Player = game.player
		if attack.active and not chapters.has(str(attack.attack_kind)): chapters[str(attack.attack_kind)] = float(frame) / 30
		# A scripted baseline-speed sidestep shows each aim locking before the throw.
		var destination := player.global_position
		if attack.state in [CaramelEncounter.State.WINDUP, CaramelEncounter.State.FLIGHT]:
			var offset := Vector2(0, -155 if attack.throw_index % 2 == 0 else 155)
			destination = attack.destination + offset
		elif attack.state == CaramelEncounter.State.RECOVERY:
			destination = Vector2(1050, 650) if attack.hearts.entries.is_empty() else player.global_position
		elif attack.state == CaramelEncounter.State.HEART_WINDUP:
			var distance := maxf(player.global_position.distance_to(boss.global_position), 240)
			dodge_goal = boss.global_position + attack.aim.rotated(deg_to_rad(attack.profile.fan_step_degrees * 0.5 * (-1 if attack.salvo_index % 2 == 0 else 1))) * distance
			destination = dodge_goal
		elif attack.state == CaramelEncounter.State.HEART_RELEASE:
			destination = dodge_goal
		elif attack.state in [CaramelEncounter.State.RUSH_WINDUP, CaramelEncounter.State.RUSH_ACTIVE]:
			var near := Geometry2D.get_closest_point_to_segment(player.global_position, attack.rush_origin, attack.rush_end)
			var side := attack.aim.orthogonal()
			var a := near + side * (boss.data.radius + 55)
			var b := near - side * (boss.data.radius + 55)
			destination = a if player.global_position.distance_to(a) < player.global_position.distance_to(b) else b
		elif attack.state in [CaramelEncounter.State.BURST_WINDUP, CaramelEncounter.State.BURST_RELEASE]:
			var step := TAU / attack.rays.size()
			var from := attack.rays[0].angle()
			var toward := boss.global_position.angle_to_point(player.global_position)
			var angle := from + (roundf((toward - from) / step - 0.5) + 0.5) * step
			destination = boss.global_position + Vector2.from_angle(angle) * maxf(280, boss.global_position.distance_to(player.global_position))
		var before := player.global_position
		player.global_position = player.global_position.move_toward(destination, PlayerStats.BASE_MOVE_SPEED * player.floor_movement_factor() / 30.0)
		player.velocity = (player.global_position - before) * 30
		boss._physics_process(1.0 / 30.0)
		await _capture(output.path_join("frames/%03d.png" % frame))
		if frame == 75: await _capture(output.path_join("desktop.png"))
	var manifest := FileAccess.open(output.path_join("chapters.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify(chapters))
	session.clear_run()
	finish()

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
