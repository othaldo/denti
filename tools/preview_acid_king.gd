extends "res://tests/support/test_runtime.gd"

var output := "res://.godot/king_preview"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var difficulty_id := "normal"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--difficulty="): difficulty_id = argument.trim_prefix("--difficulty=")
	difficulty_id = str(DifficultyCatalog.by_id(StringName(difficulty_id)).id)
	output += "_" + difficulty_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.path_join("frames")))
	if "--portrait" in OS.get_cmdline_user_args():
		root.size = Vector2i(384, 384)
		root.content_scale_size = root.size
		root.transparent_bg = true
		var portrait := KingAcidRig.new()
		root.add_child(portrait)
		portrait.position = Vector2(192, 330)
		portrait.scale = Vector2.ONE * 1.7
		await _capture("res://assets/enemies/king_acid/portrait.png")
		finish()
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://king_preview_%s.json" % difficulty_id
	session.selected_difficulty_id = StringName(difficulty_id)
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	if game.choice_panel.mode == &"starter": game.choice_panel.starter_selection.confirm_selection()
	game.wave.set_process(false)
	game.wave.current_wave = 15
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.hud.fps_label.visible = false
	game.player.stats.max_health = 1000
	game.player.stats.health = 1000
	game.player.global_position = Vector2(1050, 650)
	game._create_enemy(EnemyCatalog.CAVITY_KING, Vector2(770, 620))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 1
	boss.health = boss.max_health * 0.6
	var attack := boss.acid_king_encounter
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.player.get_node("Camera2D").force_update_scroll()
	for study in [["channels", AcidKingEncounter.Attack.CHANNELS, 1.3], ["shift", AcidKingEncounter.Attack.TIDE, 2.65], ["stomp", AcidKingEncounter.Attack.STOMP, 1.5], ["open", AcidKingEncounter.Attack.CHANNELS, 4.5]]:
		attack.cancel()
		boss.global_position = Vector2(770, 620)
		attack.begin(study[1])
		attack.advance(study[2])
		await _capture(output.path_join(study[0] + ".png"))
	# Follow an already active river to its fixed end without rebuilding it.
	root.size = Vector2i(568, 320)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.player.get_node("Camera2D").force_update_scroll()
	attack.cancel()
	attack.begin(AcidKingEncounter.Attack.CHANNELS)
	attack.advance(1.25)
	var original_ends := AcidKingVisuals.channel_ends(attack.fields[0])
	game.player.global_position = (original_ends[1] + Vector2(110, -60)).clamp(Vector2.ONE * 48, game.arena.arena_size - Vector2.ONE * 48)
	game.player.get_node("Camera2D").force_update_scroll()
	await _capture(output.path_join("channel_end.png"))
	game.player.global_position = Vector2(1050, 650)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.player.get_node("Camera2D").force_update_scroll()
	attack.cancel()
	boss.boss_phase = 2
	attack.begin(AcidKingEncounter.Attack.TIDE)
	attack.advance(1 + attack.profile.shifts * (attack.profile.shift_flow_seconds + attack.profile.shift_warning_seconds) + attack.profile.shift_flow_seconds + 0.5)
	await _capture(output.path_join("combined.png"))
	boss.boss_phase = 1
	for extent in [Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		game.player.global_position = Vector2(1050, 650)
		boss.global_position = Vector2(1050, 535) if extent.x < extent.y else Vector2(890, 680)
		game.player.get_node("Camera2D").force_update_scroll()
		attack.cancel()
		attack.begin(AcidKingEncounter.Attack.CHANNELS)
		attack.advance(1.25)
		await _capture(output.path_join("mobile_%d.png" % extent.x))
	if "--stills-only" in OS.get_cmdline_user_args():
		session.clear_run()
		finish()
		return
	root.size = Vector2i(960, 600)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.stats.health = 1000
	boss.global_position = Vector2(770, 620)
	game.player.get_node("Camera2D").force_update_scroll()
	attack.cancel()
	attack.cycle = 0
	attack.remaining = 0.1
	var chapters := {}
	for frame in 840:
		var player: Player = game.player
		player.hurt_time = maxf(player.hurt_time - 1.0 / 30, 0)
		if attack.active and not chapters.has(str(attack.attack_kind)): chapters[str(attack.attack_kind)] = float(frame) / 30
		if attack.state == AcidKingEncounter.State.OPEN and not chapters.has("open"): chapters.open = float(frame) / 30
		if attack.state == AcidKingEncounter.State.WARN_SHIFT and not chapters.has("shift"): chapters.shift = float(frame) / 30
		var goal := player.global_position
		if attack.state in [AcidKingEncounter.State.WARN_CHANNEL, AcidKingEncounter.State.WARN_SHIFT]:
			var threatened := false
			for channel in attack.pending:
				if HazardGeometry.circle_box(player.global_position, Rect2(channel.at - channel.half_size, channel.half_size * 2)): threatened = true
			var shortest := INF
			for side in [-1, 1]:
				var candidate := player.global_position
				candidate[attack.axis] += side * 110
				var safe := true
				for channel in attack.pending:
					if HazardGeometry.circle_box(candidate, Rect2(channel.at - channel.half_size, channel.half_size * 2)): safe = false
				if threatened and safe and candidate.distance_to(player.global_position) < shortest:
					shortest = candidate.distance_to(player.global_position)
					goal = candidate
		elif attack.state in [AcidKingEncounter.State.WARN_STOMP, AcidKingEncounter.State.STOMP]:
			goal = player.global_position + attack.aim.orthogonal() * 160
		elif attack.state == AcidKingEncounter.State.OPEN:
			goal = boss.global_position + boss.global_position.direction_to(player.global_position) * 145
		var before := player.global_position
		player.global_position = player.global_position.move_toward(goal, PlayerStats.BASE_MOVE_SPEED / 30).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
		player.velocity = (player.global_position - before) * 30
		player.get_node("Camera2D").force_update_scroll()
		boss._physics_process(1.0 / 30)
		await _capture(output.path_join("frames/%03d.png" % frame))
	var manifest := FileAccess.open(output.path_join("chapters.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify(chapters))
	session.clear_run()
	finish()

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
