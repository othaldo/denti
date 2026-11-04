extends "res://tests/support/test_runtime.gd"
## A close enemy must not shrink the advertised round sweep for other targets.

var game: Node2D
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if ok: return
	failures.append(message)
	push_error(message)

func _enemy(offset: Vector2, scaled_health := false) -> Enemy:
	game._create_enemy(EnemyCatalog.BACTERIA, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	if not scaled_health:
		enemy.health = 10000
		enemy.max_health = 10000
	return enemy

func _clear() -> void:
	game.player.loadout.restore([])
	for enemy in game.get_node("Enemies").get_children(): enemy.free()

func _sweep(tier: int, direction: Vector2, density: float, element: StringName = &"", range_bonus := 0.0, fixed_steps := false) -> void:
	_clear()
	game.player.loadout.restore([{"id": "interdental_brush", "tier": tier}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	weapon.data = WeaponSkins.with_element(weapon.data, element)
	if range_bonus > 0: weapon.data = WeaponRolls.resolve(weapon.data, {}, {"range": range_bonus})
	weapon.visual_density = density
	var pose_data := WeaponMotion.pose(weapon.data, tier, weapon.home_position, direction, 0.47, 0, 35, density)
	var blade := WeaponMotion.segment(weapon.data, pose_data)
	_check(is_equal_approx(blade[1].length(), weapon.data.range_at_tier(tier)), "visible brush does not reach its advertised radius")
	var near := _enemy(direction * 35)
	var targets: Array[Enemy] = [near]
	for index in 8:
		targets.append(_enemy(direction.rotated(index * TAU / 8) * weapon.data.range_at_tier(tier)))
	var outside := _enemy(-direction * (weapon.data.range_at_tier(tier) + near.data.radius + weapon.data.attack_width + 5))
	weapon._physics_process(0.001)
	_check(targets.all(func(enemy: Enemy) -> bool: return enemy.health == 10000), "brush dealt damage before windup")
	var left := weapon.attack_duration
	while left > 0.000001:
		var step := minf(1.0 / 60, left) if fixed_steps else left
		weapon._physics_process(step)
		left -= step
	for index in targets.size():
		_check(targets[index].health < 10000, "brush missed tier %d direction %s density %.2f element %s target %d" % [tier, direction, density, element, index])
	_check(outside.health == 10000, "brush hit beyond its advertised reach")
	var health := targets.map(func(enemy: Enemy) -> float: return enemy.health)
	weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
	for index in targets.size():
		_check(targets[index].health == health[index], "brush hit twice in one sweep")

func _resume() -> void:
	_clear()
	game.wave.current_wave = 19
	game.player.loadout.restore([{"id": "interdental_brush", "tier": 4}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	for offset in [Vector2(35, 0), Vector2(-100, 0), Vector2(0, 100), Vector2(0, -100)]: _enemy(offset, true)
	weapon._physics_process(0.001)
	weapon._physics_process(weapon.attack_duration * 0.45)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	weapon._physics_process(weapon.attack_time)
	var expected: Array = game.get_node("Enemies").get_children().map(func(enemy: Enemy) -> float: return enemy.health)
	_clear()
	RunSnapshot.restore(game, saved)
	weapon = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	weapon._physics_process(weapon.attack_time)
	var actual: Array = game.get_node("Enemies").get_children().map(func(enemy: Enemy) -> float: return enemy.health)
	_check(actual.size() == expected.size(), "resumed brush lost a target")
	for index in mini(actual.size(), expected.size()):
		_check(is_equal_approx(actual[index], expected[index]), "resumed brush changed target %d: %s instead of %s" % [index, actual[index], expected[index]])

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://interdental_brush_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.stats.crit_chance = 0
	for tier in range(1, 5):
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			for density in [1.0, WeaponLayout.density_scale(6)]: _sweep(tier, direction, density)
	for element: StringName in [&"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]:
		_sweep(4, Vector2.RIGHT, WeaponLayout.density_scale(6), element)
	_sweep(4, Vector2.RIGHT, WeaponLayout.density_scale(6), &"", 50)
	_sweep(4, Vector2.LEFT, WeaponLayout.density_scale(6), &"electric", 50, true)
	_resume()
	_clear()
	session.clear_run()
	if failures.is_empty(): print("PASS interdental brush: simultaneous close/outer contacts, all directions/tiers/elements, compact builds, windup, range, one hit and JSON resume")
	finish(0 if failures.is_empty() else 1)
