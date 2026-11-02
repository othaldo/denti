extends "res://tools/benchmark_bot_comparison.gd"

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _pilot(skill_id: String, policy: String = "simple") -> void:
	skill = skill_id
	build_policy = policy
	pilot = BRAIN.new()
	pilot.configure(skill, "kite", 13579)
	observation = OBSERVATION.new()
	previous_wave = -1

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var novice := await _projectile_trial("novice")
	var expert := await _projectile_trial("expert")
	_check(novice.dashes == 0 and novice.health < 100, "delayed novice did not receive the controlled incoming shot")
	_check(expert.dashes > 0 and expert.health == 100, "expert did not use the real dash to evade the same shot")
	var results: Array[Dictionary] = []
	var metrics: Array[Dictionary] = []
	for policy in ["simple", "synergy", "synergy"]:
		_pilot("regular", policy)
		results.append(await sample_run("turbo_drill", &"normal", "kite", 13579, 2))
		metrics.append(pilot.metrics())
	var first := results[1]
	_check(first.waves.size() == 2 and first.outcome == "wave_complete", "bot failed its two-wave integration fixture")
	_check(first.waves[0].start.coins == 0 and first.waves[0].start.stats.max_health == 100 and first.waves[0].start.equipment.size() == 1, "bot received a free stat/economy advantage")
	_check(first.waves[0].after_shop.coins >= 0 and first.waves[0].after_shop.coins < first.waves[0].after_rewards.coins, "synergy shopping did not pay real prices")
	_check(first.waves[1].start.stats == first.waves[0].after_shop.stats and first.waves[1].start.equipment == first.waves[0].after_shop.equipment, "bot replaced earned health/equipment between waves")
	for key in ["outcome", "wave", "level", "kills", "gold_earned", "xp_earned", "chests"]:
		_check(results[1][key] == results[2][key], "repeated pilot changed earned progression: " + key)
	_check(metrics[1] == metrics[2], "repeated pilot changed delayed actions or mistake RNG")
	_check(not root.get_node("GameSession").has_run(), "bot wrote a real player save")
	print("PASS bot integration: bounded current-world perception, real projectile avoidance/dash costs, earned purchases/persistence and repeated deterministic inputs")
	finish(1 if failures else 0)

func _projectile_trial(skill_id: String) -> Dictionary:
	_pilot(skill_id)
	var game = make_run("turbo_drill", &"normal", 13579)
	game._start_combat_wave()
	paused = true
	game.player.position = game.player.arena.arena_size * 0.5
	# Perception must not expose off-screen or live mutable enemy nodes.
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100, 0))
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(700, 0))
	var seen := observation.capture(game, 0)
	_check(seen.enemies.size() == 1 and not seen.has("spawn_plan"), "pilot perception exposed hidden/future enemies")
	var position: Vector2 = seen.enemies[0].position
	game.get_node("Enemies").get_child(0).position += Vector2(30, 0)
	_check(seen.enemies[0].position == position, "a delayed observation retained live entity references")
	game.player.position.y = game.player.arena.arena_size.y - DentiArena.PLAYER_MARGIN
	_check(observation.capture(game, 1).enemies.is_empty(), "wall-side perception shifted inward and exposed off-screen enemies")
	game.player.position = game.player.arena.arena_size * 0.5
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	observation.reset()
	var shot := AcidProjectile.new()
	game.get_node("EnemyProjectiles").add_child(shot)
	shot.launch(game.player.global_position + Vector2(120, 0), Vector2.LEFT, 300, 10, game.player)
	for frame in 42:
		await physics_frame
		game.player.probe_direction = farm_direction(game, "kite", frame / 60.0)
		paused = false
		await process_frame
	paused = true
	var result := {"health": game.player.stats.health, "dashes": game.telemetry.dashes}
	_stop_audio(game)
	game.wave.active = false
	game.run_flow.enter(RunFlow.Phase.ENDED)
	game._clear_arena(false)
	game.queue_free()
	await process_frame
	await process_frame
	return result
