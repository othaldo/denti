extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_run_telemetry.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(100.0, 0.0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_physics_process(false)
	var weapon := WeaponCatalog.by_id(&"magic_toothbrush")
	enemy.take_damage(8.0, weapon)
	enemy.take_damage(6.0, null, false, &"chain")
	var weapon_amount: float = game.telemetry.weapon_damage.get(str(weapon.id), 0.0)
	var chain_amount: float = game.telemetry.proc_damage.get("chain", 0.0)
	if weapon_amount <= 0.0 or chain_amount <= 0.0 or absf(game.telemetry.total_damage - weapon_amount - chain_amount) > 0.01:
		_fail("weapon and proc damage attribution is incorrect")
		return
	enemy.take_damage(9999.0)
	if absf(game.telemetry.total_damage - enemy.max_health) > 0.01 or game.telemetry.kills != 1:
		_fail("overkill damage or kills were counted incorrectly")
		return
	game._on_loot_collected(&"coin", 2)
	game._on_loot_collected(&"xp", 3)
	game.player.take_hit(8.0)
	if game.telemetry.wave_spawns != 1 or game.telemetry.wave_coins < 2 or game.telemetry.wave_xp < 3 or game.telemetry.damage_taken <= 0.0:
		_fail("wave economy or incoming damage was not recorded")
		return
	var expected: Dictionary = game.telemetry.save_data()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.telemetry.kills != int(expected["kills"]) or game.telemetry.wave_spawns != int(expected["wave_spawns"]) or absf(game.telemetry.total_damage - float(expected["total_damage"])) > 0.01 or game.telemetry.weapon_damage != expected["weapon_damage"] or game.telemetry.proc_damage != expected["proc_damage"]:
		_fail("save/resume changed run telemetry")
		return
	game.hud.toggle_telemetry()
	game._refresh_hud()
	if not game.hud.telemetry_panel.visible or not game.hud.telemetry_label.text.contains("DPS 10 s"):
		_fail("debug telemetry overlay did not show combat rates")
		return
	var stats := RunTelemetry.new()
	stats.tick(2.0)
	stats.record_damage(20.0, &"test_weapon")
	stats.record_kill(false)
	stats.record_taken(4.0)
	if absf(stats.recent_dps() - 10.0) > 0.01 or absf(stats.recent_kps() - 0.5) > 0.01 or absf(stats.taken_per_minute() - 120.0) > 0.01:
		_fail("rolling combat rates are incorrect")
		return
	stats.tick(10.0)
	if stats.recent_dps() != 0.0 or stats.recent_kps() != 0.0 or stats.taken_per_minute() != 0.0 or stats.peak_dps < 10.0:
		_fail("rolling combat rates did not expire")
		return
	var lethal_stats := PlayerStats.new()
	var damage_order: Array[String] = []
	lethal_stats.damage_taken.connect(func(_amount: float) -> void: damage_order.append("damage"))
	lethal_stats.died.connect(func() -> void: damage_order.append("death"))
	lethal_stats.take_damage(200.0)
	lethal_stats.free()
	if damage_order != ["damage", "death"]:
		_fail("lethal damage was reported after death")
		return
	stats.record_spawn(true)
	stats.tick(4.0)
	stats.record_boss_death()
	if absf(stats.last_boss_ttk - 4.0) > 0.01:
		_fail("boss time-to-kill was not recorded")
		return
	var trend := RunTelemetry.new()
	trend.begin_wave(1)
	trend.tick(10.0, 8, 3)
	trend.record_damage(100.0, &"test_weapon")
	trend.record_spawn(false)
	trend.begin_wave(2)
	if trend.wave_history.size() != 1 or absf(float(trend.wave_history[0]["average_dps"]) - 10.0) > 0.01 or int(trend.wave_history[0]["peak_enemies_alive"]) != 8 or absf(float(trend.wave_history[0]["average_enemies_alive"]) - 8.0) > 0.01 or int(trend.wave_history[0]["peak_enemy_projectiles"]) != 3 or trend.recent_dps() != 0.0:
		_fail("per-wave trends or rolling-window reset are incorrect")
		return
	session.report_dir = "user://test_run_reports_%d" % Time.get_ticks_usec()
	game.player.stats.take_damage(9999.0)
	var reports := DirAccess.open(session.report_dir)
	if reports == null or reports.get_files().size() != 1 or session.has_run():
		_fail("completed run report was not saved separately from the cleared run")
		return
	var report_path: String = session.report_dir.path_join(reports.get_files()[0])
	var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(report_path))
	if not report is Dictionary or report.get("outcome") != "death" or report.get("wave_reached") != game.wave.current_wave or float(report.get("telemetry", {}).get("damage_taken", 0.0)) <= float(expected["damage_taken"]) or report.get("waves", []).size() != 1:
		_fail("completed run report lost the final damage or run metadata")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(report_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.report_dir))
	print("Denti run telemetry test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
