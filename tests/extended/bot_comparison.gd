extends "res://tools/benchmark_bot_comparison.gd"

var inspect_intermission := false
var enchantment_drafts: Array[Dictionary] = []

func make_run(build: String, difficulty: StringName, sample_seed: int):
	var game = super.make_run(build, difficulty, sample_seed)
	if inspect_intermission:
		viewer = VIEWER.new()
		viewer.game = game
		viewer.decision_seconds = 0.02
		root.add_child(viewer)
	return game

func before_intermission_action(game, phase_name: String, detail: String) -> bool:
	if inspect_intermission:
		_check(paused and not game.wave.active, "viewer exposed a reward/shop while combat was still active")
		match phase_name:
			"Aufstieg": _check(game.choice_panel.visible and game.choice_panel.mode == &"upgrade", "viewer did not show the real stat offers")
			"Verzauberungen": _check(game.weapon_enchantment_panel.visible, "viewer skipped its real enchantment panel")
			"Shop": _check(game.shop_panel.visible and game.in_shop, "viewer did not show the real shop offers")
	var continuing := await super.before_intermission_action(game, phase_name, detail)
	if inspect_intermission and phase_name == "Verzauberungen":
		var state: WeaponUpgradeState = game.rewards.weapon_upgrades
		enchantment_drafts.append({"wave": game.wave.current_wave, "actions": state.actions.size(),
			"remaining": state.remaining(), "detail": detail})
		if detail.begins_with("Plant #"):
			var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
			_check(str(panel.models[panel.selected_weapon].uid) == str(state.cursor.target_uid), "enchantment viewer displayed a different weapon than the planned step")
			_check(panel.remaining == state.remaining(), "enchantment viewer hid the remaining point budget")
	return continuing

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
	# Present the same earned run through real, paused intermission frames.
	# These frames must expose choices without improving income or combat inputs.
	inspect_intermission = true
	_pilot("regular", "synergy")
	var watched := await sample_run("turbo_drill", &"normal", "kite", 13579, 2)
	for index in watched.waves.size():
		for key in ["start", "after_rewards", "after_shop"]:
			if first.waves[index].has(key): _check(_earned_state(watched.waves[index][key]) == _earned_state(first.waves[index][key]), "intermission reading frames changed earned state: " + key)
	_check(pilot.metrics() == metrics[1], "intermission viewer advanced the combat pilot")
	_check(viewer.events.any(func(event: Dictionary): return event.get("phase") == "Aufstieg"), "viewer never presented stat decisions")
	_check(viewer.events.any(func(event: Dictionary): return str(event.get("decision", "")).begins_with("Kauft ")), "viewer hid paid purchases")
	_check(viewer.events.any(func(event: Dictionary): return str(event.get("decision", "")).begins_with("Reroll")), "viewer hid paid rerolls")
	_check(viewer.events.any(func(event: Dictionary): return str(event.get("decision", "")).begins_with("Neue Angebote")), "viewer hid new random offers after rerolls")
	var previous_wave_number := -1
	var previous_actions := 0
	var shown_steps := 0
	var shown_budgets := 0
	for draft in enchantment_drafts:
		_check(not str(draft.detail).is_empty(), "enchantment viewer added an empty reading step")
		if draft.wave != previous_wave_number:
			shown_budgets += 1
			previous_wave_number = int(draft.wave)
			previous_actions = 0
			_check(draft.actions == 0, "enchantments were already applied before the initial reading pause")
		if str(draft.detail).begins_with("Plant #"):
			_check(draft.actions == previous_actions + 1, "enchantment viewer skipped or bundled point decisions")
			shown_steps += 1
		else: _check(draft.actions == previous_actions, "enchantment plan changed outside a visible point decision")
		previous_actions = int(draft.actions)
	_check(shown_steps >= 2, "enchantment fixture never showed individual rank increases")
	_check(enchantment_drafts.size() == shown_steps + 2 * shown_budgets, "enchantment viewer repeated or omitted budget/confirmation steps")
	viewer.free()
	_check(not root.get_node("GameSession").has_run(), "bot wrote a real player save")
	print("PASS bot integration: bounded current-world perception, real projectile avoidance/dash costs, earned purchases/persistence and repeated deterministic inputs")
	finish(1 if failures else 0)

func _earned_state(value: Dictionary) -> Dictionary:
	var normalized := value.duplicate(true)
	# Newly purchased instances have wall-clock identities, not seeded stats.
	for weapon in normalized.equipment: weapon.erase("uid")
	return normalized

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
