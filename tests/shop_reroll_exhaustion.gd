extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_shop_exhaustion.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	# No legal weapon acquisition and no eligible item in any rolled tier.
	game.player.loadout.restore([{"id": "crown_launcher", "tier": 4}, {"id": "crown_launcher", "tier": 4}, {"id": "crown_launcher", "tier": 4}])
	for item in ShopController.CATALOG:
		if item.weapon_data == null:
			game.items.owned[str(item.id)] = maxi(item.max_stacks, item.family_limit) if item.family_limit > 0 else maxi(item.max_stacks, 1)
	game.coins = 10000
	game.wave.current_wave = 1
	game._open_shop()
	for draw in 40:
		game.shop.take_offer(draw % 4)
		game._update_shop_panel()
		var remaining: ShopOfferData = game.shop.offers[(draw + 1) % 4]
		game.shop.reserved[(draw + 1) % 4] = true
		game._on_shop_reroll()
		for index in 4:
			var offer: ShopOfferData = game.shop.offers[index]
			if offer == null or game.shop_panel.offer_buttons[index].text == "Ausverkauft" or not game.shop_panel.offer_buttons[index].content.visible:
				_fail("exhausted shop left a sold-out slot after reroll")
				return
			if not game.shop_panel.offer_buttons[index].buy_button.disabled or game.shop_panel.offer_buttons[index].disabled:
				_fail("full-root fallback cannot be inspected or was incorrectly buyable")
				return
		if game.shop.offers[(draw + 1) % 4] != remaining:
			_fail("fallback changed a reserved offer")
			return
		game.shop.reserved.assign([false, false, false, false])
	# A fallback offer becomes purchasable after selling a weapon.
	game.player.loadout.sell(0)
	game._update_shop_panel()
	if game.shop_panel.offer_buttons[0].buy_button.disabled:
		_fail("making root space did not make the replacement offer buyable")
		return
	session.clear_run()
	paused = false
	print("Denti exhausted shop reroll test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
