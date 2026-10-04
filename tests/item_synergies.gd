extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_item_synergies_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(2)
	game.wave.active = false
	for item_id in [&"contagious_floss", &"conductive_varnish", &"forbidden_lollipop", &"tooth_fairy_deposit"]:
		var item := ShopController.by_id(item_id)
		if item.icon_texture == null or not item.icon_texture.resource_path.ends_with(".png") or item.icon_texture.get_size().x < 64.0 or item.icon_texture.get_size().y < 64.0:
			_fail("new item has no dedicated usable icon: " + str(item_id))
			return
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(60.0, 0.0))
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(290.0, 0.0))
	var first: Enemy = game.get_node("Enemies").get_child(0)
	var second: Enemy = game.get_node("Enemies").get_child(1)
	first.health = 1000.0
	first.max_health = 1000.0
	second.health = 1000.0
	second.max_health = 1000.0
	first.set_simulation_enabled(false)
	second.set_simulation_enabled(false)
	var water := WeaponCatalog.by_id(&"water_jet")
	var light := WeaponCatalog.by_id(&"enamel_mirror")
	if not game.items.acquire(ShopController.by_id(&"radiant_filling")) or not game.items.acquire(ShopController.by_id(&"conductive_varnish")):
		_fail("water build items could not be acquired")
		return
	var second_before: float = second.health
	first.take_damage(5.0, water)
	if first.wet_time <= 0.0 or second.health >= second_before:
		_fail("wet water hit did not extend a chain beyond its ordinary range")
		return
	if game.items.modify_damage(first, water, 20.0) <= game.items.modify_damage(second, water, 20.0) or game.items.modify_damage(first, light, 20.0) <= game.items.modify_damage(second, light, 20.0):
		_fail("wet target did not take extra water and light weapon damage")
		return
	first._physics_process(3.01)
	if first.wet_time > 0.0:
		_fail("wet status did not expire")
		return

	var health_before: float = game.player.stats.max_health
	var armor_before: float = game.player.stats.armor
	if not game.items.acquire(ShopController.by_id(&"forbidden_lollipop")):
		_fail("lollipop could not be acquired")
		return
	if game.player.stats.max_health != health_before - 15.0 or game.player.stats.armor != armor_before - 2.0:
		_fail("lollipop defensive trade-off was not applied")
		return
	var idle_damage: float = game.items.modify_damage(second, water, 20.0)
	Input.action_press("move_right")
	game.player._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	if not game.player.is_moving or game.items.modify_damage(second, water, 20.0) <= idle_damage:
		_fail("lollipop did not reward real movement")
		return
	game.player.global_position = Vector2(DentiArena.PLAYER_MARGIN, game.player.global_position.y)
	Input.action_press("move_left")
	game.player._physics_process(1.0 / 60.0)
	Input.action_release("move_left")
	if game.player.is_moving or game.items.modify_damage(second, water, 20.0) != idle_damage:
		_fail("lollipop rewarded pushing into the arena wall")
		return

	if not game.items.acquire(ShopController.by_id(&"contagious_floss")):
		_fail("contagious floss could not be acquired")
		return
	second.global_position = first.global_position + Vector2(140.0, 0.0)
	first.apply_bleed(4.0, 2.5)
	first.take_damage(2000.0, WeaponCatalog.by_id(&"floss_whip"))
	if second.bleed_stacks != 1 or second.bleed_dps < 4.0:
		_fail("lethal hit did not spread bleed to a nearby enemy")
		return

	var luck_before: float = game.player.stats.luck
	if not game.items.acquire(ShopController.by_id(&"tooth_fairy_deposit")) or game.items.scrap_value(10) != 15 or game.player.stats.luck != luck_before + 10.0:
		_fail("tooth fairy deposit did not improve luck and chest scrap value")
		return
	game._clear_combat()
	await process_frame
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100.0, 0.0))
	var wet_enemy: Enemy = game.get_node("Enemies").get_child(0)
	wet_enemy.apply_wet(2.0)
	game._open_shop()
	game._save_run()
	var saved: Dictionary = session.load_run()
	if float(saved["enemies"][0].get("wet_time", 0.0)) <= 0.0:
		_fail("wet enemy status was not saved")
		return
	session.resume_requested = true
	var resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	var restored_enemy: Enemy = resumed.get_node("Enemies").get_child(0)
	if restored_enemy.wet_time <= 0.0 or resumed.items.count(&"tooth_fairy_deposit") != 1 or resumed.items.scrap_value(10) != 15:
		_fail("new item effects or wet status did not survive continue")
		return
	resumed.in_shop = false
	resumed.shop_panel.visible = false
	resumed.rewards.begin_wave()
	resumed.rewards.queue_chest(&"metal_crown", 10)
	resumed.rewards.begin_collection()
	resumed.rewards.finish_collection(false)
	resumed._advance_post_wave_rewards()
	if resumed.choice_panel.mode != &"chest" or resumed.choice_panel.buttons[1].text.find("15") < 0:
		_fail("chest choice did not show the deposit bonus")
		return
	var coins_before: int = resumed.coins
	resumed.choice_panel._on_choice_pressed(1)
	if resumed.coins != coins_before + 15 or resumed.rewards.step != PostWaveRewards.Step.SHOP:
		_fail("scrapping a chest did not grant the displayed bonus")
		return
	paused = false
	session.clear_run()
	print("Denti item synergies test passed")
	quit(0)


func _fail(message: String) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
