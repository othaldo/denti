extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D
var boss: Enemy
var player: Player

func _initialize() -> void: call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _reset() -> PillowEncounter:
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	game.get_node("Enemies").set_physics_process(false)
	player.global_position = Vector2(700, 500)
	player.stats.max_health = 10000
	player.stats.health = 10000
	player.stats.armor = 0
	player.stats.shield_charges = 0
	player.stats.dodge_chance = 0
	player.hurt_time = 0
	player.dodge_time = 0
	player.dash_moved = false
	player.dash.reset_wave()
	game._create_enemy(EnemyCatalog.CAVITY_COUNT, player.global_position + Vector2(300, 0))
	boss = game.boss
	boss.set_simulation_enabled(false)
	return boss.pillow_encounter

func _run() -> void:
	var count_source: EnemyData = EnemyCatalog.CAVITY_COUNT
	var original_cloak := count_source.cloak_profile
	count_source.cloak_profile = null
	count_source.pillow_profile = load("res://data/encounters/count_pillow.tres")
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://pillow_encounter_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.set_process(false)
	game.wave.current_wave = 5
	player = game.player
	player.loadout.restore([])
	player.set_physics_process(false)
	var encounter := _reset()
	encounter.begin()
	var locked := encounter.origin
	var hp := player.stats.health
	encounter.advance(encounter.profile.warning_seconds - 0.001)
	_check(player.stats.health == hp, "pillow dealt damage before its warning ended")
	player.global_position.x += 180
	encounter.advance(0.002)
	_check(encounter.origin == locked and player.stats.health == hp, "pillow followed the player or ignored the free side")
	encounter = _reset()
	encounter.begin()
	player.dash.remaining = 0.1
	encounter.advance(encounter.profile.warning_seconds)
	_check(player.stats.health < hp, "pillow impact missed a player remaining in the marked rectangle or dash gave immunity")
	encounter = _reset()
	encounter.begin()
	player.global_position += encounter.forward * 200
	encounter.advance(encounter.profile.warning_seconds + encounter.profile.fold_delay)
	_check(player.stats.health == hp, "fold hit before reaching the player")
	encounter.advance(encounter.profile.fold_seconds)
	_check(player.stats.health < hp and not encounter.active, "long frame skipped the traveling fold or failed to end the sequence")
	# One hit per hazard; shield hits do not spend another charge every frame.
	encounter = _reset()
	player.stats.shield_charges = 3
	encounter.begin()
	encounter.advance(encounter.profile.warning_seconds)
	_check(player.stats.shield_charges == 2, "slam did not use normal shield handling")
	encounter.advance(encounter.profile.fold_delay + 0.01)
	_check(player.stats.shield_charges == 1, "fold did not use normal shield handling")
	encounter.advance(0.01)
	_check(player.stats.shield_charges == 1, "same fold consumed a second shield")
	var already_hit := boss.save_state()
	boss.restore_state(already_hit)
	encounter.advance(0.01)
	_check(player.stats.shield_charges == 1, "resumed fold repeated an already consumed shield hit")
	# Relative sweeps catch dashes crossing the ridge, split at dash end.
	var center := Vector2(500, 400)
	player.motion_tick = Engine.get_physics_frames()
	player.dash_moved = true
	player.dash_motion_seconds = 0.16
	player.motion_start = center + Vector2(-100, 0)
	player.motion_end = center + Vector2(100, 0)
	_check(HazardGeometry.moving_box(player, center, center, Vector2(10, 50), 0, 0.3), "dash tunneled through a fold during a long frame")
	_check(not HazardGeometry.circle_box(HazardGeometry.player_at(player, 0.2), Rect2(center - Vector2(10, 50), Vector2(20, 100))), "later impact damaged a past dash position")
	player.motion_start.y += 100
	player.motion_end.y += 100
	_check(not HazardGeometry.moving_box(player, center, center, Vector2(10, 50), 0, 0.3), "safe parallel dash hit an unrelated fold")
	# Later sequences preserve a generous corridor even at walls and corners.
	encounter = _reset()
	boss.boss_phase = 1
	for at in [Vector2(48, 48), Vector2(48, 1750), Vector2(1750, 48), Vector2(1750, 1750), Vector2(700, 500)]:
		player.global_position = at.clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
		for cycle_index in 2:
			encounter.begin()
			_check(encounter.count == 2, "later phase lacks the second staggered pillow")
			_check(not encounter.slam_rect(0).grow(20).intersects(encounter.slam_rect(1).grow(20)), "staggered pillows close the safe corridor")
			_check(absf(encounter.second_offset) - encounter.profile.lane_width >= 100, "safe corridor is too narrow")
			for lane in 2:
				_check(Rect2(Vector2.ZERO, player.arena.arena_size).encloses(encounter.slam_rect(lane)), "corner attack left the arena")
	# A base-speed player can leave the first targeted strip before activation.
	_check((encounter.profile.lane_width * 0.5 + HazardGeometry.PLAYER_RADIUS + 5) / PlayerStats.BASE_MOVE_SPEED < encounter.profile.warning_seconds, "base movement cannot avoid the first pillow without dash")
	encounter = _reset()
	encounter.begin()
	boss._start_boss_phase()
	_check(not encounter.active and boss.boss_phase_burst_fired, "health phase failed to cancel the active attack or kept generic radial warnings")
	# Save every attack segment without rerolling positions or repeating damage.
	for time in [0.5, 1.4, 2.2, 3.1]:
		encounter = _reset()
		boss.boss_phase = 1
		encounter.begin()
		player.global_position.x += 600
		encounter.advance(time)
		var saved := boss.save_state()
		var expected := encounter.save_data()
		boss.restore_state(saved)
		_check(encounter.save_data() == expected, "resume changed the announced pillow segment at %.1f s" % time)
	var snapshot := RunSnapshot.capture(game)
	_check(session.save_run(snapshot) == OK, "pillow run could not be saved")
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	player = game.player
	boss = game.boss
	encounter = boss.pillow_encounter
	_check(encounter.active and is_equal_approx(encounter.elapsed, 3.1) and encounter.count == 2, "scene restart lost the active fold")
	game.get_node("Enemies").set_physics_process(false)
	player.set_physics_process(false)
	paused = true
	var saved_time := encounter.elapsed
	for frame in 4: await process_frame
	_check(encounter.elapsed == saved_time, "pause advanced the pillow sequence")
	paused = false
	# Legacy saves get a full warning, never a migrated invisible old charge.
	var old := boss.save_state()
	old.erase("pillow")
	old.phase = Enemy.SpecialPhase.ACTIVE
	boss.restore_state(old)
	_check(not encounter.active and encounter.cooldown > 0 and boss.special_phase == Enemy.SpecialPhase.COOLDOWN, "legacy charge became an unannounced pillow")
	var malformed := RunSnapshot.capture(game)
	malformed.enemies[0].pillow.origin = ["invalid", 2]
	_check(RunSaveData.normalize(malformed).is_empty(), "malformed pillow origin was accepted")
	# Two count encounters serialize their hazards rather than closing both sides.
	encounter.begin()
	game._create_enemy(EnemyCatalog.CAVITY_COUNT, player.global_position + Vector2(500, 0))
	var other: Enemy = game.get_node("Enemies").get_child(-1)
	other.set_simulation_enabled(false)
	other.pillow_encounter.cooldown = 0
	other.pillow_encounter.advance(0.1)
	_check(not other.pillow_encounter.active, "two counts announced overlapping sequences")
	encounter.cancel()
	other.pillow_encounter.advance(0.1)
	_check(other.pillow_encounter.active and other.pillow_encounter.elapsed == 0, "waiting count lost its full warning")
	other.boss_phase = 2
	other.boss_phase_timer = 0
	other.boss_damage_budget = other.max_health
	other.take_damage(1e9)
	_check(other.dying and not other.pillow_encounter.active, "dead count left active pillow hazards")
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty(): print("Pillow boss warnings, swept damage, safe routes, shields, phases, pause, death and save compatibility passed")
	count_source.cloak_profile = original_cloak
	count_source.pillow_profile = null
	finish(0 if failures.is_empty() else 1)
