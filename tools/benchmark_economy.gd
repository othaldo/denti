extends SceneTree

const PROFILES := [
	{"wave": 1, "tier": 1, "damage": 0.0, "melee": 0.0, "ranged": 0.0, "speed": 0.0, "weapons": ["magic_toothbrush"]},
	{"wave": 4, "tier": 1, "damage": 12.0, "melee": 4.0, "ranged": 2.0, "speed": 15.0, "weapons": ["magic_toothbrush", "turbo_drill", "water_jet"]},
	{"wave": 10, "tier": 2, "damage": 24.0, "melee": 8.0, "ranged": 4.0, "speed": 25.0, "weapons": ["magic_toothbrush", "turbo_drill", "water_jet", "toothpick_spear", "prophylaxis_polisher"]},
	{"wave": 19, "tier": 4, "damage": 40.0, "melee": 12.0, "ranged": 6.0, "speed": 40.0, "weapons": ["magic_toothbrush", "turbo_drill", "water_jet", "toothpick_spear", "prophylaxis_polisher"]},
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var samples: Array[Dictionary] = []
	for profile in PROFILES:
		for sample_seed in [13579, 24680, 112233]:
			var sample := await _sample(profile, sample_seed)
			samples.append(sample)
			print("Wave %d seed %d: %d kills / %d spawns; %d gold; %.0f damage taken" % [profile.wave, sample_seed, sample.kills, sample.spawns, sample.gold_earned, sample.damage_taken])
	var report := {"method": "Actual combat, Normal, 1280x720, fixed 60 Hz, three seeds per profile. Immortal player moved on a scripted ellipse, without items or shop purchases. Configured builds are benchmarks, not proven obtainable runs. Includes drops collected and coin/XP remaining on the floor at timer end. Boss wave 10 includes boss pressure; encounter stops at normal wave timer, so this is not a full boss-TTK benchmark.", "profiles": PROFILES, "samples": samples}
	var file := FileAccess.open("res://docs/economy_combat_benchmark.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	root.get_node("GameSession").clear_run()
	quit(0)

func _sample(profile: Dictionary, sample_seed: int) -> Dictionary:
	seed(sample_seed)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://benchmark_economy.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	game.player.stats.max_health = 1000000.0
	game.player.stats.health = 1000000.0
	game.player.stats.damage_bonus = profile.damage
	game.player.stats.melee_damage = profile.melee
	game.player.stats.ranged_damage = profile.ranged
	game.player.stats.attack_speed = profile.speed
	var equipment: Array[Dictionary] = []
	for id in profile.weapons:
		equipment.append({"id": id, "tier": profile.tier})
	game.player.loadout.restore(equipment)
	game.wave.current_wave = profile.wave - 1
	game.coins = 0
	game.telemetry = RunTelemetry.new()
	game.telemetry.begin_wave(profile.wave)
	game.rewards.begin_wave()
	game.wave.start_next_wave()
	var frame := 0
	paused = false
	while game.wave.active and frame < 3600:
		var phase := float(frame) / 60.0 * 0.7
		game.player.position = game.arena.arena_size / 2.0 + Vector2(cos(phase) * 210.0, sin(phase) * 130.0)
		await physics_frame
		frame += 1
	paused = true
	var gold: int = game.coins
	var experience: int = game.telemetry.xp_collected
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.is_queued_for_deletion():
			continue
		if drop.kind == &"coin":
			gold += drop.amount
		elif drop.kind == &"xp":
			experience += drop.amount
	var summary: Dictionary = game.telemetry.current_wave_summary()
	summary["seed"] = sample_seed
	summary["gold_earned"] = gold
	summary["xp_earned"] = experience
	summary["brush_i_price"] = EconomyRules.shop_price(9, profile.wave)
	summary["brush_iv_price"] = EconomyRules.shop_price(30, profile.wave)
	game.free()
	await process_frame
	paused = false
	return summary
