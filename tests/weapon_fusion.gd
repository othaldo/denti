extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var session := root.get_node("GameSession")
	session.save_path = "user://test_weapon_fusion.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	game.in_shop = true
	game.rewards.step = PostWaveRewards.Step.SHOP
	game.shop.complete_saved_offers(game.wave.current_wave, game.player.stats.luck, game.player.loadout, game.items)
	var loadout: WeaponLoadout = game.player.loadout
	var recipe := WeaponEvolutions.by_id(&"trinity_brush")
	_fixture(recipe)
	var before := loadout.save_data()
	var bank: WeaponUpgradeState = game.rewards.weapon_upgrades
	bank.points = 2
	game._update_shop_panel()
	game._on_shop_evolve(0, recipe.id)
	var panel: WeaponFusionPanel = game.weapon_fusion_panel
	_check(panel.visible and panel.plan.candidates.size() == 7, "two fully enchanted ingredients cannot reach fusion preview")
	_check(loadout.save_data() == before and bank.points == 2, "opening preview mutated weapons or points")
	var plan := panel.plan
	_check(plan.selected.size() == 4 and plan.valid(), "default draft is not usable")
	_check(plan.total_points == 48 and plan.refund() == 19, "duplicate and discarded levels have an incorrect refund")
	_check(plan.effects()[1].level == 10, "same effects did not combine to ten")
	_check(plan.preview().element_skin == &"fire", "initial element skin incorrect")
	await _settle()
	await _click(panel.effect_buttons[WeaponAffixes.find(plan.candidates, &"ice")])
	await _settle()
	_check(not plan.selected.has(&"fire") and plan.selected.has(&"ice") and plan.selected.size() == 4, "element switch requires an extra slot or keeps two elements")
	_check(plan.preview().element_skin == &"ice" and panel.result_art.texture != null, "element switch failed to update the weapon preview")
	panel._cancel()
	_check(loadout.save_data() == before and bank.points == 2 and not panel.visible, "cancel changed inventory or refunded points")
	# A changed ingredient rejects the whole transaction without deleting anything.
	plan = loadout.fusion_plan(0, recipe, game.items)
	loadout.equipped()[0].affixes[0].level = 8
	var changed := loadout.save_data()
	_check(not loadout.commit_fusion(plan, game.items, bank) and loadout.save_data() == changed and bank.points == 2, "stale preview partially committed")
	loadout.restore(before)
	game._on_shop_evolve(0, recipe.id)
	plan = panel.plan
	# Explicitly choose four effects; all other investment returns to the bank.
	plan.selected.assign([&"ice", &"tempo", &"crit", &"crit_damage"])
	panel._layout(panel.stage.last_extent)
	var refund := plan.refund()
	var expected := plan.effects()
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(390, 844), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		await _settle()
		_check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(panel.confirm_button.get_global_rect()), "fusion confirmation escaped viewport")
		_check(panel.stage.body_scroll.get_global_rect().size.x > 0 and panel.slot_buttons.size() == 4, "fusion lost its four visible slots")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://.godot/fusion-preview")
			root.get_texture().get_image().save_png("res://.godot/fusion-preview/%dx%d.png" % [extent.x, extent.y])
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await _settle()
	await _click(panel.confirm_button)
	_check(loadout.equipped().size() == 1 and loadout.equipped()[0].data.id == recipe.result.id, "confirmation did not consume exactly two weapons")
	var result := loadout.equipped()[0]
	var result_uid := result.instance_uid
	_check(result.affixes == expected and result.affix_slots == 4 and result.data.element_skin == &"ice", "result differs from selection or root-scaled power")
	_check(bank.points == 2 + refund and game.weapon_enchantment_panel.visible and game.in_shop, "refund not available for immediate shop enchanting")
	var result_save := loadout.save_data()
	game._on_fusion_confirmed(plan)
	_check(bank.points == 2 + refund and loadout.save_data() == result_save, "double confirmation duplicated a refund")
	await _click(game.weapon_enchantment_panel.finish_button)
	_check(not game.weapon_enchantment_panel.visible and game.shop_panel.enchant_button.visible, "banked points cannot be accessed again in shop")
	for extent in [Vector2i(390, 844), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		await _settle()
		_check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.shop_panel.enchant_button.get_global_rect()) and Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.shop_panel.continue_button.get_global_rect()), "shop refund action displaced the next-wave button")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await _settle()
	var saved: Dictionary = RunSnapshot.capture(game)
	RunSnapshot.restore(game, saved)
	_check(bank.points == 2 + refund and loadout.save_data() == result_save, "save/resume lost refund or chosen effects")
	# Refund can be spent immediately and a shop draft survives resume.
	game._on_shop_enchant()
	_check(bank.plan(loadout, result_uid, &"crit"), "refunded point cannot fund an upgrade")
	saved = RunSnapshot.capture(game)
	RunSnapshot.restore(game, saved)
	_check(game.weapon_enchantment_panel.visible and bank.actions.size() == 1, "shop enchantment draft was hidden on resume")
	game._on_weapon_upgrades_completed()
	_check(bank.points == 1 + refund and loadout.equipped()[0].affixes[2].level == 5, "refunded upgrade failed to commit")
	# Ordinary MK conflicts use the same preview and the new MK slot capacity.
	loadout.restore([
		{"id": "turbo_drill", "tier": 1, "affixes": [_entry("fire", 7)]},
		{"id": "turbo_drill", "tier": 1, "affixes": [_entry("fire", 6)]}])
	game._update_shop_panel()
	_check(game.shop_panel.equipment[0].mergeable, "MK conflict remains disabled in shop")
	game._on_shop_merge(0)
	_check(panel.visible and panel.plan.tier == 2 and panel.plan.refund() == 3, "MK overflow did not open selection or refund three points")
	game._on_fusion_confirmed(panel.plan)
	_check(loadout.equipped().size() == 1 and loadout.equipped()[0].tier == 2 and loadout.equipped()[0].affixes[0].level == 10 and loadout.equipped()[0].affix_slots == 2, "MK fusion changed tier, cap or slots")
	# Duplicate / foreign selected effects cannot create extra effects or points.
	game._on_weapon_upgrades_completed()
	_fixture(recipe)
	plan = loadout.fusion_plan(0, recipe, game.items)
	plan.selected.assign([&"fire", &"fire"])
	var points_before := bank.points
	_check(not loadout.commit_fusion(plan, game.items, bank) and bank.points == points_before, "duplicate selection accepted")
	plan.selected.assign([&"fire", &"ice"])
	_check(not loadout.commit_fusion(plan, game.items, bank), "two elements accepted")
	plan.selected.assign([&"holy"])
	_check(not loadout.commit_fusion(plan, game.items, bank), "foreign effect accepted")
	# Fully invested weapons: all 80 points are accounted for, with eight candidates.
	loadout.restore([
		{"id": str(recipe.base_weapon), "tier": 4, "affixes": [_entry("fire", 10), _entry("tempo", 10), _entry("range", 10), _entry("leech", 10)]},
		{"id": str(recipe.partner_weapon), "tier": 4, "affixes": [_entry("ice", 10), _entry("crit", 10), _entry("crit_damage", 10), _entry("knockback", 10)]}])
	plan = loadout.fusion_plan(0, recipe, game.items)
	_check(plan.candidates.size() == 8 and plan.total_points == 80 and plan.refund() == 40, "fully invested fusion lost part of its eighty-point budget")
	plan.selected.clear()
	_check(plan.refund() == 80 and loadout.commit_fusion(plan, game.items, bank), "explicitly returning all effects lost points")
	_check(loadout.equipped()[0].affixes.is_empty() and loadout.equipped()[0].data.element_skin == &"", "unenchanted evolution retained a discarded elemental form")
	session.clear_run()
	paused = false
	print("PASS weapon fusion: manual selection, elements, root power, caps, refunds, cancel/stale/double commit, MK conflict, shop spending/resume and responsive UI")
	finish(1 if failures > 0 else 0)


func _fixture(recipe: WeaponEvolutionRecipe) -> void:
	game.player.loadout.restore([
		{"id": str(recipe.base_weapon), "tier": 4, "affixes": [_entry("fire", 7), _entry("tempo", 6), _entry("range", 8), _entry("leech", 4)]},
		{"id": str(recipe.partner_weapon), "tier": 4, "affixes": [_entry("ice", 8), _entry("tempo", 7), _entry("crit", 4), _entry("crit_damage", 4)]}])
	for family in recipe.families:
		for item in ItemCatalog.ALL:
			if item.family_id == family and item.rarity_tier == 4:
				game.items.acquire(item)
				break
	for id in recipe.items: game.items.acquire(ItemCatalog.by_id(id))


func _entry(id: String, rank: int) -> Dictionary:
	return {"id": id, "level": rank, "damage": 1.0}


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _settle() -> void:
	for frame in 10: await process_frame


func _click(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await _settle()
