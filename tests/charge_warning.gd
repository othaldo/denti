extends "res://tests/support/test_runtime.gd"

var failures := 0

func _initialize() -> void: call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_charge_warning.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.player.loadout.restore([])
	game.wave.active = false
	game.wave.current_wave = 10
	paused = true
	game.player.global_position = Vector2(1050, 650)
	# Keep the generic charge renderer covered after all four bosses migrated.
	var legacy := EnemyCatalog.CAVITY_EMPEROR.duplicate() as EnemyData
	legacy.crown_court_profile = null
	for data in [EnemyCatalog.SUGAR, legacy]:
		game._create_enemy(data, Vector2(730, 650))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_simulation_enabled(false)
		enemy.special_timer = 0
		enemy._process_special(0, Vector2.RIGHT)
		_check(enemy.special_phase == Enemy.SpecialPhase.WARNING, "charge did not begin with a warning")
		_check(is_equal_approx(enemy.charge_aim_distance, 320), "charge did not lock Denti's initial distance")
		var end := enemy.warning_lane_end()
		var start := enemy.warning_lane_start()
		var previous := -1.0
		for step in 101:
			var front := WarningEffects.charge_front(start.distance_to(end), enemy.charge_aim_distance - start.length(), step / 100.0)
			_check(front >= previous and front <= 320, "warning front overshot or travelled backwards")
			previous = front
		_check(is_equal_approx(start.x + previous, 320), "front does not reach the aimed position at activation")
		enemy._process_special(enemy.data.warning_time * 0.4, Vector2.RIGHT)
		var saved := EnemySnapshot.capture(enemy)
		game.player.global_position = Vector2(1100, 780)
		EnemySnapshot.restore(enemy, saved)
		_check(is_equal_approx(enemy.charge_aim_distance, 320) and enemy.special_direction == Vector2.RIGHT, "resume retargeted the warning")
		_check(enemy.warning_lane_end().is_equal_approx(end), "player movement dragged the attack path")
		var timer := enemy.special_timer
		await process_frame
		await process_frame
		_check(enemy.special_timer == timer, "paused charge warning continued advancing")
		enemy._process_special(timer - 0.001, Vector2.UP)
		_check(enemy.special_phase == Enemy.SpecialPhase.WARNING, "charge launched before the wavefront arrived")
		enemy._process_special(0.002, Vector2.UP)
		_check(enemy.special_phase == Enemy.SpecialPhase.ACTIVE and enemy.global_position == Vector2(730, 650), "charge failed to activate at warning completion")
		enemy._process_special(0.05, Vector2.UP)
		_check(enemy.global_position.x > 730 and enemy.global_position.y == 650, "charge did not follow its locked path")
		saved.erase("charge_aim_distance")
		EnemySnapshot.restore(enemy, saved)
		_check(enemy.charge_aim_distance == 0 and WarningEffects.charge_front(510, 0, 1) == 510, "legacy save has no safe full-path fallback")
		saved.charge_aim_distance = "invalid"
		_check(RunSaveData.normalize({"wave": 10, "player": {}, "enemies": [saved]}).is_empty(), "save accepted a nonnumeric charge target")
		enemy.free()
		game.player.global_position = Vector2(1050, 650)
	_check(WarningEffects.charge_front(100, 320, 1) == 100, "wavefront extended past a wall-clamped attack")
	session.clear_run()
	if failures == 0: print("PASS charge_warning: locked target, advancing front, activation, pause, dash/boss, resume and legacy validation")
	finish(0 if failures == 0 else 1)
