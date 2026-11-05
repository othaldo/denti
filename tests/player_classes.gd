extends "res://tests/support/test_runtime.gd"

var failures := 0
var profile: PlayerClassData

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _rule(stat: StringName, low: float, high: float, gain: float = 1.0) -> ClassStatRuleData:
	var rule := ClassStatRuleData.new()
	rule.stat = stat
	rule.has_minimum = true
	rule.minimum = low
	rule.has_maximum = true
	rule.maximum = high
	rule.gain_factor = gain
	return rule

func _conversion(source: StringName, target: StringName, factor: float) -> ClassStatConversionData:
	var result := ClassStatConversionData.new()
	result.source_stat = source
	result.target_stat = target
	result.factor = factor
	return result

func _run() -> void:
	_check(ClassCatalog.DEFAULT.valid() and ClassCatalog.profiles.size() == 2, "shipping classes are invalid or expose diagnostic profiles")
	for weapon in WeaponCatalog.ALL:
		_check(not weapon.class_roles.is_empty(), "standard weapon has no class role: " + str(weapon.id))
		for role in weapon.class_roles: _check(role in WeaponRoles.ALL, "unknown standard weapon role")
	for recipe in WeaponEvolutions.ALL:
		_check(not recipe.result.class_roles.is_empty(), "evolution has no class role: " + str(recipe.id))
	profile = PlayerClassData.new()
	profile.id = &"test_contact"
	profile.display_name = "Kontaktprobe"
	profile.root_capacity = 4
	profile.allowed_weapon_roles.assign([&"contact"])
	profile.starting_stats = {"melee_damage": 3.0}
	profile.preferred_tags.assign([&"poison"])
	profile.stat_rules.assign([_rule(&"armor", 0, 5, 2), _rule(&"crit_chance", 0, 0.25), _rule(&"max_health", 1, 120), _rule(&"luck", 10, 50), _rule(&"dash_recovery_bonus", 0, 50)])
	profile.conversions.assign([_conversion(&"armor", &"melee_damage", 2)])
	profile.dash_override = DashData.new()
	profile.dash_override.capacity = 200
	profile.dash_override.recharge_rate = 35
	_check(profile.valid(), "valid class profile rejected")
	ClassCatalog.profiles.append(profile)
	_test_stats()
	_test_invalid_profiles()
	_test_setup()
	await _test_game()
	ClassCatalog.profiles.erase(profile)
	root.get_node("GameSession").clear_run()
	if failures == 0: print("PASS player classes: caps, raw contributions, conversions, weapons, fusion, shop, reward flow, previews and resume")
	finish(0 if failures == 0 else 1)

