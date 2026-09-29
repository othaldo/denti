extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_wave_loot_collection_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	var start: Vector2 = game.player.global_position
	game._spawn_loot(start + Vector2(300.0, 0.0), &"xp", 5)
	game._spawn_loot(start + Vector2(650.0, 0.0), &"coin", 2)
	game.wave._process(WaveController.DURATION)
	if not game.collecting_wave_loot or game.shop_panel.visible or game.choice_panel.visible or game.xp != 0 or game.coins != 0:
		_fail("wave end credited loot or opened a menu before the pickup animation")
		return
	if game.hud.timer_label.text != "Beute sammeln" or game.player.is_physics_processing():
		_fail("collection phase did not show its status or hold Denti still")
		return
	var coin: Loot = game.get_node("Loot").get_child(1)
	var distance_before := coin.global_position.distance_to(start)
	for frame in 4:
		await physics_frame
	if coin.global_position.distance_to(start) >= distance_before or game.shop_panel.visible:
		_fail("remaining loot did not visibly fly toward Denti")
		return
	for frame in 180:
		if game.choice_panel.visible:
			break
		await physics_frame
	if not paused or not game.choice_panel.visible or game.shop_panel.visible or game.collecting_wave_loot or game.get_node("Loot").get_child_count() != 0 or game.coins != 2 or game.level != 2:
		_fail("all drops were not collected before the level-up")
		return
	game.choice_panel._on_choice_pressed(0)
	if not paused or not game.shop_panel.visible:
		_fail("shop did not wait for the level-up choice")
		return

	game._on_shop_continue()
	game._spawn_loot(game.player.global_position + Vector2(700.0, 0.0), &"coin", 3)
	game.wave._process(WaveController.DURATION)
	if not game.collecting_wave_loot or not bool(session.load_run().get("collecting_wave_loot", false)):
		_fail("collection phase was not saved")
		return
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if not game.collecting_wave_loot or game.get_node("Loot").get_child_count() != 1 or game.shop_panel.visible:
		_fail("continue did not restore the flying loot")
		return
	for frame in 180:
		if game.shop_panel.visible:
			break
		await physics_frame
	if not paused or game.coins != 5 or game.collecting_wave_loot or not game.shop_panel.visible:
		_fail("restored collection did not finish exactly once before the shop")
		return

	game._on_shop_continue()
	game.wave.current_wave = 5
	game._create_enemy(WaveController.BOSS, game.player.global_position + Vector2(400.0, 0.0))
	game._spawn_loot(game.player.global_position + Vector2(650.0, 0.0), &"coin", 1)
	game.wave._process(WaveController.DURATION)
	if not game.boss_pending or game.collecting_wave_loot or game.get_node("Loot").get_child_count() != 1:
		_fail("boss overtime started collection before the boss was defeated")
		return
	game.boss.take_damage(99999.0)
	for frame in 120:
		if game.collecting_wave_loot:
			break
		await process_frame
	if not game.collecting_wave_loot or game.shop_panel.visible:
		_fail("boss defeat did not start the loot collection")
		return
	for frame in 180:
		if game.shop_panel.visible:
			break
		await physics_frame
	if not paused or game.coins != 6 or not game.shop_panel.visible:
		_fail("boss wave shop did not wait for the final drop")
		return
	game._on_shop_continue()
	game.wave.current_wave = WaveController.MAX_WAVES
	game._create_enemy(WaveController.FINAL_BOSS, game.player.global_position + Vector2(400.0, 0.0))
	game._spawn_loot(game.player.global_position + Vector2(650.0, 0.0), &"coin", 1)
	game.wave._process(WaveController.DURATION)
	game.boss.take_damage(99999.0)
	for frame in 120:
		if game.collecting_wave_loot:
			break
		await process_frame
	if game.ended or not game.collecting_wave_loot:
		_fail("final victory appeared before loot collection")
		return
	for frame in 180:
		if game.ended:
			break
		await physics_frame
	if not game.ended or game.coins != 7 or not game.choice_panel.visible:
		_fail("final drop was lost or counted twice before victory")
		return
	paused = false
	session.clear_run()
	print("Denti wave loot collection test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
