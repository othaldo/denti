extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_boss_pressure_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.player.loadout.sell(0)
	game.player.stats.max_health = 10000.0
	game.player.stats.health = 10000.0
	game.wave.active = false
	game.wave.current_wave = 15
	game.telemetry.begin_wave(15)
	game._create_enemy(WaveController.BOSS, game.player.global_position + Vector2(300.0, 0.0))
	var boss: Enemy = game.boss
	boss.set_physics_process(false)
	var max_health := boss.max_health
	boss.take_damage(99999.0)
	if boss.dying or boss.boss_phase != 0 or boss.health < max_health * 0.89:
		_fail("one huge hit bypassed the visible boss guard")
		return
	var radial := EnemyProjectilePatterns.radial_directions(12, 0.0)
	if WaveController.CAVITY_COUNT.boss_radial_volley_count != 1 or WaveController.CAVITY_PRINCE.boss_radial_volley_count != 3 or WaveController.CAVITY_KING.boss_radial_volley_count != 5 or WaveController.CAVITY_EMPEROR.boss_radial_volley_count != 9:
		_fail("boss projectile salvos do not escalate 1/3/5/9")
		return
	if radial.size() < 8 or radial.size() >= 12:
		_fail("radial pattern has no readable safe gap")
		return
	for ray in radial:
		if ray.angle_to(Vector2.RIGHT) > -0.1 and ray.angle_to(Vector2.RIGHT) < 0.1:
			_fail("radial pattern fired into its safe gap")
			return
	var seconds := 0.0
	var phase_saved := false
	for step in 350:
		game.telemetry.tick(0.1)
		boss._physics_process(0.1)
		boss.take_damage(99999.0)
		seconds += 0.1
		if boss.boss_phase == 1 and boss.boss_phase_burst_fired and not phase_saved:
			var projectile_count: int = game.get_node("EnemyProjectiles").get_child_count()
			if projectile_count < 8 or game.get_node("Enemies").get_child_count() < 6:
				_fail("boss phase lacked telegraphed projectiles or reinforcements")
				return
			var projectile: AcidProjectile = game.get_node("EnemyProjectiles").get_child(-1)
			if projectile.projectile_color.r < 0.9 or projectile.projectile_color.b < 0.5:
				_fail("boss projectiles are not visually distinct")
				return
			var phase_time: float = boss.boss_phase_timer
			game._save_run()
			session.resume_requested = true
			paused = false
			change_scene_to_file("res://scenes/game/game.tscn")
			await process_frame
			await process_frame
			game = current_scene
			boss = game.boss
			if boss == null or boss.boss_phase != 1 or not boss.boss_phase_burst_fired or absf(boss.boss_phase_timer - phase_time) > 0.1 or game.get_node("EnemyProjectiles").get_child_count() == 0:
				_fail("save/resume lost the boss phase or its projectiles")
				return
			boss.set_physics_process(false)
			phase_saved = true
		if boss.dying:
			break
	if not phase_saved or not boss.dying or seconds < 17.5 or seconds > 30.0 or boss.boss_phase != 2 or game.telemetry.last_boss_ttk < 17.5:
		_fail("strong build still deleted the king or boss phases stalled: %.1fs, phase %d" % [seconds, boss.boss_phase])
		return
	var king_seconds := seconds
	game._clear_combat()
	await process_frame
	game.wave.current_wave = 20
	game.telemetry.begin_wave(20)
	game._create_enemy(WaveController.FINAL_BOSS, game.player.global_position + Vector2(300.0, 0.0))
	boss = game.boss
	boss.set_physics_process(false)
	seconds = 0.0
	for step in 650:
		game.telemetry.tick(0.1)
		boss._physics_process(0.1)
		boss.take_damage(99999.0)
		seconds += 0.1
		if boss.dying:
			break
	if not boss.dying or seconds < 44.0 or seconds > 62.0 or boss.boss_phase != 2 or boss.boss_radial_volley_index != 9:
		_fail("strong build skipped the final boss encounter: %.1fs, phase %d" % [seconds, boss.boss_phase])
		return
	session.clear_run()
	print("Denti boss pressure test passed; king %.1fs, emperor %.1fs" % [king_seconds, seconds])
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
