extends "res://tests/support/test_runtime.gd"

var game: Node2D
var boss: Enemy
var court: CrownCourtEncounter
var retinue: ImperialRetinue
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)

func _fresh(difficulty: StringName = &"normal") -> void:
	paused = true
	game.wave.active = false
	game.boss_pending = false
	game._clear_arena(false)
	await process_frame
	await process_frame
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.wave.current_wave = 20
	game.wave.difficulty_id = difficulty
	game.wave.active = true
	game.wave.set_process(false)
	game.rewards.begin_wave()
	game.wave.boss_rewards = BossStageRewards.new()
	game.player.loadout.restore([])
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.stats.max_health = 100000
	game.player.stats.health = 100000
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	game.player.hurt_time = 0
	game.player.get_node("Camera2D").force_update_scroll()
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, game.player.global_position - Vector2(0, 140))
	boss = game.boss
	court = boss.crown_court_encounter
	retinue = court.retinue
	boss.health = boss.max_health * retinue.profile.thresholds[0]
	boss.boss_phase = 0 if boss.health / boss.max_health > 0.67 else 1
	boss.boss_phase_timer = 0
	boss.set_simulation_enabled(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	court.advance(0.01)
	court.advance(retinue.remaining)

func _kill(minion: Enemy) -> void:
	minion.imperial_vassal.budget = minion.max_health
	minion.take_damage(1e9)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://imperial_retinue.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	for difficulty in [&"easy", &"normal", &"hard", &"hell"]:
		await _fresh(difficulty)
		var expected := 2 if difficulty in [&"easy", &"normal"] else 3
		_check(retinue.state == ImperialRetinue.State.CHANNEL and retinue.live_minions().size() == expected, "Emperor summoned wrong unique lieutenant count")
		_check(retinue.profile.thresholds.size() == (1 if difficulty == &"easy" else (2 if difficulty == &"normal" else 3)), "wrong difficulty-specific retinue plan")
		await _check_hud(expected)
		var before := boss.health
		_check(boss.take_damage(1e9) == 0 and boss.health == before and not boss.is_targetable(), "Emperor could be killed through his lieutenants")
		for minion in retinue.live_minions():
			_check(minion.data in [EnemyCatalog.IMPERIAL_LANCER, EnemyCatalog.IMPERIAL_KEEPER, EnemyCatalog.IMPERIAL_JUSTICIAR] and minion.is_targetable() and not minion.data.is_boss and minion.data.is_boss_objective, "retinue reused trash or entered the milestone-boss list")
			_check(minion.contact_damage == 0 and minion.inflicted_statuses.is_empty() and minion.data.xp_drop == 0 and minion.data.coin_drop == 0, "lieutenant inherited trash statuses, contact or extra loot")
			var health := minion.health
			minion.take_damage(1e9)
			_check(minion.health > 0 and minion.health < health, "a lieutenant was a one-hit objective")
			game._refresh_hud()
			var slot: int = game.hud.retinue_display.members.find(minion)
			_check(slot >= 0 and is_equal_approx(game.hud.retinue_display.frames[slot].material.get_shader_parameter("health_fill"), minion.health / minion.max_health), "damaging a lieutenant did not update its named bar")
		court.advance(2)
		_check(boss.health > before and boss.health - before <= boss.max_health * retinue.profile.regeneration_fraction, "keeper omitted or exceeded bounded regeneration")
		var keeper: Enemy
		for minion in retinue.live_minions():
			if minion.imperial_vassal.profile.role == ImperialVassalData.Role.KEEPER: keeper = minion
		_kill(keeper)
		var after_keeper := boss.health
		court.advance(3)
		_check(boss.health == after_keeper and retinue.live_minions().size() == expected - 1, "killing the keeper did not stop regeneration")
		game._refresh_hud()
		_check(game.hud.retinue_display.members.size() == expected - 1, "dead keeper retained a named HUD bar")
		_check(game.get_node("Loot").get_child_count() == 0 and BossEncounter.remaining(game.get_node("Enemies")).size() == 1, "vassal death generated stage loot or counted as a milestone boss")
	# Actual scene reload preserves ownership, depleted guard and a fixed lance.
	await _fresh()
	var lancer: Enemy = retinue.live_minions()[0]
	lancer.imperial_vassal.state = ImperialVassal.State.FOLLOW
	lancer.imperial_vassal.remaining = 0
	lancer.imperial_vassal.advance(0.05)
	lancer.take_damage(1e9)
	var aimed := lancer.imperial_vassal.destination
	var guard := lancer.imperial_vassal.budget
	game._save_run()
	_check(not session.load_run().is_empty(), "retinue root save failed validation")
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	game.get_node("Enemies").set_physics_process(false)
	game.player.set_physics_process(false)
	boss = game.boss
	court = boss.crown_court_encounter
	retinue = court.retinue
	_check(retinue.live_minions().size() == 2 and retinue.state == ImperialRetinue.State.CHANNEL, "reload lost or duplicated a lieutenant")
	lancer = retinue.live_minions()[0]
	_check(lancer.boss_objective_owner == boss and lancer.imperial_vassal.destination == aimed and lancer.imperial_vassal.state == ImperialVassal.State.WARNING, "reload changed lance: role=%d owner=%s state=%d destination=%s expected=%s" % [lancer.imperial_vassal.profile.role, lancer.boss_objective_owner == boss, lancer.imperial_vassal.state, lancer.imperial_vassal.destination, aimed])
	_check(lancer.imperial_vassal.budget <= guard + lancer.max_health * 0.03, "reload refilled a lieutenant's guard")
	var frozen := retinue.save_data()
	var minion_frozen := lancer.imperial_vassal.save_data()
	await process_frame
	await process_frame
	_check(retinue.save_data() == frozen and lancer.imperial_vassal.save_data() == minion_frozen, "pause advanced charge or lieutenant attacks")
	# Earned opening is finite and cannot skip directly to the next summon.
	for minion in retinue.live_minions(): _kill(minion)
	court.advance(0.01)
	game._refresh_hud()
	_check(not game.hud.retinue_display.visible, "cleared retinue retained HUD bars")
	_check(retinue.state == ImperialRetinue.State.OPEN and boss.is_targetable(), "last lieutenant did not break the court shield")
	boss.boss_damage_budget = 0
	_check(is_equal_approx(boss.take_damage(10), 16.5), "court opening retained armor or the normal burst limit")
	var allowance := retinue.opening_left
	_check(boss.take_damage(1e9) <= allowance + 0.01, "court counterattack skipped its finite opening")
	court.advance(0.01)
	_check(not retinue.busy() and boss.boss_damage_budget == 0 and retinue.completed_mask == 1, "opening left stale immunity or repeated a summon")
	# Full Hell sequence: huge hits cannot skip a retinue checkpoint, and the
	# last boss death ends the wave with one shared reward budget.
	await _fresh(&"hell")
	for index in 3:
		_check(retinue.trial_index == index and retinue.live_minions().size() == 3, "Hell omitted a complete retinue phase")
		for minion in retinue.live_minions(): _kill(minion)
		court.advance(0.01)
		_check(retinue.state == ImperialRetinue.State.OPEN, "complete retinue did not yield an attack opening")
		boss.take_damage(1e9)
		court.advance(0.01)
		if index < 2:
			var threshold: float = retinue.profile.thresholds[index + 1]
			for attempt in 4:
				if boss.health <= boss.max_health * threshold + 0.01: break
				boss.boss_phase_timer = 0
				boss.boss_damage_budget = boss.max_health
				boss.take_damage(1e9)
			_check(is_equal_approx(boss.health / boss.max_health, threshold), "burst skipped the next Imperial checkpoint")
			boss.boss_phase_timer = 0
			court.advance(0.01)
			court.advance(retinue.remaining)
	_check(retinue.used and retinue.completed_mask == 7, "third Imperial retinue was not final")
	boss.boss_damage_budget = boss.max_health
	boss.take_damage(1e9)
	boss._process(Enemy.BOSS_DEATH_DURATION + 0.01)
	await process_frame
	await process_frame
	_check(not game.wave.active and game.collecting_wave_loot and game.wave.boss_rewards.paid, "Imperial finale waited for a timer or missed the reward budget")
	# Failure releases a fully warned volley; survivors remain real enemies.
	await _fresh(&"hell")
	retinue.remaining = 0.01
	court.advance(0.02)
	_check(retinue.state == ImperialRetinue.State.FAILURE and retinue.shots.entries.is_empty(), "charge expired without a finisher warning")
	court.advance(retinue.remaining + 0.01)
	_check(not retinue.blocks_damage() and retinue.live_minions().size() == 3 and not retinue.shots.entries.is_empty(), "failed charge removed the challenge or left permanent immunity")
	game._refresh_hud()
	_check(game.hud.retinue_display.visible and game.hud.retinue_display.members.size() == 3, "failed charge hid the surviving lieutenants' health")
	var survivor := retinue.live_minions()[0]
	var elapsed := survivor.imperial_vassal.elapsed
	court.advance(0.2)
	_check(survivor.imperial_vassal.elapsed > elapsed, "surviving lieutenant stopped fighting after the charge")
	var legacy := EnemySnapshot.capture(boss)
	legacy.crown_court.version = 2
	legacy.crown_court.erase("retinue")
	EnemySnapshot.restore(boss, legacy)
	_check(retinue.used and not retinue.blocks_damage(), "legacy court save inserted new unannounced minions")
	for invalid in [{"budget": "bad"}, {"destination": [0]}, {"hit": 1}]:
		_check(not ImperialVassal.valid(invalid), "malformed vassal snapshot was accepted")
	session.clear_run()
	if failures.is_empty(): print("PASS imperial_retinue: unique lieutenants, burst protection, keeper regeneration, fixed warnings, finite openings, no extra stage loot, failure, real reload, pause and legacy")
	finish(0 if failures.is_empty() else 1)

func _check_hud(expected: int) -> void:
	var display: HUDRetinue = game.hud.retinue_display
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		await process_frame
		await process_frame
		game._refresh_hud()
		_check(display.visible and display.members.size() == expected, "retinue HUD omitted a live lieutenant")
		var screen := Rect2(Vector2.ZERO, Vector2(extent))
		_check(screen.encloses(display.get_global_rect()), "retinue HUD exceeds viewport at %s" % extent)
		_check(not display.get_global_rect().intersects(game.hud.boss_rows[0].get_global_rect()), "retinue covers the Emperor's bar")
		for index in expected:
			var member := display.members[index]
			var label := display.labels[index]
			_check(label.text == member.data.display_name, "lieutenant HUD label names the wrong actor")
			_check(label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x, "lieutenant name is clipped at %s: %s" % [extent, label.text])
			_check(display.frames[index].material.get_shader_parameter("fill_shadow") == HUDRetinue.SHADOW, "lieutenant reused the red main-boss fill")
			_check(is_equal_approx(display.frames[index].material.get_shader_parameter("health_fill"), member.health / member.max_health), "lieutenant bar displays the wrong health")
			_check(display.rows[index].mouse_filter == Control.MOUSE_FILTER_IGNORE, "lieutenant HUD blocks movement input")
			for other in range(index + 1, expected):
				_check(not display.rows[index].get_global_rect().intersects(display.rows[other].get_global_rect()), "lieutenant HUD bars overlap")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
