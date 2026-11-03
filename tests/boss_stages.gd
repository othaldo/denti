extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D

func _initialize() -> void: call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_boss_stages.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	# Actual wave planning: no stream, burst, elite, horde or recycled adds.
	for difficulty in [&"easy", &"normal", &"hard", &"hell"]:
		for number in [5, 10, 15, 20, 25, 30, 40]:
			var planner := WaveController.new()
			var counts := {"bosses": 0, "trash": 0, "finished": 0}
			planner.current_wave = number - 1
			planner.endless_enabled = number > 20
			planner.difficulty_id = difficulty
			planner.boss_requested.connect(func(_data: EnemyData): counts.bosses += 1)
			planner.enemy_requested.connect(func(_data: EnemyData): counts.trash += 1)
			planner.elite_requested.connect(func(_data: EnemyData): counts.trash += 1)
			planner.horde_requested.connect(func(_data: EnemyData, amount: int): counts.trash += amount)
			planner.wave_finished.connect(func(_wave: int): counts.finished += 1)
			planner.start_next_wave()
			for tick in 241: planner._process(0.25)
			planner._process(10000)
			_check(counts.bosses == (2 if number in [30, 40] else 1) and counts.trash == 0 and counts.finished == 0 and planner.active and planner.remaining == planner.duration, "boss stage spawned trash or retained a timed finish/inflammation: %s/%d" % [difficulty, number])
			planner.free()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	await _fresh(10)
	var boss: Enemy = game.boss
	var attack := boss.caramel_encounter
	var ritual := attack.overload
	boss.boss_phase = 2
	boss.boss_phase_timer = 0
	var health := boss.health
	_check(boss.take_damage(10000) == 0 and boss.health == health, "threshold gap allowed skipping the objective phase")
	attack.advance(0.01)
	_check(ritual.state == CaramelOverload.State.WARNING and ritual.live_pylons().size() == 4, "ritual did not create exactly four unique hearts")
	_check(not boss.is_targetable(), "immune Prince remained an automatic weapon target")
	for pylon in ritual.live_pylons():
		_check(pylon.data == EnemyCatalog.CARAMEL_HEART and pylon.contact_damage == 0 and pylon.inflicted_statuses.is_empty(), "heart inherited a trash role/status/contact attack")
	attack.advance(ritual.profile.warning_seconds)
	_check(ritual.state == CaramelOverload.State.ACTIVE, "ritual preparation did not enter active task")
	game._on_boss_reinforcements(8)
	_check(game.get_node("Enemies").get_child_count() == 5, "health phase recycled normal enemies as minions")
	# A boss wave has no running clock, also during a live task.
	game.wave.remaining = 0.01
	game.wave._process(10000)
	_check(game.wave.active and not game.boss_pending and not boss.overtime_active and ritual.live_pylons().size() == 4 and not game.collecting_wave_loot, "boss wave clock still ended/inflamed the fight or removed objectives")
	# Root-level save/resume must link exactly the same four targets and clocks.
	var expected := ritual.save_data()
	var first: Enemy = ritual.live_pylons()[0]
	game.player.global_position = first.global_position + Vector2(55, 0)
	first.take_damage(5)
	var first_health := first.health
	game._save_run()
	_check(not session.load_run().is_empty(), "complete objective snapshot failed validation")
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	boss = game.boss
	attack = boss.caramel_encounter
	ritual = attack.overload
	_check(ritual.state == CaramelOverload.State.ACTIVE and ritual.live_pylons().size() == 4 and game.get_node("Enemies").get_child_count() == 5, "resume lost/duplicated ritual objectives")
	_check(absf(ritual.remaining - float(expected.remaining)) < 0.1 and absf(ritual.live_pylons()[0].health - first_health) < 0.01, "resume reset objective health or task deadline")
	var frozen := ritual.save_data()
	await process_frame
	await process_frame
	_check(ritual.save_data() == frozen, "pause advanced task/hazard clocks")
	# Immune targets do not absorb normal weapon/projectile queries.
	game.player.global_position = boss.global_position
	_check(not game.get_node("Enemies").in_circle(boss.global_position, 1).has(boss), "spatial query kept the immune boss as a hit target")
	for pylon in ritual.live_pylons():
		game.player.global_position = pylon.global_position + Vector2(55, 0)
		_check(pylon.is_targetable(), "approaching a heart did not open its shell")
		pylon.take_damage(1000)
	attack.advance(0.01)
	_check(ritual.state == CaramelOverload.State.RECOVERY and ritual.live_pylons().is_empty() and boss.is_targetable(), "last heart did not immediately break the shield")
	var recovered := ritual.save_data()
	EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
	_check(ritual.save_data() == recovered and boss.is_targetable(), "snapshot reset the earned vulnerability window")
	health = boss.health
	boss.boss_damage_budget = 0
	var dealt := boss.take_damage(10)
	_check(dealt > 10 and boss.health < health, "success window retained the boss guard or lost vulnerability")
	attack.advance(ritual.profile.recovery_seconds + 0.1)
	_check(ritual.used and ritual.state == CaramelOverload.State.FINISHED, "completed task repeated or left permanent immunity")
	# Failure releases warned, dodgeable projectiles, then restores normal combat.
	await _fresh(10)
	boss = game.boss
	attack = boss.caramel_encounter
	ritual = attack.overload
	boss.boss_phase = 2
	boss.boss_phase_timer = 0
	attack.advance(0.01)
	attack.advance(ritual.profile.warning_seconds + ritual.duration)
	_check(ritual.state == CaramelOverload.State.BLAST and ritual.missed == 4, "deadline did not announce the unfinished finisher")
	var blast_warning := ritual.save_data()
	EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
	_check(ritual.save_data() == blast_warning and attack.hearts.entries.is_empty(), "resume skipped the finisher warning")
	attack.advance(ritual.profile.blast_warning_seconds + 0.01)
	_check(ritual.state == CaramelOverload.State.FINISHED and boss.is_targetable() and not attack.hearts.entries.is_empty(), "failure stalled invulnerability instead of resuming combat")
	# Small viewports and slow builds retain reachable, fixed world-space targets.
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720)]:
		root.size = extent
		root.content_scale_size = extent
		await _fresh(10)
		game.player.stats.speed_bonus = -60
		game.player.get_node("Camera2D").force_update_scroll()
		await process_frame
		boss = game.boss
		boss.boss_phase = 2
		boss.boss_phase_timer = 0
		attack = boss.caramel_encounter
		attack.advance(0.01)
		ritual = attack.overload
		var visible := boss.get_canvas_transform().affine_inverse() * boss.get_viewport_rect()
		for pylon in ritual.live_pylons():
			_check(visible.has_point(pylon.global_position), "objective spawned outside the visible arena")
		_check(ritual.duration >= ritual.profile.minimum_seconds and ritual.duration <= ritual.profile.maximum_seconds, "route-derived deadline escaped bounds")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	# Early victory, exact fixed budget and collection before mandatory choices.
	await _fresh(5)
	boss = game.boss
	game.wave.boss_rewards.release_phase(game, game.player.global_position, 1)
	game.wave.boss_rewards.release_phase(game, game.player.global_position, 1)
	game.wave.boss_rewards.release_phase(game, game.player.global_position, 2)
	_kill(boss)
	await process_frame
	await process_frame
	_check(game.collecting_wave_loot and not game.wave.active and game.wave.remaining > 0 and not game.shop_panel.visible, "early boss death waited for timer or skipped loot collection")
	var totals := _loot_totals()
	_check(totals.xp == 30 and totals.coins == 32 and totals.chests == 1, "phase fragments and boss completion did not share one fixed budget")
	game.wave.boss_rewards.deliver(game, game.player.global_position)
	_check(_loot_totals() == totals, "completion budget paid twice")
	for drop: Loot in game.get_node("Loot").get_children():
		if not drop.is_queued_for_deletion(): drop.advance_collection(0.01, drop.global_position, 0)
	await process_frame
	await process_frame
	_check(game.rewards.pending_levels > 0 and game.rewards.step == PostWaveRewards.Step.LEVELS and not game.shop_panel.visible, "boss XP did not queue levels after complete collection")
	_check(game.telemetry.wave_xp == 30 and game.telemetry.wave_coins == 32, "boss payouts bypassed loot telemetry")
	_check(game.wave.boss_rewards.save_data().paid, "paid state was not captured")
	# Endlessly many boss/minion kills cannot generate additional stage budgets.
	await _fresh(30)
	var bosses := BossEncounter.remaining(game.get_node("Enemies"))
	_check(bosses.size() == 2, "endless stage lost the second boss")
	_kill(bosses[0])
	await process_frame
	await process_frame
	_check(not game.collecting_wave_loot and not game.wave.boss_rewards.paid, "first double-boss death finished/payed the stage")
	_kill(bosses[1])
	await process_frame
	await process_frame
	_check(game.collecting_wave_loot and _loot_totals().xp == 65, "last double-boss death failed the single shared budget")
	# Completion also recovers when the last boss disappears without its normal
	# defeat callback; no timer wait or lost stage budget.
	await _fresh(15)
	game.boss.queue_free()
	await process_frame
	await process_frame
	paused = false
	game._process(1.0 / 60)
	paused = true
	_check(game.collecting_wave_loot and not game.wave.active and game.wave.boss_rewards.paid and _loot_totals().xp == 55, "empty boss stage waited for its timer or lost its payout")
	# Old saves keep their earned/lying loot and receive only the missing budget.
	await _fresh(5)
	game.telemetry.wave_xp = 10
	game.telemetry.wave_coins = 12
	game.telemetry.wave_chests_found = 1
	game._spawn_loot(game.player.global_position, &"xp", 5)
	game._spawn_loot(game.player.global_position, &"coin", 4)
	game.wave.boss_rewards.restore({})
	game.wave.boss_rewards.deliver(game, game.player.global_position)
	_check(_loot_totals().xp == 20 and _loot_totals().coins == 20 and _loot_totals().chests == 0, "legacy boss save duplicated prior loot instead of topping up the fixed budget")
	for bad in [{"state": "bad"}, {"anchor": [0]}, {"used": 1}]:
		_check(RunSaveData.normalize({"wave": 10, "player": {}, "enemies": [{"caramel": {"overload": bad}}]}).is_empty(), "malformed ritual passed run validation")
	session.clear_run()
	if failures.is_empty(): print("PASS boss_stages: isolated encounters, task success/failure, targeting, pause/resume, inflammation, reachable layouts, early victory, fixed loot and double bosses")
	finish(0 if failures.is_empty() else 1)

