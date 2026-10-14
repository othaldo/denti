extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Previous spawn totals at 60 Hz, with the same fixed horde waves. These are
	# normal stream/burst requests, excluding elite groups and their escorts.
	for sample in [[1, 44], [4, 80], [8, 116], [12, 199], [19, 255], [20, 188]]:
		seed(9231)
		var wave := WaveController.new()
		var counts := {"total": 0}
		wave.enemy_requested.connect(func(_data: EnemyData) -> void: counts.total += 1)
		wave.horde_requested.connect(func(_data: EnemyData, count: int) -> void: counts.total += count)
		wave.current_wave = int(sample[0]) - 1
		wave.horde_waves.assign([4, 8, 12, 17])
		wave.start_next_wave()
		for frame in ceili(wave.duration * 60):
			wave._process(1.0 / 60.0)
		var ratio := float(counts.total) / float(sample[1])
		if wave.is_boss_wave(wave.current_wave):
			assert(ratio > 1.05 and ratio < 1.13, "boss support pressure increased too little or too much")
		else:
			assert(ratio > 1.12 and ratio < 1.28, "normal waves lack the intended moderate density increase")
			var loot_ratio := ratio * ChestRewards.drop_chance(0) / 0.02
			assert(loot_ratio > 0.90 and loot_ratio < 1.05, "extra density causes a chest drought or snowball")
		print("Wave %d: %d -> %d stream/burst enemies" % [sample[0], sample[1], counts.total])
		wave.free()
	for sample in [[WaveController.PLAQUE, 36, 6, 0.3], [WaveController.BACTERIA, 25, 4.5, 0.6], [WaveController.SUGAR, 100, 20, 6], [WaveController.ACID_SPITTER, 40, 8, 2.2], [WaveController.POISON_GERM, 45, 8.2, 1.7], [WaveController.GUM_BITER, 30, 7, 1.2]]:
		var data: EnemyData = sample[0]
		for number in [1, 8, 12, 20]:
			var late := maxi(number - 6, 0)
			var previous: float = float(sample[1]) + (number - 1) * float(sample[2]) + late * late * float(sample[3])
			if number < 10:
				previous *= lerpf(0.35, 1.0, smoothstep(0.0, 1.0, float(number - 1) / 9.0))
			var actual := data.max_health * WaveController.health_multiplier(data, number)
			assert(actual > previous * 1.15 and actual < previous * 1.30, "HP compensation is missing or makes enemies sponges")
	assert(is_equal_approx(ChestRewards.drop_chance(100), 0.04))
	print("PASS affix compensation: HP, density and bounded chest economy")
	quit(0)
