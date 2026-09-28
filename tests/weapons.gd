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
	for count in 8:
		if not game.player.loadout.acquire(brush):
			_fail("matching weapon could not merge")
			return
	if game.player.loadout.equipped().size() != 1 or game.player.loadout.equipped()[0].tier != 4 or game.player.loadout.used_slots() != 2:
		_fail("eight matching weapons did not form tier IV")
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
	if not game.player.loadout.acquire(WeaponCatalog.by_id(&"turbo_drill")) or game.player.loadout.used_slots() != 5:
		_fail("merging did not free a slot")
		return
	game._open_shop()
	var coins_before: int = game.coins
	var button: Button = game.shop_panel.inventory_row.get_child(0)
	button.pressed.emit()
	if game.coins != coins_before:
		_fail("first sell click removed a weapon")
		return
	button.pressed.emit()
	if game.coins <= coins_before or game.player.loadout.used_slots() != 4 or not game.player.loadout.can_acquire(brush):
		_fail("confirmed sale did not free weapon space")
		return
	game.player.loadout.restore([])
	for count in 8:
		if not game.player.loadout.acquire(brush):
			_fail("tier-up weapon purchase was blocked")
			return
	game._save_run()
	var saved: Dictionary = session.load_run()
	if saved.get("weapons", []).size() != game.player.loadout.equipped().size():
		_fail("weapon loadout was not saved")
		return
	session.resume_requested = true
	var resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	var resumed_weapons: Array[Dictionary] = resumed.player.loadout.save_data()
	if resumed_weapons.size() != saved["weapons"].size():
		_fail("continue changed the weapon count")
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
