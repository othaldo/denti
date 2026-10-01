extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_economy_items.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.rewards.chest_spawned = true
	game.player.stats.luck = 1000.0
	if game.items.coin_double_chance() != 0.0:
		_fail("luck generated double drops without an item")
		return
	var extractor := ShopController.by_id(&"gold_extractor")
	var probe := ShopController.by_id(&"gold_probe")
	for item in [extractor, probe]:
		var icon := DentiUIIcons.item(item.icon_index) as AtlasTexture
		if icon == null or icon.atlas != DentiUIIcons.ITEM_ECONOMY or icon.get_size() != Vector2(512, 512):
			_fail("new economy item has a missing or clipped icon cell")
			return
	game.items.acquire(extractor)
	game.items.acquire(extractor)
	if game.items.acquire(extractor) or game.items.coin_drop_value(1) != 1 or game.items.coin_drop_value(2) != 4 or game.items.coin_drop_value(4) != 6 or game.items.coin_drop_value(0) != 0:
		_fail("extractor stack cap or base-value condition is incorrect")
		return
	game.items.acquire(probe)
	game.items.acquire(probe)
	game.player.stats.luck = -100.0
	if game.items.acquire(probe) or not is_equal_approx(game.items.coin_double_chance(), 0.40) or game.player.stats.damage_bonus != -10.0 or game.player.stats.speed_bonus != -6.0:
		_fail("probe stacks, penalties or negative luck are incorrect")
		return
	game.player.stats.luck = 1000.0
	seed(817263)
	for base in [1, 2, 4]:
		var total := 0
		for index in 10000:
			var value: int = game.items.coin_drop_value(base)
			var premium := 2 if base >= 2 else 0
			if value not in [base + premium, base * 2 + premium]:
				_fail("doubled normal gold acquired the rich-drop premium")
				return
			total += value
		var expected: float = base * 1.5 + (2 if base >= 2 else 0)
		if absf(float(total) / 10000.0 - expected) > 0.05:
			_fail("gold item probability escaped its luck cap")
			return
	game.items.acquire(ShopController.by_id(&"gold_filling"))
	var drop_total := 0
	for index in 80:
		game._on_enemy_defeated(game.player.global_position + Vector2(300.0, 0.0), WaveController.SUGAR)
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.kind == &"coin":
			if drop.amount not in [4, 6]:
				_fail("enemy death bypassed the new drop-value effects")
				return
			drop_total += drop.amount
	var saved := RunSnapshot.capture(game)
	game._clear_arena(false)
	await process_frame
	RunSnapshot.restore(game, saved)
	await process_frame
	var restored_total := 0
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.kind == &"coin" and not drop.is_queued_for_deletion():
			restored_total += drop.amount
	if restored_total != drop_total or game.items.count(probe.id) != 2 or game.player.stats.damage_bonus != -5.0 or game.player.stats.speed_bonus != -6.0:
		_fail("resume rerolled loot values or reapplied item penalties: %d/%d coins, %d probes, %s damage, %s speed" % [restored_total, drop_total, game.items.count(probe.id), game.player.stats.damage_bonus, game.player.stats.speed_bonus])
		return
	game._clear_arena(true)
	if game.coins != drop_total + floori(drop_total * 0.15 + 0.0001) or game.telemetry.wave_gold_sources.get("drop", 0) != drop_total:
		_fail("gold filling or loot sweep multiplied drop effects again")
		return
	session.clear_run()
	paused = false
	print("Denti economy items test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
