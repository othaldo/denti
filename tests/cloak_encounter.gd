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

func _reset() -> CloakEncounter:
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	game.get_node("Enemies").set_physics_process(false)
	player.global_position = Vector2(900, 600)
	player.stats.max_health = 10000
	player.stats.health = 10000
	player.stats.armor = 0
	player.stats.shield_charges = 0
	player.stats.dodge_chance = 0
	player.hurt_time = 0
	player.dodge_time = 0
	player.dash_moved = false
	player.dash.reset_wave()
	game._create_enemy(EnemyCatalog.CAVITY_COUNT, player.global_position - Vector2(150, 0))
	boss = game.boss
	boss.set_simulation_enabled(false)
	return boss.cloak_encounter

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://cloak_encounter_test.json"
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
	var attack := _reset()
	_check(boss.pillow_encounter == null and attack.rig.skeleton.get_bone_count() == 12 and boss.sprite.texture == null, "canonical Graf does not use its rig encounter")
	attack.begin()
	var hp := player.stats.health
	var origin := attack.origin
	var direction := attack.direction
	var planted := boss.global_position
	attack.advance(attack.profile.warning_seconds - 0.001)
	_check(player.stats.health == hp, "cloak hit during its warning")
	player.global_position += Vector2(0, 240)
	attack.advance(0.15)
	_check(attack.origin == origin and attack.direction == direction and player.stats.health == hp, "locked warning followed the player or hit a safe side")
	_check(boss.global_position == planted, "Graf moved an announced strike")
	# Maximise the shortest escape: side and outer arc should be equally far.
	attack = _reset()
	var ideal := attack.profile.placement_distance(player.global_position, player.arena.arena_size)
	var angle := attack.profile.half_angle_at(player.global_position, player.arena.arena_size)
	var side_exit := ideal * sin(angle) + HazardGeometry.PLAYER_RADIUS
	var arc_exit := attack.profile.reach - ideal + HazardGeometry.PLAYER_RADIUS
	_check(is_equal_approx(side_exit, arc_exit), "placement does not balance the shortest side and arc exits")
	for distance in range(80, 341, 5):
		var escape := minf(distance * sin(angle), attack.profile.reach - distance) + HazardGeometry.PLAYER_RADIUS
		_check(escape <= side_exit + 0.001, "another distance gives a longer minimum escape than the chosen placement")
	_check(side_exit / PlayerStats.BASE_MOVE_SPEED < attack.profile.followup_warning_seconds, "optimal placement removed the ordinary movement escape")
	# Approach can advance OR retreat, and gets in position before announcing.
	for initial_distance in [110.0, 500.0]:
		attack = _reset()
		boss.global_position = player.global_position - Vector2(initial_distance, 0)
		attack.remaining = 0
		for tick in 240:
			var previous := boss.global_position
			attack.advance(1.0 / 60.0)
			_check(previous.distance_to(boss.global_position) <= boss._movement_speed() * attack.profile.chase_factor / 60.0 + 0.01, "placement teleported the Graf")
			if attack.active: break
		_check(attack.state == CloakEncounter.State.WARNING and absf(boss.global_position.distance_to(player.global_position) - ideal) <= attack.profile.position_tolerance + 0.01, "Graf announced before reaching useful placement")
	attack = _reset()
	boss.global_position = player.global_position - Vector2(110, 0)
	attack.remaining = 0
	for tick in 90:
		player.global_position = player.global_position.move_toward(boss.global_position, PlayerStats.BASE_MOVE_SPEED / 60.0)
		attack.advance(1.0 / 60.0)
		if attack.active: break
	_check(attack.state == CloakEncounter.State.WARNING and attack.elapsed == 0, "a pursuing melee player made the Graf retreat forever")
	# Between strikes he improves placement rather than adding an arbitrary flank.
	attack = _reset()
	boss.global_position = player.global_position - Vector2(110, 0)
	attack.begin()
	attack.advance(attack.profile.warning_seconds + attack.profile.strike_seconds)
	var before_step := boss.global_position
	attack.advance(attack.profile.step_seconds)
	_check(boss.global_position.distance_to(before_step) > 35 and boss.global_position.distance_to(player.global_position) > 175, "Graf did not retreat enough to lengthen the escape route")
	_check(attack.state == CloakEncounter.State.WARNING and attack.remaining > 0.7 and attack.origin == boss.global_position, "repositioning lost the new full locked warning")
	# A short breath stays safe; only its latter portion gently closes distance.
	attack = _reset()
	attack.state = CloakEncounter.State.RECOVERY
	attack.remaining = attack.profile.recovery_seconds
	player.global_position += Vector2(500, 0)
	planted = boss.global_position
	attack.advance(attack.profile.recovery_settle_seconds)
	_check(boss.global_position == planted, "Graf no longer takes his recovery breath")
	attack.advance(0.2)
	var travel := planted.distance_to(boss.global_position)
	_check(travel > 10 and travel < 35, "recovery pursuit is missing or too fast")
	_check(player.stats.health == 10000, "non-attacking footwork caused cloak damage")
	# Standing still or dashing in the active sector uses normal damage/shields.
	attack = _reset()
	player.stats.shield_charges = 3
	attack.begin()
	attack.advance(attack.profile.warning_seconds + 0.06)
	_check(player.stats.shield_charges == 2 and attack.hit_mask == 1, "cloak strike missed the shield or used an unrelated damage path")
	var saved := boss.save_state()
	boss.restore_state(saved)
	attack.advance(0.02)
	_check(player.stats.shield_charges == 2, "resume repeated an already consumed strike")
	attack = _reset()
	var impacts := [0]
	boss.attack_performed.connect(func(kind: StringName):
		if kind == &"boss_pulse": impacts[0] += 1
	)
	attack.begin()
	attack.advance(attack.profile.warning_seconds)
	attack.advance(attack.profile.hit_start)
	attack.advance(0.01)
	_check(impacts[0] == 1, "an exact hit-window boundary repeated the impact feedback")
	# A new aim follows the short visible step, not the original player position.
	attack = _reset()
	attack.begin()
	player.global_position += Vector2(0, 190)
	attack.advance(attack.profile.warning_seconds + attack.profile.strike_seconds + attack.profile.step_seconds)
	_check(attack.state == CloakEncounter.State.WARNING and attack.strike_index == 1 and attack.remaining > 0.7, "follow-up lost its full warning")
	_check(absf(direction.angle_to(attack.direction)) > 0.4, "follow-up reused the first direction")
	_check(attack.count == 2, "first phase lacks the basic double strike")
	boss.boss_phase = 1
	attack.begin()
	_check(attack.count == 3, "later phase lacks the third strike")
	attack = _reset()
	attack.begin()
	player.global_position += Vector2(800, 0)
	attack.advance(attack.profile.warning_seconds + attack.profile.strike_seconds * 2 + attack.profile.step_seconds + attack.profile.followup_warning_seconds)
	_check(attack.state == CloakEncounter.State.RECOVERY, "double strike did not open recovery")
	var rest_before := attack.remaining
	boss.start_overtime()
	boss.advance_overtime(10)
	attack.advance(0.2)
	_check(is_equal_approx(rest_before - attack.remaining, 0.28), "overtime failed to shorten recovery while preserving warning timing")
	# Every point in the cone has a side or outward route within the shortest warning.
	var alpha := deg_to_rad(attack.profile.half_angle_degrees)
	for radius in [80.0, 120.0, 160.0, 210.0, 260.0, 330.0]:
		var escape := minf(radius * sin(alpha) + 25, attack.profile.reach - radius + 25)
		_check(escape / PlayerStats.BASE_MOVE_SPEED < attack.profile.followup_warning_seconds, "base movement cannot escape a locked sector")
	# Exact swept-sector checks catch a crossing dash but reject earlier positions.
	var center := Vector2(600, 500)
	player.motion_tick = Engine.get_physics_frames()
	player.dash_moved = true
	player.dash_motion_seconds = 0.16
	player.motion_start = center + Vector2(180, -230)
	player.motion_end = center + Vector2(180, 230)
	_check(HazardGeometry.swept_sector(player, center, Vector2.RIGHT, 340, alpha, 0, 0.16), "dash tunneled through the active sector")
	_check(not HazardGeometry.swept_sector(player, center, Vector2.RIGHT, 340, alpha, 0.15, 0.20), "strike damaged an earlier dash position")
	player.motion_start.x -= 400
	player.motion_end.x -= 400
	_check(not HazardGeometry.swept_sector(player, center, Vector2.RIGHT, 340, alpha, 0, 0.16), "dash behind the boss hit the front sector")
	attack = _reset()
	attack.begin()
	attack.advance(attack.profile.warning_seconds)
	player.motion_tick = Engine.get_physics_frames()
	player.dash_moved = true
	player.dash.remaining = 0.1
	player.dash_motion_seconds = 0.16
	player.motion_start = attack.origin + Vector2(180, -230)
	player.motion_end = attack.origin + Vector2(180, 230)
	player.global_position = player.motion_end
	attack.advance(0.16)
	_check(player.stats.health < 10000, "active dash incorrectly ignored actual cloak damage")
	# Narrower locked warnings at walls retain an ordinary movement route.
	attack = _reset()
	var arena := player.arena.arena_size
	for side in [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]:
		player.global_position = Vector2(48 if side.x > 0 else arena.x - 48, 48 if side.y > 0 else arena.y - 48)
		boss.global_position = player.global_position + side * 150
		var placement := attack._placement_goal()
		var margin := DentiArena.WALL_WIDTH + boss.data.radius + 6
		_check(placement == placement.clamp(Vector2.ONE * margin, arena - Vector2.ONE * margin), "placement put Graf outside the arena")
		_check(absf(placement.distance_to(player.global_position) - attack.profile.placement_distance(player.global_position, arena)) < 0.01, "wall placement lost its optimal distance")
		boss.global_position = placement
		boss.boss_phase = 1
		attack.begin()
		attack.strike_index = 1
		attack._warn(player.global_position)
		var safe := false
		for index in 32:
			var goal := player.global_position + Vector2.RIGHT.rotated(TAU * float(index) / 32) * PlayerStats.BASE_MOVE_SPEED * attack.profile.followup_warning_seconds
			goal = goal.clamp(Vector2.ONE * 48, arena - Vector2.ONE * 48)
			var near_boss := Geometry2D.get_closest_point_to_segment(boss.global_position, player.global_position, goal).distance_to(boss.global_position) < 70
			if not near_boss and not HazardGeometry.circle_sector(goal, attack.origin, attack.direction, attack.profile.reach, attack.half_angle): safe = true
		_check(safe, "corner warning leaves no base-speed route")
	_test_variants()
	# State, aim, consumed hits and sampled bones survive every stage.
	for time in [0.4, 0.92, 1.14, 1.29, 1.7, 2.4, 3.5]:
		attack = _reset()
		boss.boss_phase = 1
		attack.begin()
		player.global_position += Vector2(500, 0)
		attack.advance(time)
		var expected := attack.save_data()
		var pose := attack.rig.bones[&"LeftShoulder"].rotation
		var foot_pose := attack.rig.bones[&"LeftFoot"].transform
		boss.restore_state(boss.save_state())
		_check(attack.save_data() == expected and is_equal_approx(attack.rig.bones[&"LeftShoulder"].rotation, pose), "resume changed cloak state or pose at %.2f" % time)
		_check(attack.rig.bones[&"LeftFoot"].transform.is_equal_approx(foot_pose), "resume changed the movement pose at %.2f" % time)
	var snapshot := RunSnapshot.capture(game)
	_check(session.save_run(snapshot) == OK, "cloak snapshot was not accepted")
	var expected := attack.save_data()
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	player = game.player
	boss = game.boss
	attack = boss.cloak_encounter
	game.get_node("Enemies").set_physics_process(false)
	player.set_physics_process(false)
	var restored := attack.save_data()
	for key in expected:
		var same: bool = is_equal_approx(float(restored[key]), float(expected[key])) if key in ["remaining", "elapsed"] else restored[key] == expected[key]
		_check(same, "full scene restart lost cloak field: %s" % key)
	paused = true
	var frozen := attack.save_data()
	for frame in 3: await process_frame
	_check(attack.save_data() == frozen, "pause advanced the encounter")
	paused = false
	var legacy := boss.save_state()
	legacy.erase("cloak")
	legacy.pillow = {"active": true, "elapsed": 2.2}
	boss.restore_state(legacy)
	_check(not attack.active and attack.remaining > 0 and boss.special_phase == Enemy.SpecialPhase.COOLDOWN, "old pillow save became an unannounced strike")
	var malformed := RunSnapshot.capture(game)
	malformed.enemies[0].cloak.origin = ["invalid", 0]
	_check(RunSaveData.normalize(malformed).is_empty(), "malformed cloak vectors were accepted")
	malformed = RunSnapshot.capture(game)
	malformed.enemies[0].cloak.variant = "ring"
	_check(RunSaveData.normalize(malformed).is_empty(), "malformed cloak variant was accepted")
	attack.begin()
	boss._start_boss_phase()
	_check(not attack.active and boss.boss_phase_burst_fired, "health phase did not cancel the strike")
	boss.boss_phase_timer = 0
	attack.begin()
	game._create_enemy(EnemyCatalog.CAVITY_COUNT, player.global_position + Vector2(150, 0))
	var other: Enemy = game.get_node("Enemies").get_child(-1)
	other.set_simulation_enabled(false)
	other.cloak_encounter.remaining = 0
	other.cloak_encounter.advance(0.01)
	_check(not other.cloak_encounter.active, "two counts closed all routes with simultaneous sequences")
	boss.boss_phase = 2
	boss.boss_phase_timer = 0
	boss.boss_damage_budget = boss.max_health
	boss.take_damage(1e9)
	_check(boss.dying and not attack.active, "dead Graf left an active strike")
	game.free()
	session.clear_run()
	if failures.is_empty(): print("PASS cloak_encounter: rig, timing, re-aim, swept dash, shields, phases, save, pause and death")
	finish(0 if failures.is_empty() else 1)

