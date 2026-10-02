extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://player_status_preview.json"
	session.report_dir = "user://player_status_preview_reports"
	session.selected_difficulty_id = &"normal"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.wave.current_wave = 12
	game.wave.remaining = 28.0
	game.telemetry.begin_wave(12)
	game.player.stats.health = 73.0
	paused = true
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	game._clear_arena(false)
	game._create_enemy(WaveController.POISON_GERM, game.player.position + Vector2(-200, -60))
	game._create_enemy(WaveController.GUM_BITER, game.player.position + Vector2(155, -80))
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(-110, 145))
	game._create_enemy(WaveController.BACTERIA, game.player.position + Vector2(185, 130))
	for enemy: Enemy in game.get_node("Enemies").get_children():
		enemy.special_phase = Enemy.SpecialPhase.WARNING
		enemy.special_timer = enemy.data.warning_time * 0.6
		enemy.special_direction = enemy.position.direction_to(game.player.position)
		enemy.queue_redraw()
	var plaque: Enemy = game.get_node("Enemies").get_child(2)
	plaque.inflicted_statuses = [EnemyStatusRules.POISON.payload()]
	var bacteria: Enemy = game.get_node("Enemies").get_child(3)
	bacteria.special_phase = Enemy.SpecialPhase.COOLDOWN
	bacteria.inflicted_statuses = [EnemyStatusRules.BLEED.payload()]
	var combined: Array[Dictionary] = [EnemyStatusRules.POISON.payload(), EnemyStatusRules.BLEED.payload()]
	var poison: Array[Dictionary] = [EnemyStatusRules.POISON.payload()]
	var bleed: Array[Dictionary] = [EnemyStatusRules.BLEED.payload()]
	game.player.status_effects.apply_attacks(combined)
	game._refresh_hud()
	await _capture("player_status_combat")
	game.player.status_effects.clear()
	game.player.status_effects.apply_attacks(poison)
	game._refresh_hud()
	await _capture("player_poison_combat")
	game.player.status_effects.clear()
	game.player.status_effects.apply_attacks(bleed)
	game._refresh_hud()
	await _capture("player_bleed_combat")
	game.free()
	paused = false
	session.clear_run()
	quit()

func _capture(name: String) -> void:
	# Freeze the setup after the short application popups, for a clear still.
	for popup in current_scene.get_node("DamageNumbers").get_children():
		popup.free()
	for frame in 8:
		await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/%s.png" % name))
