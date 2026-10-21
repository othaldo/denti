extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D
var boss: Enemy
var attack: CaramelEncounter

func _initialize() -> void: call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition: return
	failures.append(message)
	push_error(message)

func _fresh() -> void:
	attack.cancel()
	attack.cycle = 0
	boss.boss_phase_timer = 0
	boss.boss_phase = 0
	boss.global_position = Vector2(740, 650)
	game.player.global_position = Vector2(1050, 650)
	game.player.stats.health = 10000
	game.player.hurt_time = 0
	game.player.dodge_time = 0
	game.player.stats.shield_charges = 0
	game.player.dash_moved = false
	game.player.velocity = Vector2.ZERO
	game.player.get_node("Camera2D").force_update_scroll()
	attack.begin()

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://caramel_encounter_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.current_wave = 10
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.max_health = 10000
	game.player.stats.dodge_chance = 0
	game.player.stats.armor = 0
	game.get_node("Enemies").set_physics_process(false)
	game._create_enemy(EnemyCatalog.CAVITY_PRINCE, Vector2(740, 650))
	boss = game.boss
	boss.set_simulation_enabled(false)
	attack = boss.caramel_encounter
	paused = true
	_check(attack != null and attack.rig.bones.size() == 5, "Prince did not replace generic attacks with a skeletal caramel encounter")
	_check(attack.profile.throws_for_phase(0) == 2 and attack.profile.throws_for_phase(1) == 3, "Prince does not progress from two to three throws")
	for step in 61:
		attack.rig.sample(step / 30.0, step / 60.0, step / 60.0, true)
		for bone: Bone2D in attack.rig.bones.values():
			_check(bone.transform.get_scale().is_equal_approx(Vector2.ONE), "Prince animation stretched painted artwork")
	_fresh()
	var aimed := attack.destination
	attack.advance(attack.profile.windup_seconds)
	_check(attack.state == CaramelEncounter.State.FLIGHT and attack.pools.is_empty() and game.player.stats.health == 10000, "windup caused damage or a pool before the projectile landed")
	game.player.global_position += Vector2(0, 160)
	attack.advance(attack.profile.flight_seconds - 0.001)
	_check(attack.destination == aimed and attack.pools.is_empty(), "airborne bomb retargeted Denti or landed early")
	attack.advance(0.002)
	_check(attack.pools.size() == 1 and game.player.stats.health == 10000 and attack.pools[0].at == aimed, "safe sidestep was hit or pool missed the locked destination")
	attack.advance(attack.profile.followup_seconds)
	_check(attack.state == CaramelEncounter.State.WINDUP and attack.destination == game.player.global_position and attack.destination != aimed, "follow-up did not aim again with a full fresh warning")
	game.player.velocity = Vector2.RIGHT * 1000
	attack.throw_index = 1
	attack._warn(-1)
	_check(is_equal_approx(attack.destination.x - game.player.global_position.x, attack.profile.maximum_lead), "predictive second throw exceeded its bounded lead")
	var predicted := attack.destination
	game.player.velocity = Vector2.LEFT * 1000
	attack.advance(0.1)
	_check(attack.destination == predicted, "predictive warning homed after its aim was locked")
	_fresh()
	attack.advance(attack.profile.windup_seconds + attack.profile.flight_seconds)
	var after_hit: float = game.player.stats.health
	_check(after_hit < 10000 and attack.pools.size() == 1, "stationary Denti escaped the actual impact")
	var snapshot := EnemySnapshot.capture(boss)
	EnemySnapshot.restore(boss, snapshot)
	attack.advance(0.1)
	_check(game.player.stats.health == after_hit, "resume duplicated the already resolved impact")
	game.player.global_position = attack.pools[0].at
	var base_speed: float = game.player.stats.move_speed
	_check(is_equal_approx(game.player.floor_movement_factor(), 0.72), "caramel floor did not slow normal movement")
	attack.pools.append(attack.pools[0].duplicate())
	_check(is_equal_approx(game.player.floor_movement_factor(), 0.72) and game.player.stats.move_speed == base_speed, "overlapping pools multiplied slow or changed authoritative stats")
	game.player.global_position += Vector2(0, attack.profile.pool_radius * 0.75)
	_check(game.player.floor_movement_factor() == 1, "slow extends outside the visible flat puddle")
	attack._age_pools(attack.profile.pool_seconds)
	_check(attack.pools.is_empty(), "caramel did not expire at its fixed lifetime")
	attack.state = CaramelEncounter.State.RECOVERY
	attack.remaining = attack.profile.recovery_seconds
	var recovery_position := boss.global_position
	attack.advance(attack.profile.recovery_settle_seconds)
	_check(boss.global_position == recovery_position, "Prince fled during the melee recovery window")
	for phase in [0, 1]:
		_fresh()
		boss.boss_phase = phase
		attack.begin()
		for time in [0.15, 0.60, 1.12, 1.42, 2.9, 4.2]:
			attack.advance(time)
			var before := attack.save_data()
			var entry := EnemySnapshot.capture(boss)
			_check(not RunSaveData.normalize({"wave": 10, "player": {}, "enemies": [entry]}).is_empty(), "valid caramel snapshot was rejected")
			EnemySnapshot.restore(boss, entry)
			if attack.save_data() != before:
				var after := attack.save_data()
				for key in before:
					if before[key] != after[key]: print("roundtrip difference ", key, ": ", before[key], " -> ", after[key])
			_check(attack.save_data() == before, "save/resume lost aim, flight clock, sequence or floor lifetime")
	var frozen := attack.save_data()
	await process_frame
	await process_frame
	_check(attack.save_data() == frozen, "pause advanced a bomb or caramel lifetime")
	# A long frame must sample the dash at the instant of landing, not its end.
	_fresh()
	attack.advance(attack.profile.windup_seconds + attack.profile.flight_seconds - 0.08)
	var centre := attack.destination
	game.player.motion_start = centre + Vector2(-180, 0)
	game.player.motion_end = centre + Vector2(180, 0)
	game.player.global_position = game.player.motion_end
	game.player.motion_tick = Engine.get_physics_frames()
	game.player.dash_motion_seconds = 0.16
	game.player.dash_moved = true
	attack.advance(0.16)
	_check(game.player.stats.health < 10000, "dash skipped impact that occurred halfway through its swept movement")
	_fresh()
	attack.advance(attack.profile.windup_seconds + attack.profile.flight_seconds - 0.3)
	centre = attack.destination
	game.player.motion_start = centre
	game.player.motion_end = centre + Vector2(180, 0)
	game.player.global_position = game.player.motion_end
	game.player.motion_tick = Engine.get_physics_frames()
	game.player.dash_motion_seconds = 0.16
	game.player.dash_moved = true
	attack.advance(0.4)
	_check(game.player.stats.health == 10000, "landing after dash end hit Denti's old position")
	for corner: Vector2 in [Vector2(48, 48), Vector2(game.player.arena.arena_size.x - 48, 48), Vector2(48, game.player.arena.arena_size.y - 48), game.player.arena.arena_size - Vector2.ONE * 48]:
		_fresh()
		game.player.global_position = corner
		attack.begin()
		attack.pools.append({"at": corner, "life": 5.0})
		var escape: Vector2 = corner + corner.direction_to(game.player.arena.arena_size * 0.5) * 130
		for tick in 66:
			game.player.global_position = game.player.global_position.move_toward(escape, PlayerStats.BASE_MOVE_SPEED * game.player.floor_movement_factor() / 60)
			attack.advance(1.0 / 60)
		_check(game.player.stats.health == 10000, "corner warning has no baseline-speed escape even without dash")
	_fresh()
	game._create_enemy(EnemyCatalog.CAVITY_PRINCE, Vector2(1400, 650))
	var second: Enemy = game.boss
	second.set_simulation_enabled(false)
	var other := second.caramel_encounter
	for index in 12:
		var source := attack if index % 2 == 0 else other
		source.destination = Vector2(500 + index * 30, 500)
		source._land(-1)
		_check(attack.pools.size() + other.pools.size() <= attack.profile.max_pools, "double-Prince exceeded the shared floor budget")
	var second_snapshot := EnemySnapshot.capture(second)
	EnemySnapshot.restore(second, second_snapshot)
	_check(attack.pools.size() + other.pools.size() <= attack.profile.max_pools, "double-Prince resume exceeded the shared floor budget")
	attack.cancel()
	other.cancel()
	attack.begin()
	other.remaining = 0
	other.advance(0.01)
	_check(other.state == CaramelEncounter.State.APPROACH, "two Princes launched an unreserved simultaneous volley")
	attack.advance(0.75)
	BossAttackController.start_boss_phase(boss)
	_check(attack.state == CaramelEncounter.State.APPROACH and boss.boss_phase_burst_fired, "health phase retained an airborne attack or generic projectile burst")
	EnemySnapshot.restore(boss, {"health": boss.max_health})
	_check(attack.state == CaramelEncounter.State.APPROACH and attack.pools.is_empty(), "old Prince save did not start a safe fresh warning")
	for bad in [{"origin": [1]}, {"pools": [{"position": [0, "bad"], "life": 1}]}, {"remaining": "bad"}, {"pools": [{}]}]:
		_check(RunSaveData.normalize({"wave": 10, "player": {}, "enemies": [{"caramel": bad}]}).is_empty(), "malformed caramel state passed save validation")
	# The real coordinator must preserve a flight and floor fields together.
	_fresh()
	attack.pools.append({"at": Vector2(1100, 720), "life": 3.25})
	attack.advance(0.72)
	var saved_flight := attack.save_data()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	boss = game.boss
	attack = boss.caramel_encounter
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	boss.set_simulation_enabled(false)
	paused = true
	_check(attack.state == CaramelEncounter.State.FLIGHT and attack.destination == SnapshotValues.read_vector(saved_flight.destination) and attack.pools.size() == 1 and absf(attack.remaining - float(saved_flight.remaining)) < 0.05, "actual game save/resume lost the projectile or caramel fields")
	# On a portrait viewport a distant Prince must first enter the view.
	root.size = Vector2i(320, 568)
	root.content_scale_size = root.size
	game.player.global_position = Vector2(1050, 650)
	for frame in 3: await process_frame
	attack.cancel()
	boss.global_position = Vector2(750, 650)
	var moved_from := boss.global_position
	attack.advance(0.10)
	_check(boss.global_position.distance_to(game.player.global_position) < moved_from.distance_to(game.player.global_position), "portrait Prince kept cooking outside the visible arena")
	var narrow_bounds := attack._cooking_bounds()
	_check(narrow_bounds.size.x <= 150, "portrait cooking bounds retained a desktop-wide horizontal range")
	attack.remaining = 0
	attack.advance(0.001)
	_check(attack.state == CaramelEncounter.State.APPROACH, "offscreen Prince began an unseen throw")
	attack.pools.append({"at": game.player.global_position, "life": 5.0})
	boss.boss_damage_budget = boss.max_health * 10
	boss.boss_phase = 2
	boss.take_damage(1e9)
	_check(boss.dying and attack.pools.is_empty() and attack.state == CaramelEncounter.State.APPROACH, "boss death left live caramel or an invisible pending bomb")
	session.clear_run()
	if failures.is_empty(): print("PASS caramel_encounter: aim/flight, exact impacts, no stacking, bounded shared pools, phases, death, pause, legacy saves, snapshots and swept dash timing")
	finish(0 if failures.is_empty() else 1)
