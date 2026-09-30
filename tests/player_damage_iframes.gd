extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_player_damage_iframes.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	var player: Player = game.player
	for sample in [[5.0, 0.2], [7.5, 0.2], [8.0, 0.4 * 0.08 / 0.15], [10.0, 0.4 * 0.10 / 0.15], [15.0, 0.4], [30.0, 0.4]]:
		player.stats.health = 100.0
		player.hurt_time = 0.0
		player.take_hit(sample[0])
		if not is_equal_approx(player.hurt_time, sample[1]):
			_fail("wrong i-frame duration for %.1f%% damage" % sample[0])
			return
		var health_after_hit: float = player.stats.health
		player.take_hit(10.0)
		if player.stats.health != health_after_hit:
			_fail("second hit bypassed active i-frames")
			return
	player.stats.health = 100.0
	player.stats.armor = 5.0
	player.hurt_time = 0.0
	player.take_hit(15.0)
	if not is_equal_approx(player.hurt_time, 0.4 * 0.10 / 0.15):
		_fail("i-frames used raw damage instead of damage after armor")
		return
	player.stats.health = 100.0
	player.stats.shield_charges = 1
	player.hurt_time = 0.0
	player.take_hit(15.0)
	if player.hurt_time != 0.0 or player.stats.health != 100.0:
		_fail("blocked damage started i-frames")
		return
	session.clear_run()
	print("Denti player damage i-frames test passed")
	quit(0)


func _fail(message: String) -> void:
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
