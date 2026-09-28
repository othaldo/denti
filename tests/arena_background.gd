extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameSession").save_path = "user://test_arena_run.json"
	root.size = Vector2i(1280, 720)
	await process_frame
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	var arena: DentiArena = game.get_node("Arena")
	if arena.FLOOR == null or arena.arena_size.distance_to(Vector2(1280.0, 720.0)) > 1.0:
		_fail("arena background did not load at base resolution")
		return
	root.size = Vector2i(1280, 960)
	await process_frame
	await process_frame
	print("4:3 viewport: ", arena.arena_size)
	if arena.arena_size.y <= 720.0:
		_fail("arena did not expand vertically at 4:3")
		return
	game.player.global_position = arena.arena_size / 2.0
	game.player._physics_process(0.016)
	if game.player.global_position.y <= 360.0:
		_fail("player did not use expanded arena")
		return
	root.size = Vector2i(1920, 720)
	await process_frame
	await process_frame
	print("ultrawide viewport: ", arena.arena_size)
	if arena.arena_size.x <= 1280.0:
		_fail("arena did not expand horizontally on ultrawide")
		return
	root.get_node("GameSession").clear_run()
	print("Denti arena background test passed")
	quit(0)


func _fail(message: String) -> void:
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
