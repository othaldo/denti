extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	_test_damage_and_armor()
	_test_weapon_scaling()
	_test_migrations()
	_test_live_build()
	paused = false
	root.get_node("GameSession").clear_run()
	if failures == 0:
		print("PASS damage_defense_balance")
	quit(0 if failures == 0 else 1)


func _test_damage_and_armor() -> void:
	var stats := PlayerStats.new()
	_check(stats.damage_bonus == 0.0 and stats.melee_damage == 0.0 and stats.ranged_damage == 0.0, "new damage stats do not start at zero")
	stats.apply_upgrade(&"damage_bonus", 20.0)
	stats.apply_upgrade(&"damage_bonus", 30.0)
	_check(stats.scale_damage(20.0) == 30.0, "damage bonuses multiply instead of adding")
	stats.apply_upgrade(&"damage_bonus", -110.0)
	_check(is_equal_approx(stats.scale_damage(20.0), 8.0), "-60% does not leave 40% weapon damage")
	stats.apply_upgrade(&"damage_bonus", -200.0)
	_check(stats.scale_damage(20.0) == 1.0, "negative damage bypasses minimum hit damage")
	stats.apply_upgrade(&"damage_bonus", 260.0)
	_check(stats.scale_damage(20.0) == 20.0, "damage floor discarded underlying penalties")
	stats.crit_chance = 0.0
	stats.damage_bonus = 25.0
	_check(stats.scale_damage(stats.roll_critical_damage(20.0, 0.0, 2.0, true)) == 50.0, "crit or global damage applied twice")
	for row in [[0.0, 1.0], [1.0, 0.9375], [5.0, 0.75], [15.0, 0.5], [30.0, 1.0 / 3.0], [-15.0, 1.5], [-30.0, 5.0 / 3.0]]:
		stats.armor = row[0]
		_check(is_equal_approx(stats.armor_damage_factor(), row[1]), "armor does not follow the reference defense curve")
		stats.health = 100.0
		_check(is_equal_approx(stats.take_damage(20.0), 20.0 * row[1]), "actual incoming damage ignores armor curve")
	stats.armor = 10.0
	stats.health = 100.0
	_check(is_equal_approx(stats.take_damage(10.0), 6.0), "ten armor trivializes ten-damage attacks")
	stats.shield_charges = 1
	var health_before := stats.health
	_check(stats.take_damage(50.0) == 0.0 and stats.health == health_before, "armor change bypasses shields")
	stats.health = 100.0
	stats.armor = 10000.0
	_check(stats.take_damage(10.0) == 1.0, "positive armor bypasses minimum received damage")
	stats.free()


func _test_weapon_scaling() -> void:
	var stats := PlayerStats.new()
	stats.crit_chance = 0.0
	for weapon in WeaponCatalog.ALL:
		_check(weapon.damage_stat in ["melee", "ranged"] and weapon.stat_scaling > 0.0, "weapon lacks a declared stat/scaling")
		stats.melee_damage = 0.0
		stats.ranged_damage = 0.0
		stats.damage_bonus = 0.0
		_check(is_equal_approx(weapon.damage_with_stats(1, stats), weapon.damage_at_tier(1)), "base damage changed before upgrades")
		stats.apply_upgrade(StringName("ranged_damage" if weapon.damage_stat == "melee" else "melee_damage"), 100.0)
		_check(is_equal_approx(weapon.damage_with_stats(1, stats), weapon.damage_at_tier(1)), "wrong specialization scales weapon")
		stats.apply_upgrade(StringName(weapon.damage_stat + "_damage"), 10.0)
		for tier in [1, 4]:
			_check(is_equal_approx(weapon.raw_damage_with_stats(tier, stats) - weapon.damage_at_tier(tier), 10.0 * weapon.stat_scaling), "fusion also multiplies flat-stat scaling")
		stats.damage_bonus = 20.0
		var before_crit := weapon.damage_with_stats(4, stats)
		var chance := weapon.crit_bonus
		if weapon.crit_cycle > 0:
			chance = 1.0 / weapon.crit_cycle + (1.0 - 1.0 / weapon.crit_cycle) * chance
		var expected := before_crit * (1.0 + chance * (weapon.crit_multiplier - 1.0)) * weapon.trash_damage_factor * (1.0 + 0.55 * float(weapon.projectile_count_at_tier(4) - 1)) / weapon.cooldown_at_tier(4, stats.attack_interval, 1.0)
		_check(is_equal_approx(weapon.estimated_dps(4, stats), expected), "DPS estimate uses an outdated damage formula")
	var fast := WeaponCatalog.by_id(&"interdental_brush")
	var heavy := WeaponCatalog.by_id(&"turbo_drill")
	_check(fast.stat_scaling < heavy.stat_scaling and fast.interval < heavy.interval, "fast AoE has the same flat scaling as a slower single-target weapon")
	stats.damage_bonus = -200.0
	var grinder := WeaponCatalog.by_id(&"cavity_grinder")
	_check(is_equal_approx(grinder.estimated_dps(1, stats), 1.0 / grinder.interval_at_tier(1)), "minimum damage DPS is reduced below one HP by a trash modifier")
	stats.free()


