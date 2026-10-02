extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DentiRarity.cumulative_chance(2, 1, 0.0) != 0.0 or DentiRarity.cumulative_chance(3, 3, 0.0) != 0.0:
		_fail("higher rarity appeared before its first wave")
		return
	if DentiRarity.cumulative_chance(2, 8, 100.0) <= DentiRarity.cumulative_chance(2, 8, 0.0):
		_fail("luck did not increase shop rarity odds")
		return
	if DentiRarity.cumulative_chance(4, 20, 1000.0) > 0.08:
		_fail("legendary rarity exceeded its cap")
		return
	for milestone in [5, 10, 15, 20, 25]:
		var expected := 2 if milestone == 5 else (4 if milestone == 25 else 3)
		if DentiRarity.upgrade_tier(milestone, 0.0) != expected:
			_fail("guaranteed level-up tier failed at level %d" % milestone)
			return
	var upgrade: UpgradeData = load("res://data/upgrades/bisskraft.tres")
	if upgrade.with_tier(4).amount <= upgrade.with_tier(3).amount or upgrade.with_tier(2).amount <= upgrade.amount:
		_fail("higher-tier level-up values did not increase")
		return

	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_rarity_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(1)
	game.wave.active = false
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	game.player.loadout.restore([{"id": "turbo_drill", "tier": 2}])
	game.coins = 100
	game.wave.current_wave = 8
	game._open_shop()
	game.shop.offers[0] = ShopController.weapon_offer(ShopController.by_id(&"turbo_drill"), 2)
	game._update_shop_panel()
	var offer: ShopOfferData = game.shop.offers[0]
	var offer_card := game.shop_panel.offer_buttons[0] as OfferCard
	if offer.rarity_tier != 2 or offer.price <= drill.price or offer_card.summary_row.get_child_count() != 4 or not offer_card.category_label.text.contains("II") or not offer_card.tooltip_text.contains("Basis-Schaden"):
		_fail("tiered weapon offer did not show its rarity, price and stats")
		return
	game._save_run()
	var saved: Dictionary = session.load_run()
	if int(saved["offers"][0]["tier"]) != 2:
		_fail("shop offer tier was not saved")
		return
	game._on_shop_buy(0)
	if game.player.loadout.equipped().size() != 2 or game.player.loadout.equipped()[0].tier != 2 or game.player.loadout.equipped()[1].tier != 2 or game.player.loadout.refund_for(1) != roundi(float(offer.price) * 0.5):
		_fail("purchased tier-II weapon merged despite free slot")
		return
	if not game.player.loadout.merge(0) or game.player.loadout.equipped().size() != 1 or game.player.loadout.equipped()[0].tier != 3:
		_fail("manual tier-II merge did not reach tier III")
		return
	if not game.player.loadout.acquire(drill, 3) or game.player.loadout.equipped().size() != 2 or game.player.loadout.equipped()[1].tier != 3:
		_fail("tier-III weapon did not use free slot")
		return
	if not game.player.loadout.merge(0) or game.player.loadout.equipped()[0].tier != 4:
		_fail("manual tier-III merge did not reach tier IV")
		return

	session.save_run(saved)
	session.resume_requested = true
	var resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	if not resumed.in_shop or resumed.shop.offers[0] == null or resumed.shop.offers[0].weapon_tier != 2:
		_fail("continuing a run lost its tier-II shop offer")
		return
	var restored_card := resumed.shop_panel.offer_buttons[0] as OfferCard
	if restored_card.rarity_label.text.to_upper().find("UNGEWÖHNLICH") < 0:
		_fail("shop rarity badge was not restored")
		return
	resumed.in_shop = false
	resumed.shop_panel.visible = false
	resumed.player.stats.apply_upgrade(&"luck", 20.0)
	resumed.level = 4
	resumed.xp_goal = 5
	resumed.xp = 0
	resumed._award_xp(5)
	if resumed.choice_panel.visible or resumed.rewards.pending_levels != 1:
		_fail("level-up did not queue during combat")
		return
	resumed.rewards.begin_collection()
	resumed.rewards.finish_collection(false)
	resumed._advance_post_wave_rewards()
	if not resumed.choice_panel.visible:
		_fail("queued level-up did not open after the wave")
		return
	for choice in resumed.choice_panel.current_upgrades:
		if choice.tier != 2:
			_fail("level 5 did not offer guaranteed tier-II choices")
			return
	# Moving keyboard focus must leave the rarity surface unchanged.
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	for frame in 5:
		await process_frame
	var first: UpgradeCard = resumed.choice_panel.buttons[0]
	var normal := first.get_theme_stylebox("normal") as StyleBoxFlat
	var focus := first.get_theme_stylebox("focus") as StyleBoxFlat
	if normal.bg_color != DentiUIStyle.PANEL.lerp(DentiRarity.color_for(2), 0.16) or focus.draw_center or focus.border_color != DentiUIStyle.INK or focus.expand_margin_left >= 0:
		_fail("rarity surface and keyboard selection use the same visual signal")
		return
	first.grab_focus()
	var right := InputEventAction.new()
	right.action = &"ui_right"
	right.pressed = true
	root.push_input(right, true)
	await process_frame
	if not resumed.choice_panel.buttons[1].has_focus() or first.get_theme_stylebox("normal") != normal:
		_fail("keyboard focus does not move independently of the rarity surface")
		return
	resumed._save_run()
	session.resume_requested = true
	var upgrade_resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(upgrade_resumed)
	current_scene = upgrade_resumed
	if upgrade_resumed.player.stats.luck != 20.0 or not upgrade_resumed.choice_panel.visible or upgrade_resumed.choice_panel.current_upgrades[0].tier != 2:
		_fail("continuing a run lost luck or tiered level-up choices")
		return

	var loadout := WeaponLoadout.new()
	root.add_child(loadout)
	var shop := ShopController.new()
	root.add_child(shop)
	shop.rng.seed = 4321
	var baseline := 0
	for index in 400:
		if shop._pick_weapon(1, loadout).id == &"turbo_drill":
			baseline += 1
	loadout.acquire(drill)
	shop.rng.seed = 4321
	var owned := 0
	for index in 400:
		if shop._pick_weapon(1, loadout).id == &"turbo_drill":
			owned += 1
	if owned <= baseline * 2:
		_fail("owned weapon was not favored in shop draws (%d vs %d)" % [owned, baseline])
		return

	paused = false
	session.clear_run()
	print("Denti rarity progression test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
