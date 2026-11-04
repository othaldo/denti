extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session := root.get_node("GameSession")
	session.save_path = "user://acid_collector.json"
	session.resume_requested = false
	session.selected_story_mode = false
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game.wave.set_process(false)
	game.wave.current_wave = 15
	game.get_node("Enemies").set_physics_process(false)
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.get_node("Camera2D").force_update_scroll()
	for difficulty in [&"easy", &"normal", &"hard", &"hell"]:
		game._clear_arena(false)
		await process_frame
		game.wave.difficulty_id = difficulty
		game._create_enemy(EnemyCatalog.CAVITY_KING, game.player.global_position - Vector2(260, 0))
		var boss: Enemy = game.boss
		boss.set_simulation_enabled(false)
		var companion := boss.acid_king_encounter.companion
		companion.advance(5.01)
		_check(companion.live_minions().size() == (1 if difficulty in [&"hard", &"hell"] else 0), "collector difficulty plan changed Easy/Normal or omitted Hard/Hell")
	var boss: Enemy = game.boss
	var court := boss.acid_king_encounter
	var companion := court.companion
	var actor := companion.minion
	var ai := actor.acid_collector
	_check(actor.data == EnemyCatalog.ACID_COLLECTOR and actor.is_targetable() and not actor.data.is_boss and actor.contact_damage == 0, "Schlacko reused trash or became a second stage boss")
	await _check_combination(game, boss, actor)
	actor.take_damage(1e9)
	_check(actor.health > 0 and actor.health < actor.max_health, "Schlacko is a one-hit minion")
	ai.advance(ai.remaining + ai.profile.follow_seconds + 0.01)
	_check(ai.state == AcidCollector.State.WARNING, "collector did not announce its acid glob")
	var locked := ai.destination
	game.player.global_position += Vector2(160, 100)
	ai.advance(ai.remaining + ai.profile.flight_seconds + 0.01)
	_check(ai.pools.size() == 1 and ai.destination == locked and game.player.stats.health == 10000, "glob tracked its target, hit early or did not leave a pool")
	game.player.global_position = locked
	game.player.hurt_time = 0
	ai.advance(ai.profile.pool_tick_seconds + 0.01)
	_check(game.player.stats.health < 10000, "collector acid pool is harmless")
	game._refresh_hud()
	_check(game.hud.retinue_display.labels[0].text == "Schlacko" and game.hud.retinue_display.visible, "collector has no named miniboss bar")
	# Actual root reload preserves owned actor and its active acid pool.
	game._save_run()
	_check(not session.load_run().is_empty(), "collector snapshot failed root validation")
	var saved := ai.save_data()
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
	court = boss.acid_king_encounter
	companion = court.companion
	_check(companion.live_minions().size() == 1 and companion.spawned == 1, "collector was lost or duplicated on reload")
	actor = companion.minion
	ai = actor.acid_collector
	_check(actor.boss_objective_owner == boss and ai.destination == locked and ai.pools.size() == 1 and ai.pools[0].at == SnapshotValues.read_vector(saved.pools[0].position) and ai.pools[0].life <= saved.pools[0].life, "reload changed ownership, locked aim or acid-pool geometry")
	var frozen := ai.save_data()
	await process_frame
	await process_frame
	_check(ai.save_data() == frozen, "pause advanced Schlacko's pools")
	var attack_before := ai.save_data()
	boss._start_boss_phase()
	_check(ai.save_data() == attack_before and actor.is_targetable(), "boss phase cancelled Schlacko's pool or made him immune")
	for phase in [KingPressureTrial.State.INTRODUCTION, KingPressureTrial.State.TRACKING, KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING, KingPressureTrial.State.EXPOSED]:
		court.pressure.state = phase
		_check(actor.is_targetable() and not ai.suspended(), "Schlacko became inactive during the shield trial")
	court.pressure.state = KingPressureTrial.State.TRACKING
	var health: float = game.player.stats.health
	game.player.hurt_time = 0
	ai.advance(0.05)
	_check(not ai.pools.is_empty() and actor.is_targetable() and actor.take_damage(5) > 0, "Schlacko cleared his pool or became immune in the shield trial")
	ai.state = AcidCollector.State.FOLLOW
	ai.remaining = 0
	ai.advance(0.01)
	game.player.global_position = ai.destination
	game.player.hurt_time = 0
	companion.advance(ai.remaining + ai.profile.flight_seconds + 0.01)
	_check(game.player.stats.health < health, "Schlacko stopped firing during the shield trial")
	game._refresh_hud()
	_check(game.hud.retinue_display.rows[0].modulate.a == 1, "active Schlacko retained an invulnerable HUD tint")
	court.pressure.state = KingPressureTrial.State.FINISHED
	court.pressure.used = true
	_check(actor.is_targetable(), "collector stayed invulnerable after the trial")
	var loot_before: int = game.get_node("Loot").get_child_count()
	for call in int(companion.profile.get("max_summons")):
		companion.minion.acid_collector.budget = companion.minion.max_health
		companion.minion.take_damage(1e9)
		companion.advance(float(companion.profile.get("reinforcement_delay")) + 0.01)
		await process_frame
	_check(companion.spawned == 3 and companion.live_minions().is_empty() and game.get_node("Loot").get_child_count() == loot_before, "collector reinforcements or rewards are unbounded")
	companion.spawned = 0
	companion.remaining = 0
	companion.advance(0.01)
	boss.health = 0
	court.cancel()
	game._refresh_hud()
	_check(companion.live_minions().is_empty() and not game.hud.retinue_display.visible and court.acid_wake.streams.is_empty(), "boss death retained a collector or acid hazard")
	_check(not AcidCollector.valid({"pools": [{"position": [1], "life": 3, "cooldown": 0}]}), "invalid collector pool passed validation")
	session.clear_run()
	if failures.is_empty(): print("PASS acid_collector: continuous targetable shield-phase pressure, fixed glob/pool, named HUD, real reload, pause, finite reinforcements and cleanup")
	finish(0 if failures.is_empty() else 1)

