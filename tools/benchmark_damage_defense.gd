extends SceneTree

const REPORT_PATH := "res://docs/balance_damage_defense.json"
const BOSS_LOADOUT := [&"magic_toothbrush", &"turbo_drill", &"water_jet", &"toothpick_spear", &"prophylaxis_polisher"]
const PROFILES := [
	{"name": "Start", "wave": 1, "tier": 1, "damage_bonus": 0.0, "melee_damage": 0.0, "ranged_damage": 0.0, "attack_speed": 0.0, "crit_chance": 0.05, "armor": 0.0},
	{"name": "Welle 5", "wave": 5, "tier": 1, "damage_bonus": 12.0, "melee_damage": 4.0, "ranged_damage": 2.0, "attack_speed": 15.0, "crit_chance": 0.10, "armor": 5.0},
	{"name": "Welle 10", "wave": 10, "tier": 2, "damage_bonus": 24.0, "melee_damage": 8.0, "ranged_damage": 4.0, "attack_speed": 25.0, "crit_chance": 0.15, "armor": 10.0},
	{"name": "Welle 20", "wave": 20, "tier": 4, "damage_bonus": 40.0, "melee_damage": 12.0, "ranged_damage": 6.0, "attack_speed": 40.0, "crit_chance": 0.25, "armor": 15.0},
]


func _initialize() -> void:
	call_deferred("_run")


func _stats(profile: Dictionary) -> PlayerStats:
	var result := PlayerStats.new()
	for key in ["damage_bonus", "melee_damage", "ranged_damage", "attack_speed", "crit_chance", "armor"]:
		result.set(key, profile[key])
	return result


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var report := {"method": "fixed-fps 60; seed 13579; stationary immortal Denti; six hands; no shop items/relics; boss phases/adds enabled; theoretical DPS is single-target per hand", "profiles": PROFILES, "weapons": [], "armor": [], "bosses": []}
	for profile in PROFILES:
		var stats := _stats(profile)
		for weapon in WeaponCatalog.ALL:
			report.weapons.append({"profile": profile.name, "weapon": str(weapon.id), "family": weapon.damage_stat, "scaling": weapon.stat_scaling, "tier": profile.tier, "hit": weapon.damage_with_stats(profile.tier, stats), "dps_per_hand": weapon.estimated_dps(profile.tier, stats) / weapon.hands})
		stats.free()
	# Same number of white Bisskraft choices; attack speed and specialization are excluded.
	for choices in [1, 6, 10]:
		var stats := PlayerStats.new()
		stats.damage_bonus = float(choices) * 4.0
		var old_factor := (18.0 + float(choices) * 5.0) / 18.0
		report["damage_choices_%d" % choices] = {"old_factor": old_factor, "new_factor": stats.damage_factor()}
		stats.free()
	for armor in [0.0, 5.0, 10.0, 15.0, 30.0, -15.0]:
		var stats := PlayerStats.new()
		stats.armor = armor
		report.armor.append({"armor": armor, "new_received_10": maxf(10.0 * stats.armor_damage_factor(), 1.0), "old_received_10": maxf(10.0 - armor, 1.0), "new_received_30": maxf(30.0 * stats.armor_damage_factor(), 1.0), "old_received_30": maxf(30.0 - armor, 1.0), "effective_hp_100": 100.0 / stats.armor_damage_factor()})
		stats.free()
	var failed := false
	for profile in PROFILES.slice(1):
		var encounter: Dictionary = await _boss_encounter(profile)
		report.bosses.append(encounter)
		print("Wave %d: boss %.1fs, damage taken %.0f, alive=%s" % [profile.wave, encounter.seconds, encounter.damage_taken, encounter.boss_alive])
		if encounter.boss_alive or encounter.seconds < 8.0:
			failed = true
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write damage/defense benchmark")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	root.get_node("GameSession").clear_run()
	print("Damage/defense report: " + REPORT_PATH)
	quit(1 if failed else 0)


func _boss_encounter(profile: Dictionary) -> Dictionary:
	seed(13579)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://benchmark_damage_defense.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	paused = true
	game.wave.active = false
	game._clear_combat()
	var loadout: Array[Dictionary] = []
	for id in BOSS_LOADOUT:
		loadout.append({"id": str(id), "tier": profile.tier})
	game.player.loadout.restore(loadout)
	for key in ["damage_bonus", "melee_damage", "ranged_damage", "attack_speed", "crit_chance", "armor"]:
		game.player.stats.set(key, profile[key])
	game.player.stats.max_health = 1000000.0
	game.player.stats.health = 1000000.0
	game.wave.current_wave = profile.wave
	game.telemetry.begin_wave(profile.wave)
	game._create_enemy(WaveController.boss_for_wave(profile.wave), game.player.position + Vector2(90.0, 0.0))
	var boss: Enemy = game.boss
	var boss_hp := boss.max_health
	var frames := 0
	paused = false
	while is_instance_valid(boss) and boss.health > 0.0 and frames < 6000:
		await physics_frame
		frames += 1
	paused = true
	var result := {"wave": profile.wave, "seconds": float(frames) / 60.0, "boss_hp": boss_hp, "boss_alive": is_instance_valid(boss) and boss.health > 0.0, "damage_taken": game.telemetry.damage_taken, "phases_reached": boss.boss_phase if is_instance_valid(boss) else 2}
	game.free()
	await process_frame
	paused = false
	return result
