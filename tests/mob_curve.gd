extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var plaque := WaveController.PLAQUE
	var bacteria := WaveController.BACTERIA
	var sugar := WaveController.SUGAR
	var spitter := WaveController.ACID_SPITTER
	var boss := WaveController.CAVITY_KING
	for normal in [plaque, bacteria, sugar, spitter]:
		if normal.health_per_wave <= 0.0 or normal.late_health_acceleration <= 0.0:
			_fail("normal enemy lacks its own health curve: %s" % normal.display_name)
			return
	if not _check_opening_curve():
		return
	var plaque_20 := plaque.max_health * WaveController.health_multiplier(plaque, 20)
	var sugar_20 := sugar.max_health * WaveController.health_multiplier(sugar, 20)
	var spitter_20 := spitter.max_health * WaveController.health_multiplier(spitter, 20)
	if plaque_20 > 260.0 or sugar_20 < 1500.0 or spitter_20 < 600.0 or sugar_20 < plaque_20 * 6.0:
		_fail("normal enemy roles do not diverge in late waves: %.0f / %.0f / %.0f" % [plaque_20, sugar_20, spitter_20])
		return
	if spitter.trigger_range < 500.0:
		_fail("ranged enemy cannot create pressure before reaching short range")
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
	if WaveController.loot_chance(19) > 0.4 or not is_equal_approx(WaveController.loot_chance(20), WaveController.BOSS_WAVE_LOOT_CHANCE_MIN):
		_fail("denser late waves create excessive loot chances")
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_mob_curve_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	game.wave.current_wave = 1
	game._create_enemy(plaque, game.player.global_position + Vector2(300.0, 0.0))
	var opening_mob: Enemy = game.get_node("Enemies").get_child(0)
	if not is_equal_approx(opening_mob.max_health, 15.84):
		_fail("opening enemy instance did not receive reduced health")
		return
	var starter: WeaponData = WeaponCatalog.by_id(&"plaque_scaler")
	opening_mob.take_damage(starter.base_damage)
	if opening_mob.health > 0.0:
		_fail("opening plaque survives one starter scaler hit")
		return
	await process_frame
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


func _check_opening_curve() -> bool:
	for data in [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.POISON_GERM, WaveController.GUM_BITER]:
		var previous_health := 0.0
		for wave_number in range(1, 21):
			var late_waves := maxi(wave_number - 6, 0)
			var original_health: float = data.max_health + (wave_number - 1) * data.health_per_wave + late_waves * late_waves * data.late_health_acceleration
			var health: float = data.max_health * WaveController.health_multiplier(data, wave_number)
			if health < previous_health or health > original_health + 0.001:
				_fail("opening curve regressed or exceeded original health: %s, wave %d" % [data.display_name, wave_number])
				return false
			if wave_number >= 10 and not is_equal_approx(health, original_health):
				_fail("opening adjustment changed middle/late health: %s, wave %d" % [data.display_name, wave_number])
				return false
			if wave_number == 1 and not is_equal_approx(health, data.max_health * 0.40):
				_fail("opening health reduction missing: %s" % data.display_name)
				return false
			previous_health = health
	for data in [WaveController.ACID_CROWN, WaveController.HUNT_GERM, WaveController.CAVITY_COUNT]:
		for wave_number in range(1, 11):
			var step := 0.27 if data.is_boss else 0.17
			var late_waves := maxi(wave_number - 6, 0)
			var original_multiplier := 1.0 + (wave_number - 1) * step + (0.0 if data.is_boss else late_waves * late_waves * 0.018)
			if not is_equal_approx(WaveController.health_multiplier(data, wave_number), original_multiplier):
				_fail("opening adjustment changed boss/elite health")
				return false
	return true


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
