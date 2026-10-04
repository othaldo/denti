extends SceneTree

var game: Node2D
var failures := 0
const STEP := 0.1


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _enemy(data: EnemyData) -> Enemy:
	game._create_enemy(data, game.player.global_position + Vector2(500, 0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_physics_process(false)
	enemy.special_timer = 100.0
	return enemy


func _travel(enemy: Enemy) -> float:
	enemy.global_position = game.player.global_position + Vector2(500, 0)
	var start := enemy.global_position
	enemy._physics_process(STEP)
	return start.distance_to(enemy.global_position)


func _distance_matches(actual: float, expected: float) -> bool:
	# Vector2 uses 32-bit coordinates; small displacements at arena coordinates
	# lose more precision than is_equal_approx's relative tolerance allows.
	return absf(actual - expected) < 0.001


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_wet_slow.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.player.loadout.restore([])
	paused = true
	# Test real displacement, not just the helper's multiplication.
	for row in [[WaveController.PLAQUE, 0.80], [WaveController.ACID_SPITTER, 0.80], [WaveController.HUNT_GERM, 0.90], [WaveController.BOSS, 0.95]]:
		var enemy := _enemy(row[0])
		var dry := _travel(enemy)
		var base_speed := enemy.move_speed
		enemy.apply_wet(2.5)
		_check(_distance_matches(_travel(enemy), dry * float(row[1])), "wet did not slow actual walking: " + enemy.data.display_name)
		enemy.apply_wet(1.0)
		_check(_distance_matches(_travel(enemy), dry * float(row[1])) and enemy.wet_time > 2.0, "repeated wet stacked slow or shortened duration")
		_check(enemy.move_speed == base_speed, "wet permanently mutated base speed")
		enemy.target = null
		enemy._physics_process(2.6)
		enemy.target = game.player
		_check(enemy.wet_time == 0.0 and _distance_matches(_travel(enemy), dry), "movement did not recover when wet expired")
		enemy.free()
	# Haste and boss overtime remain live while wet; neither gets baked into speed.
	var hasted := _enemy(WaveController.PLAQUE)
	hasted.apply_haste(0.45, 0.65)
	hasted.apply_wet(2.5)
	_check(_distance_matches(_travel(hasted), hasted.move_speed * 1.45 * 0.8 * STEP), "wet discarded elite haste")
	hasted.free()
	var boss := _enemy(WaveController.BOSS)
	boss.start_overtime()
	boss.advance_overtime(10)
	boss.apply_wet(2.5)
	_check(_distance_matches(_travel(boss), boss.move_speed * boss.overtime_speed_factor() * 0.95 * 1.25 * STEP), "wet discarded boss overtime/rage speed")
	boss.free()
	# Locked dashes keep their advertised travel/timing even when wet.
	for data in [WaveController.BACTERIA, WaveController.BOSS]:
		var charger := _enemy(data)
		charger.special_direction = Vector2.LEFT
		charger.boss_move = Enemy.BossMove.CHARGE
		charger.boss_dash_end = charger.global_position + Vector2.LEFT * 300.0
		charger._activate_special()
		var start := charger.global_position
		charger.apply_wet(2.5)
		charger._physics_process(STEP)
		_check(_distance_matches(start.distance_to(charger.global_position), data.attack_speed * STEP), "wet changed announced charge distance")
		charger.free()
	# Every existing wet source shares the slowdown, without requiring Leitlack.
	var water := WeaponCatalog.by_id(&"water_jet")
	var wet_target := _enemy(WaveController.PLAQUE)
	game.items.on_weapon_hit(wet_target, 1.0, water, false)
	_check(wet_target.wet_time == 2.5 and is_equal_approx(wet_target._movement_speed(), wet_target.move_speed * 0.8), "water weapon needs an item to slow")
	wet_target.wet_time = 0.0
	game.items.acquire(ShopController.by_id(&"rinse_valve"))
	game.items._puddle_tick(wet_target.global_position)
	_check(wet_target.wet_time > 0.0 and wet_target._movement_speed() < wet_target.move_speed, "puddle wet did not slow")
	wet_target.free()
	# Snapshot roundtrip derives slow from saved wet_time; no compounded modifier.
	for data in [WaveController.PLAQUE, WaveController.ACID_CROWN, WaveController.BOSS]:
		var enemy := _enemy(data)
		enemy.apply_wet(1.75)
	var snapshot := RunSnapshot.capture(game)
	for enemy in game.get_node("Enemies").get_children():
		enemy.free()
	game.boss = null
	RunSnapshot.restore(game, snapshot)
	paused = true
	for enemy: Enemy in game.get_node("Enemies").get_children():
		_check(is_equal_approx(enemy.wet_time, 1.75), "resume lost wet duration")
		_check(is_equal_approx(enemy._movement_speed(), enemy.move_speed * Enemy.WET_STATUS.speed_factor(enemy.data)), "resume lost or compounded wet slowdown")
	_check(water.combat_text().contains("20 % Lauftempo") and water.combat_text().contains("Bosse -5 %"), "weapon details omit wet slowdown/resistance")
	_check(WeaponPresentation.card_effect(water, 1).contains("20 % Lauftempo"), "weapon card omits slow")
	session.clear_run()
	game.free()
	paused = false
	if failures == 0:
		print("PASS wet_slow: movement, resistance, refresh/expiry, haste/overtime, charges, sources, save/resume and descriptions")
	quit(0 if failures == 0 else 1)
