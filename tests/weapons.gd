extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapons_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	if not paused or not game.player.loadout.equipped().is_empty():
		_fail("Denti was armed before starter selection")
		return
	game.choice_panel._on_choice_pressed(2)
	if paused or game.player.loadout.equipped()[0].data.id != &"water_jet":
		_fail("starter selection did not equip the water jet")
		return
	game.wave.active = false
	for data in WeaponCatalog.ALL:
		game.player.loadout.restore([{"id": str(data.id), "tier": 1}])
		var weapon: WeaponInstance = game.player.loadout.equipped()[0]
		if weapon.sprite.texture != data.sprite or weapon.tier != 1:
			_fail("weapon sprite or tier failed: " + str(data.id))
			return
		game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(80.0, 0.0))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 1000.0
		enemy.set_physics_process(false)
		for frame in 45:
			await physics_frame
			if enemy.health < 1000.0:
				break
		if enemy.health >= 1000.0:
			_fail("weapon did not hit: " + str(data.id))
			return
		enemy.free()
		for projectile in game.get_node("Projectiles").get_children():
			projectile.free()
	game.player.loadout.restore([])
	var brush := WeaponCatalog.by_id(&"magic_toothbrush")
	for count in 3:
		if not game.player.loadout.acquire(brush):
			_fail("matching weapon could not occupy a free slot")
			return
	if game.player.loadout.equipped().size() != 3 or game.player.loadout.equipped()[0].tier != 1 or game.player.loadout.used_slots() != 6:
		_fail("matching weapons merged despite free slots")
		return
	if not game.player.loadout.acquire(brush) or game.player.loadout.equipped().size() != 3 or game.player.loadout.equipped()[0].tier != 2:
		_fail("full loadout did not merge the purchased weapon")
		return
	if not game.player.loadout.merge(1) or game.player.loadout.equipped().size() != 2 or game.player.loadout.equipped()[1].tier != 2:
		_fail("manual merge did not combine matching equipped weapons")
		return
	if not game.player.loadout.merge(0) or game.player.loadout.equipped().size() != 1 or game.player.loadout.equipped()[0].tier != 3 or game.player.loadout.used_slots() != 2:
		_fail("manual tier-II merge did not reach tier III")
		return
	if game.player.loadout.merge(0):
		_fail("manual merge worked without a matching partner")
		return
	var full: Array[Dictionary] = [
		{"id": "turbo_drill", "tier": 1}, {"id": "turbo_drill", "tier": 2},
		{"id": "floss_whip", "tier": 1}, {"id": "water_jet", "tier": 1},
		{"id": "enamel_mirror", "tier": 1}, {"id": "plaque_scaler", "tier": 1},
	]
	game.player.loadout.restore(full)
	if game.player.loadout.used_slots() != 6 or game.player.loadout.can_acquire(brush):
		_fail("full loadout accepted a two-hand weapon")
		return
	if not game.player.loadout.acquire(WeaponCatalog.by_id(&"turbo_drill")) or game.player.loadout.used_slots() != 6 or game.player.loadout.equipped()[0].tier != 2:
		_fail("full loadout did not upgrade matching drill")
		return
	if not game.player.loadout.merge(0) or game.player.loadout.used_slots() != 5:
		_fail("manual merge did not free a slot")
		return
	game._open_shop()
	var coins_before: int = game.coins
	var expected_refund: int = game.player.loadout.refund_for(0)
	var button: Button = game.shop_panel.inventory_row.get_child(0).get_child(0)
	button.pressed.emit()
	if game.coins != coins_before:
		_fail("first sell click removed a weapon")
		return
	button.pressed.emit()
	if game.coins != coins_before + expected_refund or expected_refund != WeaponCatalog.by_id(&"turbo_drill").price * 2 or game.player.loadout.used_slots() != 4 or not game.player.loadout.can_acquire(brush):
		_fail("confirmed sale did not return half the combined weapon value")
		return
	game.shop.offers[0] = ShopController.by_id(&"turbo_drill")
	game.coins = 100
	game._on_shop_buy(0)
	if game.coins != 100 - ShopController.by_id(&"turbo_drill").price or game.player.loadout.equipped().size() != 5 or game.player.loadout.equipped()[-1].data.id != &"turbo_drill" or game.player.loadout.equipped()[-1].tier != 1:
		_fail("buying after selling upgraded an old weapon instead of adding the new one")
		return
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}])
	game._update_shop_panel()
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	(game.shop_panel.inventory_row.get_child(0).get_child(0) as Button).gui_input.emit(right_click)
	if game.player.loadout.equipped().size() != 1 or game.player.loadout.equipped()[0].tier != 2:
		_fail("shop right-click did not merge matching weapons")
		return
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4, "invested_coins": 72}])
	game._save_run()
	var saved: Dictionary = session.load_run()
	if saved.get("weapons", []).size() != game.player.loadout.equipped().size() or int(saved["weapons"][0].get("invested_coins", 0)) != 72:
		_fail("weapon loadout and sale value were not saved")
		return
	session.resume_requested = true
	var resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	var resumed_weapons: Array[Dictionary] = resumed.player.loadout.save_data()
	if resumed_weapons.size() != saved["weapons"].size() or resumed.player.loadout.refund_for(0) != 36:
		_fail("continue changed the weapon count or sale value")
		return
	for index in resumed_weapons.size():
		if str(resumed_weapons[index]["id"]) != str(saved["weapons"][index]["id"]) or int(resumed_weapons[index]["tier"]) != int(saved["weapons"][index]["tier"]):
			_fail("continue did not restore weapon types and tiers")
			return
	var old_save := saved.duplicate(true)
	old_save.erase("weapons")
	old_save.erase("starter_pending")
	old_save["owned_weapons"] = ["floss"]
	old_save["offers"] = ["floss", "drill", ""]
	session.save_run(old_save)
	session.resume_requested = true
	var restored: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(restored)
	current_scene = restored
	if restored.player.loadout.equipped().size() != 2 or restored.player.loadout.equipped()[0].data.id != &"magic_toothbrush" or restored.player.loadout.equipped()[1].data.id != &"floss_whip":
		_fail("old save did not migrate its weapons")
		return
	if restored.shop.offers[0] == null or restored.shop.offers[0].id != &"floss_whip" or restored.shop.offers[1] == null or restored.shop.offers[1].id != &"turbo_drill":
		_fail("old shop offers did not migrate")
		return
	paused = false
	session.clear_run()
	print("Denti weapon loadout test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
