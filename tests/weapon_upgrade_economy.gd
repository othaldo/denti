extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://test_upgrade_economy.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	_budgets()
	_healing_and_percentages()
	_migration_and_stale_drafts()
	_fusion_conversion()
	_income_and_resume()
	await _ui_costs()
	session.clear_run()
	paused = false
	print("PASS upgrade economy: equal six-root costs, percentages/healing budgets, migration/undo/stale drafts, cross-root fusion, real pickups/item limits, bounded luck, JSON resume and UI prices")
	finish(1 if failures else 0)


func _budgets() -> void:
	var loadout: WeaponLoadout = game.player.loadout
	for setup in [["turbo_drill", 6], ["uv_lamp", 3]]:
		var equipment: Array[Dictionary] = []
		for index in int(setup[1]): equipment.append({"id": setup[0], "tier": 4})
		loadout.restore(equipment)
		var bank := WeaponUpgradeState.new()
		# 30 collected capsules buy ten ranks on every weapon in either build.
		bank.points = 30 * WeaponUpgrades.POINTS_PER_CAPSULE
		for weapon in loadout.equipped():
			for rank in 10: _check(bank.plan(loadout, weapon.instance_uid, &"fire"), "equal-root build cannot afford its ranks")
		_check(bank.remaining() == 0 and bank.commit(loadout) and bank.points == 0, "six roots did not cost exactly thirty capsules")
		for weapon in loadout.equipped(): _check(weapon.affixes[0].level == 10, "equal investment produced a missing rank")
	loadout.restore([{"id": "turbo_drill", "tier": 4}, {"id": "uv_lamp", "tier": 4}])
	var bank := WeaponUpgradeState.new()
	bank.points = 2
	var weapons := loadout.equipped()
	_check(bank.plan(loadout, weapons[0].instance_uid, &"fire") and bank.remaining() == 1, "small rank must cost one")
	_check(not bank.plan(loadout, weapons[1].instance_uid, &"fire"), "one remaining point bought a heavy rank")
	bank.undo()
	_check(bank.remaining() == 2 and bank.plan(loadout, weapons[1].instance_uid, &"fire") and bank.remaining() == 0, "undo or heavy price wrong")
	bank.undo()
	_check(bank.plan(loadout, weapons[0].instance_uid, &"fire") and bank.plan(loadout, weapons[0].instance_uid, &"fire"), "one capsule cannot buy two small ranks")


func _healing_and_percentages() -> void:
	var small := WeaponCatalog.by_id(&"turbo_drill")
	var large := WeaponCatalog.by_id(&"uv_lamp")
	for definition in WeaponAffixes.ALL:
		if definition.stat_key == &"": continue
		for rank in range(1, 11):
			_check(is_equal_approx(WeaponUpgrades.power(definition.id, rank, small, 4), WeaponUpgrades.power(definition.id, rank, large, 4)), "support double-counts the heavy weapon budget")
	for rank in range(1, 11):
		var first := WeaponUpgrades.next_entry({"id": "leech", "level": rank - 1}, &"leech", small, 4) if rank > 1 else WeaponUpgrades.next_entry({}, &"leech", small, 4)
		var second := first.duplicate(true)
		var light_heal := WeaponAffixes.utility_value(first, 1)
		var heavy_heal := WeaponAffixes.utility_value(second, 2)
		_check(is_equal_approx(light_heal * 6, heavy_heal * 3), "lifesteal capacity differs per occupied root")
		_check(is_equal_approx(AffixPresentation.display_value(float(second.damage), &"leech", large), heavy_heal), "displayed healing differs from actual budget")
	var enemy: Enemy
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(150, 0))
	enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 100000
	enemy.max_health = 100000
	enemy.damage_reduction = 0
	game.player.stats.max_health = 1000
	game.player.stats.health = 10
	game.items.cooldowns.clear()
	var effects := WeaponUpgrades.next_entry({}, &"leech", small, 4)
	var light_before: float = game.player.stats.health
	WeaponAttackShapes.hit(enemy, small, 1, 1000, false, game.items, Vector2.RIGHT, [effects], 1, false, "small")
	var light: float = game.player.stats.health - light_before
	light_before = game.player.stats.health
	WeaponAttackShapes.hit(enemy, large, 1, 1000, false, game.items, Vector2.RIGHT, [effects], 1, false, "large")
	_check(is_equal_approx(game.player.stats.health - light_before, light * 2), "actual heavy hit did not heal twice the small budget")
	game._clear_combat()


