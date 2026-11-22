extends "res://tests/support/test_runtime.gd"

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
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	for capacity in [1, 2, 3, 4, 5, 6, 8, 12]:
		for root in capacity:
			var anchor := WeaponLayout.root_position(root, capacity)
			if anchor.length() < 45:
				_fail("root anchor obscures the player centre")
				return
			if absf(anchor.x) < 12 and anchor.y < 0:
				_fail("root anchor sits on top of Denti's head")
				return
			for other in range(root):
				if anchor.distance_to(WeaponLayout.root_position(other, capacity)) < 25:
					_fail("two roots share an anchor")
					return
			if capacity >= 3:
				var pair := WeaponLayout.anchor(root, 2, capacity)
				var next := WeaponLayout.root_position((root + 1) % capacity, capacity)
				if absf(pair.distance_to(anchor) - pair.distance_to(next)) > 0.01 or pair.distance_to(anchor) > anchor.distance_to(next):
					_fail("two-root weapon is not held between neighbouring roots")
					return
	if not WeaponLayout.root_position(0, 6).is_equal_approx(Vector2(WeaponLayout.HAND_RADIUS, 0)):
		_fail("first root is not on Denti's right-hand side")
		return
	if not _fixed_roots():
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
	# Root 3 of six sits on Denti's left; it picks the enemy nearest to itself.
	var left_hand := weapons[3]
	if left_hand.home_position.x >= 0:
		_fail("fourth root is not on Denti's left")
		return
	left_hand._physics_process(left_hand.cooldown + 0.001)
	if left_hand.strike.target_id != left.get_instance_id():
		_fail("weapon did not select a nearby target from its own root")
		return
	if not is_equal_approx(left_hand.cooldown, left_hand.attack_interval()):
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
		if (blade[1] - weapon.home_position).length() < weapon.data.range_at_tier(1) * 0.95:
			_fail("smaller weapon lost its attack reach")
			return
		weapon._physics_process(weapon.attack_duration)
	if single.health >= 10000 - 6 * 20:
		_fail("compact swept contact weapons missed their shared target")
		return
	_clear_enemies()
	if not _reach_from_root():
		return
	session.clear_run()
	game.free()
	paused = false
	print("PASS weapon_layout")
	finish()


func _fixed_roots() -> bool:
	var loadout: WeaponLoadout = game.player.loadout
	game.player.stats.root_capacity = 6
	loadout.restore([{"id": "toothpick_spear"}, {"id": "cavity_grinder"}, {"id": "toothpick_spear"}, {"id": "plaque_scaler"}])
	var roots: Array[int] = []
	for weapon in loadout.equipped(): roots.append(weapon.root_index)
	if roots != [0, 1, 3, 4]:
		_fail("weapons did not fill neighbouring roots in equipment order: " + str(roots))
		return false
	var grinder := loadout.equipped()[1]
	if not grinder.home_position.is_equal_approx(WeaponLayout.anchor(1, 2, 6)):
		_fail("two-root weapon left its anchor")
		return false
	var scaler := loadout.equipped()[3]
	var scaler_home := scaler.home_position
	loadout.sell(1)
	if scaler.root_index != 4 or not scaler.home_position.is_equal_approx(scaler_home):
		_fail("selling a weapon moved the remaining weapons")
		return false
	loadout.acquire(WeaponCatalog.by_id(&"plaque_scaler"))
	if loadout.equipped()[-1].root_index != 1:
		_fail("new weapon did not take the first free root")
		return false
	# Free roots 0 and 5 only neighbour each other across the ring's seam.
	loadout.sell(0)
	loadout.acquire(WeaponCatalog.by_id(&"cavity_grinder"))
	if loadout.equipped()[-1].root_index != 5:
		_fail("two-root weapon did not wrap onto neighbouring roots")
		return false
	var saved := loadout.save_data()
	loadout.restore(saved)
	for index in saved.size():
		if loadout.equipped()[index].root_index != int(saved[index].root):
			_fail("restored weapon changed its root")
			return false
	var legacy: Array = []
	for entry in saved:
		var old: Dictionary = entry.duplicate(true)
		old.erase("root")
		legacy.append(old)
	loadout.restore(legacy)
	var cursor := 0
	for weapon in loadout.equipped():
		if weapon.root_index != cursor:
			_fail("save without roots was not packed in equipment order")
			return false
		cursor += weapon.data.hands
	game.player.stats.root_capacity = 4
	for weapon in loadout.equipped():
		if not weapon.home_position.is_equal_approx(WeaponLayout.anchor(weapon.root_index, weapon.data.hands, 4)):
			_fail("root capacity change did not re-anchor weapons")
			return false
	game.player.stats.root_capacity = 6
	return true


func _reach_from_root() -> bool:
	# Reach counts from the weapon's own root, not from Denti's centre.
	game.player.loadout.restore([{"id": "plaque_scaler"}])
	var scaler: WeaponInstance = game.player.loadout.equipped()[0]
	scaler.set_physics_process(false)
	var reach := scaler.data.range_at_tier(1)
	var far_side := _enemy(Vector2(-(reach + 10), 0))
	var own_side := _enemy(Vector2(reach + 30, 0))
	scaler.engagement_pending = false
	scaler._physics_process(0.001)
	if scaler.strike.target_id != own_side.get_instance_id() or far_side.health < 10000:
		_fail("melee reach was not measured from its root")
		return false
	return true


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
	finish(1)
