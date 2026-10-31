extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func _settle() -> void:
	for frame in 8: await process_frame

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_ascension_test.json"
	session.clear_run()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.set_process(false)
	game.wave.active = false
	paused = true
	_prices_and_drafts()
	_fusion_budget()
	await _real_flow(session)
	await _layouts()
	session.clear_run()
	paused = false
	if failures == 0: print("PASS weapon_ascension: root-weighted prices, endless scaling, mixed atomic drafts, undo, stale budgets, native purchase, real JSON resume, additive stats, telemetry and seven layouts")
	finish(0 if failures == 0 else 1)

func _prices_and_drafts() -> void:
	var small := WeaponCatalog.by_id(&"turbo_drill")
	var large := WeaponCatalog.by_id(&"magic_toothbrush")
	for data in [small, large]:
		var current: WeaponData = data
		for row in [[3, 60], [5, 100], [8, 160], [12, 240], [17, 340]]:
			var price := WeaponAscension.quote(current, 20)
			_check(int(price.cost) == row[0] * data.hands and int(price.coins) == row[1] * data.hands, "agreed ascending price/root curve changed")
			_check(WeaponAscension.quote(current, 1) == price, "normal-wave inflation made the advertised ascension price unstable")
			_check(int(WeaponAscension.quote(current, 40).coins) == ceili(int(price.coins) * EndlessRules.price_factor(40)), "ascension missed endless gold inflation")
			current = WeaponAscension.advance(current)
	_check(6 * int(WeaponAscension.quote(small, 20).cost) == 3 * int(WeaponAscension.quote(large, 20).cost), "equal six-root builds pay different point budgets")
	_check(6 * int(WeaponAscension.quote(small, 20).coins) == 3 * int(WeaponAscension.quote(large, 20).coins), "equal six-root builds pay different gold budgets")
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "turbo_drill", "tier": 4}, {"id": "turbo_drill", "tier": 4}, {"id": "magic_toothbrush", "tier": 3}])
	var first := loadout.equipped()[0]
	var uid := first.instance_uid
	var original := loadout.save_data()
	var bank := WeaponUpgradeState.new()
	bank.points = 20
	_check(not bank.plan_ascension(loadout, loadout.equipped()[2].instance_uid, 10000, 15), "Mk III bypassed the fusion gate")
	_check(not bank.plan_ascension(loadout, uid, 59, 15), "insufficient gold accepted an ascension")
	bank.points = 2
	_check(not bank.plan_ascension(loadout, uid, 1000, 15), "insufficient points accepted an ascension")
	bank.points = 20
	_check(bank.plan(loadout, uid, &"crit") and bank.plan_ascension(loadout, uid, 1000, 15), "mixed effect/ascension draft rejected")
	_check(bank.remaining() == 16 and bank.remaining_gold(1000) == 940 and loadout.save_data() == original, "draft spent money or changed live equipment")
	_check(WeaponAscension.level(bank.preview_data(first)) == 1 and bank.preview_data(loadout.equipped()[1]).chest_upgrades.get("mk", 0) == 0, "preview missed the ascension or changed an identical copy")
	bank.undo()
	_check(bank.remaining() == 19 and bank.gold_spent() == 0, "undo lost points or reserved gold")
	_check(bank.plan_ascension(loadout, uid, 1000, 15) and bank.plan_ascension(loadout, uid, 1000, 15), "second Mk step rejected")
	_check(bank.remaining() == 11 and bank.gold_spent() == 160, "queued Mk steps reused the cheaper first price")
	_check(not bank.commit(loadout, 159, 15) and loadout.save_data() == original and bank.points == 20, "gold shortfall partially committed effects/ascensions")
	bank.actions[1].coins = 1
	_check(not bank.commit(loadout, 1000, 15) and loadout.save_data() == original, "tampered ascension quote partially committed")
	bank.validate(loadout, 1000, 15)
	_check(bank.gold_spent() == 160 and bank.commit(loadout, 160, 15), "validated draft failed to reconstruct authoritative prices")
	_check(bank.points == 11 and WeaponPresentation.tier_text(first.data, first.tier) == "Mk VI" and first.affixes.size() == 1 and first.affix_slots == 4, "commit lost ranks, Mk or the four-slot cap")
	_check(is_equal_approx(first.data.base_damage, small.base_damage * 1.2) and is_equal_approx(first.data.interval, small.interval / 1.06) and is_equal_approx(first.data.attack_range, small.attack_range * 1.06), "ascension bonuses compounded instead of adding to the base")
	_check(bank.plan_ascension(loadout, uid, 1000, 15), "next ascension unavailable")
	first.data = WeaponAscension.advance(first.data)
	var changed := loadout.save_data()
	_check(not bank.commit(loadout, 1000, 15) and loadout.save_data() == changed, "stale Mk target received a second unquoted upgrade")
	bank.validate(loadout, 1000, 15)
	_check(bank.actions.is_empty() and bank.points == 11, "stale draft swallowed unspent points")
	loadout.restore([{"id": str(WeaponEvolutions.ALL[0].result.id), "tier": 4}])
	_check(bank.plan_ascension(loadout, loadout.equipped()[0].instance_uid, 1000, 15), "evolved weapon cannot ascend")
	var saved := RunSnapshot.capture(game)
	for key in ["coins", "from_mk"]:
		var broken := saved.duplicate(true)
		broken.rewards.weapon_upgrades.actions = [{"id": "mk", key: []}]
		_check(RunSaveData.normalize(broken).is_empty(), "invalid ascension metadata entered typed restore")

