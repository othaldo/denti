extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_queued_level_rarity_run.json"
	# Cover batches ending on a milestone and batches passing beyond one.
	for levels in [Vector2i(8, 10), Vector2i(8, 11), Vector2i(3, 6), Vector2i(13, 16), Vector2i(18, 21), Vector2i(23, 31)]:
		session.clear_run()
		paused = false
		change_scene_to_file("res://scenes/game/game.tscn")
		await process_frame
		await process_frame
		var game: Node2D = current_scene
		game.choice_panel._on_choice_pressed(0)
		game.wave.spawn_cooldown = 100.0
		game.level = levels.x
		game.xp = 0
		game.xp_goal = 5 + (levels.x - 1) * 3
		# Disable random rarity bonuses to isolate the guaranteed milestone rewards.
		game.player.stats.luck = -100.0
		var earned_xp := 0
		for previous_level in range(levels.x, levels.y):
			earned_xp += 5 + (previous_level - 1) * 3
		game._award_xp(earned_xp)
		if game.level != levels.y or game.rewards.pending_levels != levels.y - levels.x or paused or game.choice_panel.visible:
			_fail("batched XP did not queue the expected levels during combat")
			return
		game.wave.active = false
		game.rewards.begin_collection()
		game.rewards.finish_collection(false)
		game._advance_post_wave_rewards()
		for earned_level in range(levels.x + 1, levels.y + 1):
			var expected_tier := 1
			if earned_level == 5:
				expected_tier = 2
			elif earned_level in [10, 15, 20]:
				expected_tier = 3
			elif earned_level >= 25 and earned_level % 5 == 0:
				expected_tier = 4
			if game.rewards.pending_levels != levels.y - earned_level + 1:
				_fail("pending level-up count did not advance one choice at a time")
				return
			if not _check_choices(game, earned_level, expected_tier):
				return
			# Resume each decision, including the next one generated after resolving it.
			game._save_run()
			var saved: Dictionary = session.load_run()
			session.resume_requested = true
			paused = false
			change_scene_to_file("res://scenes/game/game.tscn")
			await process_frame
			await process_frame
			game = current_scene
			if game.level != levels.y or game.rewards.pending_levels != levels.y - earned_level + 1:
				_fail("resume lost the position of the pending level-up")
				return
			if not _check_choices(game, earned_level, expected_tier):
				return
			for index in ChoicePanel.UPGRADE_COUNT:
				if str(game.choice_panel.current_upgrades[index].stat) != str(saved["upgrades"][index]["stat"]):
					_fail("resume rerolled an already offered upgrade")
					return
			# Do not pick luck: keep the deterministic rarity setup for the next choice.
			# Loading clamps negative luck, so reapply the test-only override after resume.
			game.player.stats.luck = -100.0
			var selected_index := 0
			while game.choice_panel.current_upgrades[selected_index].stat == &"luck":
				selected_index += 1
			game.choice_panel._on_choice_pressed(selected_index)
		if game.rewards.pending_levels != 0 or not game.in_shop or not game.shop_panel.visible:
			_fail("batched level-up rewards did not finish before opening the shop")
			return
	session.clear_run()
	paused = false
	print("Denti queued level rarity test passed")
	quit(0)


func _check_choices(game: Node2D, earned_level: int, expected_tier: int) -> bool:
	if not paused or not game.choice_panel.visible or game.choice_panel.mode != &"upgrade" or game.choice_panel.current_upgrades.size() != ChoicePanel.UPGRADE_COUNT:
		_fail("pending level %d did not show four upgrades" % earned_level)
		return false
	for choice: UpgradeData in game.choice_panel.current_upgrades:
		if choice.tier != expected_tier:
			_fail("pending level %d used tier %d instead of %d (final level %d)" % [earned_level, choice.tier, expected_tier, game.level])
			return false
	return true


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
