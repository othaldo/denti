extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_post_wave_rewards_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.spawn_cooldown = 100.0
	game._on_loot_collected(&"xp", 25)
	game._on_loot_collected(&"chest", 4, &"metal_crown")
	if paused or game.choice_panel.visible or game.rewards.pending_levels != 3 or game.level != 4 or game.xp != 1 or game.rewards.pending_chests.size() != 1:
		_fail("combat XP or chest pickup interrupted play instead of queuing rewards")
		return
	game._spawn_loot(game.player.global_position + Vector2(500.0, 0.0), &"xp", 5)
	game._spawn_loot(game.player.global_position + Vector2(580.0, 0.0), &"coin", 2)
	game._spawn_loot(game.player.global_position + Vector2(660.0, 0.0), &"chest", 5, &"fluoride_gel")
	game.rewards.mark_chest_spawned()
	game._save_run()
	session.resume_requested = true
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if paused or game.rewards.pending_levels != 3 or game.rewards.pending_chests.size() != 1 or not game.rewards.chest_spawned or game.get_node("Loot").get_child_count() != 3:
		_fail("continue lost pending combat rewards or the chest on the ground")
		return
	game.wave._process(game.wave.remaining)
	if not game.collecting_wave_loot or game.choice_panel.visible or game.rewards.step != PostWaveRewards.Step.COLLECTING:
		_fail("reward choices opened before the loot sweep")
		return
	for frame in 180:
		if game.choice_panel.visible:
			break
		await physics_frame
	if not paused or game.get_node("Loot").get_child_count() != 0 or game.coins != 2 or game.xp != 6 or game.rewards.pending_chests.size() != 2 or game.rewards.step != PostWaveRewards.Step.LEVELS or game.choice_panel.mode != &"upgrade":
		_fail("loot sweep did not finish before level-up and chest choices")
		return
	for index in 3:
		if game.choice_panel.mode != &"upgrade" or game.rewards.pending_levels != 3 - index or game.shop_panel.visible:
			_fail("pending level-ups were skipped or shop opened early")
			return
		game.choice_panel._on_choice_pressed(0)
	if game.rewards.step != PostWaveRewards.Step.CHESTS or game.choice_panel.mode != &"chest" or game.choice_panel.chest_item.id != &"metal_crown":
		_fail("chest choices did not follow all level-ups")
		return
	var armor_before: float = game.player.stats.armor
	game.choice_panel._on_choice_pressed(0)
	if game.items.count(&"metal_crown") != 1 or game.player.stats.armor != armor_before + 3.0 or game.choice_panel.chest_item.id != &"fluoride_gel" or game.rewards.pending_chests.size() != 1:
		_fail("KEEP did not grant the item or advance to the next chest")
		return
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if not paused or game.rewards.step != PostWaveRewards.Step.CHESTS or game.choice_panel.mode != &"chest" or game.choice_panel.chest_item.id != &"fluoride_gel" or game.items.count(&"metal_crown") != 1:
		_fail("continue lost the pending chest decision")
		return
	game.choice_panel._on_choice_pressed(1)
	if not paused or not game.shop_panel.visible or game.coins != 7 or game.items.count(&"fluoride_gel") != 0 or game.telemetry.chests_found != 2 or game.telemetry.chests_kept != 1 or game.telemetry.chests_scrapped != 1:
		_fail("SCRAP did not grant coins and finish the reward queue before shop")
		return
	if ChestRewards.drop_chance(1000.0) > ChestRewards.BASE_DROP_CHANCE * 2.0 or ChestRewards.drop_chance(100.0) <= ChestRewards.drop_chance(0.0):
		_fail("luck did not affect chest chance within its cap")
		return
	session.clear_run()
	paused = false
	print("Denti post-wave rewards test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
