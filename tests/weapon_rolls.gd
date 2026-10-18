extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5812
	var qualities: Dictionary = {}
	var template := WeaponCatalog.by_id(&"magic_toothbrush")
	var original := template.base_damage
	var minimum := INF
	var maximum := 0.0
	for index in 4000:
		var data := WeaponRolls.resolve(template, WeaponRolls.roll(10, 50, rng))
		qualities[data.rolls.quality] = true
		minimum = minf(minimum, data.base_damage)
		maximum = maxf(maximum, data.base_damage)
		assert(data.interval > 0 and data.range_at_tier(4) > 0)
	assert(qualities.size() == 4 and maximum > minimum * 2.0, "shop loot lacks trash-to-divine variety")
	assert(template.base_damage == original and template.rolls.is_empty(), "roll mutated shared resource")
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_rolls.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.set_process(false)
	game.coins = 9999
	game._open_shop()
	var rolled := WeaponRolls.resolve(template, {"quality": 4, "damage": 1.65, "interval": 0.75, "range": 1.23, "crit": 0.09})
	var offer := ShopController.weapon_offer(ShopController.by_id(template.id), 1)
	offer.weapon_data = rolled
	game.shop.offers[0] = offer
	game.shop.reserved[0] = true
	game._on_shop_reroll()
	assert(game.shop.offers[0].weapon_data.rolls == rolled.rolls, "pinned roll changed")
	var snapshot := RunSnapshot.capture(game)
	RunSnapshot.restore(game, snapshot)
	assert(game.shop.offers[0].weapon_data.rolls == rolled.rolls, "saved shop rerolled")
	game._on_shop_buy(0)
	var loadout: WeaponLoadout = game.player.loadout
	var bought := loadout.equipped()[-1]
	assert(bought.data.rolls == rolled.rolls and is_equal_approx(bought.data.base_damage, original * 1.65), "purchase lost displayed stats")
	bought.affixes = WeaponAffixes.sanitize([{"id": "fire", "rarity": 2, "damage": 5}])
	var uid := bought.instance_uid
	loadout.restore(loadout.save_data())
	bought = loadout.equipped()[-1]
	assert(bought.instance_uid == uid and bought.data.rolls == rolled.rolls and bought.affixes[0].damage == 5, "weapon resume lost roll/affix")
	var saved: Array = [{"id": str(template.id), "tier": 1, "rolls": rolled.rolls, "affixes": [{"id": "fire", "rarity": 2, "damage": 5}]}]
	var weak := WeaponRolls.resolve(template, {"quality": 1, "damage": 0.6, "interval": 1.35, "range": 0.8, "crit": 0})
	saved.append({"id": str(template.id), "tier": 1, "rolls": weak.rolls})
	loadout.restore(saved)
	assert(loadout.merge(0))
	assert(loadout.equipped()[0].data.rolls == rolled.rolls and loadout.equipped()[0].affixes[0].damage == 5, "fusion lost selected roll")
	for index in 4:
		saved.append({"id": str(template.id), "tier": 4})
	loadout.restore(saved)
	assert(loadout.used_slots() == 6)
	assert(loadout.acquire(weak, 1, 10))
	assert(loadout.equipped()[0].data.rolls == rolled.rolls, "default shop fusion destroyed existing roll")
	_fusion_regressions(loadout, template, rolled, weak)
	for entry: Dictionary in saved:
		entry["rolls"] = weak.rolls
	loadout.restore(saved)
	var upgrade_offer := ShopController.weapon_offer(ShopController.by_id(template.id), 1)
	upgrade_offer.weapon_data = rolled
	game.shop.offers[0] = upgrade_offer
	game._update_shop_panel()
	game.shop_panel._select("offer", 0)
	assert(game.shop_panel.detail_buy_button.text.begins_with("Fusion"), "full-loadout purchase hides fusion")
	assert(game.shop_panel.details.action_hint.text.contains("beste Werte"), "fusion lacks result preview")
	assert(game.shop_panel.details.action_hint.text.contains("Crit") and not game.shop_panel.details.compare.visible, "fusion lacks crit preview or shows a misleading unmerged comparison")
	for extent in [Vector2i(1280, 720), Vector2i(360, 640)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 5:
			await process_frame
		assert(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.shop_panel.detail_popup.get_global_rect()), "roll purchase popup exceeds viewport")
		assert(game.shop_panel.detail_popup.get_global_rect().encloses(game.shop_panel.detail_buy_button.get_global_rect()), "fusion purchase action inaccessible")
		if "--capture" in OS.get_cmdline_user_args():
			root.get_texture().get_image().save_png("res://.godot/fusion-%dx%d.png" % [extent.x, extent.y])
	var coins_before: int = game.coins
	game.shop_panel.offer_buttons[0].buy_button.pressed.emit()
	assert(game.coins == coins_before - upgrade_offer.price and game.shop.offers[0] == null, "fusion purchase charged incorrectly")
	assert(loadout.equipped()[0].tier == 2 and loadout.equipped()[0].data.rolls == rolled.rolls and loadout.equipped()[0].affixes[0].damage == 5, "direct shop fusion lost legendary values or enchantments")
	var mixed := WeaponRolls.resolve(template, {"quality": 3, "damage": 1.65, "interval": 1.35, "range": 1.0, "crit": 0})
	var mixed_offer := ShopController.weapon_offer(ShopController.by_id(template.id), 1)
	mixed_offer.weapon_data = mixed
	var card: OfferCard = game.shop_panel.offer_buttons[0]
	card.show_offer(mixed_offer, 9999)
	card.show_weapon_values(mixed, 1, game.player)
	assert(card.name_label.text.ends_with("Mk I"), "shop weapon name omits Mk")
	assert(card.get_theme_stylebox("normal").border_color == DentiUIStyle.rarity_surface(1).border_color, "Mk I weapon inherits purple roll frame")
	assert(card.summary_row.get_child(0).get_child(1).get_theme_color("font_color") == DentiRarity.color_for(4), "great damage roll has wrong color")
	assert(card.summary_row.get_child(1).get_child(1).get_theme_color("font_color") == DentiRarity.color_for(1), "bad tempo roll inherits aggregate rarity")
	var equipment: Array[Dictionary] = []
	game.shop_panel.details.show_weapon(mixed, 1, game.player, false, equipment)
	assert(game.shop_panel.details.heading.text.ends_with("Mk I"))
	assert(game.shop_panel.details.values_grid.get_child(1).get_theme_color("font_color") == DentiRarity.color_for(4))
	assert(game.shop_panel.details.values_grid.get_child(3).get_theme_color("font_color") == DentiRarity.color_for(1))
	game.shop_panel.hide()
	var pool := game.get_node("Projectiles") as PlayerProjectilePool
	var shot := pool.acquire(rolled, 1)
	shot.launch(Vector2.ZERO, Vector2.RIGHT, 12, rolled, game.items)
	var shot_saved := shot.save_state({})
	var resumed := pool.acquire(template, 1)
	resumed.restore_state(shot_saved, game.items, [])
	assert(resumed.data.rolls == rolled.rolls and is_equal_approx(resumed.data.range_at_tier(1), rolled.range_at_tier(1)), "projectile resume lost range roll")
	loadout.restore([{"id": str(template.id), "tier": 1}])
	assert(loadout.equipped()[0].data == template, "old saves gained random stats")
	for recipe in WeaponEvolutions.ALL:
		loadout.restore([])
		game.items.restore({})
		loadout.acquire(WeaponRolls.resolve(WeaponCatalog.by_id(recipe.base_weapon), rolled.rolls), 4)
		if recipe.partner_weapon != &"":
			loadout.acquire(WeaponCatalog.by_id(recipe.partner_weapon), 4)
		for family in recipe.families:
			for item in ShopController.CATALOG:
				if item.family_id == family and item.rarity_tier == 4:
					game.items.acquire(item)
					break
		for id in recipe.items:
			game.items.acquire(ShopController.by_id(id))
		loadout.equipped()[0].affixes = WeaponAffixes.sanitize([{"id": "fire", "rarity": 2, "damage": 5}])
		assert(loadout.evolve(0, recipe, game.items), "rolled weapon cannot evolve")
		var evolved := loadout.equipped()[0]
		assert(evolved.data.rolls == rolled.rolls and is_equal_approx(evolved.data.base_damage, recipe.result.base_damage * 1.65) and evolved.affixes[0].damage == 5, "evolution lost roll or affix")
		loadout.restore(loadout.save_data())
		assert(is_equal_approx(loadout.equipped()[0].data.base_damage, recipe.result.base_damage * 1.65), "evolved roll compounded on resume")
	var six: Array = []
	for index in 6:
		six.append({"id": "turbo_drill", "tier": 1, "affix_slots": 2, "affixes": [{"id": "fire", "damage": 5, "rarity": 2}, {"id": "ice", "damage": 3, "rarity": 1}]})
	loadout.restore(six)
	var chest := {"kind": "affix", "scrap_coins": 5, "options": [{"id": "fire", "damage": 4, "rarity": 1}, {"id": "poison", "damage": 5, "rarity": 2}, {"id": "electric", "damage": 6, "rarity": 3}]}
	game.weapon_chest_panel.show_chest(chest, loadout, game.player.stats, 5)
	var panel: WeaponChestPanel = game.weapon_chest_panel
	assert(panel.weapon_buttons.size() == 6 and panel.find_children("*", "OptionButton", true, false).is_empty(), "weapon options still hidden behind dropdown")
	panel.weapon_buttons[4].pressed.emit()
	assert(panel.selected_weapon == 4 and panel.buttons[1].disabled, "target cards failed or silently replace effects")
	panel.replacement_buttons[1].pressed.emit()
	assert(int(panel.reward.replace) == 1 and not panel.buttons[1].disabled, "replacement cards failed")
	for extent in [Vector2i(1280, 720), Vector2i(360, 640)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 4:
			await process_frame
		for button in panel.weapon_buttons:
			assert(button.visible and button.get_global_rect().end.x <= extent.x, "weapon card outside viewport")
			var labels: Array = button.get_meta("labels")
			assert(labels[1].get_global_rect().end.y <= button.get_global_rect().end.y, "weapon metadata overflows card")
	game.items.acquire(ShopController.by_id(&"xp_heal_1"))
	game.player.stats.health = game.player.stats.max_health - 1
	game.items.on_pickup(&"xp", 10)
	var heal_shown := false
	for number: DamageNumber in game.get_node("DamageNumbers").get_children():
		if number.render_color == Color(0.50, 1.0, 0.70):
			heal_shown = number.text.begins_with("+") and number.text.substr(1).is_valid_float()
	assert(heal_shown, "heal feedback still contains a type label")
	var no_luck := 0
	var high_luck := 0
	for seed_value in 300:
		rng.seed = seed_value
		no_luck += _chests(rng, 0)
		rng.seed = seed_value
		high_luck += _chests(rng, 100)
	assert(no_luck > 1800 and high_luck > no_luck * 1.4, "chest decisions remain rare or luck is ineffective")
	print("Chest simulation, eight waves: %.1f without luck, %.1f with 100 luck" % [no_luck / 300.0, high_luck / 300.0])
	paused = false
	session.clear_run()
	print("PASS weapon rolls, shop/fusion/save and chest frequency")
	finish(0)

func _fusion_regressions(loadout: WeaponLoadout, template: WeaponData, rolled: WeaponData, weak: WeaponData) -> void:
	var specialist := WeaponRolls.resolve(template, {"quality": 3, "damage": 1.7, "interval": 1.35, "range": 1.25, "crit": 0})
	var expected := {"quality": 4, "damage": 1.7, "interval": 0.75, "range": 1.25, "crit": 0.09}
	assert(WeaponRolls.fuse(specialist, rolled).rolls == expected, "fusion discarded a better individual attribute")
	assert(WeaponRolls.fuse(rolled, specialist).rolls == expected, "fusion depends on operand order")
	assert(WeaponRolls.fuse(template, weak).base_damage == template.base_damage, "legacy neutral damage was downgraded")
	assert(WeaponRolls.fuse(template, weak).interval == template.interval, "legacy neutral tempo was downgraded")
	assert(WeaponRolls.fuse(template, template) == template, "neutral fusion mutated catalog identity")
	var mk_left := WeaponRolls.resolve(template, rolled.rolls, {"mk": 2})
	var mk_right := WeaponRolls.resolve(template, weak.rolls, {"mk": 3})
	var mk_result := WeaponRolls.fuse(mk_left, mk_right)
	assert(int(mk_result.chest_upgrades.mk) == 3 and is_equal_approx(mk_result.base_damage, template.base_damage * 1.65 * 1.3), "fusion discarded or added capsule Mk upgrades")
	var state: Array = [
		{"id": str(template.id), "tier": 1, "uid": "weak", "rolls": weak.rolls, "invested_coins": 5},
		{"id": str(template.id), "tier": 1, "uid": "best", "rolls": specialist.rolls, "invested_coins": 20, "affix_slots": 2, "affixes": [{"id": "fire", "damage": 5, "rarity": 2}, {"id": "tempo", "damage": 15, "rarity": 2}]},
	]
	for index in 4:
		state.append({"id": str(template.id), "tier": 4})
	loadout.restore(state)
	var target := loadout.purchase_fusion_target(rolled, 1)
	assert(target.instance_uid == "best", "purchase selected first match instead of best fusion result")
	var preview := loadout.fusion_data(target, rolled)
	assert(loadout.acquire(rolled, 1, 11))
	assert(target.tier == 2 and target.data.rolls == expected and target.instance_uid == "best", "automatic fusion lost mixed legendary values or identity")
	assert(target.affixes.size() == 2 and target.affix_slots == 2 and target.invested_coins == 31, "fusion lost investments or enchantments")
	assert(target.data.interval == preview.interval and target.data.attack_range == preview.attack_range, "preview disagrees with result")
	assert(loadout.equipped()[0].data.rolls == weak.rolls and loadout.equipped()[0].tier == 1, "fusion consumed an unrelated copy")
	loadout.restore(loadout.save_data())
	assert(loadout.equipped()[1].data.interval == preview.interval and loadout.equipped()[1].data.rolls == expected, "fused stats compounded or changed on resume")
	# Selecting a weak weapon must still find the strongest compatible partner.
	loadout.restore([state[0], state[0], {"id": str(template.id), "tier": 1, "rolls": rolled.rolls}])
	assert(loadout.merge_partner(0) == loadout.equipped()[2], "manual fusion chose a weak first partner")
	assert(loadout.merge(0) and loadout.equipped()[0].data.rolls == rolled.rolls, "manual fusion discarded better partner rolls")
	assert(loadout.equipped().size() == 2 and loadout.equipped()[1].data.rolls == weak.rolls, "manual fusion consumed wrong copy")
	loadout.restore([])
	assert(loadout.purchase_fusion_target(rolled, 1) == null and loadout.acquire(rolled, 1), "fusion prevented a free-slot purchase")
	assert(loadout.equipped()[0].tier == 1 and loadout.equipped()[0].data.rolls == rolled.rolls, "free-slot purchase changed offer")
	assert(template.rolls.is_empty() and specialist.rolls.damage == 1.7 and rolled.rolls.damage == 1.65, "fusion changed shared/source resources")


func _chests(rng: RandomNumberGenerator, luck: float) -> int:
	var total := 0
	var rewards := PostWaveRewards.new()
	for kills in [20, 30, 40, 55, 60, 70, 80, 90]:
		rewards.begin_wave()
		for kill in kills:
			if rewards.can_drop_chest() and rng.randf() < ChestRewards.drop_chance(luck):
				rewards.mark_chest_spawned()
		assert(rewards.random_chests_spawned <= 3)
		var restored := PostWaveRewards.new()
		restored.restore(rewards.save_data())
		assert(restored.random_chests_spawned == rewards.random_chests_spawned and restored.can_drop_chest() == rewards.can_drop_chest())
		total += rewards.random_chests_spawned
	return total
