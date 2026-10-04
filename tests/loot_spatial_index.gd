extends SceneTree

var failures: Array[String] = []
var events: Array[int] = []
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/test_loot_spatial_index.json"
	session.resume_requested = false
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.player.loadout.restore([])
	paused = true
	seed(88817)
	var grid: LootSpatialIndex = game.get_node("Loot")
	var drops: Array[Loot] = []
	var expected: Dictionary[int, Vector2] = {}
	var order: Array[int] = []
	for number in 800:
		var position_world := Vector2(randf_range(-500, 1800), randf_range(-350, 1100))
		game._spawn_loot(position_world, &"coin" if number % 2 == 0 else &"xp", 1)
		var drop: Loot = grid.get_child(-1)
		var id := drop.get_instance_id()
		drop.collected.connect(func(_kind, _amount, _reward): events.append(id))
		drops.append(drop)
		expected[id] = position_world
		order.append(id)
		_check(not drop.is_physics_processing(), "ground loot still runs an individual per-tick callback")
	# Boundary cases and a same-frame teleport across cells.
	drops[0].global_position = Vector2(667, 360)
	expected[order[0]] = drops[0].global_position
	drops[1].global_position = Vector2(750, 360)
	expected[order[1]] = drops[1].global_position
	for tick in 100:
		if tick == 10:
			game.position = Vector2(130, -260)
			for id in expected:
				expected[id] += game.position
		if tick == 20:
			game.rotation = 0.2
			game.scale = Vector2(1.2, 0.8)
			for drop in drops:
				if is_instance_valid(drop) and expected.has(drop.get_instance_id()):
					expected[drop.get_instance_id()] = drop.global_position
		if tick % 15 == 0:
			game.player.global_position = Vector2(randf_range(0, 1100), randf_range(0, 750)) if tick > 0 else Vector2(640, 360)
		if tick == 35:
			game.items.cached_pickup_range = 235
		if tick == 50:
			for drop in drops:
				if is_instance_valid(drop):
					drop.begin_wave_collection()
		var at: Vector2 = game.player.global_position
		var expected_events: Array[int] = []
		for id in order:
			if not expected.has(id):
				continue
			var position_world := expected[id]
			var distance := position_world.distance_squared_to(at)
			if distance <= Loot.PICKUP_DISTANCE * Loot.PICKUP_DISTANCE:
				expected_events.append(id)
				expected.erase(id)
			elif tick >= 50:
				expected[id] = position_world.move_toward(at, maxf(Loot.WAVE_COLLECTION_SPEED, sqrt(distance) * 3) / 60)
			elif distance <= game.items.cached_pickup_range * game.items.cached_pickup_range:
				expected[id] = position_world.move_toward(at, 200.0 / 60)
		events.clear()
		grid._physics_process(1.0 / 60)
		_check(events == expected_events, "grid changed pickup timing/order or emitted a pickup twice at tick %d" % tick)
		for drop in drops:
			if is_instance_valid(drop) and expected.has(drop.get_instance_id()):
				# World/local conversion under nonuniform scale accumulates float rounding.
				if drop.global_position.distance_to(expected[drop.get_instance_id()]) > 0.01:
					_check(false, "grid changed magnet/sweep movement at tick %d: actual %s, expected %s" % [tick, drop.global_position, expected[drop.get_instance_id()]])
					game.free()
					quit(1)
					return
		await process_frame
	for drop in grid.get_children():
		drop.free()
	_check(grid.cells.is_empty() and grid.membership.is_empty() and grid.collecting.is_empty() and not grid.is_physics_processing(), "freed loot leaked grid entries or active processing")
	# A far-away chest sleeps, wakes on teleport, and retains its exact reward.
	game.rotation = 0
	game.scale = Vector2.ONE
	game.position = Vector2.ZERO
	game.player.global_position = Vector2(640, 360)
	game._spawn_loot(Vector2(-10000, 20000), &"chest", 7, &"metal_crown")
	var chest: Loot = grid.get_child(0)
	grid._physics_process(1.0 / 60)
	_check(grid.last_candidates == 0 and not chest.is_queued_for_deletion(), "distant chest still needs a per-tick distance check")
	chest.global_position = game.player.global_position
	grid._physics_process(1.0 / 60)
	grid._physics_process(1.0 / 60)
	_check(game.rewards.pending_chests.size() == 1 and game.rewards.current_chest().item_id == "metal_crown" and game.rewards.current_chest().scrap_coins == 7, "teleported chest lost its reward or was collected twice")
	session.clear_run()
	game.free()
	paused = false
	if failures.is_empty():
		print("Denti loot spatial index regression test passed")
	quit(0 if failures.is_empty() else 1)
