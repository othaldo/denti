extends SceneTree

var failures: Array[String] = []
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_combat_performance.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.player.loadout.restore([])
	game.wave.active = false
	paused = true
	seed(61192)
	var index: EnemySpatialIndex = game.get_node("Enemies")
	for number in 240:
		var data: EnemyData = WaveController.PLAQUE.duplicate()
		data.radius = randf_range(5, 85)
		game._create_enemy(data, Vector2(randf_range(-500, 2000), randf_range(-400, 1400)))
	for query in 140:
		var at := Vector2(randf_range(-500, 2000), randf_range(-400, 1400))
		var radius := randf_range(0, 400)
		_compare_circle(index, at, radius, query % 2 == 0)
		var end := at + Vector2(randf_range(-900, 900), randf_range(-900, 900))
		var actual := index.along_segment(at, end, 10)
		var expected: Array[Enemy] = []
		for enemy: Enemy in index.get_children():
			var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, at, end)
			if closest.distance_squared_to(enemy.global_position) <= pow(enemy.data.radius + 10, 2):
				expected.append(enemy)
		_check(actual == expected, "segment query omitted a collider or changed spawn order")
	var moved: Enemy = index.get_child(0)
	moved.global_position = Vector2(-129, 128)
	_compare_circle(index, moved.global_position, 0, true)
	_check(index.in_circle(moved.global_position, 0).has(moved), "same-frame teleport left a stale cell")
	WeaponAttackShapes.hit(moved, WeaponCatalog.by_id(&"water_jet"), 4, 1, false, game.items, Vector2.RIGHT)
	_compare_circle(index, moved.global_position, 0, true)
	game.position = Vector2(130, -260)
	_compare_circle(index, moved.global_position, 0, true)
	game.rotation = 0.2
	game.scale = Vector2(1.2, 0.8)
	_compare_circle(index, moved.global_position, 110, true)
	game.rotation = 0
	game.scale = Vector2.ONE
	game.position = Vector2.ZERO
	moved.take_damage(1e9)
	_check(not index.in_circle(moved.global_position, 500).has(moved), "dead enemy remained targetable before deferred deletion")
	moved.free()
	_check(index.membership.size() == 239, "freed enemy leaked its index entry")
	for enemy in index.get_children():
		enemy.free()
	_check(index.cells.is_empty() and index.membership.is_empty() and index.bosses.is_empty(), "combat cleanup leaked spatial references")
	_check_projectile_order()
	_check_telemetry()
	_check_visual_sharing()
	_check_damage_budget(session)
	session.clear_run()
	paused = false
	game.free()
	if failures.is_empty():
		print("Denti combat performance regression test passed")
	quit(0 if failures.is_empty() else 1)

func _compare_circle(index: EnemySpatialIndex, at: Vector2, radius: float, include_radius: bool) -> void:
	var expected: Array[Enemy] = []
	for enemy: Enemy in index.get_children():
		var reach := radius + (enemy.data.radius if include_radius else 0.0)
		if enemy.health > 0 and not enemy.is_queued_for_deletion() and at.distance_squared_to(enemy.global_position) <= reach * reach:
			expected.append(enemy)
	_check(index.in_circle(at, radius, include_radius) == expected, "circle query differs from brute-force range/collider test")

func _check_projectile_order() -> void:
	var at: Vector2 = game.player.global_position
	# Spawn farther enemy first: collision order must be distance along the shot.
	game._create_enemy(WaveController.PLAQUE, at + Vector2(200, 0))
	game._create_enemy(WaveController.PLAQUE, at + Vector2(100, 0))
	var far: Enemy = game.get_node("Enemies").get_child(0)
	var near: Enemy = game.get_node("Enemies").get_child(1)
	far.health = 1000
	near.health = 1000
	var shot: WeaponProjectile = WeaponInstance.PROJECTILE_SCENE.instantiate()
	game.get_node("Projectiles").add_child(shot)
	shot.launch(at, Vector2.RIGHT, 5, WeaponCatalog.by_id(&"magic_toothbrush"), game.items)
	shot._physics_process(0.5)
	_check(near.health < 1000 and far.health == 1000 and shot.impact_time > 0, "fast non-piercing shot hit the wrong enemy")
	_check(not shot.body_sprite.visible, "impact still showed a flying projectile")
	shot.free()
	far.free()
	near.free()