func _fresh(number: int) -> void:
	paused = true
	game._clear_arena(false)
	await process_frame
	await process_frame
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.choice_panel.hide()
	game.wave.endless_enabled = number > 20
	game.wave.current_wave = number - 1
	game.player.loadout.restore([])
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	game.player.stats.speed_bonus = 0
	game.player.hurt_time = 0
	game.rewards.begin_wave()
	game.wave.start_next_wave()
	game.get_node("Enemies").set_physics_process(false)
	game.player.set_physics_process(false)
	game.wave.set_process(false)
	game.player.get_node("Camera2D").force_update_scroll()

func _kill(enemy: Enemy) -> void:
	if enemy.crown_court_encounter != null: enemy.crown_court_encounter.retinue.used = true
	if enemy.acid_king_encounter != null: enemy.acid_king_encounter.pressure.used = true
	enemy.boss_phase = 2
	enemy.boss_phase_timer = 0
	enemy.boss_damage_budget = enemy.max_health * 10
	if enemy.caramel_encounter != null: enemy.caramel_encounter.overload.used = true
	enemy.take_damage(1e9)
	enemy._process(Enemy.BOSS_DEATH_DURATION)

func _loot_totals() -> Dictionary:
	var result := {"xp": 0, "coins": 0, "chests": 0}
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.is_queued_for_deletion(): continue
		if drop.kind == &"xp": result.xp += drop.amount
		elif drop.kind == &"coin": result.coins += drop.amount
		else: result.chests += 1
	return result
