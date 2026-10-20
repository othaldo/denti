extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _entries(costs: Array) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for cost: int in costs:
		entries.append({"id": "magic_toothbrush" if cost == 2 else "turbo_drill", "tier": 1})
	return entries

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://root_capacity_test.json"
	session.resume_requested = false
	session.clear_run()
	var scene: PackedScene = load("res://scenes/game/game.tscn")
	game = scene.instantiate()
	# Class/challenge setup before adding the scene must affect starter choices.
	game.get_node("Player/Stats").root_capacity = 1
	root.add_child(game)
	current_scene = game
	var loadout: WeaponLoadout = game.player.loadout
	var stats: PlayerStats = game.player.stats
	_check(loadout.capacity == 1, "loadout did not bind the player's configured roots")
	for starter: WeaponData in game.choice_panel.starter_options:
		_check(starter.hands <= 1, "one-root challenge offered an unusable starter")
	game._on_starter_chosen(WeaponCatalog.by_id(&"magic_toothbrush"))
	_check(game.starter_pending and loadout.equipped().is_empty(), "invalid starter began a weaponless run")
	game.choice_panel._on_choice_pressed(0)
	_check(not game.starter_pending and loadout.used_slots() == 1, "one-root challenge could not begin with a valid weapon")
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.coins = 1000
	game._open_shop()
	var brush := WeaponCatalog.by_id(&"magic_toothbrush")
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	for capacity in [1, 2, 4, 5, 8, 12]:
		loadout.restore([])
		game._update_shop_panel()
		stats.root_capacity = capacity
		_check(game.shop_panel.inventory_label.text == "Wurzeln · 0/%d" % capacity, "open shop did not react to changed root capacity")
		for index in capacity:
			_check(loadout.acquire(drill, 4), "legal weapon rejected at root capacity %d" % capacity)
		_check(loadout.used_slots() == capacity and not loadout.can_acquire(drill, 4), "weapon limit ignores capacity %d" % capacity)
		_check(not loadout.acquire(brush, 4), "full roots accepted another two-root weapon")
		var model := BuildPresentation.shop_view(game.player, game.shop, game.items, game.relics, 1, game.coins)
		_check(model.capacity == capacity, "shop presentation hardcodes six roots")
		game._update_shop_panel()
		_check(game.shop_panel.inventory_label.text == "Wurzeln · %d/%d" % [capacity, capacity], "shop root label differs from the player")
		game.game_menu._show_stats()
		var found := false
		for child in game.game_menu.rows.get_children():
			if child is Label and child.text == "Wurzeln · %d/%d" % [capacity, capacity]: found = true
		_check(found, "pause stats hardcode six roots")
		game.game_menu.open_pause()
		game.game_menu._show_stats()
		for extent in [Vector2i(320, 568), Vector2i(1280, 720)]:
			root.content_scale_size = extent
			root.size = extent
			for frame in 5: await process_frame
			_check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.game_menu.build_panel.get_global_rect()), "many weapons pushed pause stats outside the viewport")
			var scroll: ScrollContainer = game.game_menu.rows.get_node("WeaponScroll")
			_check(game.game_menu.build_panel.get_global_rect().encloses(scroll.get_global_rect()), "pause weapon scroller exceeds its panel")
		game.game_menu.hide()
	# Mixed costs, odd limits and larger grids must neither overlap nor overflow.
	for sample in [[1, [1]], [4, [2, 1]], [5, [1, 2, 2]], [8, [1, 2, 1, 2, 1]], [12, [2, 1, 2, 1, 2, 1, 2]]]:
		loadout.restore([])
		stats.root_capacity = sample[0]
		loadout.restore(_entries(sample[1]))
		game._update_shop_panel()
		var slots: EquipmentSlots = game.shop_panel.inventory_row
		for columns in [2, 3, 6]:
			var height := slots.layout_slots(330, columns, 44)
			var rectangles: Array[Rect2] = []
			for slot: Control in slots.get_children():
				var rect := Rect2(slot.position, slot.size)
				_check(Rect2(0, 0, 330, height).encloses(rect), "root grid escaped its measured bounds: %s, %d columns, %s" % [sample, columns, rect])
				for previous in rectangles:
					_check(not previous.intersects(rect), "mixed root spans overlap: %s" % str(sample))
				rectangles.append(rect)
		for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.content_scale_size = extent
			root.size = extent
			for frame in 5: await process_frame
			_check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.shop_panel.get_node("Root/Center/Panel").get_global_rect()), "variable roots pushed the shop outside the viewport")
	# Automatic full-inventory fusion still works at a non-default limit.
	loadout.restore([])
	stats.root_capacity = 4
	loadout.restore(_entries([2, 1, 1]))
	_check(loadout.acquire(brush) and loadout.used_slots() == 4 and loadout.equipped()[0].tier == 2, "full four-root inventory lost purchase fusion")
	# Evolution capacity uses the player, too, including a result with higher cost.
	var recipe := WeaponEvolutionRecipe.new()
	recipe.base_weapon = drill.id
	recipe.result = brush
	loadout.restore([])
	stats.root_capacity = 1
	loadout.acquire(drill, 4)
	_check(not loadout.evolution_ready(0, recipe, game.items), "evolution ignored a one-root limit")
	stats.root_capacity = 2
	_check(loadout.evolution_ready(0, recipe, game.items), "evolution did not see increased root capacity")
	# Save the per-player limit before restoring weapon entries larger than six.
	loadout.restore([])
	stats.root_capacity = 8
	loadout.restore(_entries([1, 1, 1, 1, 1, 1, 1, 1]))
	game._update_shop_panel()
	var saved := RunSnapshot.capture(game)
	_check(session.save_run(saved) == OK, "eight-root run could not be saved")
	game.free()
	session.resume_requested = true
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	loadout = game.player.loadout
	stats = game.player.stats
	_check(stats.root_capacity == 8 and loadout.used_slots() == 8, "resume restored six before loading an eight-root loadout")
	# Reducing the limit during a run blocks additions without deleting purchases.
	stats.root_capacity = 4
	_check(not loadout.can_acquire(brush, 4), "reduced limit allowed additional equipment")
	saved = RunSnapshot.capture(game)
	RunSnapshot.restore(game, saved)
	_check(stats.root_capacity == 4 and loadout.used_slots() == 8, "lowered root limit deleted owned weapons on resume")
	stats.root_capacity = 0
	_check(stats.root_capacity == 1, "invalid root capacity was not bounded to one")
	var legacy: Dictionary = stats.to_save_data()
	legacy.erase("root_capacity")
	stats.load_save_data(legacy)
	_check(stats.root_capacity == 6, "legacy saves lost their six-root default")
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty(): print("Configurable player roots, acquisition, fusion, evolution, UI and save compatibility passed")
	finish(0 if failures.is_empty() else 1)
