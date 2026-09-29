extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_arena_run.json"
	session.clear_run()
	root.size = Vector2i(1280, 720)
	await process_frame
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	var arena: DentiArena = game.get_node("Arena")
	var player: Player = game.player
	var camera: Camera2D = player.get_node("Camera2D")
	if arena.FLOOR == null or arena.arena_size.distance_to(Vector2(1920.0, 1080.0)) > 1.0:
		_fail("arena must be larger than the base viewport")
		return
	game.choice_panel.visible = false
	paused = false
	for corner in [Vector2.ZERO, Vector2(arena.arena_size.x, 0.0), Vector2(0.0, arena.arena_size.y), arena.arena_size]:
		player.global_position = corner
		player._physics_process(0.0)
		camera.force_update_scroll()
		var screen_position := player.get_global_transform_with_canvas().origin
		var expected: Vector2 = corner.clamp(Vector2.ONE * DentiArena.PLAYER_MARGIN, arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN)
		if player.global_position.distance_to(expected) > 1.0 or screen_position.distance_to(Vector2(root.size) * 0.5) > 1.0:
			_fail("player crossed the wall or camera lost the player at an arena corner")
			return
		for index in 10:
			var edge: int = game._spawn_edge()
			var at: Vector2 = game._spawn_position(edge)
			var delta: Vector2 = (at - player.global_position).abs()
			if at.x < DentiArena.WALL_WIDTH or at.y < DentiArena.WALL_WIDTH or at.x > arena.arena_size.x - DentiArena.WALL_WIDTH or at.y > arena.arena_size.y - DentiArena.WALL_WIDTH or (delta.x <= 640.0 and delta.y <= 360.0):
				_fail("enemy spawn is inside the camera view or outside the wall")
				return
	player.global_position = Vector2.ONE * DentiArena.PLAYER_MARGIN
	camera.force_update_scroll()
	var hud_bottom: float = maxf(game.hud.get_node("Root/VitalsFrame").get_global_rect().end.y, game.hud.wave_frame.get_global_rect().end.y)
	var top_wall_screen := (arena.get_global_transform_with_canvas() * Vector2.ZERO).y
	if top_wall_screen <= hud_bottom:
		_fail("HUD still overlaps the arena when Denti reaches the top wall")
		return
	root.size = Vector2i(1280, 960)
	await process_frame
	await process_frame
	if arena.arena_size.y <= 960.0 or arena.arena_size.x <= 1280.0:
		_fail("arena did not expand vertically at 4:3")
		return
	root.size = Vector2i(1920, 720)
	await process_frame
	await process_frame
	if arena.arena_size.x <= 1920.0 or arena.arena_size.y <= 720.0:
		_fail("arena did not expand horizontally on ultrawide")
		return
	session.clear_run()
	print("Denti arena background test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
