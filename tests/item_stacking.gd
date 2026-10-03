extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_item_stacking.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	paused = true
	for item in ShopController.CATALOG:
		if item.family_id != &"":
			_check(item.family_limit == 12, "family still has a restrictive cap: " + str(item.id))
	for id in [&"chain_4", &"mouthwash", &"polish_paste", &"return_drill", &"conductive_varnish", &"cavity_bounty"]:
		for copy in 6:
			_check(game.items.acquire(ShopController.by_id(id)), "could not stack effect six times: " + str(id))
	_check(not game.items.can_acquire(ShopController.by_id(&"cavity_bounty")), "special item exceeded six copies")
	_check(game.items.can_acquire(ShopController.by_id(&"chain_1")), "six rare items blocked another rarity")
	_check(is_equal_approx(game.items.projectile_return_factor(), 2.1), "return damage stopped at old 70 percent cap")
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(120, 0))
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(140, 0))
	var first: Enemy = game.get_node("Enemies").get_child(0)
	var second: Enemy = game.get_node("Enemies").get_child(1)
	first.health = 10000
	second.health = 10000
	var water := WeaponCatalog.by_id(&"water_jet")
	var light := WeaponCatalog.by_id(&"enamel_mirror")
	game.items.on_weapon_hit(first, 100, light, false)
	_check(is_equal_approx(second.health, 9640), "six chain items lost damage to old cap")
	game.items.cooldowns["chain"] = 99.0
	game.items.on_weapon_hit(first, 100, water, false)
	_check(is_equal_approx(second.health, 9490), "six splash items lost damage to old cap")
	game.items.on_weapon_hit(first, 100, light, true)
	_check(is_equal_approx(second.health, 9280), "six crit bursts lost damage to old cap")
	var health_after := second.health
	game.items.on_weapon_hit(first, 100, light, true)
	_check(second.health == health_after, "stacking bypassed shared proc cooldown")
	var coins := 0
	for kill in 12:
		coins += game.items.on_kill(first.position, false)
	_check(coins == 6, "six bounty copies did not increase payout")
	var saved: Dictionary = game.items.save_data()
	game.items.restore(saved)
	_check(game.items.count(&"chain_4") == 6 and is_equal_approx(game.items.projectile_return_factor(), 2.1), "save/restore lost larger effect stacks")
	paused = false
	session.clear_run()
	if failures.is_empty():
		print("Denti item stacking test passed")
	quit(0 if failures.is_empty() else 1)