func _fusion_budget() -> void:
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "magic_toothbrush", "tier": 4}, {"id": "magic_toothbrush", "tier": 4}])
	var weapons := loadout.equipped()
	for weapon in weapons: weapon.data = WeaponAscension.advance(weapon.data)
	var result := WeaponAscension.inherit(WeaponCatalog.by_id(&"turbo_drill"), weapons[0].data, weapons[1].data)
	var plan := WeaponFusionPlan.new()
	plan.configure(weapons[0], weapons[1], result, 4)
	_check(WeaponAscension.level(result) == 2 and plan.total_points == 12 and WeaponAscension.invested_points(result) == 8 and plan.refund() == 4, "cross-root evolution minted Mk ranks or lost paid points")
	var repeated := WeaponAscension.inherit(result, result)
	_check(WeaponAscension.level(repeated) == 2 and WeaponAscension.invested_points(repeated) == 8, "repeated inheritance compounds paid Mk levels")
	_check(WeaponAffixes.apply(weapons[0], {"id": "mk"}), "an already saved Mk capsule no longer applies to a paid weapon")
	result = WeaponAscension.inherit(weapons[0].data, weapons[0].data)
	_check(WeaponAscension.level(result) == 2 and WeaponAscension.invested_points(result) == 6 and int(result.chest_upgrades.mk_legacy) == 1, "a free legacy Mk awarded after purchase vanished or minted refundable points")
	var legacy := WeaponRolls.resolve(WeaponCatalog.by_id(&"magic_toothbrush"), {}, {"mk": 2})
	result = WeaponAscension.inherit(WeaponCatalog.by_id(&"uv_lamp"), legacy, legacy)
	_check(WeaponAscension.level(result) == 4 and WeaponAscension.invested_points(result) == 0, "legacy Mk finds were lost or converted to free points")
	# Real evolution through the loadout uses the same budget and refunds.
	for recipe in WeaponEvolutions.ALL:
		if recipe.partner_weapon == &"": continue
		loadout.restore([{"id": str(recipe.base_weapon), "tier": 4}, {"id": str(recipe.partner_weapon), "tier": 4}])
		game.items.restore({})
		for id in recipe.items: game.items.acquire(ItemCatalog.by_id(id))
		for family in recipe.families:
			for item in ItemCatalog.ALL:
				if item.family_id == family: game.items.acquire(item); break
		weapons = loadout.equipped()
		var paid := 0
		for weapon in weapons:
			weapon.data = WeaponAscension.advance(weapon.data)
			paid += WeaponAscension.invested_points(weapon.data)
		plan = loadout.fusion_plan(0, recipe, game.items)
		_check(plan != null, "paid Mk blocked a real evolution")
		if plan != null:
			var refund := plan.refund()
			var state := WeaponUpgradeState.new()
			_check(loadout.commit_fusion(plan, game.items, state), "real evolution failed to commit paid Mk")
			_check(WeaponAscension.invested_points(loadout.equipped()[0].data) + state.points == paid and state.points == refund, "real evolution failed to conserve invested Mk points")
		break

