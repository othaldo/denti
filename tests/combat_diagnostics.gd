extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://diagnostics_protected.json"
	session.test_save_path = "user://diagnostics_temporary.json"
	session.settings_path = "user://diagnostics_settings.cfg"
	session.code_entry_unlocked = true
	session.selected_story_mode = false
	session.selected_difficulty_id = &"normal"
	session.save_run({"version": 1, "coins": 39})
	var original := FileAccess.get_file_as_string(session.save_path)
	var original_graphics: int = session.graphics_mode
	var base := TestArenaCatalog.by_code("debug map")
	var quantiles := TestArena.new()
	quantiles.frame_histogram.resize(2048)
	quantiles.frame_histogram[16] = 95
	quantiles.frame_histogram[50] = 5
	quantiles.histogram_count = 100
	check(quantiles.percentile(0.95) == 17.0 and quantiles.percentile(0.99) == 51.0, "frame histogram percentiles ignore slow tail frames")
	quantiles.free()
	for code: String in TestArenaCatalog.DIAGNOSTICS:
		var preset := TestArenaCatalog.by_code("  " + code.to_upper() + "  ")
		check(preset != null and preset.enemies == base.enemies and preset.weapons == base.weapons and preset.items == base.items and preset.enemy_count == base.enemy_count and preset.loot_count == base.loot_count and preset.random_seed == base.random_seed, "diagnosis preset changed the comparison workload")
		check(base.diagnostic == TestArenaData.Diagnostic.NONE and TestArenaCatalog.by_id(preset.id).code == code, "diagnostic lookup modified the normal preset")
		check(session.begin_test_run(preset.id), "diagnostic entry is rejected")
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		var arena: TestArena = game.get_node("TestArena")
		var profile: CombatDiagnostics = game.get_node("CombatDiagnostics")
		check(CombatDiagnostics.current == profile and game.get_node("Enemies").get_child_count() == 110 and game.player.loadout.equipped().size() == 3, "diagnostic game did not create the full comparison arena")
		var enemy: Enemy = game.get_node("Enemies").get_child(0)
		var weapon: WeaponInstance = game.player.loadout.equipped()[0]
		check(enemy.get_script().resource_path.ends_with("profiled_enemy.gd") and weapon.get_script().resource_path.ends_with("profiled_weapon.gd"), "combat timing wrappers are not installed before configure/ready")
		game._show_damage_number(Vector2.ZERO, 8)
		check(game.get_node("DamageNumbers").visible == (preset.diagnostic not in [TestArenaData.Diagnostic.NO_TEXT, TestArenaData.Diagnostic.NO_DRAW]), "text comparison does not hide only rendering")
		check(game.get_node("DamageNumbers").get_child_count() == 1, "rendering comparison removed text simulation")
		var prior_health := enemy.health
		enemy.take_damage(10.0, weapon.data)
		check((enemy.health == prior_health) == (preset.diagnostic == TestArenaData.Diagnostic.NO_HITS), "damage comparison failed to isolate enemy hit consequences")
		check(weapon.is_physics_processing() == (preset.diagnostic != TestArenaData.Diagnostic.NO_WEAPONS), "weapon comparison did not disable attack callbacks")
		check(weapon.evolution.is_physics_processing() == (preset.diagnostic != TestArenaData.Diagnostic.NO_WEAPONS), "disabled weapon still advances evolution attacks")
		check(game.get_node("Enemies").visible == (preset.diagnostic != TestArenaData.Diagnostic.NO_DRAW) and enemy.is_physics_processing(), "simulation-only comparison changed enemy physics callbacks")
		for frame in 35:
			await physics_frame
		check(profile.sampled_us.has(&"enemy_physics") and profile.calls[&"enemy_physics"] >= 110, "enemy timings do not aggregate sampled callbacks")
		check(profile.sampled_us.has(&"loot") and profile.sampled_us.has(&"effects"), "loot/item timing categories are missing")
		if preset.diagnostic != TestArenaData.Diagnostic.NO_WEAPONS:
			check(profile.sampled_us.has(&"weapons") and game.get_node("Projectiles").get_child_count() > 0, "weapon timings or real player shots are missing")
			for shot: WeaponProjectile in game.get_node("Projectiles").get_children():
				check(shot.get_script().resource_path.ends_with("profiled_player_projectile.gd"), "new player shots bypass timing")
		EnemyProjectilePatterns.fire_aimed_fan(game.get_node("EnemyProjectiles"), Vector2.ZERO, Vector2.RIGHT, 3, 30, 1, null)
		check(game.get_node("EnemyProjectiles").get_child(-1).get_script().resource_path.ends_with("profiled_enemy_projectile.gd"), "pooled enemy shots bypass timing")
		game._save_run()
		check(profile.save_ms > 0.0 and FileAccess.get_file_as_string("user://diagnostics_protected.json") == original, "diagnostic save timing changed the normal save")
		var report: Dictionary = JSON.parse_string(arena.report_text())
		check(report.code == code and report.cpu_estimated_ms_per_frame.has("enemy_physics") and report.enemies == 110 and arena.copy_button != null, "copyable report lacks the selected mode or measurements")
		arena._notification(Node.NOTIFICATION_PAUSED)
		check(profile.sampled_us.is_empty() and profile.save_ms == 0.0 and arena.histogram_count == 0 and arena.latest_fps == 0.0, "pause kept old timing samples")
		game.free()
		check(CombatDiagnostics.current == null, "diagnostic exit leaked global instrumentation")
		session.end_test_run()
		check(session.graphics_mode == original_graphics, "diagnostics changed persistent graphics settings")
	var normal: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(normal)
	current_scene = normal
	normal.choice_panel._on_choice_pressed(0)
	normal._create_enemy(WaveController.PLAQUE, Vector2.ZERO)
	check(not normal.has_node("CombatDiagnostics") and normal.get_node("Enemies").get_child(-1).get_script().resource_path == "res://scripts/enemies/enemy.gd" and normal.player.loadout.equipped()[0].get_script().resource_path == "res://scripts/weapons/weapon_instance.gd", "normal combat retained timing wrappers")
	session.clear_run()
	normal.free()
	paused = false
	if failures.is_empty():
		print("Denti combat diagnostics and isolation test passed")
	quit(0 if failures.is_empty() else 1)