func _migration_and_stale_drafts() -> void:
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "uv_lamp", "tier": 4}])
	var weapon := loadout.equipped()[0]
	var bank := WeaponUpgradeState.new()
	bank.restore({"points": 3, "actions": [{"uid": weapon.instance_uid, "id": "fire"}]})
	bank.validate(loadout)
	_check(bank.points == 6 and bank.remaining() == 4, "old capsule bank or draft was not converted once")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(bank.save_data()))
	bank.restore(saved)
	bank.validate(loadout)
	_check(bank.points == 6 and bank.remaining() == 4 and bank.commit(loadout) and bank.points == 4, "JSON resume repeated migration or charged the old price")
	bank.plan(loadout, weapon.instance_uid, &"fire")
	bank.actions[0].cost = 1
	_check(not bank.commit(loadout) and weapon.affixes[0].level == 1 and bank.points == 4, "tampered cost partially committed")
	bank.validate(loadout)
	_check(bank.remaining() == 2 and bank.actions[0].cost == 2, "validation did not reconstruct the authoritative price")
	loadout.restore([])
	bank.validate(loadout)
	_check(bank.actions.is_empty() and bank.points == 4, "missing target destroyed banked points")


func _fusion_conversion() -> void:
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([
		{"id": "turbo_drill", "tier": 4, "affixes": [{"id": "fire", "level": 7, "damage": 1}]},
		{"id": "enamel_mirror", "tier": 4, "affixes": [{"id": "fire", "level": 6, "damage": 1}, {"id": "tempo", "level": 1, "damage": 1}]}])
	var weapons := loadout.equipped()
	var plan := WeaponFusionPlan.new()
	plan.configure(weapons[0], weapons[1], WeaponCatalog.by_id(&"uv_lamp"), 4)
	_check(plan.total_points == 14 and plan.effects().size() == 1 and plan.effects()[0].level == 6 and plan.refund() == 2, "changing root costs minted ranks or swallowed partial cost")
	plan.selected.clear()
	_check(plan.refund() == 14, "discarding effects did not return their original purchase budget")
	loadout.restore([{"id": "uv_lamp", "tier": 4, "affixes": [{"id": "ice", "level": 7, "damage": 1}]}])
	plan = WeaponFusionPlan.new()
	plan.configure(loadout.equipped()[0], null, WeaponCatalog.by_id(&"turbo_drill"), 4)
	_check(plan.effects()[0].level == 10 and plan.refund() == 4, "conversion to a small weapon bypassed the rank cap")


