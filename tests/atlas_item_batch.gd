extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_atlas_item_batch_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(2)
	game.wave.active = false
	var ids := [&"bleeding_hourglass", &"rinse_valve", &"shine_prism", &"shard_crown",
		&"interest_tooth", &"return_drill", &"saliva_chalice", &"sugar_shock"]
	var item_count := 0
	for template in ShopController.CATALOG:
		if template.weapon_data == null:
			item_count += 1
	if item_count != 30:
		_fail("item catalog did not expand to 30 entries")
		return
	for index in ids.size():
		var item := ShopController.by_id(ids[index])
		var icon := DentiUIIcons.item(item.icon_index) as AtlasTexture
		if item.icon_index != 20 + index or icon == null or not icon.atlas.resource_path.ends_with("item_icons_expansion_2.png"):
			_fail("new item has the wrong atlas cell: " + str(ids[index]))
			return
		if not game.items.acquire(item):
			_fail("new item could not be acquired: " + str(ids[index]))
			return
	game.items.acquire(ShopController.by_id(&"floss_reel"))
	var floss := WeaponCatalog.by_id(&"floss_whip")
	var water := WeaponCatalog.by_id(&"water_jet")
	var light := WeaponCatalog.by_id(&"enamel_mirror")
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100.0, 0.0))
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(150.0, 0.0))
	var first: Enemy = game.get_node("Enemies").get_child(0)
	var second: Enemy = game.get_node("Enemies").get_child(1)
	first.health = 1000.0
	first.max_health = 1000.0
	second.health = 1000.0
	second.max_health = 1000.0
	first.set_physics_process(false)
	second.set_physics_process(false)
	for index in 4:
		first.take_damage(1.0, floss)
	if first.bleed_stacks != 4 or first.bleed_time < 3.49:
		_fail("bleeding hourglass did not extend duration and stack cap")
		return
	first.take_damage(1.0, water)
	var second_before: float = second.health
	game.items._process(0.1)
	if game.items.puddles.size() != 1 or second.wet_time <= 0.0 or second.health >= second_before:
		_fail("rinse valve puddle did not wet and damage a nearby enemy")
		return
	second_before = second.health
	first.take_damage(1.0, light, true)
	if second.health >= second_before:
		_fail("critical hit did not trigger the prism beam")
		return
	second.global_position = game.player.global_position + Vector2(45.0, 0.0)
	game.player.stats.shield_charges = 0
	game.player.stats.grant_shield(1)
	game.player.hurt_time = 0.0
	second_before = second.health
	game.player.take_hit(20.0)
	if second.health >= second_before or game.player.stats.shield_charges != 0:
		_fail("splitter crown did not retaliate on a shield block")
		return
	game.player.stats.health = game.player.stats.max_health
	game.player.stats.heal(40.0)
	if game.player.stats.shield_charges != 1:
		_fail("saliva chalice did not turn overheal into a shield")
		return
	for index in 12:
		game.items.on_kill(game.player.position, false)
	if game.items.attack_interval_factor() >= 1.0:
		_fail("sugar shock did not start after twelve kills")
		return
	game.items._process(4.01)
	if game.items.attack_interval_factor() <= 1.0:
		_fail("sugar shock did not cause its crash")
		return
	game.items._process(3.01)
	if game.items.attack_interval_factor() != 1.0:
		_fail("sugar shock crash did not expire")
		return
	game._clear_combat()
	game.items.on_wave_start()
	game.items.cooldowns["water_puddle"] = 99.0
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100.0, 0.0))
	first = game.get_node("Enemies").get_child(0)
	first.health = 1000.0
	first.max_health = 1000.0
	first.set_physics_process(false)
	var projectile: WeaponProjectile = load("res://scenes/game/weapon_projectile.tscn").instantiate()
	game.get_node("Projectiles").add_child(projectile)
	projectile.launch(game.player.global_position + Vector2(20.0, 0.0), Vector2.RIGHT, 20.0, water, game.items)
	for index in 12:
		projectile._physics_process(0.02)
		if projectile.returning:
			break
	if not projectile.returning or projectile.return_factor < 0.34:
		_fail("direct projectile did not begin its return pass")
		return
	first.global_position += Vector2(400.0, 0.0)
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(45.0, 0.0))
	second = game.get_node("Enemies").get_child(1)
	second.health = 1000.0
	second.max_health = 1000.0
	second.set_physics_process(false)
	second_before = second.health
	for index in 12:
		projectile._physics_process(0.02)
		if second.health < second_before:
			break
	if second.health >= second_before:
		_fail("returning projectile did not damage an enemy on the way back")
		return
	game._clear_combat()
	game.items.cooldowns["water_puddle"] = 0.0
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100.0, 0.0))
	var saved_enemy: Enemy = game.get_node("Enemies").get_child(0)
	saved_enemy.health = 1000.0
	saved_enemy.max_health = 1000.0
	saved_enemy.take_damage(1.0, water)
	game.items.overheal_bank = 8.0
	for index in 12:
		game.items.on_kill(game.player.position, false)
	game._open_shop()
	game._save_run()
	session.resume_requested = true
	var resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	if resumed.items.count(&"rinse_valve") != 1 or resumed.items.puddles.size() != 1 or resumed.items.overheal_bank != 8.0 or resumed.items.sugar_rush_time <= 0.0:
		_fail("new item effects did not survive continue")
		return
	resumed.in_shop = false
	resumed.shop_panel.visible = false
	resumed.wave.active = false
	resumed.coins = 100
	resumed.rewards.begin_wave()
	resumed.rewards.begin_collection()
	resumed.collecting_wave_loot = true
	resumed.wave_loot_remaining = 0
	resumed._finish_loot_collection()
	if resumed.coins != 106 or resumed.rewards.step != PostWaveRewards.Step.SHOP:
		_fail("interest was not paid once before the shop")
		return
	paused = false
	session.clear_run()
	print("Denti atlas item batch test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
