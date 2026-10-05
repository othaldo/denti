extends SceneTree

# Isolate movement/contact and spatial-index upkeep from rendering, weapons,
# attack creation, autosaves and debug sampling. No real-time FPS claim.
const TICKS := 1800
const COUNT := 110

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/benchmark_enemy_physics.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.selected_difficulty_id = &"normal"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.player.loadout.restore([])
	paused = true
	await process_frame
	var index: EnemySpatialIndex = game.get_node("Enemies")
	for child in index.get_children():
		child.free()
	var enemies: Array[Enemy] = []
	for number in COUNT:
		var data: EnemyData = [WaveController.PLAQUE, WaveController.ACID_SPITTER, WaveController.BACTERIA][number % 3]
		game._create_enemy(data, Vector2.ZERO)
		enemies.append(index.get_child(-1))
	game.player.hurt_time = 1000000
	var reference := PackedVector2Array()
	var wet := "--wet" in OS.get_cmdline_user_args()
	for pass_index in 8:
		for number in COUNT:
			enemies[number].position = Vector2(640, 360) + Vector2.from_angle(float(number) * TAU / COUNT) * 280
			enemies[number].special_phase = Enemy.SpecialPhase.COOLDOWN
			enemies[number].special_timer = 1000000
			enemies[number].contact_timer = 0
			enemies[number].wet_time = 1000000.0 if wet else 0.0
		var started := Time.get_ticks_usec()
		for tick in TICKS:
			game.player.position = Vector2(640, 360) + Vector2.from_angle(float(tick) * 0.014) * 190
			if pass_index % 2 == 0:
				for enemy in enemies:
					enemy._physics_process(1.0 / 60)
			else:
				index._physics_process(1.0 / 60)
		var elapsed := Time.get_ticks_usec() - started
		var result := PackedVector2Array()
		for enemy in enemies:
			result.append(enemy.position)
		if pass_index == 0:
			reference = result
		elif result != reference:
			push_error("central movement changed a final enemy position")
			game.free()
			quit(1)
			return
		# First pass per path warms runtime/cache; then alternate three pairs.
		if pass_index > 1:
			var checksum := Vector2.ZERO
			for enemy in enemies:
				checksum += enemy.position
			print(JSON.stringify({"path": "central" if pass_index % 2 else "individual", "wet": wet, "pass": pass_index, "ms_per_tick": float(elapsed) / TICKS / 1000, "position_checksum": checksum}))
	game.free()
	await process_frame
	quit()
