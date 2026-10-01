extends SceneTree

func _initialize() -> void:
	for row in [[20, 0.0], [21, 0.02], [25, 0.30], [30, 1.10], [35, 2.40], [36, 2.992], [40, 6.30], [50, 23.25]]:
		if not is_equal_approx(EndlessRules.factor(row[0]), row[1]):
			_fail("endless factor differs at wave %d" % row[0])
			return
	for data in [WaveController.PLAQUE, WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.CAVITY_EMPEROR]:
		if not is_equal_approx(WaveController.health_multiplier(data, 30) / WaveController.health_multiplier(data, 20), 3.475) or not is_equal_approx(WaveController.enemy_damage_multiplier(data, 30) / WaveController.enemy_damage_multiplier(data, 20), 2.10):
			_fail("endless enemy stats did not use one shared baseline and factor")
			return
		if not is_equal_approx(WaveController.enemy_speed_multiplier(data, 1000) / WaveController.enemy_speed_multiplier(data, 20), 2.75) or WaveController.damage_reduction(data, 1000) != WaveController.damage_reduction(data, 20):
			_fail("endless movement or defense grows beyond its bound")
			return
	if EconomyRules.shop_price(9, 20) != 47 or EconomyRules.shop_price(9, 30) != 80 or EconomyRules.shop_price(9, 40) != 192 or EconomyRules.gold_drop_factor(34) != 0.5:
		_fail("endless shop inflation or gold floor differs")
		return
	if EndlessRules.shop_reroll_start(40) != 5 or EndlessRules.shop_reroll_step(40) != 3 or EndlessRules.density_factor(1000) != 2.0:
		_fail("endless rerolls or spawn-pressure limit differs")
		return
	var wave := WaveController.new()
	wave.current_wave = 20
	wave.start_next_wave()
	if wave.current_wave != 20 or wave.active:
		_fail("normal run entered endless without opting in")
		return
	wave.endless_enabled = true
	var bosses: Array[EnemyData] = []
	wave.boss_requested.connect(func(data: EnemyData) -> void: bosses.append(data))
	for number in [21, 25, 30, 40, 100]:
		wave.current_wave = number - 1
		wave.start_next_wave()
		if wave.current_wave != number or wave.duration != 60.0 or bosses.size() != (2 if number % 10 == 0 else (1 if number % 5 == 0 else 0)):
			_fail("endless wave duration or boss schedule differs at %d" % number)
			return
		if number % 5 != 0 and wave.current_profile_id == &"":
			_fail("endless normal waves lost their enemy profiles")
			return
		for count in wave.elite_counts:
			if count > EndlessRules.MAX_ELITE_GROUP or count < 1:
				_fail("endless elites escaped their performance bound")
				return
		bosses.clear()
	wave.free()
	print("Denti endless rules test passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