func _check_combination(game: Node2D, boss: Enemy, actor: Enemy) -> void:
	var court := boss.acid_king_encounter
	var ai := actor.acid_collector
	court.pressure.used = true
	for corner: Vector2 in [Vector2(60, 60), Vector2(game.arena.arena_size.x - 60, 60), Vector2(60, game.arena.arena_size.y - 60), game.arena.arena_size - Vector2.ONE * 60]:
		for close in [true, false]:
			var safe := false
			for route in 64:
				court.cancel()
				ai.pause_attack() # Reset this isolated route, not the live boss behavior.
				boss.boss_phase = 2
				# Near stomps begin in open space; far stomps also cover corners.
				# A body-sealed corner pocket is not a legal no-contact start.
				var start: Vector2 = game.arena.arena_size * 0.5 if close else corner
				game.player.global_position = start
				game.player.velocity = Vector2.ZERO
				game.player.stats.health = 10000
				game.player.hurt_time = 0
				game.player.dash_moved = false
				game.player.motion_tick = -1
				game.player.get_node("Camera2D").force_update_scroll()
				var inward := corner.direction_to(game.arena.arena_size * 0.5)
				boss.global_position = start + inward * (120 if close else 260)
				actor.global_position = start + inward.rotated(0.2) * 230
				ai.state = AcidCollector.State.FOLLOW
				ai.remaining = 0
				ai.advance(0.001)
				court.begin(AcidKingEncounter.Attack.STOMP)
				var direction := Vector2.from_angle(route * TAU / 32)
				var first_goal := (start + direction * 130).clamp(Vector2.ONE * 48, game.arena.arena_size - Vector2.ONE * 48)
				var goal := first_goal
				var turned := false
				var crossed := false
				for tick in 300:
					var before: Vector2 = game.player.global_position
					if not turned and before.distance_to(first_goal) < 4:
						turned = true
						goal = (before + direction.orthogonal() * (850 if route < 32 else -850)).clamp(Vector2.ONE * 48, game.arena.arena_size - Vector2.ONE * 48)
					game.player.global_position = before.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * 0.72 / 60)
					game.player.velocity = (game.player.global_position - before) * 60
					game.player.get_node("Camera2D").force_update_scroll()
					if Geometry2D.get_closest_point_to_segment(boss.global_position, before, game.player.global_position).distance_to(boss.global_position) <= boss.data.radius + 20:
						crossed = true
						break
					if court.state in [AcidKingEncounter.State.WARN_STOMP, AcidKingEncounter.State.STOMP, AcidKingEncounter.State.CHASE_STOMP]: court.advance(1.0 / 60)
					else:
						court.volley.advance(1.0 / 60, 0)
						court.spit.advance(1.0 / 60, 0)
						ai.advance(1.0 / 60)
					if game.player.stats.health < 10000: break
				if not crossed and game.player.stats.health == 10000:
					safe = true
					break
			_check(safe, "Hell collector/stomp combination has no observed slowed corner escape: %s / close=%s" % [corner, close])
	court.cancel()
	court.pressure.used = false
	boss.boss_phase = 0
	game.player.stats.health = 10000
	game.player.hurt_time = 0
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.velocity = Vector2.ZERO
	game.player.get_node("Camera2D").force_update_scroll()
	boss.global_position = game.player.global_position - Vector2(260, 0)
	actor.global_position = game.player.global_position + Vector2(260, 0)
	ai.state = AcidCollector.State.ARRIVAL
	ai.remaining = ai.profile.arrival_seconds
