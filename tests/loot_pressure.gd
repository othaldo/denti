extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_loot_pressure_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = true
	game.wave.current_wave = 1
	for index in 100:
		game._on_enemy_defeated(game.player.global_position + Vector2(300.0, 0.0), WaveController.PLAQUE)
	var early_xp := _xp_drops(game)
	game._clear_arena(false)
	await process_frame
	game.wave.current_wave = 14
	seed(31)
	for index in 100:
		game._on_enemy_defeated(game.player.global_position + Vector2(300.0, 0.0), WaveController.PLAQUE)
	var late_xp := _xp_drops(game)
	if early_xp != 100 or late_xp < 35 or late_xp > 70 or late_xp >= early_xp or game.telemetry.kills != 200:
		_fail("denser late waves still grant XP for almost every kill: %d / %d" % [early_xp, late_xp])
		return
	session.clear_run()
	print("Denti loot pressure test passed; XP drops per 100 kills: %d / %d" % [early_xp, late_xp])
	quit(0)


func _xp_drops(game: Node2D) -> int:
	var count := 0
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.kind == &"xp":
			count += 1
	return count


func _fail(message: String) -> void:
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
