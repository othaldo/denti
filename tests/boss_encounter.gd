extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_boss_encounter_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.current_wave = 5
	game.player.stats.max_health = 1000.0
	game.player.stats.health = 1000.0
	var center: Vector2 = game.arena.arena_size / 2.0
	game.player.global_position = center
	# The real court encounter must survive a reload before milestone rewards.
	game._create_enemy(WaveController.CAVITY_EMPEROR, center + Vector2(300, 0))
	var boss: Enemy = game.boss
	boss.crown_court_encounter.begin(CrownCourtEncounter.Attack.PORTAL)
	var announced_end := boss.crown_court_encounter.portal_b
	boss.crown_court_encounter.advance(0.3)
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	boss = game.boss
	if boss == null or boss.crown_court_encounter.state != CrownCourtEncounter.State.PORTAL_WARN or boss.crown_court_encounter.portal_b.distance_to(announced_end) > 1:
		_fail("continue lost the Emperor's announced portal path")
		return
	boss.boss_phase = 1
	boss.health = boss.max_health * 0.51
	boss.boss_damage_budget = boss.max_health
	boss.take_damage(boss.max_health * 0.06)
	if not boss.is_enraged or game.camera_shake_time <= 0.0:
		_fail("emperor did not enter its faster second phase at half health")
		return
	game.wave.active = false
	game.boss_pending = true
	boss.boss_phase = 2
	boss.boss_phase_timer = 0.0
	boss.boss_damage_budget = boss.health
	boss.take_damage(99999.0)
	if not boss.dying or game.boss == null or game.camera_shake_time <= 0.0 or boss.is_in_group("enemies"):
		_fail("lethal hit did not start the boss death sequence")
		return
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	boss = game.boss
	if boss == null or not boss.dying or boss.health != 0.0 or game.shop_panel.visible:
		_fail("continue lost the boss death animation")
		return
	for frame in 120:
		if game.choice_panel.visible:
			break
		await process_frame
	if game.boss != null or game.choice_panel.mode != &"relic" or not paused or game.shop_panel.visible:
		_fail("relic choice did not follow the boss death sequence")
		return
	choose_panel(game.choice_panel, 0)
	if not game.shop_panel.visible:
		_fail("shop did not follow the boss relic choice")
		return
	paused = false
	session.clear_run()
	print("Denti boss encounter test passed")
	finish(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	finish(1)
