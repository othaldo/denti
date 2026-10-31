extends "res://tests/support/test_runtime.gd"
var failures: Array[String] = []
var game: Node2D
func _initialize() -> void: call_deferred("_run")
func _check(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _spawn(data: EnemyData, wave: int, difficulty: DifficultyData) -> Enemy:
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.get_node("Camera2D").force_update_scroll()
	var boss: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	boss.configure(data, game.player, wave, difficulty.id)
	game.get_node("Enemies").add_child(boss)
	boss.global_position = Vector2(600, 650)
	boss.set_simulation_enabled(false)
	return boss
func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://boss_aggression_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	var previous_king_distance := -1.0
	var previous_emperor_distance := -1.0
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		var prince := _spawn(EnemyCatalog.CAVITY_PRINCE, 10, difficulty)
		var caramel := prince.caramel_encounter
		caramel.begin(-1, CaramelEncounterData.Attack.BOMBS)
		caramel.advance(caramel.profile.windup_seconds)
		var target := caramel.destination
		var launch := caramel.origin
		var airborne: Dictionary = caramel.bombs.entries[0] if not caramel.bombs.entries.is_empty() else {}
		var before := prince.global_position
		caramel.advance(caramel.profile.flight_seconds * 0.5)
		_check((airborne.at == target and airborne.origin == launch) if not airborne.is_empty() else (caramel.destination == target and caramel.origin == launch), "moving Prince dragged his airborne bomb")
		if caramel.profile.move_between_volleys:
			_check(prince.global_position.distance_to(game.player.global_position) < before.distance_to(game.player.global_position), "Prince failed to close while the bomb was airborne")
		var mid := EnemySnapshot.capture(prince)
		var flights := caramel.bombs.save_data()
		EnemySnapshot.restore(prince, mid)
		_check(caramel.bombs.save_data() == flights if not flights.is_empty() else caramel.origin == launch and caramel.destination == target, "resuming moving flight changed the warned landing")
		caramel.begin(-1, CaramelEncounterData.Attack.HEART_FAN)
		before = prince.global_position
		var rays := caramel.rays.duplicate()
		caramel.advance(caramel.profile.heart_warning_seconds * 0.5)
		_check(prince.global_position == before and caramel.rays == rays, "aggressive Prince moved during his fixed fan warning")
		prince.free()
		var king := _spawn(EnemyCatalog.CAVITY_KING, 15, difficulty)
		var acid := king.acid_king_encounter
		acid.state = AcidKingEncounter.State.OPEN
		acid.remaining = acid.profile.open_seconds
		before = king.global_position
		acid.advance(acid.profile.recovery_settle_seconds)
		_check(king.global_position == before, "King skipped his recovery settle")
		acid.advance(0.25)
		var moved := king.global_position.distance_to(before)
		_check(moved > previous_king_distance and king.global_position.distance_to(game.player.global_position) < before.distance_to(game.player.global_position), "King recovery pursuit did not close or scale by difficulty")
		previous_king_distance = moved
		acid.begin(AcidKingEncounter.Attack.CHANNELS)
		before = king.global_position
		var pending := acid.pending.duplicate(true)
		acid.advance(acid.profile.warning_seconds * 0.5)
		_check(king.global_position == before and acid.pending == pending, "King moved his announced channels")
		king.free()
		var emperor := _spawn(EnemyCatalog.CAVITY_EMPEROR, 20, difficulty)
		var court := emperor.crown_court_encounter
		court.state = CrownCourtEncounter.State.OPEN
		court.remaining = court.profile.open_seconds
		before = emperor.global_position
		court.advance(court.profile.recovery_settle_seconds)
		_check(emperor.global_position == before, "Emperor skipped his recovery settle")
		court.advance(0.25)
		moved = emperor.global_position.distance_to(before)
		_check(moved > previous_emperor_distance and emperor.global_position.distance_to(game.player.global_position) < before.distance_to(game.player.global_position), "Emperor recovery pursuit did not close or scale by difficulty")
		previous_emperor_distance = moved
		emperor.global_position = game.player.global_position - Vector2(160, 0)
		court.state = CrownCourtEncounter.State.OPEN
		court.remaining = court.profile.open_seconds - court.profile.recovery_settle_seconds
		court.advance(0.2)
		_check(emperor.global_position.distance_to(game.player.global_position) <= 160.01, "Emperor fled from melee to his preferred ranged distance")
		emperor.free()
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty(): print("PASS boss_aggression: airborne pursuit with locked/resumable bombs, recovery settles, four-tier closing movement, fixed warnings and no Emperor melee retreat")
	finish(0 if failures.is_empty() else 1)
