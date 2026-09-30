extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_player_death_cleanup.json"
	session.report_dir = "user://test_player_death_reports_%d" % Time.get_ticks_usec()
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(25.0, 0.0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.contact_damage = 1000.0
	game.player.stats.health = 1.0
	game.player.hurt_time = 0.0
	enemy._physics_process(0.016)
	if not game.ended or game.choice_panel.mode != &"end" or not is_instance_valid(enemy) or not enemy.is_queued_for_deletion():
		_fail("lethal enemy contact did not defer combat cleanup until the frame ends")
		return
	await process_frame
	if is_instance_valid(enemy) or game.get_node("Enemies").get_child_count() != 0:
		_fail("enemy remained after deferred death cleanup")
		return
	print("Denti player death cleanup test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