func _check_telemetry() -> void:
	var stats := RunTelemetry.new()
	stats.begin_wave(1)
	stats.tick(1)
	for hit in 2000:
		stats.record_damage(0.5, &"test")
		stats.record_taken(0.25)
	stats.record_kill(false)
	_check(stats.damage_events.size() == 1 and stats.taken_events.size() == 1, "same-frame telemetry still allocates one bucket per hit")
	stats.tick(4)
	stats.record_damage(20)
	stats.record_taken(2)
	stats.record_kill(false)
	var legacy := stats.save_data()
	legacy["damage_events"] = [{"at": 1.0, "amount": 600.0}, {"at": 1.0, "amount": 400.0}, {"at": 5.0, "amount": 20.0}]
	var restored := RunTelemetry.new()
	restored.restore(legacy, 1)
	_check(is_equal_approx(restored.recent_dps(), 204) and is_equal_approx(restored.taken_per_minute(), 6024), "old per-hit telemetry save changed rolling totals")
	restored.tick(6)
	_check(is_equal_approx(restored.recent_dps(), 2) and is_equal_approx(restored.taken_per_minute(), 12) and is_equal_approx(restored.recent_kps(), 0.1), "window boundary expired the wrong bucket")
	var roundtrip := RunTelemetry.new()
	roundtrip.restore(restored.save_data(), 1)
	_check(is_equal_approx(roundtrip.recent_dps(), restored.recent_dps()), "expired telemetry reappeared after save/resume")
	roundtrip.tick(4)
	_check(roundtrip.recent_dps() == 0 and roundtrip.recent_kps() == 0 and roundtrip.taken_per_minute() == 0, "rolling sums did not fully expire")
	roundtrip.begin_wave(2)
	roundtrip.record_damage(3)
	_check(roundtrip.recent_dps() == 3, "next wave reused previous rolling sums")

func _check_visual_sharing() -> void:
	var weapon := WeaponCatalog.by_id(&"water_jet")
	var first := CombatSpriteTextures.projectile_body(weapon.projectile_color, 11) as AtlasTexture
	var second := CombatSpriteTextures.projectile_tail(weapon.projectile_color, 11) as AtlasTexture
	_check(first.atlas == second.atlas, "projectile layers cannot batch together")
	_check(first == CombatSpriteTextures.projectile_body(weapon.projectile_color, 11), "projectile texture was regenerated")
	var xp := CombatSpriteTextures.loot(&"xp") as AtlasTexture
	var coin := CombatSpriteTextures.loot(&"coin") as AtlasTexture
	var chest := CombatSpriteTextures.loot(&"chest") as AtlasTexture
	_check(xp.atlas == coin.atlas and coin.atlas == chest.atlas, "alternating loot kinds break texture batching")

func _check_damage_budget(session: Node) -> void:
	var prior: int = session.graphics_mode
	session.graphics_mode = session.GraphicsMode.ECONOMY
	for number in 200:
		game._show_damage_number(game.player.global_position, 5)
	_check(game.get_node("DamageNumbers").get_child_count() == game.MAX_ECONOMY_DAMAGE_NUMBERS, "cosmetic damage numbers are unbounded")
	game._show_damage_number(game.player.global_position, 5, true)
	game._show_item_feedback("Schild!", game.player.global_position, Color.WHITE)
	_check(game.get_node("DamageNumbers").get_child_count() == game.MAX_ECONOMY_DAMAGE_NUMBERS + 2, "cosmetic budget hid player damage or important feedback")
	session.graphics_mode = prior
