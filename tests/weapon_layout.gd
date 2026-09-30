extends SceneTree

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_layout.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	for count in range(1, 7):
		for index in count:
			var home := WeaponLayout.home(index, count)
			if absf(home.x) < 45:
				_fail("hand position obscures the player centre")
				return
			for other in range(index):
				if home.distance_to(WeaponLayout.home(other, count)) < 25:
					_fail("equipped weapons share an idle hand position")
					return
	for data in WeaponCatalog.ALL:
		if WeaponLayout.visual_size(data, WeaponLayout.density_scale(6)) > 88.01:
			_fail("shared size limit did not apply to " + str(data.id))
			return
		if data.held_style == "staff":
			for side in [-1.0, 1.0]:
				var resting := WeaponMotion.pose(data, 1, Vector2(side * 50, 16), Vector2.RIGHT, -1, 0)
				var blade := WeaponMotion.segment(data, resting)
				if (blade[1].x - blade[0].x) * side < -0.001:
					_fail("resting melee weapon points across Denti's face")
					return
	_equip_six()
	var right := _enemy(Vector2(120, 0))
	var left := _enemy(Vector2(-120, 0))
	var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
	for weapon in weapons:
		weapon._physics_process(0.001)
	if weapons[0].strike.target_id != right.get_instance_id() or weapons[1].attack_time > 0:
		_fail("first engagement did not stagger simultaneous weapons")
		return
	var saved := RunSnapshot.capture(game)
	RunSnapshot.restore(game, saved)
	paused = true
	weapons = game.player.loadout.equipped()
	left = game.get_node("Enemies").get_child(1)
	weapons[1]._physics_process(weapons[1].cooldown + 0.001)
	if weapons[1].strike.target_id != left.get_instance_id():
		_fail("weapon did not select a nearby target from its own hand")
		return
	if not is_equal_approx(weapons[1].cooldown, weapons[1].attack_interval()):
		_fail("staggering changed the sustained attack interval")
		return
	_clear_enemies()
	_equip_six()
	var single := _enemy(Vector2(140, 0))
	weapons = game.player.loadout.equipped()
	for weapon in weapons:
		weapon._physics_process(0.001)
		if weapon.cooldown > 0 and weapon.attack_time == 0:
			weapon._physics_process(weapon.cooldown + 0.001)
		if weapon.strike.target_id != single.get_instance_id():
			_fail("target distribution prevented focus on a single enemy")
			return
		var pose := WeaponMotion.pose(weapon.data, weapon.tier, weapon.home_position, weapon.aim, 0.70, 0.0, weapon.aim_distance, weapon.visual_density)
		var blade := WeaponMotion.segment(weapon.data, pose)
		if blade[1].length() < weapon.data.range_at_tier(1) * 0.95:
			_fail("smaller weapon lost its attack reach")
			return
		weapon._physics_process(weapon.attack_duration)
	if single.health >= 10000 - 6 * 20:
		_fail("compact swept contact weapons missed their shared target")
		return
	session.clear_run()
	game.free()
	paused = false
	print("PASS weapon_layout")
	quit()


func _equip_six() -> void:
	var entries: Array[Dictionary] = []
	for index in 6:
		entries.append({"id": "toothpick_spear", "tier": 1})
	game.player.loadout.restore(entries)
	game.player.stats.crit_chance = 0
	for weapon in game.player.loadout.equipped():
		weapon.set_physics_process(false)


func _enemy(offset: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.set_physics_process(false)
	return enemy


func _clear_enemies() -> void:
	for enemy in game.get_node("Enemies").get_children():
		enemy.free()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
