extends "res://tests/support/test_runtime.gd"
const STEP := 0.001
var failures: Array[String] = []
var game: Node2D
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _spawn(difficulty: DifficultyData) -> Enemy:
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.hurt_time = 0
	game.player.dash_moved = false
	game.player.stats.health = game.player.stats.max_health
	game.player.get_node("Camera2D").force_update_scroll()
	var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	boss.configure(EnemyCatalog.CAVITY_PRINCE, game.player, 10, difficulty.id)
	game.get_node("Enemies").add_child(boss)
	boss.set_simulation_enabled(false)
	boss.caramel_encounter.overload.used = true # Isolate bomb cadence and in-flight save state.
	boss.boss_phase = 2
	boss.global_position = Vector2(750, 650)
	return boss
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://prince_bomb_frequency_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.max_health = 100000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var measured: Array[Dictionary] = []
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var boss := _spawn(difficulty)
		var a := boss.caramel_encounter
		var warnings: Array[float] = []
		var impacts: Array[float] = []
		boss.attack_performed.connect(func(kind: StringName):
			if a.attack_kind != CaramelEncounterData.Attack.BOMBS: return
			if kind == &"boss_warning": warnings.append(a.elapsed)
			elif kind == &"boss_pulse": impacts.append(a.elapsed))
		a.begin(-1, CaramelEncounterData.Attack.BOMBS)
		var peak := 0
		for tick in 10000:
			a.advance(STEP)
			peak = maxi(peak, a.bombs.entries.size())
			if impacts.size() == a.count: break
		_check(warnings.size() == a.count and impacts.size() == a.count, "bomb sequence omitted or duplicated an announced impact")
		for index in range(1, warnings.size()):
			_check(absf(warnings[index] - warnings[index - 1] - a.profile.bomb_interval()) < 0.0001, "actual bomb interval differs from difficulty scaling")
		for index in impacts.size():
			_check(absf(impacts[index] - warnings[index] - a.profile.windup_seconds - a.profile.flight_seconds) <= STEP * 1.1, "frequency change shortened a bomb's full warning")
		_check(peak <= 2 and a.pools.size() <= a.profile.max_pools, "bomb frequency escaped the rendering/floor budget")
		_check(a.bombs.entries.is_empty(), "resolved sequence retained a live bomb")
		measured.append({"difficulty": str(difficulty.id), "interval": a.profile.bomb_interval(), "frequency": a.profile.bomb_frequency, "warning": a.profile.windup_seconds + a.profile.flight_seconds, "peak": peak})
		boss.free()
	print("PRINCE BOMB FREQUENCY: ", JSON.stringify(measured))
	_check(is_equal_approx(measured[0].frequency, 0.75) and is_equal_approx(measured[1].frequency, 1) and is_equal_approx(measured[2].frequency, 1.5) and is_equal_approx(measured[3].frequency, 2), "bomb frequency is not Easy/Normal/Hard/Hell 0.75/1/1.5/2")
	var boss := _spawn(DifficultyCatalog.HELL)
	var a := boss.caramel_encounter
	a.begin(-1, CaramelEncounterData.Attack.BOMBS)
	a.advance(0.8)
	_check(a.bombs.entries.size() == 2, "Hell did not overlap the next full warning with the first bomb")
	var locked := a.bombs.entries[0].at as Vector2
	var snapshot := a.save_data()
	game.player.global_position += Vector2(130, 60)
	a.advance(0.1)
	_check(a.bombs.entries[0].at == locked, "an airborne bomb homed after a later throw")
	a.restore(snapshot)
	_check(a.save_data() == snapshot, "overlapping bomb snapshot changed ages, geometry or launch state")
	await process_frame
	await process_frame
	_check(a.save_data() == snapshot, "pause advanced overlapping bombs")
	# A large frame releases/lands each bomb once, at its actual subframe time.
	var expected := a.count
	var landed := [0]
	boss.attack_performed.connect(func(kind: StringName):
		if kind == &"boss_pulse" and a.attack_kind == CaramelEncounterData.Attack.BOMBS: landed[0] += 1)
	a.advance(2.0)
	_check(landed[0] == expected and a.bombs.entries.is_empty(), "long frame lost or replayed an overlapping bomb")
	# Old version-2 serial saves finish their announced throw with full warning.
	a.begin(-1, CaramelEncounterData.Attack.BOMBS)
	a._warn(-1)
	a.advance(0.2)
	var legacy := a.save_data()
	legacy.version = 2
	legacy.erase("bombs")
	a.restore(legacy)
	_check(a.state == CaramelEncounter.State.WINDUP and a.bombs.entries.is_empty() and is_equal_approx(a.remaining, 0.3), "version-2 bomb warning was converted or shortened")
	# Actual scene reload with one airborne bomb and a second winding up.
	a.begin(-1, CaramelEncounterData.Attack.BOMBS)
	a.advance(0.8)
	var live := a.bombs.save_data()
	game.boss = boss
	game.boss_pending = true
	game.wave.current_wave = 10
	game.wave.difficulty_id = &"hell"
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	boss = game.boss
	boss.set_simulation_enabled(false)
	a = boss.caramel_encounter
	paused = true
	var loaded := a.bombs.save_data()
	_check(a.state == CaramelEncounter.State.BOMB_SEQUENCE and loaded.size() == live.size(), "actual continue lost an overlapping warning/flight")
	for index in mini(live.size(), loaded.size()):
		_check(loaded[index].origin == live[index].origin and loaded[index].position == live[index].position and loaded[index].launched == live[index].launched and absf(loaded[index].age - live[index].age) <= 2.0 / 60 + 0.000001, "actual continue changed bomb ownership, aim or age")
	for bad in [[{}], [{"origin": [0, 0], "position": [1, 2], "age": "bad", "launched": false}], [{"origin": [0], "position": [1, 2], "age": 0.1, "launched": false}]]:
		_check(RunSaveData.normalize({"wave": 10, "player": {}, "enemies": [{"caramel": {"bombs": bad}}]}).is_empty(), "malformed bomb batch entered runtime")
	a.begin(-1, CaramelEncounterData.Attack.BOMBS)
	a.advance(0.8)
	BossAttackController.start_boss_phase(boss)
	_check(a.bombs.entries.is_empty(), "health phase retained an announced live bomb")
	boss.boss_phase_timer = 0
	a.begin(-1, CaramelEncounterData.Attack.BOMBS)
	a.advance(0.8)
	boss.health = 1
	boss.boss_damage_budget = boss.max_health
	boss.boss_phase = 2
	boss.take_damage(1000000)
	_check(boss.dying and a.bombs.entries.is_empty(), "dead Prince retained live bombs")
	boss.free()
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty(): print("PASS prince_bomb_frequency: measured cadence/full warnings at four tiers, bounded overlap, fixed targets, long frames, snapshots, pause, old saves, phase and death cleanup")
	finish(0 if failures.is_empty() else 1)
