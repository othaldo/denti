extends "res://tests/support/test_runtime.gd"
## Full warning-aware sequences, including surviving projectiles between attacks.
const STEP := 1.0 / 60
const SPEED := PlayerStats.BASE_MOVE_SPEED * 0.72
const HEALTH := 100000.0
var game: Node2D
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")

func _warning(a: AcidKingEncounter) -> bool:
	return a.state in [a.State.WARN_CHANNEL, a.State.WARN_SHIFT, a.State.WARN_SPIT, a.State.WARN_STOMP]

# Replay the real collision/clock until the next new warning. This only selects
# a response to the current announcement; it never dodges an unannounced target.
func _travel(boss: Enemy, goal: Vector2) -> Dictionary:
	var a := boss.acid_king_encounter
	var initial := a.state
	var left_warning := false
	var tail := initial == a.State.OPEN
	for tick in 420:
		var player: Player = game.player
		var before := player.global_position
		player.global_position = before.move_toward(goal, SPEED * STEP)
		player.velocity = (player.global_position - before) / STEP
		player.get_node("Camera2D").force_update_scroll()
		if Geometry2D.get_closest_point_to_segment(boss.global_position, before, player.global_position).distance_to(boss.global_position) <= boss.data.radius + 20: return {}
		if tail:
			a._tick_fields(STEP, 0)
			a.volley.advance(STEP, 0)
			a.spit.advance(STEP, 0)
		else: a.advance(STEP)
		if player.stats.health < HEALTH: return {}
		if player.global_position.distance_to(boss.global_position) <= boss.data.radius + 20: return {}
		if a.state != initial: left_warning = true
		if tail and a.fields.is_empty() and a.volley.entries.is_empty() and a.spit.entries.is_empty(): return {"complete": true}
		if not tail and (a.state == a.State.OPEN or left_warning and (_warning(a) or a.state in [a.State.PURSUE, a.State.CHASE_STOMP])): return {"complete": false}
	return {}

func _reset_trial(boss: Enemy, saved: Dictionary, at: Vector2, velocity: Vector2) -> void:
	EnemySnapshot.restore(boss, saved)
	boss.position = SnapshotValues.read_vector(saved.position)
	game.player.global_position = at
	game.player.velocity = velocity
	game.player.stats.health = HEALTH
	game.player.hurt_time = 0

func _route(boss: Enemy, depth: int = 0) -> bool:
	if depth >= 24: return false
	var saved := EnemySnapshot.capture(boss)
	var at: Vector2 = game.player.global_position
	var velocity: Vector2 = game.player.velocity
	var candidates: Array[Dictionary] = []
	# A legal response may stop on a bank before the second river. A pilot
	# restricted to 260-unit moves overshoots that bank even when humans can
	# simply release movement. Keep the same real hazards/body-clearance checks.
	for index in 64:
		_reset_trial(boss, saved, at, velocity)
		var distance := 130 if index < 32 else 260
		var goal: Vector2 = (at + Vector2.from_angle(index * TAU / 32) * distance).clamp(Vector2.ONE * 48, game.arena.arena_size - Vector2.ONE * 48)
		var result := _travel(boss, goal)
		if result.is_empty(): continue
		if result.complete: return true
		var end: Vector2 = game.player.global_position
		var edge := minf(minf(end.x, end.y), minf(game.arena.arena_size.x - end.x, game.arena.arena_size.y - end.y))
		var score := minf(edge, 250) - absf(end.distance_to(boss.global_position) - 280) * 0.15
		candidates.append({"goal": goal, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	# Try other legal banks when a first safe response leads into a later corner.
	for candidate in candidates:
		_reset_trial(boss, saved, at, velocity)
		var result := _travel(boss, candidate.goal)
		if not result.is_empty() and (result.complete or _route(boss, depth + 1)): return true
	_reset_trial(boss, saved, at, velocity)
	return false

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://king_assault_routes_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.max_health = HEALTH
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var cases := 0
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		boss.configure(EnemyCatalog.CAVITY_KING, game.player, 15, difficulty.id)
		game.get_node("Enemies").add_child(boss)
		boss.set_simulation_enabled(false)
		boss.boss_phase = 2
		var a := boss.acid_king_encounter
		for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
			root.size = extent
			root.content_scale_size = extent
			await process_frame
			await process_frame
			for corner: Vector2 in [Vector2(48, 48), Vector2(game.arena.arena_size.x - 48, 48), Vector2(48, game.arena.arena_size.y - 48), game.arena.arena_size - Vector2.ONE * 48]:
				for kind in ([a.Attack.CHANNELS, a.Attack.STOMP, a.Attack.TIDE] if extent.x == 1280 else [a.Attack.CHANNELS, a.Attack.TIDE]):
					a.cancel()
					a.cycle = 0
					game.player.global_position = corner
					game.player.velocity = Vector2.ZERO
					game.player.stats.health = HEALTH
					game.player.hurt_time = 0
					game.player.dash_moved = false
					boss.global_position = corner + corner.direction_to(game.arena.arena_size * 0.5) * 260
					game.player.get_node("Camera2D").force_update_scroll()
					a.begin(kind)
					if not _route(boss): failures.append("%s complete attack %d has no observed slowed route from %s at %s (state %d)" % [difficulty.id, kind, corner, extent, a.state])
					cases += 1
		boss.free()
		print("Completed routes: ", difficulty.id)
	game.free()
	paused = false
	session.clear_run()
	for message in failures: push_error(message)
	if failures.is_empty(): print("PASS king_assault_routes: %d complete fan/river/stomp sequences, 72%% speed, all tiers, corners and three viewports, including projectile tails and body clearance" % cases)
	finish(0 if failures.is_empty() else 1)
