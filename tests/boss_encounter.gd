extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_boss_encounter_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.current_wave = 5
	game.player.stats.max_health = 1000.0
	game.player.stats.health = 1000.0
	var center: Vector2 = game.arena.arena_size / 2.0
	game.player.global_position = center
	game._create_enemy(WaveController.BOSS, center + Vector2(300.0, 0.0))
	var boss: Enemy = game.boss
	boss.special_timer = 0.0
	boss._physics_process(0.01)
	var announced_end := boss.boss_dash_end
	if boss.boss_move != Enemy.BossMove.CHARGE or boss.special_phase != Enemy.SpecialPhase.WARNING or announced_end.x >= boss.global_position.x or announced_end.x < DentiArena.WALL_WIDTH + boss.data.radius:
		_fail("king did not telegraph a valid charge toward Denti")
		return
	if boss.data.move_speed <= 70.0 or boss.data.attack_speed <= 450.0:
		_fail("king remained too slow to threaten Denti")
		return
	game.player.global_position += Vector2(0.0, 200.0)
	var health_before: float = game.player.stats.health
	boss._physics_process(boss.data.warning_time)
	boss._physics_process(boss.data.attack_duration)
	if game.player.stats.health != health_before or boss.global_position.distance_to(announced_end) > 1.0:
		_fail("dodging the marked lane did not avoid the locked charge")
		return

	game.player.global_position = center
	boss.global_position = center + Vector2(300.0, 0.0)
	boss.boss_charge_next = true
	boss.special_timer = 0.0
	boss._physics_process(0.01)
	boss._physics_process(boss.data.warning_time)
	if game.player.stats.health != health_before:
		_fail("charge dealt damage during its warning")
		return
	boss._physics_process(boss.data.attack_duration)
	if game.player.stats.health >= health_before:
		_fail("king charge missed Denti despite crossing the marked lane")
		return

	game.player.hurt_time = 0.0
	boss.global_position = center + Vector2(80.0, 0.0)
	boss.boss_charge_next = false
	boss.special_timer = 0.0
	boss._physics_process(0.01)
	if boss.boss_move != Enemy.BossMove.PULSE or boss.special_phase != Enemy.SpecialPhase.WARNING:
		_fail("king did not vary its attack at close range")
		return
	health_before = game.player.stats.health
	boss._physics_process(boss.data.warning_time)
	if game.player.stats.health >= health_before:
		_fail("marked pulse did not deal damage at close range")
		return

	game.player.global_position = center
	boss.global_position = center + Vector2(300.0, 0.0)
	boss.special_timer = 0.0
	boss._physics_process(0.01)
	announced_end = boss.boss_dash_end
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	boss = game.boss
	if boss == null or boss.special_phase != Enemy.SpecialPhase.WARNING or boss.boss_move != Enemy.BossMove.CHARGE or boss.boss_dash_end.distance_to(announced_end) > 1.0:
		_fail("continue lost the boss's announced charge path")
		return
	boss.boss_phase = 1
	boss.health = boss.max_health * 0.51
	boss.take_damage(30.0)
	if not boss.is_enraged or game.camera_shake_time <= 0.0:
		_fail("king did not enter its faster second phase at half health")
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
		if game.shop_panel.visible:
			break
		await process_frame
	if game.boss != null or not game.shop_panel.visible or not paused:
		_fail("shop opened before the boss death sequence finished")
		return
	paused = false
	session.clear_run()
	print("Denti boss encounter test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
