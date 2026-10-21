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

func _start(kind: int, phase := 0) -> void:
	attack.cancel()
	attack.cycle = 0
	boss.boss_phase = phase
	boss.boss_phase_timer = 0
	boss.contact_timer = 0
	boss.global_position = Vector2(740, 650)
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.stats.health = 10000
	game.player.stats.shield_charges = 0
	game.player.hurt_time = 0
	game.player.dash_moved = false
	game.player.get_node("Camera2D").force_update_scroll()
	attack.begin(-1, kind)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://prince_variants_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
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
	_start(CaramelEncounterData.Attack.BOMBS)
	var seen := {}
	for tick in 1800:
		seen[attack.attack_kind] = true
		game.player.hurt_time = maxf(game.player.hurt_time - 1.0 / 60, 0)
		attack.advance(1.0 / 60)
	_check(seen.size() == 3, "first health phase still repeats only one attack")
	_start(CaramelEncounterData.Attack.HEART_FAN)
	var locked := attack.rays.duplicate()
	game.player.global_position += Vector2(0, 200)
	attack.advance(attack.profile.heart_warning_seconds - 0.001)
	_check(attack.hearts.entries.is_empty() and attack.rays == locked, "heart fan fired early or tracked Denti after its warning")
	attack.advance(0.001)
	_check(attack.hearts.entries.size() == attack.profile.fan_count(0), "first fan did not emit its announced number of hearts")
	for index in attack.hearts.entries.size():
		_check(attack.hearts.entries[index].velocity.is_equal_approx(locked[index] * attack.profile.heart_speed), "heart velocity differs from the marked ray")
	_check(attack.hearts.get_child_count() == 0, "heart fan allocates a scene node for every projectile")
	_start(CaramelEncounterData.Attack.HEART_FAN)
	game.player.global_position += Vector2(0, 400)
	var ray: Vector2 = attack.rays[0]
	var launch_origin := boss.global_position
	attack.advance(attack.profile.heart_warning_seconds + 0.15)
	var expected := launch_origin + ray * (boss.data.radius + 12 + attack.profile.heart_speed * 0.15)
	_check(attack.hearts.entries[0].at.is_equal_approx(expected), "long frame moved new hearts before their launch time")
	_start(CaramelEncounterData.Attack.HEART_FAN, 2)
	attack.advance(attack.profile.heart_warning_seconds + attack.profile.heart_release_seconds)
	_check(attack.state == CaramelEncounter.State.HEART_WINDUP and attack.salvo_index == 1 and is_equal_approx(attack.remaining, attack.profile.heart_followup_warning), "second salvo skipped its own full warning")
	_check(attack.rays.size() == 9, "late fan did not change its projectile pattern")
	# A crossed projectile must hit even if both final positions are clear.
	_start(CaramelEncounterData.Attack.HEART_FAN)
	attack.hearts.entries.append({"at": game.player.global_position + Vector2(-200, 0), "velocity": Vector2(400, 0), "life": 2.0, "damage": 10.0, "source": &"heart_fan"})
	attack.hearts.advance(1, 0)
	_check(game.player.stats.health < 10000 and attack.hearts.entries.is_empty(), "heart sweep skipped a player crossing or retained a spent projectile")
	var health: float = game.player.stats.health
	attack.hearts.advance(0.1, 0)
	_check(game.player.stats.health == health, "one heart dealt damage twice")
	_start(CaramelEncounterData.Attack.HEART_FAN)
	var centre: Vector2 = game.player.global_position
	game.player.motion_start = centre - Vector2(150, 0)
	game.player.motion_end = centre + Vector2(150, 0)
	game.player.global_position = game.player.motion_end
	game.player.motion_tick = Engine.get_physics_frames()
	game.player.dash_motion_seconds = 0.16
	game.player.dash_moved = true
	attack.hearts.entries.append({"at": centre, "velocity": Vector2.ZERO, "life": 2.0, "damage": 10.0, "source": &"heart_fan"})
	attack.hearts.advance(0.16, 0)
	_check(game.player.stats.health < 10000, "dash tunneled through an active heart")
	game.player.hurt_time = 0
	game.player.stats.health = 10000
	attack.hearts.entries.append({"at": centre, "velocity": Vector2.ZERO, "life": 2.0, "damage": 10.0, "source": &"heart_fan"})
	attack.hearts.advance(0.1, 0.35)
	_check(game.player.stats.health == 10000, "heart launched after dash end hit the earlier dash path")
	_start(CaramelEncounterData.Attack.SUGAR_RUSH)
	var end := attack.rush_end
	game.player.global_position += Vector2(0, 180)
	attack.advance(attack.profile.rush_warning_seconds - 0.001)
	_check(boss.global_position == Vector2(740, 650) and attack.rush_end == end, "rush moved early or dragged its warned endpoint")
	attack.advance(0.001 + attack.profile.rush_seconds * 0.5)
	_check(boss.global_position.is_equal_approx(Vector2(740, 650).lerp(end, 0.5)), "rush movement does not follow the marked path")
	_check(DashCollision._charge_movement(boss, 0.1).is_equal_approx(attack.rush_movement(0.1)), "player dash does not account for the rushing Prince")
	attack.advance(attack.profile.rush_seconds * 0.5)
	_check(attack.state == CaramelEncounter.State.BURST_WINDUP and attack.hearts.entries.is_empty() and game.player.stats.health == 10000, "rush released an unannounced burst or hit the safe sidestep")
	_check(attack.rays.size() == attack.profile.burst_count(boss.boss_phase), "heart crown silently omitted projectiles")
	_start(CaramelEncounterData.Attack.SUGAR_RUSH)
	attack.advance(attack.profile.rush_warning_seconds + attack.profile.rush_seconds)
	_check(game.player.stats.health < 10000 and attack.rush_hit, "rush body sweep missed stationary Denti")
	var hit_health: float = game.player.stats.health
	var hit_snapshot := EnemySnapshot.capture(boss)
	EnemySnapshot.restore(boss, hit_snapshot)
	attack.advance(0.1)
	_check(game.player.stats.health == hit_health and boss.contact_timer > 0, "resume duplicated the rush contact")
	_start(CaramelEncounterData.Attack.SUGAR_RUSH, 2)
	attack._warn_burst(-1)
	game.player.global_position = boss.global_position + attack.rays[0] * 180
	attack.advance(attack.profile.burst_warning_seconds + 1)
	_check(game.player.stats.health < 10000, "standing in a ring projectile was protected by a gifted aisle")
	# Find a real baseline-speed route for every fan tier at all arena corners.
	# Treat movement as slowed for the entire route, even after leaving caramel.
	for phase in [0, 1, 2]:
		for corner: Vector2 in [Vector2(48, 48), Vector2(game.player.arena.arena_size.x - 48, 48), Vector2(48, game.player.arena.arena_size.y - 48), game.player.arena.arena_size - Vector2.ONE * 48]:
			var safe_route := false
			for route in 32:
				_start(CaramelEncounterData.Attack.HEART_FAN, phase)
				game.player.global_position = corner
				boss.global_position = corner + corner.direction_to(game.player.arena.arena_size * 0.5) * 260
				attack.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
				attack.salvo_count = 1
				var goal := (corner + Vector2.from_angle(route * TAU / 32) * 210).clamp(Vector2.ONE * 48, game.player.arena.arena_size - Vector2.ONE * 48)
				var touched_body := false
				for tick in 234:
					game.player.global_position = game.player.global_position.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * attack.profile.movement_factor / 60)
					if game.player.global_position.distance_to(boss.global_position) <= boss.data.radius + 20:
						touched_body = true
						break
					if attack.state in [CaramelEncounter.State.HEART_WINDUP, CaramelEncounter.State.HEART_RELEASE]: attack.advance(1.0 / 60)
					else: attack.hearts.advance(1.0 / 60, 0)
					if game.player.stats.health < 10000: break
				if not touched_body and game.player.stats.health == 10000:
					safe_route = true
					break
			_check(safe_route, "fan tier %d has no slowed baseline route from corner %s" % [phase, corner])
	# Every kind/state round-trips without retargeting, replay or lifetime drift.
	for kind in [0, 1, 2]:
		_start(kind, 2)
		for step in [0.2, 0.4, 0.35, 0.5, 0.75, 1.0, 1.6]:
			attack.advance(step)
			var saved := EnemySnapshot.capture(boss)
			var before := attack.save_data()
			_check(not RunSaveData.normalize({"wave": 10, "player": {}, "enemies": [saved]}).is_empty(), "valid multi-attack save was rejected")
			EnemySnapshot.restore(boss, saved)
			_check(attack.save_data() == before, "multi-attack roundtrip changed the warning, rush or live hearts")
	var frozen := attack.save_data()
	await process_frame
	await process_frame
	_check(attack.save_data() == frozen, "paused heart/rush continued advancing")
	_start(CaramelEncounterData.Attack.BOMBS)
	attack.advance(0.7)
	var legacy := attack.save_data()
	legacy.version = 1
	for key in ["attack_kind", "salvo_index", "salvo_count", "aim", "rush_origin", "rush_end", "rush_hit", "rays", "hearts"]: legacy.erase(key)
	attack.restore(legacy)
	_check(attack.state == CaramelEncounter.State.FLIGHT and is_equal_approx(attack.remaining, 0.4) and attack.hearts.entries.is_empty(), "version 1 bomb warning was discarded or converted into a new attack")
	for invalid in [{"hearts": [{}]}, {"rays": [[1]]}, {"hearts": [{"position": [1, 2], "velocity": [0, "bad"], "life": 1, "damage": 1}]}, {"rush_hit": []}, {"attack_kind": "bad"}]:
		_check(RunSaveData.normalize({"wave": 10, "player": {}, "enemies": [{"caramel": invalid}]}).is_empty(), "malformed heart/rush data was accepted")
	_start(CaramelEncounterData.Attack.HEART_FAN, 2)
	attack.advance(attack.profile.heart_warning_seconds + 0.1)
	var saved_hearts := attack.hearts.save_data()
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
	_check(attack.hearts.entries.size() == saved_hearts.size() and attack.attack_kind == CaramelEncounterData.Attack.HEART_FAN, "actual run resume lost the custom heart projectiles")
	BossAttackController.start_boss_phase(boss)
	_check(attack.hearts.entries.is_empty() and not attack.active, "health transition left hearts or an unannounced rush alive")
	_start(CaramelEncounterData.Attack.HEART_FAN, 2)
	for repeat in 10: attack.hearts.fire(boss.global_position, attack.rays, &"heart_fan")
	_check(attack.hearts.entries.size() <= attack.profile.max_hearts, "heart projectiles exceeded their fixed budget")
	boss.boss_damage_budget = boss.max_health * 10
	boss.take_damage(1e9)
	_check(boss.dying and attack.hearts.entries.is_empty(), "dead Prince retained damaging hearts")
	session.clear_run()
	if failures.is_empty(): print("PASS prince_attack_variants: full repertoire, warnings, rays, swept hearts, dash timing, rush, full rings, budgets, pause, death, legacy and real save/resume")
	finish(0 if failures.is_empty() else 1)
