extends SceneTree

var failures: Array[String] = []
var legacy_events: Array[String] = []
var central_events: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _fixture(events: Array[String]) -> Node2D:
	seed(92917)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.wave.current_wave = 17
	game.player.loadout.restore([])
	game.player.stats.max_health = 100000
	game.player.stats.health = 100000
	paused = true
	var types: Array[EnemyData] = [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.POISON_GERM, WaveController.GUM_BITER, WaveController.ACID_CROWN, WaveController.HUNT_GERM, WaveController.CAVITY_KING]
	for number in 36:
		seed(92917 + number)
		game._create_enemy(types[number % types.size()], Vector2(640, 360) + Vector2.from_angle(number * TAU / 36) * (80 + number * 7))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.special_timer = 0.01 + (number % 4) * 0.11
		enemy.attack_performed.connect(func(kind): events.append("%d:%s" % [number, kind]))
	return game

func _inputs(game: Node2D, tick: int) -> void:
	game.player.global_position = Vector2(640, 360) + Vector2.from_angle(tick * 0.023) * 115
	game.player.hurt_time = 0
	var index: EnemySpatialIndex = game.get_node("Enemies")
	if tick == 20:
		index.get_child(0).apply_wet(0.4)
		index.get_child(1).apply_bleed(0.2, 1.4)
		index.get_child(2).apply_haste(0.3, 0.3)
		index.get_child(3).apply_enamel_exposure(0.1, 0.7)
	if tick == 65:
		var enemy: Enemy = index.get_child(0)
		WeaponAttackShapes.hit(enemy, WeaponCatalog.by_id(&"water_jet"), 4, 1, false, game.items, Vector2.RIGHT)
	if tick in [30, 75, 190]:
		# Frequent water hits must retain the central path, including overlapping
		# clocks, refreshes, expiry and a warning starting on the same step.
		for number in index.get_child_count():
			var enemy: Enemy = index.get_child(number)
			if not enemy.data.is_boss and not enemy.data.is_elite:
				enemy.apply_wet(0.01 if number % 3 == 0 else 0.42)
				enemy.apply_haste(0.25, 0.3)
				enemy.apply_enamel_exposure(0.15, 0.2)
				if number % 4 == 0:
					enemy.special_timer = 0.0
	if tick == 80:
		index.get_child(1).global_position = Vector2(-129, 128)
	if tick == 95:
		index.get_child(0).move_speed += 33
	if tick == 120:
		index.get_child(2).target = null
	if tick == 135:
		index.get_child(2).target = game.player
	if tick == 160:
		game.position = Vector2(130, -260)
		game.rotation = 0.2
		game.scale = Vector2(1.2, 0.8)
	if tick == 185:
		game.transform = Transform2D.IDENTITY
	if tick == 205:
		index.get_child(0).set_simulation_enabled(false)
	if tick == 220:
		index.get_child(0).set_simulation_enabled(true)
	if tick == 225:
		game.player.stats.health = 0.0
		index.get_child(0).apply_wet(0.035)
		index.get_child(0).apply_haste(0.25, 0.025)
		index.get_child(0).apply_enamel_exposure(0.15, 0.015)
	if tick == 230:
		game.player.stats.health = 100000.0
	if tick == 235:
		index.get_child(4).take_damage(1e9)
	if tick == 245:
		game._create_enemy(WaveController.BACTERIA, Vector2(750, 360))

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://central_enemy_motion.json"
	session.selected_story_mode = false
	session.selected_difficulty_id = &"normal"
	session.clear_run()
	var legacy := _fixture(legacy_events)
	var central := _fixture(central_events)
	var index: EnemySpatialIndex = central.get_node("Enemies")
	for enemy: Enemy in index.get_children():
		_check(not enemy.is_physics_processing() and enemy.simulation_enabled, "managed enemy still has an individual fixed-step callback")
	for tick in 300:
		# Match randomness consumed by attack effects, status chances and spawns.
		current_scene = legacy
		seed(88231 + tick)
		_inputs(legacy, tick)
		for enemy: Enemy in legacy.get_node("Enemies").get_children():
			if enemy.simulation_enabled:
				enemy._physics_process(1.0 / 60)
		current_scene = central
		seed(88231 + tick)
		_inputs(central, tick)
		index._physics_process(1.0 / 60)
		var expected := RunSnapshot.capture(legacy)
		var actual := RunSnapshot.capture(central)
		for key in ["enemies", "acid", "loot"]:
			if actual[key] != expected[key]:
				print("DIFFERENCE %s count: expected %d, actual %d" % [key, expected[key].size(), actual[key].size()])
				for number in mini(actual[key].size(), expected[key].size()):
					for field in actual[key][number]:
						if actual[key][number][field] != expected[key][number][field]:
							print("DIFFERENCE %s %d %s: expected %s, actual %s" % [key, number, field, expected[key][number][field], actual[key][number][field]])
			_check(actual[key] == expected[key], "central motion changed %s at tick %d" % [key, tick])
		_check(central.player.stats.health == legacy.player.stats.health and central.player.hurt_time == legacy.player.hurt_time, "central motion changed contact damage/order at tick %d" % tick)
		_check(central_events == legacy_events, "central motion changed attack timing/order at tick %d" % tick)
		if not failures.is_empty():
			break
		await process_frame
	# Removing nodes and compacting must preserve spawn order and index ownership.
	for number in 30:
		central._create_enemy(WaveController.PLAQUE, Vector2(-2000, -2000))
	for enemy: Enemy in index.get_children().slice(0, 40):
		enemy.free()
	index._physics_process(1.0 / 60)
	var last_order := -1
	for enemy in index.motion.enemies:
		if enemy != null:
			_check(enemy.spatial_order > last_order and index.motion.enemies[enemy.motion_slot] == enemy, "compaction reordered enemies or assigned stale slots")
			last_order = enemy.spatial_order
	for enemy in index.get_children():
		enemy.free()
	_check(index.motion.enemies.is_empty() and index.motion.positions.is_empty() and not index.is_physics_processing(), "combat cleanup left active motion entries")
	session.clear_run()
	legacy.free()
	central.free()
	paused = false
	if failures.is_empty():
		print("Denti central enemy motion matches individual simulation")
	quit(0 if failures.is_empty() else 1)
