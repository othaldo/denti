extends "res://tests/boss_stages.gd"
## Exercise the complete trial plan, not just a debug jump into the finisher.

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_caramel_trials.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	var counts: Array[int] = []
	for difficulty in [&"easy", &"normal", &"hard", &"hell"]:
		game.wave.difficulty_id = difficulty
		await _fresh(10)
		var boss: Enemy = game.boss
		var attack := boss.caramel_encounter
		var ritual := attack.overload
		var count := 0
		for index in ritual.profile.trials.size():
			var definition := ritual.profile.trials[index]
			if ritual.profile.rank < definition.minimum_rank: continue
			boss.health = boss.max_health * definition.health_fraction
			boss.boss_phase = 2 if definition.health_fraction < 0.34 else 1
			boss.boss_phase_timer = 0
			attack.advance(0.01)
			_check(ritual.state == CaramelOverload.State.WARNING and ritual.trial_index == index and ritual.live_pylons().size() == definition.objectives, "wrong trial/order/count on " + str(difficulty))
			attack.advance(ritual.profile.warning_seconds + 0.01)
			if definition.kind == CaramelTrialData.Kind.COURIERS:
				var at := ritual.live_pylons()[0].position
				attack.advance(0.05)
				_check(ritual.live_pylons()[0].position != at, "courier remained a stationary pylon")
			for pylon in ritual.live_pylons():
				game.player.global_position = pylon.global_position + Vector2(55, 0)
				pylon.take_damage(10000)
			attack.advance(0.01)
			_check(ritual.state == CaramelOverload.State.RECOVERY and ritual.completed_mask & (1 << index), "successful trial did not mark only its checkpoint complete")
			if index < ritual.profile.trials.size() - 1:
				# Strong burst damage can reach the next check, but cannot skip it
				# through the reward window or kill the boss across phase floors.
				boss.boss_damage_budget = boss.max_health
				boss.take_damage(1e9)
				_check(not boss.dying and boss.health > 0, "vulnerability burst skipped a later mandatory trial")
			var checkpoint := EnemySnapshot.capture(boss)
			var expected := ritual.save_data()
			EnemySnapshot.restore(boss, checkpoint)
			_check(ritual.save_data() == expected, "trial progress or per-heart clocks changed on snapshot restore")
			attack.advance(ritual.profile.recovery_seconds + boss.boss_phase_timer + 0.1)
			# Manually sampled tests may already have entered the next warning
			# after the forced burst. Keep that checkpoint and inspect it next.
			if ritual.busy():
				attack.cancel()
			count += 1
		counts.append(count)
		_check(ritual.used and count == (1 if difficulty == &"easy" else (2 if difficulty == &"normal" else 3)), "difficulty trial plan did not finish exactly once")
	_check(counts == [1, 2, 3, 3], "hard difficulties did not add the courier examination")
	# A surviving heart owns its volley: breaking another opens a clean route.
	game.wave.difficulty_id = &"normal"
	await _fresh(10)
	var boss: Enemy = game.boss
	var attack := boss.caramel_encounter
	var ritual := attack.overload
	boss.boss_phase = 2
	boss.health = boss.max_health / 3
	boss.boss_phase_timer = 0
	attack.advance(0.01)
	attack.advance(ritual.profile.warning_seconds + 1.8)
	_check(not attack.hearts.entries.is_empty(), "active ritual hearts never attacked")
	var pylon: Enemy = ritual.live_pylons()[0]
	var broken_source := ritual.pressure.source(pylon.boss_objective_slot)
	game.player.global_position = pylon.global_position + Vector2(50, 0)
	pylon.take_damage(10000)
	ritual.pressure.advance(0)
	var other_shots := 0
	for shot in attack.hearts.entries:
		_check(shot.source != broken_source, "breaking a heart left its dangerous projectiles behind")
		other_shots += 1
	_check(other_shots > 0, "breaking one heart silently removed every other heart's pressure")
	# Real save/reload after one death must preserve stable owner/slot indices.
	game._save_run()
	var expected_pressure := ritual.pressure.save_data()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	game.get_node("Enemies").set_physics_process(false)
	game.player.set_physics_process(false)
	ritual = game.boss.caramel_encounter.overload
	_check(ritual.live_pylons().size() == 3, "reload resurrected a destroyed trial heart")
	for entry in ritual.pressure.entries:
		_check(ritual.pressure.pylon_for(entry.slot) != null, "reload changed a surviving heart's source/slot identity")
	_check(ritual.pressure.entries.size() == expected_pressure.shots.size(), "reload duplicated/lost independent heart clocks")
	# Missing couriers resolve into an announced attack; no permanent immunity.
	game.wave.difficulty_id = &"hard"
	await _fresh(10)
	boss = game.boss
	attack = boss.caramel_encounter
	ritual = attack.overload
	boss.boss_phase = 1
	boss.health = boss.max_health * 2 / 3
	boss.boss_phase_timer = 0
	attack.advance(0.01)
	attack.advance(ritual.profile.warning_seconds + ritual.duration + 2)
	_check(ritual.escaped > 0 and ritual.missed > 0 and not ritual.blocks_damage() and not ritual.used, "courier leakage stalled the campaign or skipped remaining trials")
	for bad in [{"pressure": {"shots": "bad"}}, {"pressure": {"shots": [{"position": [1]}]}}, {"completed_mask": "bad"}]:
		_check(not CaramelOverload.valid(bad), "malformed trial-pressure snapshot was accepted")
	session.clear_run()
	if failures.is_empty(): print("PASS caramel_trials: 1/2/3/3 trials, burst-proof milestones, independent heart pressure, courier movement/leaks, stable save identities and completed-checkpoint persistence")
	finish(0 if failures.is_empty() else 1)
