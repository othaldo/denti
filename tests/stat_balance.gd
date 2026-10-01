extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	_test_scaling()
	_test_regeneration()
	_test_save_data()
	_test_build_and_resume()
	paused = false
	root.get_node("GameSession").clear_run()
	if failures == 0:
		print("PASS stat_balance")
	quit(0 if failures == 0 else 1)


func _test_scaling() -> void:
	var stats := PlayerStats.new()
	_check(stats.max_health == 100.0 and stats.attack_speed == 0.0 and stats.speed_bonus == 0.0 and stats.regen == 0.0, "base stats changed unexpectedly")
	stats.apply_upgrade(&"attack_speed", 50.0)
	_check(is_equal_approx(stats.attack_interval, 0.65 / 1.5), "+50% attack speed is not 1.5x attacks")
	stats.apply_upgrade(&"attack_speed", 50.0)
	_check(is_equal_approx(stats.attack_interval, 0.325), "two +50% bonuses do not halve the base cooldown")
	stats.apply_upgrade(&"attack_speed", -200.0)
	_check(is_equal_approx(stats.attack_interval, 1.3), "negative attack speed became singular or stopped slowing attacks")
	stats.apply_upgrade(&"attack_speed", 100.0)
	_check(is_equal_approx(stats.attack_interval, 0.65), "opposite attack bonuses did not cancel")
	stats.apply_upgrade(&"speed_bonus", 10.0)
	stats.apply_upgrade(&"speed_bonus", 10.0)
	_check(is_equal_approx(stats.move_speed, 276.0), "movement bonuses compound instead of adding")
	stats.apply_upgrade(&"speed_bonus", -120.0)
	_check(stats.move_speed == 80.0, "minimum effective movement was not preserved")
	stats.apply_upgrade(&"speed_bonus", 100.0)
	_check(is_equal_approx(stats.move_speed, 230.0), "speed floor discarded penalties and made acquisition order matter")
	for entry in [["putzeifer", &"attack_speed", [5.0, 10.0, 15.0, 20.0]], ["bewegung", &"speed_bonus", [3.0, 6.0, 9.0, 12.0]], ["speichel", &"regen", [1.0, 2.0, 3.0, 4.0]]]:
		var upgrade: UpgradeData = load("res://data/upgrades/%s.tres" % entry[0])
		for tier in range(1, 5):
			var option := upgrade.with_tier(tier)
			_check(option.stat == entry[1] and option.amount == entry[2][tier - 1], "level-up data uses old or oversized bonuses")
			_check(not option.effect_text().contains("Sekunde") and not option.effect_text().contains("s schneller"), "choice text uses old units")
	stats.free()


func _test_regeneration() -> void:
	var stats := PlayerStats.new()
	for entry in [[-5.0, 0.0], [0.0, 0.0], [1.0, 0.2], [10.0, 1.0], [21.0, 22.25 / 11.25], [33.0, 34.25 / 11.25]]:
		stats.regen = entry[0]
		_check(is_equal_approx(stats.regen_per_second(), entry[1]), "regen rate differs from reference curve")
	stats.regen = 1.0
	stats.health = 50.0
	stats._process(4.99)
	_check(stats.health == 50.0, "one regen point healed before five seconds")
	stats._process(0.01)
	_check(stats.health == 51.0, "one regen point did not heal one HP at five seconds")
	stats.health = 1.0
	stats.regen_progress = 0.0
	stats._process(60.0)
	_check(stats.health == 13.0, "one regen point heals too much in a minute")
	stats.health = 1.0
	stats.regen = 10.0
	stats._process(60.0)
	_check(stats.health == 61.0, "ten points do not heal sixty HP per minute")
	stats.health = 1.0
	stats.regen_progress = 0.0
	for frame in 3600:
		stats._process(1.0 / 60.0)
	_check(stats.health == 61.0, "regeneration changes with frame size")
	var overhealing: Array[float] = []
	stats.healed.connect(func(_amount: float, overheal: float) -> void: overhealing.append(overheal))
	stats.health = 99.5
	stats._process(10.0)
	_check(stats.health == 100.0 and overhealing.size() == 1 and overhealing[0] == 0.0, "passive regen generated overheal or exceeded max HP")
	stats._process(60.0)
	stats.health = 90.0
	stats._process(0.5)
	_check(stats.health == 90.0, "full health banked healing for the next hit")
	stats.health = 0.0
	stats._process(60.0)
	_check(stats.health == 0.0, "passive regen resurrected Denti")
	stats.health = 80.0
	stats.regen = -1.0
	stats._process(60.0)
	_check(stats.health == 80.0, "negative regen healed or damaged Denti")
	stats.free()


