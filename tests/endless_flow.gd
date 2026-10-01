extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_endless_flow.json"
	session.report_dir = "user://test_endless_reports"
	session.resume_requested = false
	session.clear_run()
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	var game: Node2D = current_scene
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.wave.current_wave = 20
	game._clear_arena(false)
	await process_frame
	game.coins = 100
	game.items.acquire(ShopController.by_id(&"gold_probe"))
	game._award_xp(5)
	game.rewards.queue_chest(&"metal_crown", 4)
	game._on_wave_finished(20)
	if game.ended or game.choice_panel.mode != &"upgrade":
		_fail("victory skipped pending levels")
		return
	game.choice_panel.buttons[0].pressed.emit()
	if game.choice_panel.mode != &"chest" or game.ended:
		_fail("victory skipped pending chest rewards")
		return
	game.choice_panel.buttons[0].pressed.emit()
	if not game.ended or not game.base_victory or not game.choice_panel.buttons[3].visible or session.has_run():
		_fail("normal victory did not offer an optional endless continuation")
		return
	var stats_before: Dictionary = game.player.stats.to_save_data()
	var weapons_before: Array[Dictionary] = game.player.loadout.save_data()
	game.choice_panel.buttons[3].pressed.emit()
	if game.ended or not game.wave.endless_enabled or not game.in_shop or game.coins != 100 or game.wave.current_wave != 20 or game.player.stats.to_save_data() != stats_before or game.player.loadout.save_data() != weapons_before:
		_fail("entering endless changed the completed build or skipped the wave 20 shop")
		return
	game._on_shop_continue()
	if not game.wave.active or game.wave.current_wave != 21 or game.wave.duration != 60.0 or game.rewards.pending_levels != 0:
		_fail("endless did not start at wave 21 with a fresh reward queue")
		return
	game._save_run()
	game = await _resume(session)
	if game.wave.current_wave != 21 or not game.wave.endless_enabled or not game.base_victory or game.items.count(&"gold_probe") != 1:
		_fail("resume clamped the endless wave to 20 or lost the build/victory")
		return
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	game.wave.current_wave = 29
	game.rewards.begin_wave()
	game.telemetry.begin_wave(30)
	game.wave.start_next_wave()
	var bosses := BossEncounter.remaining(game.get_node("Enemies"))
	if bosses.size() != 2:
		_fail("wave 30 did not spawn a double boss")
		return
	game.wave.active = false
	game._on_wave_finished(30)
	game._spawn_loot(game.player.global_position + Vector2(400, 0), &"coin", 7)
	for member in bosses:
		if not member.overtime_active:
			_fail("only one boss became inflamed at the wave timeout")
			return
		member._tick_overtime(3.0)
	game._save_run()
	game = await _resume(session)
	bosses = BossEncounter.remaining(game.get_node("Enemies"))
	if bosses.size() != 2 or not game.boss_pending or bosses[0].overtime_seconds != 3 or bosses[1].overtime_seconds != 3:
		_fail("resume lost a boss or one boss's inflammation")
		return
	_kill_boss(bosses[0])
	await process_frame
	if not game.boss_pending or game.choice_panel.visible or game.shop_panel.visible or BossEncounter.remaining(game.get_node("Enemies")).size() != 1 or game.telemetry.last_boss_ttk != 0.0:
		_fail("first boss death ended the double encounter")
		return
	_kill_boss(bosses[1])
	for frame in 180:
		await physics_frame
		if game.choice_panel.visible or game.shop_panel.visible:
			break
	if game.boss_pending or game.ended or game.coins != 107 or game.rewards.step != PostWaveRewards.Step.RELICS:
		_fail("second boss did not collect loot before the milestone reward")
		return
	game.choice_panel.buttons[0].pressed.emit()
	if not game.in_shop or game.wave.current_wave != 30 or game.rewards.final_wave:
		_fail("endless milestone did not return to the shop")
		return
	game._on_shop_reserve(0)
	var kept_price: int = game.shop.offers[0].price
	game._on_shop_reroll()
	var paid_coins: int = game.coins
	var cost: int = game.shop.reroll_cost
	game = await _resume(session)
	if game.shop.offers[0].price != kept_price or not game.shop.reserved[0] or game.shop.reroll_cost != cost or game.coins != paid_coins:
		_fail("endless shop resume lost reservations, inflation or reroll costs")
		return
	game._on_shop_continue()
	var existing_reports := DirAccess.get_files_at(session.report_dir)
	game._on_player_died()
	if not game.ended or game.choice_panel.buttons[3].visible or not game.choice_panel.subtitle_label.text.contains("Sieg") or session.has_run():
		_fail("endless death offered continuation or lost the base victory")
		return
	var fresh_reports: Array[String] = []
	for file in DirAccess.get_files_at(session.report_dir):
		if not existing_reports.has(file):
			fresh_reports.append(file)
	if fresh_reports.size() != 1:
		_fail("endless death did not write one final report")
		return
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(session.report_dir + "/" + fresh_reports[0]))
	if report.outcome != "victory" or report.ended_by != "death" or report.wave_reached != 31 or not report.endless_enabled:
		_fail("endless run report did not preserve victory and final wave")
		return
	paused = false
	session.clear_run()
	print("Denti endless flow test passed")
	quit(0)

func _resume(session: Node) -> Node2D:
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	return current_scene

func _kill_boss(member: Enemy) -> void:
	member.boss_phase = 2
	member.boss_phase_timer = 0.0
	member.boss_damage_budget = member.max_health
	member.health = 1.0
	member.take_damage(10000000.0)
	member._process(Enemy.BOSS_DEATH_DURATION + 0.01)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
