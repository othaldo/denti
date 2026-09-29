extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var plaque := WaveController.PLAQUE
	var boss := WaveController.CAVITY_KING
	if not is_equal_approx(WaveController.health_multiplier(plaque, 6), 1.0 + 5.0 * WaveController.MOB_HEALTH_WAVE_STEP):
		_fail("early-wave mob health changed")
		return
	if WaveController.health_multiplier(plaque, 12) < 3.5 or WaveController.health_multiplier(plaque, 20) < 7.5:
		_fail("late-wave mob health curve is too flat")
		return
	if WaveController.enemy_speed_multiplier(plaque, 12) < 1.35 or WaveController.enemy_damage_multiplier(plaque, 12) < 1.8:
		_fail("mid-run mobs still cannot create movement or damage pressure")
		return
	if WaveController.damage_reduction(plaque, 20) > WaveController.MAX_DAMAGE_REDUCTION:
		_fail("late-wave defense escaped its cap")
		return
	if not is_equal_approx(WaveController.health_multiplier(boss, 15), 1.0 + 14.0 * WaveController.BOSS_HEALTH_WAVE_STEP) or not is_equal_approx(WaveController.enemy_speed_multiplier(boss, 15), 1.0 + 14.0 * WaveController.ENEMY_SPEED_WAVE_STEP):
		_fail("mob curve changed boss scaling")
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_mob_curve_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	game.wave.current_wave = 12
	game._create_enemy(plaque, game.player.global_position + Vector2(350.0, 0.0))
	var mob: Enemy = game.get_node("Enemies").get_child(0)
	if not is_equal_approx(mob.max_health, plaque.max_health * WaveController.health_multiplier(plaque, 12)) or not is_equal_approx(mob.move_speed, plaque.move_speed * WaveController.enemy_speed_multiplier(plaque, 12)):
		_fail("enemy instance did not use the new curve")
		return
	game._create_enemy(WaveController.ACID_CROWN, game.player.global_position + Vector2(450.0, 0.0))
	var elite: Enemy = game.get_node("Enemies").get_child(1)
	var before := elite.health
	elite.take_damage(elite.max_health * 100.0)
	if elite.health <= 0.0 or before - elite.health > elite.max_health * elite.data.elite_guard_fraction + 0.01:
		_fail("late elite died to one hit")
		return
	session.clear_run()
	print("Denti mob curve test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
