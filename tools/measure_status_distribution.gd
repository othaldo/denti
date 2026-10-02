extends SceneTree

const SAMPLES := 10000

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rows := ["difficulty,wave,traits_percent,poison_traits,bleed_traits,specialist_percent,poison_tick,poison_duration,bleed_tick,bleed_duration"]
	for difficulty in DifficultyCatalog.ALL:
		for number in [4, 6, 8, 12, 20, 40, 100]:
			var rng := RandomNumberGenerator.new()
			var poison := 0
			var bleed := 0
			for index in SAMPLES:
				rng.seed = index + 9800
				var attacks := EnemyStatusRules.attacks_for(WaveController.PLAQUE, number, difficulty, rng)
				if not attacks.is_empty():
					poison += int(attacks[0]["kind"] == DentiStatus.Type.POISON)
					bleed += int(attacks[0]["kind"] == DentiStatus.Type.BLEED)
			var wave := WaveController.new()
			wave.current_wave = number
			wave.difficulty_id = difficulty.id
			wave.duration = 60.0
			wave.remaining = 30.0
			seed(7429)
			var specialists := 0
			for index in SAMPLES:
				var data := wave._choose_enemy()
				specialists += int(data == WaveController.POISON_GERM or data == WaveController.GUM_BITER)
			wave.free()
			var poison_data := EnemyStatusRules.attacks_for(WaveController.POISON_GERM, number, difficulty)[0]
			var bleed_data := EnemyStatusRules.attacks_for(WaveController.GUM_BITER, number, difficulty)[0]
			rows.append("%s,%d,%.2f,%d,%d,%.2f,%.3f,%.2f,%.3f,%.2f" % [difficulty.id, number, 100.0 * (poison + bleed) / SAMPLES, poison, bleed, 100.0 * specialists / SAMPLES, poison_data["damage"], poison_data["duration"], bleed_data["damage"], bleed_data["duration"]])
	var file := FileAccess.open("res://docs/status_distribution.csv", FileAccess.WRITE)
	file.store_string("\n".join(rows) + "\n")
	file.close()
	print("Measured traits and actual spawn mix: 28 cases, 10,000 draws each.")
	quit()
