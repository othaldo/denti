extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if ok: return
	failures.append(message)
	push_error(message)

func _spawn(difficulty: DifficultyData) -> Enemy:
	game.wave.difficulty_id = difficulty.id
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.stats.health = 100000
	game.player.hurt_time = 0
	game.player.dash_moved = false
	game.player.get_node("Camera2D").force_update_scroll()
	game._create_enemy(EnemyCatalog.CAVITY_KING, Vector2(770, 620))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 2
	return boss

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://king_difficulty_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.current_wave = 15
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.stats.max_health = 100000
	game.player.loadout.restore([])
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var original := EnemyCatalog.CAVITY_KING.acid_king_profile
	var results: Array[Dictionary] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss := _spawn(difficulty)
		var attack := boss.acid_king_encounter
		var profile := attack.profile
		_check(profile != original and profile.shards != original.shards and original.shards.speed == 210, "difficulty modified the shared King resource")
		_check(profile.warning_seconds == original.warning_seconds and profile.stomp_warning_seconds == original.stomp_warning_seconds and profile.shift_warning_seconds == original.shift_warning_seconds, "difficulty shortened a warned reaction window")
		_check(profile.rows(2) == 4 + difficulty.boss_volley_bonus and profile.shard_count(2) == 7 + difficulty.boss_volley_bonus * 2, "King action/projectile counts ignore difficulty")
		_check(is_equal_approx(profile.shards.speed, 210 * difficulty.boss_projectile_speed_multiplier), "King shard speed ignores difficulty")
		var warnings := [0]
		boss.attack_performed.connect(func(kind: StringName):
			if kind == &"boss_warning": warnings[0] += 1)
		var kinds := {}
		var peak_fields := 0
		var peak_shards := 0
		for tick in 3600:
			game.player.hurt_time = maxf(game.player.hurt_time - 1.0 / 60, 0)
			attack.advance(1.0 / 60)
			if attack.active: kinds[attack.attack_kind] = true
			peak_fields = maxi(peak_fields, attack.fields.size())
			peak_shards = maxi(peak_shards, attack.volley.entries.size())
			_check(attack.fields.size() <= 2 and attack.volley.entries.size() <= profile.shards.maximum, "King exceeded a hazard budget")
		results.append({"difficulty": str(difficulty.id), "seconds": 60, "warnings": warnings[0], "channels": attack.channels_created, "rows": attack.rows_fired, "projectiles": attack.volley.fired, "movement": snappedf(attack.movement, 0.1), "damage_acid": snappedf(attack.damage_by_source.acid, 0.1), "damage_stomp": snappedf(attack.damage_by_source.stomp, 0.1), "damage_shards": snappedf(attack.volley.damage_dealt, 0.1), "peak_fields": peak_fields, "peak_shards": peak_shards, "kinds": kinds.size()})
		_check(kinds.size() == 3, "King did not use its whole repertoire")
		# Every difficulty/attack/state preserves its actual announced geometry.
		for kind in [0, 1, 2]:
			attack.cancel()
			attack.begin(kind)
			for seconds in [0.2, 0.9, 0.3, 0.5, 0.8, 1.3, 1.5]:
				attack.advance(seconds)
				var before := attack.save_data()
				EnemySnapshot.restore(boss, EnemySnapshot.capture(boss))
				_check(attack.save_data() == before, "difficulty-specific King resume changed a live attack")
		# Real slowed routes from all four corners; no lane is removed for Denti.
		for corner: Vector2 in [Vector2(48, 48), Vector2(game.player.arena.arena_size.x - 48, 48), Vector2(48, game.player.arena.arena_size.y - 48), game.player.arena.arena_size - Vector2.ONE * 48]:
			for kind in [AcidKingEncounter.Attack.CHANNELS, AcidKingEncounter.Attack.STOMP]:
				var safe := false
				for route in 32:
					attack.cancel()
					attack.cycle = 0
					boss.global_position = corner + corner.direction_to(game.player.arena.arena_size * 0.5) * 260
					game.player.global_position = corner
					game.player.stats.health = 100000
					game.player.hurt_time = 0
					game.player.get_node("Camera2D").force_update_scroll()
					attack.begin(kind)
					var goal := (corner + Vector2.from_angle(route * TAU / 32) * (130 if kind == AcidKingEncounter.Attack.STOMP else 180)).clamp(Vector2.ONE * 48, game.player.arena.arena_size - Vector2.ONE * 48)
					var body := false
					for frame in 240:
						game.player.global_position = game.player.global_position.move_toward(goal, PlayerStats.BASE_MOVE_SPEED * 0.72 / 60)
						if game.player.global_position.distance_to(boss.global_position) <= boss.data.radius + 20:
							body = true
							break
						attack.advance(1.0 / 60)
						if game.player.stats.health < 100000: break
					if not body and game.player.stats.health == 100000:
						safe = true
						break
				_check(safe, "%s King attack %d has no slowed route from %s" % [difficulty.id, kind, corner])
		boss.free()
	for index in range(1, results.size()):
		_check(results[index].projectiles > results[index - 1].projectiles, "actual King projectile pressure did not rise with every difficulty")
	print("KING PRESSURE: ", JSON.stringify(results))
	# Double Kings take turns; floor fields and projectiles clear on interruption.
	var first := _spawn(DifficultyCatalog.HELL)
	var second := _spawn(DifficultyCatalog.HELL)
	first.acid_king_encounter.begin(AcidKingEncounter.Attack.CHANNELS)
	_check(second.acid_king_encounter._reserved(), "two Kings failed to coordinate their warning starts")
	first.acid_king_encounter.advance(1.1)
	_check(first.acid_king_encounter.fields.size() + second.acid_king_encounter.fields.size() <= 2, "two Kings duplicated the floor budget")
	BossAttackController.start_boss_phase(first)
	_check(first.acid_king_encounter.fields.is_empty(), "phase change retained acid under the other King's attack")
	first.free()
	second.free()
	session.clear_run()
	if failures.is_empty(): print("PASS acid_king_difficulty: all tiers, measured pressure, timed geometry, slowed corner routes, shared resources, save/resume and double Kings")
	finish(0 if failures.is_empty() else 1)