func _test_migrations() -> void:
	var stats := PlayerStats.new()
	stats.load_save_data({"stat_model_version": 2, "damage": 42.0, "attack_speed": 25.0, "speed_bonus": -12.0, "regen": 3.0, "regen_progress": 0.6, "armor": 15.0})
	_check(is_equal_approx(stats.scale_damage(18.0), 42.0), "legacy raw damage changed during migration")
	_check(stats.attack_speed == 25.0 and stats.speed_bonus == -12.0 and stats.regen == 3.0 and stats.regen_progress == 0.6, "version-2 migration repeated the previous tempo/regen conversion")
	_check(stats.melee_damage == 0.0 and stats.ranged_damage == 0.0, "legacy migration invented specialization bonuses")
	stats.apply_upgrade(&"melee_damage", 6.0)
	stats.apply_upgrade(&"ranged_damage", -2.0)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(stats.to_save_data()))
	stats.load_save_data(saved)
	_check(is_equal_approx(stats.scale_damage(18.0), 42.0) and stats.melee_damage == 6.0 and stats.ranged_damage == -2.0, "save/resume duplicated global or lost signed specialization stats")
	stats.free()


func _test_live_build() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_damage_defense_balance.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	paused = true
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100.0, 0.0))
	var bleed_target: Enemy = game.get_node("Enemies").get_child(-1)
	var scaler := WeaponCatalog.by_id(&"plaque_scaler")
	game.items.on_weapon_hit(bleed_target, 1.0, scaler, false)
	_check(is_equal_approx(bleed_target.bleed_dps, scaler.bleed_dps), "percent conversion changed baseline fractional bleeding damage")
	game.player.stats.damage_bonus = 100.0
	game.items.on_weapon_hit(bleed_target, 1.0, scaler, false)
	_check(is_equal_approx(bleed_target.bleed_dps, scaler.bleed_dps * 2.0), "Bisskraft does not scale bleeding exactly once")
	game._clear_combat()
	for id in [&"amalgam_core", &"forbidden_lollipop", &"scalpel_wax", &"conductive_varnish", &"implant"]:
		game.items.acquire(ShopController.by_id(id))
	game.relics.acquire(&"shattered_halo")
	game.relics.halo_time = 4.0
	game.player.stats.damage_bonus = 20.0
	game.player.stats.armor = 10.0
	game.player.is_moving = true
	game._create_enemy(WaveController.CAVITY_COUNT, game.player.position + Vector2(100.0, 0.0))
	var boss: Enemy = game.boss
	boss.bleed_stacks = 1
	boss.wet_time = 1.0
	var water := WeaponCatalog.by_id(&"water_jet")
	_check(is_equal_approx(game.items.modify_damage(boss, water, 40.0), 109.2), "global + armor + halo + movement + wet + bleed + boss bonuses compound multiplicatively")
	game.player.is_moving = false
	var shown := WeaponPresentation.values(water, 1, game.player)
	_check(is_equal_approx(shown.damage, 19.25), "weapon card does not add global, armor and halo bonuses")
	game.player.loadout.acquire(water)
	game._clear_combat()
	# All-ranged loadouts should not spend post-wave choices on dead melee stats.
	for trial in 30:
		game._show_level_choice()
		for option in game.choice_panel.current_upgrades:
			_check(option.stat != &"melee_damage", "all-ranged build received an unusable melee choice")
	game.player.loadout.acquire(WeaponCatalog.by_id(&"turbo_drill"))
	game.player.stats.melee_damage = 4.0
	game.player.stats.ranged_damage = 2.0
	game.rewards.pending_levels = 1
	game.rewards.step = PostWaveRewards.Step.LEVELS
	var options: Array[UpgradeData] = []
	for id in ["bisskraft", "nahschaden", "fernschaden"]:
		options.append((load("res://data/upgrades/%s.tres" % id) as UpgradeData).with_tier(2))
	game.choice_panel.show_upgrades(options)
	var snapshot := RunSnapshot.capture(game)
	snapshot["upgrades"][0]["stat"] = "damage"
	game.free()
	session.save_run(snapshot)
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_check(game.player.stats.melee_damage == 4.0 and game.player.stats.ranged_damage == 2.0, "continue lost specialization values")
	_check(game.choice_panel.current_upgrades.size() == 3, "legacy Bisskraft choice disappeared")
	if game.choice_panel.current_upgrades.size() == 3:
		game.choice_panel._on_choice_pressed(0)
		_check(game.player.stats.damage_bonus == 28.0, "legacy choice applied raw damage instead of its new percentage")
	game.free()