func _test_stats() -> void:
	var neutral := new_stats()
	var neutral_before := neutral.to_save_data()
	_check(neutral.begin_class(ClassCatalog.DEFAULT) and neutral.to_save_data() == neutral_before, "Good Old Molar changed baseline stats")
	var automatic := new_stats()
	automatic.class_data = profile
	root.add_child(automatic)
	_check(automatic.root_capacity == 4 and automatic.melee_damage == 3 and not automatic.begin_class(profile), "node readiness omitted or repeated profile initialization")
	var challenge := new_stats()
	challenge.root_capacity = 8
	root.add_child(challenge)
	_check(challenge.root_capacity == 8 and challenge.class_data == ClassCatalog.DEFAULT, "default initialization replaced challenge roots")
	var stats := new_stats()
	_check(stats.begin_class(profile) and stats.root_capacity == 4 and stats.melee_damage == 3, "class did not apply initial roots/stats")
	_check(not stats.begin_class(profile) and stats.melee_damage == 3, "class start could be applied twice")
	stats.apply_upgrade(&"armor", 5)
	_check(stats.raw_stat(&"armor") == 10 and stats.armor == 5 and stats.melee_damage == 13, "cap lost raw armor or conversion used uncapped armor")
	stats.apply_upgrade(&"armor", -7)
	_check(stats.armor == 3 and stats.melee_damage == 9, "penalty was scaled like a gain or applied to capped value")
	var before := stats.class_save_data()
	_check(DentiAttributes.upgrade_preview_text(stats, DentiAttributes.Type.ARMOR, 2) == "3 → 5 · MAX", "preview ignores class gain/cap")
	_check(stats.class_save_data() == before and stats.armor == 3, "preview mutated the build")
	stats.apply_upgrade(&"crit_chance", 0.4)
	_check(is_equal_approx(stats.raw_stat(&"crit_chance"), 0.45) and stats.crit_chance == 0.25, "crit class limit discarded overflow")
	stats.apply_upgrade(&"crit_chance", -0.1)
	_check(stats.crit_chance == 0.25, "penalty subtracted from effective crit")
	stats.apply_upgrade(&"crit_chance", -0.15)
	_check(is_equal_approx(stats.crit_chance, 0.2), "crit overflow did not unwind correctly")
	stats.apply_upgrade(&"luck", -20)
	_check(stats.luck == 10 and stats.raw_stat(&"luck") == -20, "class minimum overwrote the raw penalty")
	stats.health = 50
	stats.apply_upgrade(&"max_health", 50)
	_check(stats.max_health == 120 and stats.health == 70, "capped HP purchase healed by the nominal amount")
	stats.apply_upgrade(&"max_health", 50)
	_check(stats.raw_stat(&"max_health") == 200 and stats.health == 70, "purchase at HP cap granted free healing")
	stats.apply_upgrade(&"dash_recovery_bonus", 90)
	_check(stats.max_stamina() == 250 and not stats.upgrade_has_effect(&"dash_recovery_bonus", 90), "class stamina cap ignored")
	var temporary := new_stats()
	var temp_profile := profile.duplicate(true) as PlayerClassData
	temp_profile.stat_rules.append(_rule(&"attack_speed", -50, 20))
	temp_profile.stat_rules.append(_rule(&"damage_bonus", -50, 25))
	temporary.begin_class(temp_profile)
	_check(is_equal_approx(temporary.attack_interval_with_bonus(50), 0.65 / 1.2) and temporary.damage_factor(100) == 1.25, "temporary bonuses bypass class limits")
	_check(temporary.raw_stat(&"attack_speed") == 0 and temporary.raw_stat(&"damage_bonus") == 0, "temporary bonuses changed permanent contributions")
	var evasive := new_stats()
	var evasive_profile := profile.duplicate(true) as PlayerClassData
	evasive_profile.stat_rules.append(_rule(&"dodge_chance", 0, 0.8))
	evasive.begin_class(evasive_profile)
	evasive.apply_upgrade(&"dodge_chance", 0.75)
	_check(evasive.effective_dodge_chance() == 0.75 and DentiAttributes.upgrade_preview_text(evasive, DentiAttributes.Type.DODGE, 0.12) == "75 % → 80 % · MAX", "raised class dodge limit differs between combat and preview")
	var restored := new_stats()
	var saved_stats: Dictionary = JSON.parse_string(JSON.stringify(stats.to_save_data()))
	var state: Dictionary = JSON.parse_string(JSON.stringify(stats.class_save_data()))
	for index in 3:
		_check(restored.load_save_data(saved_stats, state), "class stats failed to load")
		var round_trip_state: Dictionary = JSON.parse_string(JSON.stringify(restored.class_save_data()))
		var round_trip_stats: Dictionary = JSON.parse_string(JSON.stringify(restored.to_save_data()))
		_check(round_trip_state == state and round_trip_stats == saved_stats, "resume changed raw contributions or reapplied gains")
	var live_before := restored.class_save_data()
	var invalid := state.duplicate(true)
	invalid.version = 99
	_check(not restored.load_save_data(saved_stats, invalid) and restored.class_save_data() == live_before, "unsupported class rules mutated live stats")
	restored.load_save_data({"stat_model_version": 3, "health": 75, "root_capacity": 8, "armor": 2})
	_check(restored.class_data == ClassCatalog.DEFAULT and restored.root_capacity == 8 and restored.armor == 2, "legacy save retained diagnostic class rules")

