extends SceneTree

# Measure script-side charge activation and the first/repeated finishing volley.
# --cold clears only the procedural texture cache; it is not a cold GPU profile.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/boss_first_charge_probe.json"
	session.resume_requested = false
	for frame in 4:
		await process_frame
	print("Prepared textures before combat: %d" % EnemyProjectileVisuals.textures.size())
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	game.player.loadout.restore([])
	var cold := "--cold" in OS.get_cmdline_user_args()
	for data in [WaveController.CAVITY_COUNT, WaveController.CAVITY_PRINCE, WaveController.CAVITY_KING, WaveController.CAVITY_EMPEROR]:
		game._clear_combat()
		await process_frame
		game._create_enemy(data, game.player.global_position + Vector2(300, 0))
		var boss: Enemy = game.boss
		boss.special_direction = Vector2.LEFT
		if cold:
			EnemyProjectileVisuals.textures.clear()
		for index in 2:
			var started := Time.get_ticks_usec()
			boss._activate_special()
			var activation_ms := float(Time.get_ticks_usec() - started) / 1000.0
			started = Time.get_ticks_usec()
			boss._fire_boss_fan()
			var volley_ms := float(Time.get_ticks_usec() - started) / 1000.0
			print("%s pass=%d activate=%.3fms volley=%.3fms textures=%d" % [data.display_name, index, activation_ms, volley_ms, EnemyProjectileVisuals.textures.size()])
			for shot in game.get_node("EnemyProjectiles").get_children():
				shot.free()
	game.free()
	paused = false
	quit()
