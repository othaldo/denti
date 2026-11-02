extends "res://tests/support/test_runtime.gd"

const STEP := 1.0 / 60.0
var game: Node2D
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_balance_first_pass.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.stats.crit_chance = 0
	_leech_growth()
	_brush_space()
	_verdict_prediction()
	session.clear_run()
	print("PASS first balance pass: brush reach/radial space/one-hit contact, bounded fixed verdict prediction, Easy/legacy behavior, JSON resume and readable escape")
	finish(1 if failures else 0)


func _brush_space() -> void:
	game.player.loadout.restore([{"id": "interdental_brush", "tier": 1}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	var targets: Array[Enemy] = []
	var starts: Array[Vector2] = []
	for offset in [Vector2(80, 0), Vector2(-65, 0)]:
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_simulation_enabled(false)
		enemy.max_health = 10000
		enemy.health = 10000
		targets.append(enemy)
		starts.append(enemy.global_position)
	weapon._physics_process(0.001)
	_check(targets[0].health == 10000 and targets[1].health == 10000, "brush hit before its windup")
	weapon._physics_process(weapon.attack_duration)
	for index in targets.size():
		var enemy := targets[index]
		var outward: Vector2 = (starts[index] - game.player.global_position).normalized()
		_check(enemy.health < 10000, "brush missed its moving blade at useful close range")
		_check((enemy.global_position - starts[index]).dot(outward) > 0, "spin pushed an enemy through Denti instead of away")
		var health := enemy.health
		weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
		_check(enemy.health == health, "spin hit an enemy twice in one attack")
	for enemy in targets: enemy.free()
	game.player.loadout.restore([])


func _leech_growth() -> void:
	var small := WeaponCatalog.by_id(&"interdental_brush")
	var large := WeaponCatalog.by_id(&"uv_lamp")
	var affixes: Array[Dictionary] = []
	var previous := 0.0
	for rank in range(1, 11):
		affixes = WeaponUpgrades.advance(affixes, &"leech", small, 4)
		var affix := affixes[0]
		var heal := WeaponAffixes.utility_value(affix)
		_check(heal > previous, "a lifesteal rank no longer improves healing")
		if rank <= 4:
			_check(is_equal_approx(heal, 0.25 + float(affix.damage) * 0.04), "early lifesteal was reduced")
		_check(is_equal_approx(heal * 6, WeaponAffixes.utility_value(affix, 2) * 3), "soft scaling broke root parity")
		_check(is_equal_approx(AffixPresentation.display_value(float(affix.damage), &"leech", large), heal * 2), "lifesteal card and combat disagree")
		var restored: Dictionary = JSON.parse_string(JSON.stringify(affix))
		_check(is_equal_approx(WeaponAffixes.utility_value(restored), heal), "JSON changed lifesteal scaling")
		previous = heal
	_check(is_equal_approx(previous, 1.11), "max lifesteal missed its bounded healing budget")


func _verdict_prediction() -> void:
	game.wave.current_wave = 20
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, Vector2(700, 540))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	var attack := boss.crown_court_encounter
	game.player.global_position = Vector2(960, 540)
	game.player.velocity = Vector2(0, 230)
	attack.begin(CrownCourtEncounter.Attack.EDICT)
	var expected := boss.global_position.direction_to(game.player.global_position + (game.player.velocity * attack.profile.verdict_lead_seconds).limit_length(attack.profile.verdict_lead_distance))
	_check(Vector2.from_angle(attack.edict_angle).dot(expected) > 0.9999, "verdict did not warn its bounded intercept")
	_check(attack.remaining >= 1.0, "first verdict lost its readable reaction time")
	var origin := attack.origin
	var angle := attack.edict_angle
	game.player.global_position += Vector2(-30, -60)
	game.player.velocity = Vector2(0, -230)
	attack.advance(0.1)
	_check(attack.origin == origin and attack.edict_angle == angle, "verdict tracked after the warning was drawn")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(attack.save_data()))
	attack.restore(snapshot)
	_check(is_equal_approx(attack.edict_angle, angle) and attack.origin == origin, "save/resume re-aimed an announced verdict")
	attack.cancel()
	game.player.global_position = Vector2(960, 540)
	game.player.velocity = Vector2(0, 10000)
	attack._lock_verdict()
	expected = origin.direction_to(game.player.global_position + Vector2(0, attack.profile.verdict_lead_distance))
	_check(Vector2.from_angle(attack.edict_angle).dot(expected) > 0.9999, "fast movement exceeded the prediction-distance limit")
	attack.legacy_sequence = true
	attack._lock_verdict()
	_check(absf(attack.edict_angle) < 0.001, "legacy attacks acquired new aim prediction")
	attack.legacy_sequence = false
	var easy := EnemyCatalog.CAVITY_EMPEROR.crown_court_profile.for_difficulty(DifficultyCatalog.EASY)
	_check(easy.verdict_lead_seconds == 0 and easy.verdict_lead_distance == 0, "Easy inherited the new intercept pressure")
	_check(EnemyCatalog.CAVITY_EMPEROR.crown_court_profile.verdict_lead_seconds > 0, "difficulty cloning mutated the shared profile")
	_check(_route(boss, Vector2.DOWN) > 0, "continuing the warned route never incurred pressure")
	_check(_route(boss, Vector2.UP) == 0, "reading the warning and changing direction did not escape")
	boss.free()


func _route(boss: Enemy, direction: Vector2) -> float:
	var attack := boss.crown_court_encounter
	attack.cancel()
	attack.legacy_sequence = false
	boss.boss_phase = 0
	boss.boss_phase_timer = 0
	boss.global_position = Vector2(700, 540)
	game.player.global_position = Vector2(960, 540)
	game.player.velocity = Vector2.DOWN * PlayerStats.BASE_MOVE_SPEED * 0.72
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.shield_charges = 0
	game.player.hurt_time = 0
	game.player.get_node("Camera2D").force_update_scroll()
	attack.begin(CrownCourtEncounter.Attack.EDICT)
	for frame in 108:
		game.player.global_position += direction * PlayerStats.BASE_MOVE_SPEED * 0.72 * STEP
		game.player.velocity = direction * PlayerStats.BASE_MOVE_SPEED * 0.72
		game.player.hurt_time = maxf(game.player.hurt_time - STEP, 0)
		attack.advance(STEP)
	return 10000 - game.player.stats.health