func _test_invalid_profiles() -> void:
	var cyclic := profile.duplicate(true) as PlayerClassData
	cyclic.conversions.append(_conversion(&"melee_damage", &"armor", 1))
	_check(not cyclic.valid(), "conversion cycle accepted")
	var invalid := profile.duplicate(true) as PlayerClassData
	invalid.stat_rules.append(_rule(&"unknown", 0, 1))
	_check(not invalid.valid(), "unknown attribute accepted")
	invalid = profile.duplicate(true) as PlayerClassData
	invalid.stat_rules[0].minimum = 8
	_check(not invalid.valid(), "inverted limits accepted")
	invalid = profile.duplicate(true) as PlayerClassData
	invalid.allowed_weapon_roles.assign([&"unknown_role"])
	_check(not invalid.valid(), "unknown weapon role accepted")

func _test_setup() -> void:
	var setup := RunSetup.new()
	setup.weapon_id = &"uv_lamp"
	_check(setup.select_class(profile.id) and setup.root_capacity == 4 and setup.weapon_id == &"", "preparation did not update roots or invalidate a forbidden starter")
	setup.weapon_id = &"turbo_drill"
	setup.save_to("user://test_class_setup.json")
	var restored := RunSetup.load_from("user://test_class_setup.json")
	_check(restored != null and restored.class_id == profile.id and restored.root_capacity == 4 and restored.weapon_id == &"turbo_drill", "preparation lost its class")
	setup.resume_pending = true
	_check(not setup.select_class(ClassCatalog.DEFAULT.id), "pending saved run changed class")
	_check(not setup.select_class(&"missing_class") and setup.class_id == profile.id, "invalid class changed preparation")
	RunStore.clear("user://test_class_setup.json")

