extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for entry in [[1, 10], [5, 18], [10, 28], [19, 45]]:
		if EconomyRules.shop_price(9, entry[0]) != entry[1]:
			_fail("Brotato price curve differs from expected prices")
			return
	if not is_equal_approx(EconomyRules.gold_drop_factor(4), 1.0) or not is_equal_approx(EconomyRules.gold_drop_factor(10), 0.85) or not is_equal_approx(EconomyRules.gold_drop_factor(20), 0.70):
		_fail("gold decay curve is incorrect")
		return
	if EconomyRules.coin_chance(WaveController.ACID_CROWN, 19, 0.5) != 1.0:
		_fail("elite gold is not guaranteed")
		return
	for enemy in [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.ACID_SPITTER, WaveController.SUGAR]:
		for entry in [[1, 1.0], [4, 1.0], [5, 0.925], [10, 0.85], [20, 0.70], [40, 0.50]]:
			if not is_equal_approx(EconomyRules.coin_chance(enemy, entry[0]), entry[1]):
				_fail("normal enemy gold chance does not follow the materials curve")
				return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_economy_shop.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.current_wave = 19
	game.wave.active = true
	game.rewards.chest_spawned = true
	seed(776655)
	var gold_drops := 0
	var xp_drops := 0
	var gold_without_xp := 0
	for kill in 4000:
		game._on_enemy_defeated(Vector2.ZERO, WaveController.PLAQUE)
		var gold := false
		var experience := false
		for drop: Loot in game.get_node("Loot").get_children():
			gold = gold or drop.kind == &"coin"
			experience = experience or drop.kind == &"xp"
			drop.free()
		gold_drops += int(gold)
		xp_drops += int(experience)
		gold_without_xp += int(gold and not experience)
	if absi(gold_drops - 2860) > 120 or absi(xp_drops - 1520) > 120 or gold_without_xp < 1400:
		_fail("gold is still gated by XP or the unchanged XP rate drifted: %d gold, %d XP, %d independent gold" % [gold_drops, xp_drops, gold_without_xp])
		return
	game.wave.active = false
	game._on_enemy_defeated(Vector2.ZERO, WaveController.PLAQUE)
	if game.get_node("Loot").get_child_count() != 0:
		_fail("post-combat cleanup granted new drops")
		return
	game.wave.current_wave = 1
	game.coins = 0
	game._open_shop()
	var brush := ShopController.by_id(&"magic_toothbrush")
	var original_base := brush.price
	var kept: ShopOfferData = brush.duplicate()
	kept.price = EconomyRules.shop_price(brush.price, 1)
	game.shop.offers[0] = kept
	game._update_shop_panel()
	game.shop_panel.offer_buttons[0].reserve_button.pressed.emit()
	if not game.shop.reserved[0] or game.coins != 0 or game.shop_panel.offer_buttons[0].reserve_button.disabled:
		_fail("unaffordable offers cannot be reserved for free")
		return
	game.coins = 100
	game._on_shop_reroll()
	if game.shop.offers[0] != kept or kept.price != 10 or game.coins != 98:
		_fail("reroll changed reserved offer or charged the wrong amount")
		return
	for index in [1, 2, 3]:
		game._on_shop_reserve(index)
	game._on_shop_reroll()
	if game.coins != 98 or not game.shop_panel.reroll_button.disabled:
		_fail("all-reserved shop consumed reroll gold")
		return
	var saved := RunSnapshot.capture(game)
	game.shop.reserved.assign([false, false, false, false])
	game.shop.offers.clear()
	RunSnapshot.restore(game, saved)
	if game.shop.reserved != [true, true, true, true] or game.shop.offers[0].price != 10 or game.shop.offers[0].id != brush.id:
		_fail("save/resume lost reserved offers or locked prices")
		return
	game._on_shop_continue()
	game.wave.active = false
	game._open_shop()
	if game.shop.offers[0].price != 10 or game.shop.offers[0].id != brush.id or game.shop.reroll_cost != 2:
		_fail("next wave repriced a reservation or failed to reset rerolls")
		return
	game._on_shop_reserve(1)
	game._on_shop_reserve(2)
	game._on_shop_reserve(3)
	game._on_shop_reroll()
	for index in [1, 2, 3]:
		var offer: ShopOfferData = game.shop.offers[index]
		var base := ShopController.by_id(offer.id)
		var tier_base: int = ShopController.weapon_offer(base, offer.weapon_tier).price if offer.weapon_data != null else base.price
		if offer.price != EconomyRules.shop_price(tier_base, 2):
			_fail("new offers omitted inflation or inflated more than once")
			return
	var coins_before: int = game.coins
	game._on_shop_buy(0)
	if game.coins != coins_before - 10 or game.shop.offers[0] != null or game.shop.reserved[0] or brush.price != original_base:
		_fail("reserved purchase changed price/catalog or left a stale reservation")
		return
	game._on_shop_reroll()
	if game.shop.offers[0] == null:
		_fail("purchased reserved slot could not refill")
		return
	saved = RunSnapshot.capture(game)
	for offer in saved.offers:
		offer.erase("reserved")
	RunSnapshot.restore(game, saved)
	if game.shop.reserved != [false, false, false, false]:
		_fail("legacy offers acquired reservations")
		return
	# A three-slot legacy shop must retain sold slots and its exact prices.
	saved = RunSnapshot.capture(game)
	saved.offers.resize(3)
	saved.offers[0] = {}
	var old_price: int = saved.offers[1].price
	RunSnapshot.restore(game, saved)
	if game.shop.offers.size() != 4 or game.shop.offers[0] != null or game.shop.offers[1].price != old_price or game.shop.offers[3] == null:
		_fail("legacy shop migration rerolled old offers or failed to add slot four")
		return
	var telemetry := RunTelemetry.new()
	telemetry.begin_wave(2)
	telemetry.record_loot(&"coin", 10)
	telemetry.record_loot(&"coin", 2, &"pickup_item")
	telemetry.record_shop_spending(&"weapon", 7)
	telemetry.record_shop_spending(&"reroll", 2)
	var restored := RunTelemetry.new()
	restored.restore(telemetry.save_data(), 2)
	if restored.wave_coins != 12 or restored.wave_gold_sources != {"drop": 10, "pickup_item": 2} or restored.wave_shop_spending != {"weapon": 7, "reroll": 2}:
		_fail("economy telemetry does not survive resume")
		return
	paused = false
	session.clear_run()
	print("Denti economy/shop test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
