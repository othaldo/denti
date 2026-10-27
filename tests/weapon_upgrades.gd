extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_targeted_weapon_upgrades.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.set_process(false)
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 2}, {"id": "turbo_drill", "tier": 4}])
	var weapons := loadout.equipped()
	for weapon in weapons: weapon.set_physics_process(false)
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	# Combat and the loot sweep never open this view or apply an effect.
	game._on_loot_collected(&"xp", 6)
	game._spawn_loot(game.player.position + Vector2(600, 0), &"chest", 5, WeaponAffixes.CHEST_ID, WeaponUpgrades.capsule(1))
	game._spawn_loot(game.player.position + Vector2(-600, 0), &"chest", 10, WeaponAffixes.CHEST_ID, WeaponUpgrades.capsule(1, true))
	game._spawn_loot(game.player.position + Vector2(0, 600), &"coin", 3)
	_check(not paused and not game.weapon_enchantment_panel.visible, "combat pickup interrupted gameplay")
	game._on_wave_finished(1)
	_check(not game.weapon_enchantment_panel.visible, "weapon choice preceded the loot sweep")
	for frame in 180:
		await physics_frame
		if game.rewards.step == PostWaveRewards.Step.LEVELS: break
	_check(state.points == 2 and game.coins == 3 and game.get_node("Loot").get_child_count() == 0, "loot sweep lost point capsules or coins")
	_check(game.choice_panel.visible and not game.weapon_enchantment_panel.visible, "weapons preceded pending level choices")
	while game.rewards.pending_levels > 0: choose_panel(game.choice_panel, 0)
	await _settle()
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	_check(paused and panel.visible and game.rewards.step == PostWaveRewards.Step.WEAPONS and not game.shop_panel.visible, "weapon phase did not precede shop")
	_check(panel.models[0].slot_count == 1 and panel.upgrade_buttons[1].disabled and panel.upgrade_buttons[3].disabled, "Mk I must show one open and three locked places")
	panel.open_picker(1)
	_check(panel.picking_slot == -1, "locked slot opened the catalogue")
	await _click(panel.upgrade_buttons[0])
	await _click(_effect(panel, &"fire"))
	await _click(panel.finish_button)
	_check(state.actions.size() == 1 and state.preview(weapons[0])[0].level == 1 and weapons[0].affixes.is_empty(), "activation must cost one point at 1/10 and remain a draft")
	_check(state.preview(weapons[1]).is_empty(), "identical weapon copy inherited another target's effect")
	await _click(panel.back_button)
	_check(state.actions.is_empty() and state.remaining() == 2, "undo did not restore the point")
	await _click(panel.weapon_buttons[1])
	_check(panel.models[1].slot_count == 2 and not panel.upgrade_buttons[1].disabled and panel.upgrade_buttons[2].disabled, "Mk II slot gate is wrong")
	await _click(panel.upgrade_buttons[0])
	await _click(_effect(panel, &"electric"))
	await _click(panel.finish_button)
	await _click(panel.upgrade_buttons[1])
	_check(_effect(panel, &"wet").disabled and _effect(panel, &"fire").disabled, "second element remains selectable")
	await _click(_effect(panel, &"tempo"))
	var uid := weapons[1].instance_uid
	game._save_run()
	var save := RunSnapshot.capture(game)
	_check(not RunSaveData.normalize(save).is_empty(), "new pending state is not valid save data")
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game.wave.set_process(false)
	await _settle()
	panel = game.weapon_enchantment_panel
	loadout = game.player.loadout
	state = game.rewards.weapon_upgrades
	_check(panel.visible and paused and panel.selected_weapon == 1 and panel.selected_effect == &"tempo" and panel.picking_slot == 1, "resume lost target, catalogue or selected effect")
	_check(state.points == 2 and state.actions.size() == 1 and loadout.equipped()[1].affixes.is_empty(), "resume committed or lost the draft")
	await _click(panel.finish_button)
	_check(state.remaining() == 0 and panel.upgrade_buttons[0].disabled, "empty budget still permits improvements")
	_check(not state.plan(loadout, uid, &"fire"), "backend accepted an over-budget plan")
	state.points += 1 # Unspent points must survive confirmation and later waves.
	await _click(panel.finish_button)
	_check(game.shop_panel.visible and not panel.visible and state.points == 1 and state.actions.is_empty(), "confirmation did not bank the remainder and advance once")
	weapons = loadout.equipped()
	_check(weapons[0].affixes.is_empty() and weapons[1].instance_uid == uid and weapons[1].affixes.size() == 2, "confirmation changed the wrong identical copy")
	_check(weapons[1].affixes[0].level == 1 and weapons[1].affixes[1].id == "tempo", "confirmed effects or levels differ from the draft")
	_check(AffixPresentation.summary(weapons[1]).contains("1/10") and WeaponPresentation.enchantment_list(weapons[1]).contains("1/10"), "shop presentation lost the new ranks")
	var persisted := loadout.save_data()
	loadout.restore(persisted)
	_check(loadout.save_data() == persisted, "weapon resume changed rank, identity or normalized power")
	game.rewards.begin_wave()
	_check(state.points == 1 and not game.rewards.weapons_resolved, "beginning a wave discarded banked points")
	# Every Mk opens exactly that many slots; one point cannot purchase a slot.
	for tier in range(1, 5):
		loadout.restore([{"id": "turbo_drill", "tier": tier}])
		var target := loadout.equipped()[0]
		var check_state := WeaponUpgradeState.new()
		check_state.points = 40
		var choices := [&"fire", &"range", &"tempo", &"leech"]
		for index in tier: _check(check_state.plan(loadout, target.instance_uid, choices[index]), "unlocked Mk slot rejected an effect")
		_check(not check_state.plan(loadout, target.instance_uid, &"crit"), "points unlocked a slot above the weapon Mk")
		_check(check_state.commit(loadout) and target.affixes.size() == tier, "Mk slot draft could not commit")
	# Ten ranks including activation, forty points for all four effects.
	loadout.restore([{"id": "turbo_drill", "tier": 4}])
	var target := loadout.equipped()[0]
	var max_state := WeaponUpgradeState.new()
	max_state.points = 40
	for effect in [&"fire", &"range", &"tempo", &"leech"]:
		for rank in 10: _check(max_state.plan(loadout, target.instance_uid, effect), "rank below 10 was rejected")
		_check(not max_state.plan(loadout, target.instance_uid, effect), "effect grew beyond 10/10")
	_check(max_state.commit(loadout) and max_state.points == 0 and target.affixes.size() == 4, "full weapon did not cost exactly forty points")
	for effect in target.affixes: _check(effect.level == 10, "full weapon contains an incomplete effect")
	# New effect power is budgeted across roots, interval and the initial fan.
	var base_budget := -1.0
	for id in [&"turbo_drill", &"magic_toothbrush", &"uv_lamp"]:
		var data := WeaponCatalog.by_id(id)
		for tier in [1, 4]:
			var weight := 1.0 + 0.55 * (data.projectile_count_at_tier(tier) - 1) if data.attack_mode == &"projectile" else 1.0
			var budget := WeaponAffixes.effect_damage(WeaponUpgrades.power(&"fire", 4, data, tier), &"fire", data) * weight / data.interval / data.hands
			if base_budget < 0: base_budget = budget
			_check(is_equal_approx(base_budget, budget), "root budget changed with speed, Mk or the projectile fan")
	# Fusion carries levels, and refuses an overflow rather than throwing points away.
	loadout.restore([{"id": "turbo_drill", "tier": 1, "affixes": [{"id": "fire", "level": 6, "damage": 1}]}, {"id": "turbo_drill", "tier": 1, "affixes": [{"id": "fire", "level": 5, "damage": 1}]}])
	_check(not loadout.can_merge(0), "fusion silently discarded a level above 10")
	loadout.equipped()[1].affixes[0].level = 4
	_check(loadout.merge(0) and loadout.equipped()[0].affixes[0].level == 10 and loadout.equipped()[0].tier == 2, "fusion failed to retain ten invested levels")
	# Historic power above the new cap stays intact and cannot be bought again.
	loadout.restore([{"id": "turbo_drill", "tier": 1, "affixes": [{"id": "fire", "damage": 120, "rarity": 4}]}])
	_check(loadout.equipped()[0].affixes[0].damage == 120 and WeaponUpgrades.next_entry(loadout.equipped()[0].affixes[0], &"fire", loadout.equipped()[0].data, 1).is_empty(), "legacy power was lost or unbounded growth remained")
	session.clear_run()
	paused = false
	print("PASS targeted weapon upgrades: combat flow, Mk slots, native clicks, draft/undo/resume, bank, caps, budgets and fusion")
	finish(1 if failures > 0 else 0)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _settle() -> void:
	for frame in 6: await process_frame


func _effect(panel: WeaponEnchantmentPanel, id: StringName) -> Button:
	for button in panel.effect_buttons:
		if button.get_meta("effect_id") == id: return button
	assert(false, "Missing enchantment: " + str(id))
	return null


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
