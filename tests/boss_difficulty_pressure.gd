extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if ok: return
	failures.append(message)
	push_error(message)

func _prince(difficulty: DifficultyData) -> Enemy:
	game.wave.difficulty_id = difficulty.id
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.stats.health = 10000
	game.player.hurt_time = 0
	game.player.dash_moved = false
	game.player.get_node("Camera2D").force_update_scroll()
	game._create_enemy(EnemyCatalog.CAVITY_PRINCE, Vector2(740, 650))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 1
	return boss

func _pressure_sample(difficulty: DifficultyData) -> Dictionary:
	var boss := _prince(difficulty)
	var attack := boss.caramel_encounter
	var warnings := [0]
	boss.attack_performed.connect(func(kind: StringName):
		if kind == &"boss_warning": warnings[0] += 1)
	var distance := 0.0
	var projectiles := 0
	var peak := 0
	var kinds := {}
	for tick in 2400:
		game.player.hurt_time = maxf(game.player.hurt_time - 1.0 / 60, 0)
		var before := boss.global_position
		var previous := attack.state
		attack.advance(1.0 / 60)
		distance += before.distance_to(boss.global_position)
		if attack.active: kinds[attack.attack_kind] = true
		if attack.state != previous and attack.state in [CaramelEncounter.State.HEART_RELEASE, CaramelEncounter.State.BURST_RELEASE]:
			projectiles += attack.rays.size()
		peak = maxi(peak, attack.hearts.entries.size())
		_check(peak <= attack.profile.max_hearts and attack.pools.size() <= attack.profile.max_pools, "encounter exceeded its hazard budget")
	var result := {"difficulty": str(difficulty.id), "seconds": 40, "warnings": warnings[0], "hearts_launched": projectiles, "distance": snappedf(distance, 0.1), "peak_hearts": peak, "damage": snappedf(10000 - game.player.stats.health, 0.1), "kinds": kinds.size()}
	boss.free()
	return result

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://boss_pressure_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.set_process(false)
	game.wave.active = false
	game.wave.current_wave = 10
	game.player.set_physics_process(false)
	game.player.loadout.restore([])
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var original := EnemyCatalog.CAVITY_PRINCE.caramel_profile
	var normal := original.for_difficulty(DifficultyCatalog.NORMAL)
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss := _prince(difficulty)
		var attack := boss.caramel_encounter
		var profile := attack.profile
		_check(profile != original and original.action_bonus == 0 and original.heart_speed == 245, "difficulty mutated shared boss resources")
		_check(profile.windup_seconds == normal.windup_seconds and profile.heart_warning_seconds == normal.heart_warning_seconds and profile.heart_followup_warning == normal.heart_followup_warning and profile.rush_warning_seconds == normal.rush_warning_seconds and profile.burst_warning_seconds == normal.burst_warning_seconds, "difficulty shortened a warned reaction window")
		var bonus := difficulty.boss_volley_bonus
		_check(profile.throws_for_phase(1) == 3 + bonus and profile.fan_count(2) == 9 + bonus * 2 and profile.salvos_for_phase(1) == 2 + bonus, "difficulty does not scale custom attack counts")
		attack.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
		var at := boss.global_position
		var rays := attack.rays.duplicate()
		attack.advance(profile.heart_warning_seconds - 0.001)
		_check(boss.global_position == at and attack.rays == rays and attack.hearts.entries.is_empty(), "boss moved or shot during a locked fan warning")
		attack.advance(0.001)
		_check(attack.hearts.entries.size() == profile.fan_count(1), "scaled fan did not release its advertised hearts")
		_check(is_equal_approx(attack.hearts.entries[0].velocity.length(), profile.heart_speed), "heart speed ignores difficulty")
		attack.advance(profile.heart_release_seconds)
		_check(not profile.move_between_volleys or boss.global_position.distance_to(at) > 5, "hard boss remained stationary between salvos")
		# Save a late salvo and a late bomb; neither may be clamped to Normal counts.
		attack.salvo_index = attack.salvo_count - 1
		attack._warn_fan(-1)
		var before := attack.save_data()
		EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
		_check(attack.save_data() == before, "resume lost an increased salvo, moving origin or scaled projectile velocity")
		attack.cancel()
		attack.begin(-1, CaramelEncounterData.Attack.BOMBS)
		attack.throw_index = attack.count - 1
		attack._warn(-1)
		before = attack.save_data()
		EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
		_check(attack.save_data() == before, "resume clamped the additional bombs")
		attack.cancel()
		attack.begin(-1, CaramelEncounterData.Attack.SUGAR_RUSH)
		_check(attack.rush_origin.distance_to(attack.rush_end) <= profile.rush_distance + 0.01, "rush exceeded its advertised range")
		attack._warn_burst(-1)
		game.player.global_position = boss.global_position + attack.rays[0] * 180
		game.player.stats.health = 10000
		game.player.hurt_time = 0
		var first_rays := attack.rays.duplicate()
		game.player.global_position += Vector2(90, -70)
		attack._warn_burst(-1)
		_check(first_rays == attack.rays, "crown geometry follows the player")
		game.player.global_position = boss.global_position + attack.rays[0] * 180
		if profile.burst_salvos() > 1:
			attack.advance(profile.burst_warning_seconds + profile.burst_release_seconds)
			_check(attack.rays != first_rays and attack.state == CaramelEncounter.State.BURST_WINDUP and is_equal_approx(attack.remaining, profile.burst_warning_seconds), "second Hell crown was not offset or lost its own complete warning")
		attack.advance(profile.burst_warning_seconds + profile.burst_release_seconds + 0.5)
		_check(game.player.stats.health < 10000 and first_rays.size() == profile.burst_count(1), "full crown omitted shots to protect stationary Denti")
		boss.free()
	# Full slow-speed corner escapes against each Hell fan, not only count checks.
	var hell := _prince(DifficultyCatalog.HELL)
	var attack := hell.caramel_encounter
	for phase in [0, 1, 2]:
		for corner: Vector2 in [Vector2(48, 48), Vector2(game.player.arena.arena_size.x - 48, 48), Vector2(48, game.player.arena.arena_size.y - 48), game.player.arena.arena_size - Vector2.ONE * 48]:
			var safe := false
			for route in 32:
				attack.cancel()
				hell.boss_phase = phase
				game.player.global_position = corner
				game.player.stats.health = 10000
				game.player.hurt_time = 0
				hell.global_position = corner + corner.direction_to(game.player.arena.arena_size * 0.5) * 260
				attack.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
				attack.salvo_count = 1
				var goal := (corner + Vector2.from_angle(route * TAU / 32) * 210).clamp(Vector2.ONE * 48, game.player.arena.arena_size - Vector2.ONE * 48)
				var body := false
				for tick in 234:
					game.player.global_position = game.player.global_position.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * attack.profile.movement_factor / 60)
					if game.player.global_position.distance_to(hell.global_position) <= hell.data.radius + 20:
						body = true
						break
					if attack.state == CaramelEncounter.State.HEART_WINDUP: attack.advance(1.0 / 60)
					else: attack.hearts.advance(1.0 / 60, 0)
					if game.player.stats.health < 10000: break
				if not body and game.player.stats.health == 10000:
					safe = true
					break
			_check(safe, "Hell fan phase %d has no slowed corner escape at %s" % [phase, corner])
	hell.free()
	# Complete rings have only regular projectile spacing. Test real movement
	# between those shots from arena corners, including the offset second ring.
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var ring_boss := _prince(difficulty)
		var ring := ring_boss.caramel_encounter
		for corner: Vector2 in [Vector2(48, 48), Vector2(game.player.arena.arena_size.x - 48, 48), Vector2(48, game.player.arena.arena_size.y - 48), game.player.arena.arena_size - Vector2.ONE * 48]:
			ring.cancel()
			ring_boss.boss_phase = 2
			ring_boss.global_position = corner + corner.direction_to(game.player.arena.arena_size * 0.5) * 260
			game.player.global_position = corner
			game.player.stats.health = 10000
			game.player.hurt_time = 0
			ring.salvo_index = 0
			ring.salvo_count = ring.profile.burst_salvos()
			ring._warn_burst(-1)
			var chosen_salvo := -1
			var goal := corner
			for tick in 330:
				if ring.state == CaramelEncounter.State.BURST_WINDUP and chosen_salvo != ring.salvo_index:
					chosen_salvo = ring.salvo_index
					var cost := INF
					for index in ring.rays.size():
						var direction := (ring.rays[index] + ring.rays[(index + 1) % ring.rays.size()]).normalized()
						for radius in [180, 200, 220, 230, 235, 240, 245, 250, 260, 280, 320, 360]:
							var candidate: Vector2 = ring_boss.global_position + direction * radius
							if candidate != candidate.clamp(Vector2.ONE * 48, game.player.arena.arena_size - Vector2.ONE * 48): continue
							if radius * sin(PI / ring.rays.size()) < ring.profile.heart_radius + HazardGeometry.PLAYER_RADIUS + 0.2: continue
							var distance := candidate.distance_to(game.player.global_position)
							if distance < cost:
								cost = distance
								goal = candidate
				# Let the first ring pass before changing to the offset spacing.
				var waiting := chosen_salvo > 0 and ring.state == CaramelEncounter.State.BURST_WINDUP and ring.remaining > ring.profile.burst_warning_seconds - 0.35
				if not waiting: game.player.global_position = game.player.global_position.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * ring.profile.movement_factor / 60)
				if ring.state in [CaramelEncounter.State.BURST_WINDUP, CaramelEncounter.State.BURST_RELEASE]: ring.advance(1.0 / 60)
				else: ring.hearts.advance(1.0 / 60, 0)
				if game.player.stats.health < 10000:
					print("RING ROUTE hit ", difficulty.id, " tick=", tick, " at=", game.player.global_position, " goal=", goal, " boss=", ring_boss.global_position, " salvo=", chosen_salvo)
					break
			_check(game.player.stats.health == 10000 and chosen_salvo == ring.profile.burst_salvos() - 1, "complete %s rings have no slowed natural corner route at %s" % [difficulty.id, corner])
		ring_boss.free()
	var rows: Array[Dictionary] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL: rows.append(_pressure_sample(difficulty))
	_check(rows[3].hearts_launched > rows[1].hearts_launched * 1.8 and rows[3].warnings > rows[1].warnings, "Hell failed to materially increase actual attack/projectile pressure")
	_check(rows[3].distance > rows[1].distance * 1.2 and rows[3].kinds == 3, "Hell failed to increase movement across the full repertoire")
	for index in range(1, rows.size()):
		_check(rows[index].hearts_launched > rows[index - 1].hearts_launched and rows[index].warnings > rows[index - 1].warnings and rows[index].distance > rows[index - 1].distance, "actual projectile/action pressure did not rise at every difficulty step")
	print("BOSS PRESSURE (stationary target, fixed health phase, no adds): ", JSON.stringify(rows))
	# The Count uses the same difficulty source and preserves late combo saves.
	game.wave.difficulty_id = &"hell"
	game._create_enemy(EnemyCatalog.CAVITY_COUNT, Vector2(740, 650))
	var count: Enemy = game.boss
	count.set_simulation_enabled(false)
	count.boss_phase = 1
	count.cloak_encounter.begin()
	_check(count.cloak_encounter.count == 5, "Hell Count still uses a Normal combo length")
	count.cloak_encounter.strike_index = 4
	count.cloak_encounter.hit_mask = 16
	count.cloak_encounter._warn(game.player.global_position)
	var combo := count.cloak_encounter.save_data()
	EnemySnapshot.restore(count, EnemySnapshot.capture(count))
	_check(combo == count.cloak_encounter.save_data(), "late Hell cloak strike did not survive resume")
	count.free()
	# Retain generic helper coverage after every actual boss migrated.
	var legacy := EnemyCatalog.CAVITY_EMPEROR.duplicate() as EnemyData
	legacy.crown_court_profile = null
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		game.wave.difficulty_id = difficulty.id
		for data: EnemyData in [legacy]:
			game._create_enemy(data, Vector2(740, 650))
			var generic: Enemy = game.boss
			generic.set_simulation_enabled(false)
			generic._reset_special()
			_check(is_equal_approx(generic.special_timer, data.special_interval * difficulty.boss_recovery_multiplier), "generic boss recovery ignores difficulty")
			generic._fire_phase_burst()
			var expected := maxi(data.boss_radial_count + difficulty.boss_volley_bonus * 2, 4)
			var projectiles := game.get_node("EnemyProjectiles").get_children()
			_check(projectiles.size() == expected, "generic boss lost its phase projectiles")
			for projectile: AcidProjectile in projectiles:
				_check(is_equal_approx(projectile.speed, data.boss_projectile_speed * difficulty.boss_projectile_speed_multiplier), "generic boss projectile speed ignores Hell")
				projectile.free()
			generic.special_phase = Enemy.SpecialPhase.ACTIVE
			generic.boss_move = Enemy.BossMove.CHARGE
			generic.special_timer = data.attack_duration
			generic.boss_dash_end = generic._boss_dash_target(Vector2.RIGHT)
			var prediction := DashCollision._charge_movement(generic, 0.05)
			var origin := generic.global_position
			generic._process_special(0.05, Vector2.RIGHT)
			_check((generic.global_position - origin).is_equal_approx(prediction), "Hell charge movement differs from player dash collision prediction")
			generic.free()
	# A double Prince retains the shared floor budget and serializes attack starts.
	var first := _prince(DifficultyCatalog.HELL)
	var second := _prince(DifficultyCatalog.HELL)
	first.caramel_encounter.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
	_check(second.caramel_encounter._reserved(), "double Hell Princes started simultaneous heart attacks")
	for repeat in 8:
		first.caramel_encounter._make_pool_room()
		first.caramel_encounter.pools.append({"at": Vector2(800, 600), "life": 5.0})
		second.caramel_encounter._make_pool_room()
		second.caramel_encounter.pools.append({"at": Vector2(900, 600), "life": 5.0})
	_check(first.caramel_encounter.pools.size() + second.caramel_encounter.pools.size() <= 4, "Hell multiplied the shared floor budget")
	first.free()
	second.free()
	# Actual game reload must rebuild the Hell profile before restoring >28 hearts.
	var saved_boss := _prince(DifficultyCatalog.HELL)
	attack = saved_boss.caramel_encounter
	attack.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
	attack.salvo_index = 3
	attack._warn_fan(-1)
	for repeat in 3: attack.hearts.fire(saved_boss.global_position, attack.rays, &"heart_fan")
	var saved_count := attack.hearts.entries.size()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game.get_node("Enemies").set_physics_process(false)
	game.player.set_physics_process(false)
	game.boss.set_simulation_enabled(false)
	paused = true
	attack = game.boss.caramel_encounter
	_check(game.wave.difficulty_id == &"hell" and attack.salvo_count == 4 and attack.salvo_index == 3 and saved_count > 28 and attack.hearts.entries.size() == saved_count, "actual Hell reload lost the late salvo or truncated hearts to Normal budget")
	session.clear_run()
	if failures.is_empty(): print("PASS boss_difficulty_pressure: real pressure, moving volleys, preserved warnings, complete nontracking rings, slow corner routes, resource isolation and late combo saves")
	finish(0 if failures.is_empty() else 1)