func _test_game() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_player_classes.json"
	session.clear_run()
	session.selected_story_mode = false
	session.pending_start_class_id = profile.id
	var scene := load("res://scenes/game/game.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check(game.player.stats.class_data == profile and game.player.loadout.capacity == 4, "run did not initialize selected class before player readiness")
	_check(game.choice_panel.starter_selection.brand_text.text == profile.display_name, "starter preview displayed the previous class")
	_check(game.player.dash.config.recharge_rate == 35 and game.player.dash.capacity == 200, "class dash rules did not reach gameplay")
	var starts: Array = game.choice_panel.starter_options
	_check(starts.size() >= 2 and not WeaponCatalog.by_id(&"floss_garrote") in starts, "long melee-stat weapon bypassed contact restriction")
	var loadout: WeaponLoadout = game.player.loadout
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	var lamp := WeaponCatalog.by_id(&"uv_lamp")
	_check(not loadout.acquire(lamp) and not loadout.weapon_allowed(lamp), "direct purchase ignored weapon roles")
	for index in 4: _check(loadout.acquire(drill), "valid contact weapon rejected")
	_check(loadout.acquire(drill) and loadout.used_slots() == 4, "class check broke full-root purchase fusion")
	for seed_value in range(20):
		game.shop.rng.seed = seed_value
		game.shop.open_shop(10, 0, loadout, game.items)
		for offer in game.shop.offers:
			if offer != null and offer.weapon_data != null:
				_check(loadout.weapon_allowed(offer.weapon_data), "shop/fallback offered forbidden weapon")
		var fallback: ShopOfferData = game.shop._pick_weapon(1, loadout, true)
		_check(fallback == null or loadout.weapon_allowed(fallback.weapon_data), "capacity fallback bypassed class prohibition")
	var recipe := WeaponEvolutionRecipe.new()
	recipe.base_weapon = drill.id
	recipe.result = lamp
	loadout.restore([{"id": "turbo_drill", "tier": 4}])
	_check(not loadout.evolution_ready(0, recipe, game.items), "evolution result bypassed class rule")
	_check(not loadout.restore([{"id": "uv_lamp", "tier": 1}], false) and loadout.equipped().size() == 1, "direct restore silently removed owned weapons")
	_check(game.items.preferred_tags(loadout).has(&"poison"), "class preferences missing from item weighting")
	game.player.stats.apply_upgrade(&"armor", 9)
	game.player.dash.charge = 37
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	_check(not RunSaveData.normalize(saved).is_empty(), "valid class snapshot rejected")
	var invalid := saved.duplicate(true)
	invalid.player.class_state.raw_stats.armor = "bad"
	_check(RunSaveData.normalize(invalid).is_empty(), "nonnumeric raw stat accepted")
	invalid = saved.duplicate(true)
	invalid.player.class_state.id = "missing_class"
	_check(RunSaveData.normalize(invalid).is_empty(), "unknown class silently fell back")
	invalid = saved.duplicate(true)
	invalid.weapons.append({"id": "uv_lamp", "tier": 1})
	_check(RunSaveData.normalize(invalid).is_empty(), "forbidden saved weapon would be silently removed")
	RunSnapshot.restore(game, saved)
	_check(game.player.stats.raw_stat(&"armor") == 18 and game.player.stats.armor == 5 and game.player.stats.melee_damage == 13, "snapshot applied initial stats or gains twice")
	_check(game.player.dash.charge == 37 and loadout.equipped().size() == 1, "resume refilled charge or changed equipment")
	# Resume through a new scene, as the application actually does.
	_check(session.save_run(saved) == OK, "class run could not be saved")
	game.free()
	session.resume_requested = true
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check(game.player.stats.class_data == profile and game.player.dash.charge == 37, "fresh-scene resume lost class/charge")
	# Legacy snapshots get the classic profile without re-awarding any modifiers.
	var legacy := saved.duplicate(true)
	legacy.player.erase("class_state")
	RunSnapshot.restore(game, legacy)
	_check(game.player.stats.class_data == ClassCatalog.DEFAULT and game.player.stats.root_capacity == 4, "legacy run was forced into diagnostic class or default roots")
	_check(game.player.stats.melee_damage == 13, "legacy aggregate stats were reconstructed twice")
	await _test_capped_rewards(game)

func _test_capped_rewards(game: Node2D) -> void:
	var caps := profile.duplicate(true) as PlayerClassData
	caps.id = &"test_capped"
	caps.stat_rules.clear()
	caps.conversions.clear()
	for key in PlayerStatKeys.ALL:
		var current := float(game.player.stats.get(key))
		caps.stat_rules.append(_rule(key, current, current))
	var armor := caps.rule_for(&"armor")
	armor.minimum = 0
	armor.maximum = 100
	ClassCatalog.profiles.append(caps)
	var state: Dictionary = game.player.stats.class_save_data()
	state.id = str(caps.id)
	game.player.stats.load_save_data(game.player.stats.to_save_data(), state)
	game.starter_pending = false
	game.wave.active = false
	game.choice_panel.hide()
	game.rewards.pending_levels = 1
	game.level = 2
	game.rewards.step = PostWaveRewards.Step.LEVELS
	game._show_level_choice()
	_check(game.choice_panel.current_upgrades.size() == 1 and game.choice_panel.current_upgrades[0].stat == &"armor", "sparse class upgrade pool assumed four useful choices")
	game._on_upgrade_chosen(game.choice_panel.current_upgrades[0])
	armor.minimum = game.player.stats.armor
	armor.maximum = armor.minimum
	game.rewards.pending_levels = 2
	game.rewards.step = PostWaveRewards.Step.LEVELS
	game.level = 4
	game.in_shop = false
	game.shop_panel.hide()
	game.choice_panel.hide()
	game._show_level_choice()
	for frame in 5: await process_frame
	_check(game.rewards.pending_levels == 0 and game.in_shop, "fully capped attributes stranded the reward queue")
	game.free()
	ClassCatalog.profiles.erase(caps)
