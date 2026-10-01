extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_level_rerolls.json"
	session.resume_requested = false
	session.clear_run()
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	var game: Node2D = current_scene
	game.coins = 50
	game._on_level_reroll()
	if game.coins != 50 or game.choice_panel.level_actions.visible:
		_fail("starter screen offered or charged a level reroll")
		return
	game.choice_panel.buttons[0].pressed.emit()
	game._on_level_reroll()
	if game.coins != 50 or paused:
		_fail("level reroll interrupted combat")
		return
	game.wave.active = false
	game.level = 10
	game.player.stats.luck = -100.0
	game.rewards.pending_levels = 2
	game.rewards.queue_chest(&"metal_crown", 4)
	game.rewards.finish_collection(false)
	game._advance_post_wave_rewards()
	game.coins = 4
	game._update_level_reroll()
	var first_choices := _choices(game)
	game.choice_panel.reroll_button.pressed.emit()
	if game.coins != 4 or game.rewards.level_rerolls != 0 or _choices(game) != first_choices or not game.choice_panel.reroll_button.disabled:
		_fail("unaffordable reroll changed choices or charged coins")
		return
	game.coins = 50
	game._update_level_reroll()
	game.choice_panel.reroll_button.pressed.emit()
	if game.coins != 45 or game.rewards.pending_levels != 2 or game.rewards.level_rerolls != 1 or game.level != 10 or game.choice_panel.reroll_button.text != "6" or not paused:
		_fail("first reroll did not charge level 9 cost and preserve its queue")
		return
	if not _check_tier(game, 1):
		return
	var saved: Dictionary = session.load_run()
	var rolled_choices := _choices(game)
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.coins != 45 or game.rewards.level_rerolls != 1 or _choices(game) != rolled_choices or game.choice_panel.reroll_button.text != "6" or not game.choice_panel.level_actions.visible or not paused:
		_fail("resume lost reroll count, cost, choices, wallet or pause")
		return
	# Negative luck is a test-only fixture; real saves clamp luck to zero.
	game.player.stats.luck = -100.0
	game.choice_panel.reroll_button.pressed.emit()
	if game.coins != 39 or game.rewards.level_rerolls != 2 or game.telemetry.wave_shop_spending.get("level_reroll", 0) != 11:
		_fail("repeated reroll cost or economy telemetry did not survive resume")
		return
	if not _check_tier(game, 1):
		return
	game.choice_panel.buttons[0].pressed.emit()
	if game.rewards.pending_levels != 1 or game.rewards.level_rerolls != 0 or game.choice_panel.reroll_button.text != "5":
		_fail("next queued level inherited the preceding reroll cost")
		return
	game.choice_panel.reroll_button.pressed.emit()
	if game.coins != 34 or not _check_tier(game, 3):
		_fail("reroll lost the level 10 epic milestone")
		return
	game.choice_panel.buttons[0].pressed.emit()
	game._on_level_reroll()
	if game.coins != 34 or game.choice_panel.mode != &"chest" or game.choice_panel.level_actions.visible:
		_fail("chest screen offered or charged a level reroll")
		return
	game.choice_panel.buttons[1].pressed.emit()
	game._on_level_reroll()
	if game.coins != 38 or not game.in_shop:
		_fail("shop consumed a stale level reroll")
		return
	# Saves made before this feature start at the first reroll price.
	saved.rewards.erase("level_rerolls")
	RunSnapshot.restore(game, saved)
	if game.rewards.level_rerolls != 0 or game.choice_panel.reroll_button.text != "5" or _choices(game) != rolled_choices:
		_fail("legacy reward save acquired reroll fees or regenerated its choices")
		return
	session.clear_run()
	paused = false
	print("Denti level rerolls test passed")
	quit(0)

func _choices(game: Node2D) -> Array[String]:
	var result: Array[String] = []
	for option: UpgradeData in game.choice_panel.current_upgrades:
		result.append("%s:%d" % [option.stat, option.tier])
	return result

func _check_tier(game: Node2D, tier: int) -> bool:
	var stats: Array[StringName] = []
	for option: UpgradeData in game.choice_panel.current_upgrades:
		if option.tier != tier or stats.has(option.stat):
			_fail("reroll used final queued level rarity or duplicated a stat")
			return false
		stats.append(option.stat)
	return stats.size() == 4

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