func _real_flow(session: Node) -> void:
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}])
	game.coins = 300
	game.wave.current_wave = 15
	game.rewards.weapon_upgrades.points = 12
	game.rewards.step = PostWaveRewards.Step.WEAPONS
	game._advance_post_wave_rewards()
	await _settle()
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	_check(not panel.ascension_button.disabled and panel.ascension_button.text.contains("120 Gold"), "real purchase does not show the two-root quote")
	await _click(panel.ascension_button)
	_check(game.coins == 300 and game.rewards.weapon_upgrades.points == 12 and game.rewards.weapon_upgrades.remaining() == 6 and WeaponAscension.level(game.player.loadout.equipped()[0].data) == 0, "native click spent resources before confirmation")
	await _click(panel.back_button)
	_check(game.rewards.weapon_upgrades.actions.is_empty() and game.coins == 300, "native undo lost currency")
	await _click(panel.ascension_button)
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await _settle()
	game = current_scene
	game.wave.set_process(false)
	panel = game.weapon_enchantment_panel
	_check(panel.visible and paused and game.coins == 300 and game.rewards.weapon_upgrades.gold_spent() == 120 and WeaponAscension.level(panel.models[0].data) == 1, "real JSON resume lost or applied the pending ascension")
	await _click(panel.finish_button)
	_check(game.in_shop and game.shop_panel.visible and game.coins == 180 and game.rewards.weapon_upgrades.points == 6 and WeaponAscension.level(game.player.loadout.equipped()[0].data) == 1, "confirmation failed to debit both currencies exactly once")
	_check(WeaponAscension.invested_points(game.player.loadout.equipped()[0].data) == 6, "confirmed point investment was not attached to its weapon")
	_check(game.telemetry.wave_shop_spending.get("mk_upgrade", 0) == 120, "ascension gold is missing from economy telemetry")
	game._on_weapon_upgrades_completed()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	RunSnapshot.restore(game, saved)
	_check(game.coins == 180 and game.rewards.weapon_upgrades.points == 6 and WeaponAscension.level(game.player.loadout.equipped()[0].data) == 1, "repeat confirmation or resume charged twice")
	_check(WeaponAscension.invested_points(game.player.loadout.equipped()[0].data) == 6, "JSON resume lost the evolution budget")
	game.rewards.weapon_upgrades.points = 0
	game._update_shop_panel()
	_check(game.shop_panel.enchant_button.visible, "Mk IV+ access disappeared at zero points")
	game._on_shop_enchant()
	await _settle()
	_check(panel.visible and panel.ascension_button.disabled, "zero-point player cannot inspect the next ascension cost")

func _layouts() -> void:
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "turbo_drill", "tier": 4}, {"id": "magic_toothbrush", "tier": 4}])
	var state := WeaponUpgradeState.new()
	state.points = 100
	state.plan_ascension(loadout, loadout.equipped()[0].instance_uid, 5000, 30)
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(320, 568), Vector2i(360, 640), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1920, 1080)]:
		root.size = extent
		root.content_scale_size = extent
		panel.show_upgrades(state, loadout, game.player.stats, game.items, null, 5000, 30)
		await _settle()
		_check(panel.upgrade_buttons.size() == 4 and not panel.ascension_button.disabled, "ascension replaced an effect slot or lost access at %s" % extent)
		_check(Rect2(Vector2.ZERO, panel.body.size).grow(1).encloses(panel.ascension_button.get_rect()), "ascension escapes its content at %s" % extent)
		_check(panel.ascension_button.size.x + 1 >= panel.ascension_button.get_minimum_size().x, "ascension text is clipped at %s" % extent)
		_check(Rect2(Vector2.ZERO, Vector2(extent)).grow(1).encloses(panel.stage.header.get_global_rect()), "two-currency header exceeds viewport at %s" % extent)
		_check(panel.stage.panel.get_global_rect().encloses(panel.finish_button.get_global_rect()), "ascension displaced Finish at %s" % extent)

func _click(button: Button) -> void:
	var center := button.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = center
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await _settle()
