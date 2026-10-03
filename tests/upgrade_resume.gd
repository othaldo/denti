extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/game/game.tscn")

var failures: Array[String] = []
var cases: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> bool:
	if not condition:
		failures.append(message)
		push_error(message)
	return condition


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_upgrade_resume.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = GAME_SCENE.instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	# Keep the same cap-reaching late-run build that exposed the flaky layout test.
	for item in ShopController.CATALOG:
		if item.weapon_data == null:
			game.items.acquire(item)
	game.items.acquire(ShopController.by_id(&"metal_crown"))
	_check(is_equal_approx(game.player.stats.crit_chance, 0.65), "late-run fixture no longer reproduces the crit cap")
	var baseline: Dictionary = game.player.stats.to_save_data()
	var templates: Array[UpgradeData] = game.UPGRADES
	for template in templates:
		for tier in range(1, 5):
			var crit_values: Array[float] = [0.25]
			if template.stat == &"crit_chance":
				crit_values.append_array([0.64, 0.65])
			for crit in crit_values:
				game.player.stats.load_save_data(baseline)
				game.player.stats.crit_chance = crit
				game.in_shop = false
				game.shop_panel.visible = false
				game.rewards.pending_levels = 1
				game.rewards.step = PostWaveRewards.Step.LEVELS
				var choices: Array[UpgradeData] = []
				for other in templates:
					if other.stat != template.stat and choices.size() < 3:
						choices.append(other.with_tier(1))
				choices.append(template.with_tier(tier))
				game.choice_panel.show_upgrades(choices)
				var before: Dictionary = game.player.stats.to_save_data()
				# Exercise real JSON persistence and a new scene, not just in-memory restore.
				game._save_run()
				game.free()
				session.resume_requested = true
				game = GAME_SCENE.instantiate()
				root.add_child(game)
				current_scene = game
				var label := "%s tier=%d initial_crit=%.2f" % [template.stat, tier, crit]
				if not _check(game.choice_panel.current_upgrades.size() == 4 and game.choice_panel.mode == &"upgrade" and paused, "resume lost four-choice screen: " + label):
					_finish(game, session)
					return
				for index in 4:
					var restored: UpgradeData = game.choice_panel.current_upgrades[index]
					var offered := choices[index]
					_check(restored.stat == offered.stat and restored.display_name == offered.display_name and restored.tier == offered.tier and is_equal_approx(restored.amount, offered.amount), "resume changed choice %d: %s" % [index, label])
				_check_stats(game.player.stats.to_save_data(), before, "resume changed build: " + label)
				var chosen := choices[3]
				var expected := before.duplicate()
				expected[str(chosen.stat)] = float(before[str(chosen.stat)]) + chosen.amount
				if chosen.stat == &"crit_chance":
					expected["crit_chance"] = minf(float(expected["crit_chance"]), 0.65)
				elif chosen.stat == &"max_health":
					expected["health"] = minf(float(before["health"]) + chosen.amount, float(expected["max_health"]))
				game.choice_panel.buttons[3].pressed.emit()
				_check_stats(game.player.stats.to_save_data(), expected, "fourth choice effect differs: " + label)
				_check(game.rewards.pending_levels == 0 and game.in_shop and game.shop_panel.visible, "fourth choice did not resolve before shop: " + label)
				cases += 1
	_finish(game, session)


func _check_stats(actual: Dictionary, expected: Dictionary, context: String) -> void:
	for key in expected:
		_check(is_equal_approx(float(actual[key]), float(expected[key])), "%s / %s expected=%.4f actual=%.4f" % [context, key, float(expected[key]), float(actual[key])])


func _finish(game: Node2D, session: Node) -> void:
	session.clear_run()
	paused = false
	game.free()
	if failures.is_empty():
		print("Denti upgrade resume test passed: %d deterministic cases" % cases)
	quit(0 if failures.is_empty() else 1)