func _test_save_data() -> void:
	var stats := PlayerStats.new()
	stats.health = 80.0
	stats.regen = 1.0
	stats.speed_bonus = -90.0
	stats.attack_speed = -20.0
	stats._process(4.0)
	var restored := PlayerStats.new()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(stats.to_save_data()))
	restored.load_save_data(saved)
	restored._process(1.0)
	_check(restored.health == 81.0 and restored.speed_bonus == -90.0 and restored.attack_speed == -20.0, "save/resume lost tick progress or signed bonuses")
	restored.load_save_data({"move_speed": 276.0, "attack_interval": 0.325, "regen": 5.0, "health": 70.0})
	_check(is_equal_approx(restored.move_speed, 276.0) and is_equal_approx(restored.attack_interval, 0.325), "legacy migration changed existing movement/attack rate")
	_check(restored.regen == 10.0 and restored.regen_per_second() == 1.0, "legacy regen retained the old overpowered HP/s")
	saved = JSON.parse_string(JSON.stringify(restored.to_save_data()))
	restored.load_save_data(saved)
	_check(restored.regen == 10.0 and is_equal_approx(restored.attack_speed, 100.0), "new save repeated legacy migration")
	restored.load_save_data({"move_speed": 230.0, "attack_interval": 0.78})
	_check(is_equal_approx(restored.attack_interval, 0.78) and restored.attack_speed < 0.0, "legacy negative attack speed lost its slowdown")
	stats.free()
	restored.free()


func _test_build_and_resume() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_stat_balance.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	paused = true
	game.wave.active = false
	var stats: PlayerStats = game.player.stats
	stats.crit_chance = 0.0
	game.items.acquire(ShopController.by_id(&"mint_essence"))
	game.items.acquire(ShopController.by_id(&"mouthwash"))
	game.items.acquire(ShopController.by_id(&"saliva_fountain"))
	_check(stats.attack_speed == 5.0 and stats.speed_bonus == -2.0 and stats.regen == 2.0, "real item acquisitions bypass percent/point stats")
	for item in ShopController.CATALOG:
		_check(not item.stat_changes.has(&"move_speed") and not item.stat_changes.has(&"attack_interval"), "catalog still grants obsolete absolute stats")
	game.items.acquire(ShopController.by_id(&"sugar_shock"))
	stats.attack_speed = 100.0
	game.items.sugar_rush_time = 4.0
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	_check(is_equal_approx(weapon.attack_interval(), weapon.data.interval_at_tier(weapon.tier) / 2.3), "sugar rush multiplies permanent attack speed")
	game.items.sugar_rush_time = 0.0
	game.items.sugar_crash_time = 3.0
	_check(is_equal_approx(weapon.attack_interval(), weapon.data.interval_at_tier(weapon.tier) / 1.75), "sugar crash is not an additive -25% penalty")
	stats.attack_speed = 100000.0
	_check(weapon.attack_interval() == WeaponData.MIN_ATTACK_COOLDOWN, "extreme attack speed bypassed actual weapon floor")
	var shown := WeaponPresentation.values(weapon.data, weapon.tier, game.player)
	_check(is_equal_approx(shown.pause, weapon.attack_interval()), "weapon card shows a cooldown different from actual attacks")
	var expected_dps := weapon.data.damage_at_tier(weapon.tier) * (1.0 + 0.55 * float(weapon.data.projectile_count_at_tier(weapon.tier) - 1)) * weapon.data.trash_damage_factor / weapon.attack_interval()
	_check(is_equal_approx(weapon.data.estimated_dps(weapon.tier, stats, game.items.attack_interval_factor()), expected_dps), "DPS estimate ignores minimum weapon cooldown")
	stats.attack_speed = 20.0
	game.game_menu._show_stats()
	_check(_contains_label(game.game_menu.rows, "2 · 0.29 HP/s"), "stats overview confuses regeneration points with HP/s")
	game.shop.open_shop(1, stats.luck, game.player.loadout, game.items)
	game._update_shop_panel()
	_check(game.shop_panel.stats_label.text.contains("Putzeifer +20 %") and game.shop_panel.stats_label.text.contains("Bewegung -2 %") and game.shop_panel.stats_label.text.contains("2 · 0.29 HP/s"), "shop stats show wrong units")
	var options: Array[UpgradeData] = []
	for id in ["putzeifer", "bewegung", "speichel"]:
		options.append((load("res://data/upgrades/%s.tres" % id) as UpgradeData).with_tier(2))
	game.rewards.pending_levels = 1
	game.rewards.step = PostWaveRewards.Step.LEVELS
	game.choice_panel.show_upgrades(options)
	var snapshot: Dictionary = RunSnapshot.capture(game)
	snapshot["upgrades"][0]["stat"] = "attack_interval"
	snapshot["upgrades"][1]["stat"] = "move_speed"
	game.free()
	session.save_run(snapshot)
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_check(game.choice_panel.mode == &"upgrade" and game.choice_panel.current_upgrades.size() == 3, "legacy pending choices vanished on continue")
	if game.choice_panel.current_upgrades.size() == 3:
		_check(game.choice_panel.current_upgrades[0].stat == &"attack_speed" and game.choice_panel.current_upgrades[1].stat == &"speed_bonus", "legacy choices use obsolete stat names")
		game.choice_panel._on_choice_pressed(0)
		_check(game.player.stats.attack_speed == 30.0 and game.player.stats.regen == 2.0 and game.player.stats.speed_bonus == -2.0, "resume reapplied item stats or used an old level-up amount")
	game.free()


func _contains_label(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	for child in node.get_children():
		if _contains_label(child, fragment):
			return true
	return false
