extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_boss_overtime.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.wave.current_wave = 5
	game.player.loadout.restore([])
	game._create_enemy(WaveController.boss_for_wave(5), game.player.global_position + Vector2(500, 0))
	var boss: Enemy = game.boss
	boss.set_physics_process(false)
	var base_damage := boss.attack_damage
	var base_health := boss.max_health
	boss.health *= 0.6
	var fraction := boss.health / boss.max_health
	boss._tick_overtime(10)
	if boss.overtime_seconds != 0 or boss.attack_damage != base_damage:
		_fail("boss grew before timeout")
		return
	if boss.inflammation_aura == null or boss.inflammation_aura.visible:
		_fail("inflammation aura appeared before timeout or was not configured")
		return
	game._on_wave_finished(5)
	if not boss.overtime_active or not boss.is_enraged or not game.boss_pending or paused or game.shop_panel.visible or game.choice_panel.visible:
		_fail("timeout failed to start uninterrupted enrage")
		return
	if not boss.inflammation_aura.visible or not boss.inflammation_aura.is_playing():
		_fail("timeout did not start the animated inflammation aura")
		return
	boss._tick_overtime(0.99)
	if boss.overtime_seconds != 0:
		_fail("enrage increased before a full second")
		return
	boss._tick_overtime(0.01)
	boss._tick_overtime(9.25)
	if boss.overtime_seconds != 10 or not is_equal_approx(boss.attack_damage, base_damage * 1.5) or not is_equal_approx(boss.max_health, base_health * 1.2) or not is_equal_approx(boss.health / boss.max_health, fraction):
		_fail("per-second enrage scaling or health fraction is wrong")
		return
	if not is_equal_approx(boss.overtime_defense_factor(), 1.5) or not is_equal_approx(boss.overtime_speed_factor(), 1.3) or not is_equal_approx(boss.overtime_attack_factor(), 1.4):
		_fail("defense, movement or attack tempo failed to grow")
		return
	boss.boss_phase = 2
	boss.boss_phase_timer = 0
	boss.boss_damage_budget = boss.max_health
	var before := boss.health
	boss.take_damage(100)
	if not is_equal_approx(before - boss.health, 100 * (1 - boss.damage_reduction) / 1.5):
		_fail("enrage defense does not reduce actual hits")
		return
	boss.start_overtime()
	if boss.overtime_seconds != 10:
		_fail("restarting enrage reset its escalation")
		return
	boss.special_phase = Enemy.SpecialPhase.WARNING
	boss.special_timer = boss.data.warning_time
	boss._process_special(0.1, Vector2.RIGHT)
	if not is_equal_approx(boss.special_timer, boss.data.warning_time - 0.1):
		_fail("enrage shortened the readable warning")
		return
	game._refresh_hud()
	if not game.hud.timer_label.text.contains("ENTZÜNDET +10s"):
		_fail("HUD does not show overtime escalation")
		return
	var damage_saved := boss.attack_damage
	var health_saved := boss.health
	game._save_run()
	session.resume_requested = true
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	boss = game.boss
	boss.set_physics_process(false)
	if not game.boss_pending or not boss.overtime_active or boss.overtime_seconds != 10 or not is_equal_approx(boss.attack_damage, damage_saved) or not is_equal_approx(boss.health, health_saved):
		_fail("save/resume lost or doubled overtime bonuses")
		return
	if not boss.inflammation_aura.visible or not boss.inflammation_aura.is_playing() or boss.inflammation_aura.modulate.r != boss.data.inflammation_color.r:
		_fail("save/resume lost the boss inflammation aura")
		return
	boss._tick_overtime(0.75)
	if boss.overtime_seconds != 11:
		_fail("save/resume lost partial enrage seconds")
		return
	boss.boss_phase = 2
	boss.boss_phase_timer = 0
	boss.boss_damage_budget = boss.max_health
	boss.take_damage(1e9)
	var final_seconds := boss.overtime_seconds
	boss._tick_overtime(30)
	if not boss.dying or boss.overtime_seconds != final_seconds:
		_fail("dead boss continued escalating")
		return
	boss._process(Enemy.BOSS_DEATH_DURATION)
	await process_frame
	for frame in 150:
		if game.choice_panel.visible or game.shop_panel.visible:
			break
		await process_frame
	if game.boss_pending or not (game.choice_panel.visible or game.shop_panel.visible):
		_fail("enraged boss death did not resume post-wave rewards")
		return
	paused = false
	session.clear_run()
	print("Denti boss overtime test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