func _test_variants() -> void:
	var attack := _reset()
	attack.begin()
	attack.advance(attack.profile.warning_seconds + attack.profile.strike_seconds + attack.profile.step_seconds)
	_check(attack.variant == CloakStrikeData.Kind.THRUST, "first pair does not introduce the narrow thrust")
	attack.begin()
	attack.advance(attack.profile.warning_seconds + attack.profile.strike_seconds + attack.profile.step_seconds)
	_check(attack.variant == CloakStrikeData.Kind.RING, "second pair does not alternate to the ring")
	for kind in [CloakStrikeData.Kind.FAN, CloakStrikeData.Kind.THRUST, CloakStrikeData.Kind.RING]:
		attack = _reset()
		boss.boss_phase = 1
		attack.begin()
		attack.strike_index = kind
		var radius := attack.profile.placement_distance(player.global_position, player.arena.arena_size, kind)
		boss.global_position = player.global_position - Vector2(radius, 0)
		attack._warn(player.global_position)
		_check(attack.variant == kind, "later triple does not contain each announced shape")
		var saved := attack.save_data()
		boss.restore_state(boss.save_state())
		_check(attack.save_data() == saved, "restoring changed the announced variant")
		attack.advance(attack.profile.warning(kind))
		_check(player.stats.health == 10000, "a new shape damaged during warning")
		attack.advance(0.06)
		_check(player.stats.health < 10000, "the interior of a new shape failed to hit")
		var hp := player.stats.health
		boss.restore_state(boss.save_state())
		attack.advance(0.03)
		_check(player.stats.health == hp, "a new shape hit twice after resuming")
		# At the wall, every shape still offers a route that stops clear of the boss.
		for side in [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]:
			var arena := player.arena.arena_size
			player.global_position = Vector2(48 if side.x > 0 else arena.x - 48, 48 if side.y > 0 else arena.y - 48)
			var distance := attack.profile.placement_distance(player.global_position, arena, kind)
			boss.global_position = player.global_position + side.normalized() * distance
			attack._warn(player.global_position)
			var shape := attack.profile.strike(kind)
			var safe := false
			for index in 32:
				for fraction in [0.35, 0.65, 1.0]:
					var goal: Vector2 = player.global_position + Vector2.RIGHT.rotated(TAU * index / 32.0) * PlayerStats.BASE_MOVE_SPEED * attack.profile.warning(kind) * fraction
					goal = goal.clamp(Vector2.ONE * 48, arena - Vector2.ONE * 48)
					var near_boss := Geometry2D.get_closest_point_to_segment(boss.global_position, player.global_position, goal).distance_to(boss.global_position) < 70
					var danger := HazardGeometry.circle_ring(goal, attack.origin, shape.inner_radius, shape.reach) if kind == CloakStrikeData.Kind.RING else HazardGeometry.circle_sector(goal, attack.origin, attack.direction, shape.reach, attack.half_angle)
					if not near_boss and not danger: safe = true
			_check(safe, "new shape leaves no ordinary movement route at a corner")
	attack = _reset()
	var center := Vector2(600, 500)
	var thrust := attack.profile.strike(CloakStrikeData.Kind.THRUST)
	_check(HazardGeometry.circle_sector(center + Vector2(400, 0), center, Vector2.RIGHT, thrust.reach, deg_to_rad(14)), "thrust lacks its longer reach")
	_check(not HazardGeometry.circle_sector(center + Vector2(200, 100), center, Vector2.RIGHT, thrust.reach, deg_to_rad(14)), "thrust is not narrower than the fan")
	_check(not HazardGeometry.circle_ring(center + Vector2(90, 0), center, 130, 290), "ring damaged its safe core")
	_check(not HazardGeometry.circle_ring(center + Vector2(320, 0), center, 130, 290), "ring damaged outside its outer edge")
	player.motion_tick = Engine.get_physics_frames()
	player.dash_moved = true
	player.dash_motion_seconds = 0.16
	player.motion_start = center + Vector2(400, 0)
	player.motion_end = center
	_check(HazardGeometry.swept_ring(player, center, 130, 290, 0, 0.16), "dash tunneled through the ring into its safe core")
	_check(not HazardGeometry.swept_ring(player, center, 130, 290, 0.15, 0.16), "ring hit a dash before the actual damage window")
	player.dash_moved = false
