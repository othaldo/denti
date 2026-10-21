extends SceneTree

# Deterministic visual stress fixture. Uses the actual game's shared warning
# renderer, enemy resources, player, camera and projectile sprites.
var game: Node2D
var entries: Array[Enemy] = []
var title: Label
var tag := "current"

func _initialize() -> void:
	call_deferred("_run")

func _setup(count: int, mode: int) -> void:
	var all_lanes := mode == 1
	entries.clear()
	for child in game.get_node("Enemies").get_children():
		child.free()
	var center: Vector2 = game.player.global_position
	for index in count:
		var angle := TAU * index / count + 0.12
		var offset := Vector2(cos(angle) * (330 + index % 3 * 26), sin(angle) * (235 + index % 2 * 20))
		var data: EnemyData = WaveController.ACID_SPITTER if all_lanes else [WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.BACTERIA, WaveController.SUGAR][index % 4]
		if mode == 2 and index in [0, 10]:
			data = WaveController.CAVITY_COUNT if index == 0 else WaveController.CAVITY_PRINCE
		game._create_enemy(data, center + offset)
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_process(false)
		enemy.set_simulation_enabled(false)
		enemy.special_phase = Enemy.SpecialPhase.WARNING
		enemy.special_direction = enemy.global_position.direction_to(center + Vector2(sin(index * 2.7), cos(index * 1.3)) * 45)
		if data.is_boss:
			enemy.boss_move = Enemy.BossMove.CHARGE
			enemy.boss_dash_end = enemy.global_position + enemy.special_direction * 610
		if not all_lanes and index % 4 == 3:
			enemy.active_special_attack = EnemyData.SpecialAttack.PULSE
		enemy.queue_redraw()
		entries.append(enemy)
	var batch: EnemySpatialIndex = game.get_node("Enemies")
	batch._process(0.0)
	title.text = "%d gleichzeitige Warnungen · %s" % [count, "alle Geschosswände kreuzen sich" if all_lanes else "Charges, Geschosswände und Impulse"]
	if mode == 2:
		title.text = "%d Warnungen · 2 Boss-Charges und gemischte Angriffe" % count

func _projectiles() -> void:
	var center: Vector2 = game.player.global_position
	var random := RandomNumberGenerator.new()
	random.seed = 71191
	for index in 40:
		var offset := Vector2(random.randf_range(-450, 450), random.randf_range(-240, 240))
		if offset.length() < 65:
			offset.x += 100
		var shot := EnemyProjectilePatterns.acquire(game.get_node("EnemyProjectiles"))
		shot.launch(center + offset, -offset.normalized(), 200, 1, game.player, EnemyProjectilePatterns.ACID_COLOR if index % 2 == 0 else EnemyProjectilePatterns.BOSS_COLOR, 21, 9)
		shot.set_physics_process(false)
	for index in 24:
		var angle := index * 2.4
		var offset := Vector2.from_angle(angle) * (80 + index % 5 * 48)
		var data := WeaponCatalog.by_id(&"water_jet" if index % 2 == 0 else &"magic_toothbrush")
		var shot: WeaponProjectile = game.get_node("Projectiles").acquire(data, 1)
		shot.launch(center + offset, offset.normalized(), 1, data)
		shot.set_physics_process(false)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Warning density preview requires native rendering")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="):
			tag = argument.trim_prefix("--tag=")
	AudioServer.set_bus_mute(0, true)
	seed(71191)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://warning_density.json"
	session.progression_path = "user://warning_density_progression.cfg"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	if game.choice_panel.mode == &"starter": game.choice_panel.starter_selection.confirm_selection()
	game.player.loadout.restore([])
	game.wave.active = false
	game.wave.current_wave = 17
	paused = true
	game.hud.visible = false
	game.player.global_position = game.arena.arena_size / 2.0
	game.player.get_node("Camera2D").force_update_scroll()
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	title = Label.new()
	title.position = Vector2(28, 20)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("fff1ce"))
	title.add_theme_color_override("font_shadow_color", Color("302a3b"))
	title.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(title)
	_projectiles()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/warning_density/" + tag))
	for scenario in [Vector2i(10, 0), Vector2i(20, 0), Vector2i(20, 1), Vector2i(20, 2)]:
		_setup(scenario.x, scenario.y)
		var name := "%d_%s" % [scenario.x, ["mixed", "crossing", "boss_mix"][scenario.y]]
		for frame in 8:
			for index in entries.size():
				var enemy := entries[index]
				var progress := 0.3 + frame / 8.0 * 0.65
				if scenario.y == 0:
					progress = 0.2 + fposmod(progress + index * 0.137, 0.8)
				enemy.special_timer = enemy.data.warning_time * (1.0 - progress)
			var batch: EnemySpatialIndex = game.get_node("Enemies")
			batch._process(0.0)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			shot.save_png("res://.godot/warning_density/%s/%s_%02d.png" % [tag, name, frame])
			if frame == 6:
				shot.save_png("res://docs/screenshots/warning_density_%s.png" % name)
		print("Density scenario %s: %d warnings, %d enemy bullets, %d player shots, %d total scene draw calls" % [name, entries.size(), game.get_node("EnemyProjectiles").get_child_count(), game.get_node("Projectiles").get_child_count(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	game.free()
	overlay.free()
	paused = false
	session.clear_run()
	quit()
