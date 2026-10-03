extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_item_system_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(2)
	game.wave.active = false
	game.coins = 100
	game._open_shop()
	var fluoride := ShopController.by_id(&"fluoride_gel")
	game.shop.offers[0] = fluoride
	game._update_shop_panel()
	game._on_shop_buy(0)
	if game.items.count(&"fluoride_gel") != 1 or game.player.stats.max_health != 125.0:
		_fail("shop purchase did not grant item and stats")
		return
	for copy in 11:
		if not game.items.acquire(fluoride):
			_fail("item stopped stacking before twelve copies")
			return
	if game.items.acquire(fluoride):
		_fail("item stack limit was ignored")
		return
	game.shop.offers[0] = fluoride
	game._update_shop_panel()
	game.shop_panel.offer_buttons[0].pressed.emit()
	if game.shop_panel.offer_buttons[0].disabled or not game.shop_panel.offer_buttons[0].buy_button.disabled:
		_fail("maxed item offer stayed purchasable")
		return
	var original_offers: Array[ShopOfferData] = game.shop.offers.duplicate()
	game.shop.offers.clear()
	for index in 20:
		if game.shop._pick_item(1, game.items, game.player.loadout).id == &"fluoride_gel":
			_fail("maxed item still appeared in shop pool")
			return
	game.shop.offers = original_offers
	game.items.on_wave_start()
	if game.player.stats.shield_charges != 5:
		_fail("wave-start shield did not stack")
		return
	var health_before: float = game.player.stats.health
	game.player.take_hit(25.0)
	if game.player.stats.health != health_before or game.player.stats.shield_charges != 4:
		_fail("shield did not block contact damage")
		return
	game.items.acquire(ShopController.by_id(&"mint_essence"))
	if game.items.pickup_range() <= Loot.MAGNET_DISTANCE:
		_fail("item did not increase pickup range")
		return

	game.items.acquire(ShopController.by_id(&"radiant_filling"))
	var water := WeaponCatalog.by_id(&"water_jet")
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(130.0, 0.0))
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(180.0, 0.0))
	var first: Enemy = game.get_node("Enemies").get_child(0)
	var second: Enemy = game.get_node("Enemies").get_child(1)
	var second_before := second.health
	first.take_damage(5.0, water)
	if second.health >= second_before:
		_fail("water hit did not chain to another enemy")
		return

	game.items.acquire(ShopController.by_id(&"floss_reel"))
	game.items.acquire(ShopController.by_id(&"scalpel_wax"))
	var floss := WeaponCatalog.by_id(&"floss_whip")
	first.take_damage(5.0, floss)
	if first.bleed_stacks != 1 or game.items.modify_damage(first, floss, 10.0) <= 10.0:
		_fail("bleed and bleed synergy did not activate")
		return
	var before_bleed := first.health
	first._physics_process(1.01)
	if first.health >= before_bleed:
		_fail("bleed did not deal periodic damage")
		return
	second.global_position = first.global_position + Vector2(50.0, 0.0)
	game.items.acquire(ShopController.by_id(&"mouthwash"))
	game.items.cooldowns["chain"] = 99.0
	second_before = second.health
	first.take_damage(3.0, water)
	if second.health >= second_before:
		_fail("mouthwash did not splash projectile damage")
		return
	game.items.acquire(ShopController.by_id(&"polish_paste"))
	game.items.cooldowns["splash"] = 99.0
	second_before = second.health
	first.take_damage(3.0, water, true)
	if second.health >= second_before:
		_fail("critical hit did not trigger polish burst")
		return
	game.items.acquire(ShopController.by_id(&"ceramic_shell"))
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(65.0, 0.0))
	var close_enemy: Enemy = game.get_node("Enemies").get_child(2)
	var close_before := close_enemy.health
	game.player.stats.shield_charges = 0
	game.player.hurt_time = 0.0
	game.player.take_hit(12.0)
	if close_enemy.health >= close_before:
		_fail("ceramic shell did not retaliate after damage")
		return

	game.items.acquire(ShopController.by_id(&"saliva_fountain"))
	game.items.acquire(ShopController.by_id(&"cavity_bounty"))
	if not game.items.preferred_tags(game.player.loadout).has(&"economy"):
		_fail("owned item tags did not shape the shop pool")
		return
	game.player.stats.health = 50.0
	var extra_coins := 0
	for index in 12:
		extra_coins += game.items.on_kill(game.player.position, false)
	if extra_coins != 1 or game.player.stats.health <= 50.0:
		_fail("kill streak economy or healing failed")
		return
	game.items.acquire(ShopController.by_id(&"gold_filling"))
	game.items.acquire(ShopController.by_id(&"lucky_molar"))
	var coin_bonus := 0
	var xp_bonus := 0
	for index in 10:
		coin_bonus += game.items.on_pickup(&"coin", 1)
		xp_bonus += game.items.on_pickup(&"xp", 1)
	if coin_bonus != 1 or xp_bonus != 1:
		_fail("pickup bonuses did not accumulate across pickups")
		return
	game.items.acquire(ShopController.by_id(&"tooth_fairy_pact"))
	game.player.stats.health = 45.0
	game.items.on_pickup(&"xp", 10)
	if game.player.stats.health <= 45.0:
		_fail("tooth fairy pact did not heal from XP")
		return
	game.items.acquire(ShopController.by_id(&"holy_flash"))
	game.items.kill_burst_progress = 9
	var burst_before := second.health
	game.items.on_kill(first.global_position, false)
	if second.health >= burst_before:
		_fail("kill-streak burst did not damage nearby enemies")
		return

	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(300.0, 0.0))
	var bleeding_enemy: Enemy = game.get_node("Enemies").get_child(-1)
	bleeding_enemy.apply_bleed(4.0, 2.5)
	game.player.stats.grant_shield(2)
	game._save_run()
	var saved: Dictionary = session.load_run()
	if not saved.has("items") or int(saved["items"]["owned"].get("fluoride_gel", 0)) != 12 or int(saved["player"]["stats"]["shield_charges"]) != 2:
		_fail("item state was not saved")
		return
	session.resume_requested = true
	var resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	if resumed.items.count(&"fluoride_gel") != 12 or resumed.player.stats.shield_charges != 2 or resumed.items.pickup_range() <= Loot.MAGNET_DISTANCE:
		_fail("item effects or shield did not survive continue")
		return
	if resumed.player.stats.max_health != game.player.stats.max_health:
		_fail("item stat bonuses were applied twice on restore")
		return
	var found_bleed := false
	for enemy: Enemy in resumed.get_node("Enemies").get_children():
		if enemy.bleed_stacks > 0 and enemy.bleed_time > 0.0:
			found_bleed = true
	if not found_bleed or absf(resumed.items.coin_fraction - game.items.coin_fraction) > 0.0001:
		_fail("active bleed or economy progress did not survive continue")
		return
	paused = false
	session.clear_run()
	print("Denti item system test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
