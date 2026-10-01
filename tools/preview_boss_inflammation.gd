extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if "--combat" in OS.get_cmdline_user_args():
		await _combat_preview()
		return
	root.content_scale_size = Vector2i(1280, 600)
	root.size = Vector2i(1280, 600)
	DisplayServer.window_set_size(root.size)
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var background := TextureRect.new()
	background.texture = load("res://assets/environment/dental_arena_floor.png")
	background.size = Vector2(1280, 600)
	background.modulate = Color(0.52, 0.45, 0.56)
	background.z_index = -10
	stage.add_child(background)
	_label(stage, "Entzündet · animierte Boss-Auren", Vector2(0, 32), 1280, 30, DentiUIStyle.CREAM)
	_label(stage, "Graf → Prinz → König → Imperator · +30 Sekunden", Vector2(0, 82), 1280, 18, DentiUIStyle.CREAM)
	var index := 0
	for wave in [5, 10, 15, 20]:
		# Equal display sizes make color and VFX intensity easier to compare.
		var data := WaveController.boss_for_wave(wave).duplicate() as EnemyData
		data.radius = 65.0
		var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		boss.configure(data, null, wave)
		boss.position = Vector2(160 + index * 320, 310)
		stage.add_child(boss)
		boss.set_physics_process(false)
		boss.start_overtime()
		boss.advance_overtime(30)
		_label(stage, data.display_name, Vector2(index * 320, 475), 320, 24, DentiUIStyle.CREAM)
		_label(stage, "Entzündet +30s", Vector2(index * 320, 512), 320, 18, data.inflammation_color.lightened(0.28))
		index += 1
	var output := ProjectSettings.globalize_path("res://.codex/boss-inflammation-previews")
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(0.5).timeout
	for frame in 16:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "/aura_%02d.png" % frame)
		for tick in 3:
			await process_frame
	print("Boss inflammation preview saved: ", output)
	quit(0)


func _combat_preview() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_boss_inflammation_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.player.loadout.restore([])
	game.wave.active = false
	game.wave.current_wave = 20
	game.wave.remaining = 0.0
	game._create_enemy(WaveController.boss_for_wave(20), game.player.global_position + Vector2(260, 0))
	var boss: Enemy = game.boss
	boss.set_physics_process(false)
	boss.start_overtime()
	boss.advance_overtime(30)
	boss.special_phase = Enemy.SpecialPhase.WARNING
	boss.special_timer = boss.data.warning_time * 0.5
	boss.boss_move = Enemy.BossMove.PULSE
	game.boss_pending = true
	game._refresh_hud()
	await create_timer(0.5).timeout
	var output := ProjectSettings.globalize_path("res://.codex/boss-inflammation-previews")
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "/combat_1280x720.png")
	session.clear_run()
	quit(0)


func _label(parent: Node, text: String, at: Vector2, width: float, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DentiUIStyle.FONT)
	DentiUIStyle.style_hud_text(label, color, font_size)
	label.z_index = 10
	parent.add_child(label)
