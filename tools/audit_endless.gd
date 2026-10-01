extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://audit_endless.json"
	session.report_dir = "user://audit_endless_reports"
	session.resume_requested = false
	root.size = Vector2i(1280, 720)
	var rows: Array[Dictionary] = []
	for number in [21, 25, 30, 35, 40, 50]:
		rows.append({"wave": number, "factor": EndlessRules.factor(number), "hp_factor": EndlessRules.health_factor(number), "damage_factor": EndlessRules.damage_factor(number), "speed_factor": EndlessRules.speed_factor(number), "density_factor": EndlessRules.density_factor(number), "brush_i_price": EconomyRules.shop_price(9, number), "gold_chance": EconomyRules.gold_drop_factor(number), "reroll_start": EndlessRules.shop_reroll_start(number), "reroll_step": EndlessRules.shop_reroll_step(number)})
	var samples: Array[Dictionary] = []
	for number in [21, 30, 40]:
		for sample_seed in [13579, 24680, 112233]:
			var sample := await _sample(number, sample_seed)
			samples.append(sample)
			print("Endless wave %d seed %d: %d spawns / %d kills; %.0f damage taken; peak %d enemies / %d projectiles" % [number, sample_seed, sample.spawns, sample.kills, sample.damage_taken, sample.peak_enemies_alive, sample.peak_enemy_projectiles])
	var file := FileAccess.open("res://docs/endless_audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"method": "Normal, 1280x720, fixed 60 Hz. Three seeded actual combat samples each at waves 21/30/40. Immortal player on a scripted ellipse; configured tier-IV build, no items or shop purchases. This is an instrumentation sample, not a reachable shopping history or a survival claim. Boss samples stop at the 60-second timer, before overtime. Enemy density is bounded by the existing 110 cap.", "scaling": rows, "samples": samples}, "\t") + "\n")
	file.close()
	session.clear_run()
	quit(0)

func _sample(number: int, sample_seed: int) -> Dictionary:
	root.get_node("GameSession").clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	seed(sample_seed)
	game.player.stats.max_health = 1000000.0
	game.player.stats.health = 1000000.0
	game.player.stats.damage_bonus = 60.0
	game.player.stats.melee_damage = 16.0
	game.player.stats.ranged_damage = 10.0
	game.player.stats.attack_speed = 60.0
	game.player.stats.armor = 12.0
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}, {"id": "turbo_drill", "tier": 4}, {"id": "water_jet", "tier": 4}, {"id": "toothpick_spear", "tier": 4}, {"id": "prophylaxis_polisher", "tier": 4}])
	game.wave.endless_enabled = true
	game.base_victory = true
	game.wave.current_wave = number - 1
	game.player.stats.damage_taken.disconnect(game.telemetry.record_taken)
	game.telemetry = RunTelemetry.new()
	game.player.stats.damage_taken.connect(game.telemetry.record_taken)
	game.telemetry.begin_wave(number)
	game.rewards.begin_wave()
	game.wave.start_next_wave()
	paused = false
	var frame := 0
	while game.wave.active and frame < 3610:
		var phase := float(frame) / 60.0 * 0.7
		game.player.position = game.arena.arena_size / 2.0 + Vector2(cos(phase) * 210.0, sin(phase) * 130.0)
		await physics_frame
		frame += 1
	paused = true
	var sample: Dictionary = game.telemetry.current_wave_summary()
	sample["seed"] = sample_seed
	game.free()
	await process_frame
	paused = false
	return sample
