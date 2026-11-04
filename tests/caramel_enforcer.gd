extends "res://tests/support/test_runtime.gd"

var game: Node2D
var boss: Enemy
var court: CaramelEncounter
var guard: CaramelBodyguard
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)

func _fresh(difficulty: StringName = &"hell") -> void:
	paused = true
	game._clear_arena(false)
	await process_frame
	await process_frame
	game.wave.current_wave = 10
	game.wave.difficulty_id = difficulty
	game.wave.active = true
	game.wave.set_process(false)
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game.player.hurt_time = 0
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.get_node("Camera2D").force_update_scroll()
	game._create_enemy(EnemyCatalog.CAVITY_PRINCE, game.player.global_position - Vector2(260, 0))
	boss = game.boss
	boss.set_simulation_enabled(false)
	court = boss.caramel_encounter
	guard = court.bodyguard
	guard.advance(guard.profile.summon_delay + 0.01)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session := root.get_node("GameSession")
	session.save_path = "user://caramel_enforcer.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	for difficulty in [&"easy", &"normal", &"hard", &"hell"]:
		await _fresh(difficulty)
		var enabled: bool = difficulty in [&"hard", &"hell"]
		_check(guard.live_minions().size() == (1 if enabled else 0), "bodyguard changed Normal/Easy or omitted the hard-tier minion")
		if not enabled: continue
		var actor := guard.minion
		_check(actor.data == EnemyCatalog.CARAMEL_ENFORCER and actor.is_targetable() and not actor.data.is_boss, "Brösel reused trash or counted as the wave boss")
		var hp := actor.health
		actor.take_damage(1e9)
		_check(actor.health > 0 and actor.health < hp, "Brösel died before his attack could matter")
		var cycle := court.cycle
		court.advance(1)
		_check(court.cycle > cycle and guard.live_minions().size() == 1, "Don stopped attacking or summoned a second concurrent guard")
		game._refresh_hud()
		_check(game.hud.retinue_display.visible and game.hud.retinue_display.labels[0].text == "Brösel", "Brösel has no named miniboss HUD")
	await _fresh()
	var actor := guard.minion
	var ai := actor.caramel_enforcer
	# Close punches punish hugging; every second Hell punch is warned afresh.
	actor.global_position = game.player.global_position
	ai.state = CaramelEnforcer.State.FOLLOW
	ai.remaining = 0
	ai.advance(0.01)
	var point := ai.destination
	game.player.global_position = point
	game.player.hurt_time = 0
	ai.advance(ai.remaining - 0.001)
	_check(game.player.stats.health == 10000 and ai.destination == point, "punch moved its warning or dealt damage early")
	ai.advance(0.002 + ai.profile.punch_seconds)
	_check(game.player.stats.health < 10000 and ai.state == CaramelEnforcer.State.PUNCH_WARN, "hugging the guard avoided its Hell punch or followup was unannounced")
	# A slowed baseline player can leave the entire punch from its centre.
	for difficulty in [&"hard", &"hell"]:
		await _fresh(difficulty)
		actor = guard.minion
		ai = actor.caramel_enforcer
		actor.global_position = game.player.global_position
		ai.punches_left = ai.profile.punches
		ai._warn_punch()
		game.player.global_position = ai.destination
		for tick in ceili(ai.profile.punch_warning * 60) + 16:
			game.player.global_position += Vector2.DOWN * PlayerStats.BASE_MOVE_SPEED * court.profile.movement_factor / 60
			game.player.motion_tick = -1
			ai.advance(1.0 / 60)
		_check(game.player.stats.health == 10000, "slowed player cannot leave a fully warned punch")
	await _check_combined_routes()
	await _fresh()
	actor = guard.minion
	ai = actor.caramel_enforcer
	actor.global_position = game.player.global_position - Vector2(260, 0)
	ai.state = CaramelEnforcer.State.FOLLOW
	ai.remaining = 0
	ai.advance(0.01)
	_check(ai.state == CaramelEnforcer.State.CHARGE_WARN, "distant guard did not announce a rush")
	var locked := ai.destination
	var budget := ai.budget
	game._save_run()
	_check(not session.load_run().is_empty(), "bodyguard save was rejected")
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	boss = game.boss
	boss.set_simulation_enabled(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	court = boss.caramel_encounter
	guard = court.bodyguard
	_check(guard.live_minions().size() == 1 and guard.spawned == 1, "reload lost or duplicated the guard")
	actor = guard.minion
	ai = actor.caramel_enforcer
	_check(actor.boss_objective_owner == boss and ai.state == CaramelEnforcer.State.CHARGE_WARN and ai.destination == locked and ai.budget <= budget + actor.max_health * 0.03, "reload changed ownership, guard budget or locked rush")
	var frozen := [guard.save_data(), ai.save_data()]
	await process_frame
	await process_frame
	_check(frozen == [guard.save_data(), ai.save_data()], "pause advanced the bodyguard")
	var before: float = game.player.stats.health
	var attack_before := ai.save_data()
	boss._start_boss_phase()
	_check(ai.save_data() == attack_before and actor.is_targetable(), "boss phase cancelled Brösel's warning or made him immune")
	for phase in [CaramelOverload.State.WARNING, CaramelOverload.State.ACTIVE, CaramelOverload.State.BLAST, CaramelOverload.State.RECOVERY]:
		court.overload.state = phase
		_check(actor.is_targetable() and not ai.suspended(), "Brösel became inactive during a boss special phase")
	court.overload.state = CaramelOverload.State.ACTIVE
	ai.punches_left = ai.profile.punches
	ai._warn_punch()
	game.player.global_position = ai.destination
	game.player.hurt_time = 0
	guard.advance(ai.remaining + ai.profile.punch_seconds + 0.01)
	_check(game.player.stats.health < before and actor.is_targetable() and actor.take_damage(5) > 0, "Brösel stopped attacking or taking damage during the heart trial")
	game._refresh_hud()
	_check(game.hud.retinue_display.rows[0].modulate.a == 1, "active Brösel retained an invulnerable HUD tint")
	court.overload.state = CaramelOverload.State.FINISHED
	court.overload.used = true
	_check(actor.is_targetable(), "bodyguard did not return to combat after the ritual")
	# Reinforcements are bounded, never overlapping and do not create loot.
	var loot_before: int = game.get_node("Loot").get_child_count()
	for call in guard.profile.max_summons:
		guard.minion.caramel_enforcer.budget = guard.minion.max_health
		guard.minion.take_damage(1e9)
		guard.advance(guard.profile.reinforcement_delay + 0.01)
		await process_frame
	_check(guard.spawned == guard.profile.max_summons and guard.live_minions().is_empty() and game.get_node("Loot").get_child_count() == loot_before, "bodyguard respawned without limit or generated extra loot")
	await _fresh()
	var legacy := court.save_data()
	legacy.version = 4
	legacy.erase("bodyguard")
	guard.clear()
	court.restore(legacy)
	guard.advance(50)
	_check(guard.legacy and guard.live_minions().is_empty() and not court.overload.used, "legacy v4 save acquired a surprise minion or lost its heart trials")
	await _fresh()
	boss.health = 0
	court.cancel()
	game._refresh_hud()
	_check(guard.live_minions().is_empty() and not game.hud.retinue_display.visible, "boss death left a guard or HUD alive")
	_check(not CaramelEnforcer.valid({"destination": [1]}) and not CaramelBodyguard.valid({"spawned": "bad"}), "invalid minion snapshot was accepted")
	session.clear_run()
	if failures.is_empty(): print("PASS caramel_enforcer: continuous targetable pressure through health/heart phases, fixed warnings, slow escape, real reload, pause, bounded rewards and cleanup")
	finish(0 if failures.is_empty() else 1)

func _check_combined_routes() -> void:
	# A real first bomb/fan combination plus Brösel: all corners, no dash,
	# 72% speed. Find an escape without crossing the Don's body.
	for difficulty in [&"hard", &"hell"]:
		await _fresh(difficulty)
		court.overload.used = true
		var actor := guard.minion
		var ai := actor.caramel_enforcer
		for corner: Vector2 in [Vector2(60, 60), Vector2(game.arena.arena_size.x - 60, 60), Vector2(60, game.arena.arena_size.y - 60), game.arena.arena_size - Vector2.ONE * 60]:
			for close in [false, true]:
				var safe := false
				for path in 32:
					court.cancel()
					court.cycle = 0
					game.player.global_position = corner
					game.player.velocity = Vector2.ZERO
					game.player.stats.health = 10000
					game.player.hurt_time = 0
					game.player.dash_moved = false
					game.player.motion_tick = -1
					game.player.get_node("Camera2D").force_update_scroll()
					var inward := corner.direction_to(game.arena.arena_size * 0.5)
					boss.global_position = corner + inward * 260
					actor.global_position = corner + inward.rotated(0.3) * (75 if close else 210)
					ai.state = CaramelEnforcer.State.FOLLOW
					ai.remaining = 0
					ai.advance(0.001)
					court.begin(-1, CaramelEncounterData.Attack.BOMBS)
					var crossed := false
					for tick in 300:
						var before: Vector2 = game.player.global_position
						var goal := CaramelEscapePilot.goal(boss, actor, path)
						game.player.global_position = before.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * court.profile.movement_factor / 60)
						game.player.velocity = (game.player.global_position - before) * 60
						game.player.get_node("Camera2D").force_update_scroll()
						if Geometry2D.get_closest_point_to_segment(boss.global_position, before, game.player.global_position).distance_to(boss.global_position) <= boss.data.radius + 20:
							crossed = true
							break
						court.advance(1.0 / 60)
						if game.player.stats.health < 10000: break
					if not crossed and game.player.stats.health == 10000:
						safe = true
						break
				_check(safe, "combined guard/bomb pressure has no observed slowed escape: %s / %s / close=%s" % [difficulty, corner, close])