func _income_and_resume() -> void:
	var rewards: PostWaveRewards = game.rewards
	var income := rewards.upgrade_income
	game.items.restore({})
	var item := ItemCatalog.by_id(&"rune_polish")
	_check(item != null and item.icon_texture != null and game.items.acquire(item) and not game.items.acquire(item), "Runenpolitur missing or stackable")
	rewards.begin_wave()
	rewards.weapon_upgrades.points = 0
	for index in 4: rewards.queue_affix_chest(WeaponUpgrades.capsule(1, index == 3), game.items)
	_check(income.polish_progress == 4 and rewards.weapon_upgrades.points == 8, "real capsules did not count or a bonus was premature")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	_check(not RunSaveData.normalize(saved).is_empty(), "new income state fails save validation")
	for broken in [[], {"polish_progress": []}, {"resolved": "yes"}]:
		var invalid := saved.duplicate(true)
		invalid.rewards["upgrade_income"] = broken
		_check(RunSaveData.normalize(invalid).is_empty(), "malformed income entered a typed restore")
	RunSnapshot.restore(game, saved)
	rewards.queue_affix_chest(WeaponUpgrades.capsule(1), game.items)
	_check(income.polish_progress == 0 and income.polish_bonus == 1 and rewards.weapon_upgrades.points == 12, "fifth capsule or resume lost its non-recursive bonus")
	_check(income.finish_wave(0, 0) == 0 and income.finish_wave(100000, 0) == 0, "zero luck or repeat resolution minted a capsule")
	rewards.begin_wave()
	_check(income.polish_progress == 0 and income.polish_bonus == 0 and not income.resolved, "new wave retained its one-time luck state")
	_check(is_equal_approx(WeaponUpgradeIncome.luck_chance(100), 0.1) and WeaponUpgradeIncome.luck_chance(-20) == 0 and WeaponUpgradeIncome.luck_chance(10000000) < 0.25, "luck is not bounded with ten percent at 100")
	_check(income.finish_wave(100, 0.0999) == 2 and income.luck_bonus == 1 and income.polish_progress == 0, "luck bonus missing or recursively advancing polish")
	saved = JSON.parse_string(JSON.stringify(rewards.save_data()))
	rewards.restore(saved)
	_check(income.resolved and income.finish_wave(100, 0) == 0, "resuming rerolled the already resolved luck reward")
	rewards.begin_wave()
	rewards.queue_affix_chest(WeaponUpgrades.capsule(2), game.items)
	rewards.begin_wave()
	_check(income.polish_progress == 1, "wave change erased polish progress")
	game._spawn_loot(game.player.position, &"chest", 5, WeaponAffixes.CHEST_ID, WeaponUpgrades.capsule(2))
	var drop: Loot = game.get_node("Loot").get_child(-1)
	var before := rewards.weapon_upgrades.points
	game._on_loot_collected(&"chest", 5, WeaponAffixes.CHEST_ID, drop)
	_check(income.polish_progress == 2 and rewards.weapon_upgrades.points == before + 2 and not game.weapon_enchantment_panel.visible, "actual pickup bypassed income or interrupted combat")
	drop.free()
	# Exercise the real coordinator: luck settles after collection and before
	# the weapon screen, with no second award on repeated calls or JSON resume.
	rewards.begin_wave()
	game.player.stats.luck = 100
	var winning_seed := 0
	for candidate in range(1, 1000):
		seed(candidate)
		if randf() < WeaponUpgradeIncome.luck_chance(100):
			winning_seed = candidate
			break
	_check(winning_seed > 0, "no deterministic luck fixture found")
	seed(winning_seed)
	game.collecting_wave_loot = true
	game.wave_loot_remaining = 0
	rewards.step = PostWaveRewards.Step.COLLECTING
	before = rewards.weapon_upgrades.points
	game._finish_loot_collection()
	_check(income.resolved and income.luck_bonus == 1 and rewards.weapon_upgrades.points == before + 2 and rewards.step == PostWaveRewards.Step.WEAPONS, "real loot-sweep completion failed to award luck before enchanting")
	game._finish_loot_collection()
	saved = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	RunSnapshot.restore(game, saved)
	_check(income.resolved and income.luck_bonus == 1 and rewards.weapon_upgrades.points == before + 2, "post-wave JSON resume rerolled the luck reward")
	game.weapon_enchantment_panel.hide()


func _ui_costs() -> void:
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "uv_lamp", "tier": 4}, {"id": "turbo_drill", "tier": 4}])
	var bank := WeaponUpgradeState.new()
	bank.points = 1
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	panel.show_upgrades(bank, loadout, game.player.stats, game.items, game.rewards.upgrade_income)
	for frame in 8: await process_frame
	_check(panel.upgrade_buttons[0].disabled and panel.models[0].cost == 2, "heavy UI offers an unaffordable purchase")
	panel.select_weapon(1)
	for frame in 8: await process_frame
	_check(not panel.upgrade_buttons[0].disabled and panel.models[1].cost == 1, "small UI blocks an affordable purchase")
	panel.open_picker(0)
	panel.selected_effect = &"fire"
	panel._refresh()
	_check(panel.finish_button.text.ends_with("1") and not panel.finish_button.disabled and panel.count_label.tooltip_text.contains("2 je Kapsel"), "UI hides price or capsule value")
	panel.hide()
