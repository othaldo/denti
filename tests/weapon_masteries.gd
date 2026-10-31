extends "res://tests/support/test_runtime.gd"

var failures := 0
var game: Node2D
var session: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _new_game(id: StringName, difficulty: StringName = &"normal", story: bool = false) -> void:
	if is_instance_valid(game): game.free()
	paused = false
	session.clear_run()
	session.pending_start_weapon_id = id
	session.selected_difficulty_id = difficulty
	session.selected_story_mode = story
	session.resume_requested = false
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.set_process(false)
	for weapon in game.player.loadout.equipped(): weapon.set_physics_process(false)


func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://mastery_test_run.json"
	session.progression_path = "user://mastery_test_progression.cfg"
	session.report_dir = "user://mastery_test_reports"
	DirAccess.remove_absolute(session.progression_path)
	session.load_progression()
	_storage()
	_new_game(&"turbo_drill", &"easy")
	_check(game.weapon_mastery.starter_id == &"turbo_drill" and game.weapon_mastery.eligible, "prepared start did not bind mastery")
	# Change all current equipment; the confirmed origin must remain unchanged.
	game.player.loadout.restore([{"id": "trinity_brush", "tier": 4}])
	game.wave.current_wave = 5
	game._create_enemy(WaveController.BOSS, game.player.global_position + Vector2(220, 0))
	var boss: Enemy = game.get_node("Enemies").get_child(-1)
	boss.set_simulation_enabled(false)
	boss._finish_death(1, [])
	boss._process(Enemy.BOSS_DEATH_DURATION + 0.01)
	_check(session.mastery_flags(&"turbo_drill") == 1 and session.mastery_flags(&"trinity_brush") == 0, "boss award followed replacement equipment or missed the real death event")
	_check(not paused and not game.mastery_notice.visible and not game.choice_panel.visible, "boss achievement interrupted combat")
	_check(game.weapon_mastery.earned == ["exam"] and game.weapon_mastery.pending == ["exam"], "first award not queued once")
	game.weapon_mastery.record(session, &"boss", &"easy", 5)
	_check(game.weapon_mastery.earned.size() == 1, "repeated defeat duplicated an award")
	await process_frame
	game.wave.active = false
	game._on_wave_finished(5)
	for frame in 8: await process_frame
	_check(game.mastery_notice.visible and game.weapon_mastery.pending.is_empty() and game.choice_panel.mode == &"relic", "achievement did not join the existing intermission without a new choice")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	_check(not RunSaveData.normalize(saved).is_empty(), "mastery state fails run save validation")
	RunSnapshot.restore(game, saved)
	_check(game.weapon_mastery.starter_id == &"turbo_drill" and game.weapon_mastery.earned == ["exam"] and not game.mastery_notice.visible, "resume lost origin or repeated an acknowledged notice")
	session.load_progression()
	_check(session.mastery_flags(&"turbo_drill") == 1, "exam did not survive account reload")
	game._on_player_died()
	_check(session.mastery_flags(&"turbo_drill") == 1 and game.choice_panel.subtitle_label.text.contains("Zahnprüfung"), "a later death removed the achievement or hid it in the recap")
	# Victory tiers are cumulative, including a first win directly on Hell.
	for pair in [[&"normal", 3], [&"hard", 7], [&"hell", 15]]:
		_new_game(&"water_jet", pair[0])
		game.wave.active = false
		game.wave.current_wave = 20
		game._finish_run()
		_check(session.mastery_flags(&"water_jet") == pair[1] and game.choice_panel.subtitle_label.text.contains("Neu:"), "victory awarded the wrong cumulative medal tier")
		var earned: Array[String] = game.weapon_mastery.earned.duplicate()
		game._finish_run()
		_check(game.weapon_mastery.earned == earned, "double victory awarded mastery twice")
		game._on_endless_requested()
		_check(game.wave.endless_enabled and session.mastery_flags(&"water_jet") == pair[1], "endless continuation lost the wave-20 medal")
		game._on_player_died()
		_check(session.mastery_flags(&"water_jet") == pair[1], "endless death revoked a win")
	_new_game(&"enamel_mirror", &"hell")
	game.wave.current_wave = 20
	game._finish_run()
	_check(session.mastery_flags(&"enamel_mirror") == 15 and game.weapon_mastery.earned.size() == 4, "first Hell win requires redundant lower difficulty runs")
	_new_game(&"turbo_drill", &"easy")
	game.wave.current_wave = 20
	game._finish_run()
	_check(session.mastery_flags(&"turbo_drill") == 1 and game.weapon_mastery.earned.is_empty(), "Easy victory or repeat exam granted a medal")
	# Debug edits, wave jumps and test scenarios cannot earn persistent awards.
	_new_game(&"uv_lamp")
	DebugRunControls.new(game).set_coins(99)
	game.wave.current_wave = 20
	game._finish_run()
	_check(not game.weapon_mastery.eligible and session.mastery_flags(&"uv_lamp") == 0, "debug edited run earned a medal")
	_new_game(&"uv_lamp")
	game.debug_start_wave(20)
	game.weapon_mastery.record(session, &"victory", &"hell", 20)
	_check(session.mastery_flags(&"uv_lamp") == 0, "wave jump earned mastery")
	session.test_scenario_id = &"test"
	_check(session.record_weapon_mastery(&"uv_lamp", 15).is_empty(), "test arena earned permanent mastery")
	session.test_scenario_id = &""
	_check(session.record_weapon_mastery(&"trinity_brush", 15).is_empty() and session.record_weapon_mastery(&"unknown", 15).is_empty(), "evolved or invalid weapon got a starter mastery")
	_new_game(&"plaque_scaler", &"normal", true)
	_check(game.story.enabled and game.weapon_mastery.starter_id == &"plaque_scaler" and game.weapon_mastery.eligible, "story intro lost the confirmed origin")
	game.weapon_mastery.record(session, &"boss", &"normal", 5)
	_check(session.mastery_flags(&"plaque_scaler") == 1, "story runs do not earn mastery")
	_legacy_and_validation()
	session.clear_run()
	paused = false
	print("PASS weapon masteries: old/atomic account storage, immutable prepared starter, real boss death, nonblocking notice, loss/resume, cumulative victories/endless, duplicate prevention, debug/test exclusion and legacy saves")
	finish(1 if failures else 0)


func _storage() -> void:
	var old := ConfigFile.new()
	old.set_value("difficulty", "hell_unlocked", true)
	old.set_value("dentipedia", "fusions", ["trinity_brush"])
	old.set_value("unrelated", "keep", "yes")
	old.save(session.progression_path)
	session.load_progression()
	_check(session.hell_unlocked and session.discovered_fusions == ["trinity_brush"] and session.progression_data.weapon_masteries.is_empty(), "old progression was not migrated empty")
	_check(session.record_weapon_mastery(&"floss_whip", 1) == ["exam"] and session.record_weapon_mastery(&"floss_whip", 1).is_empty(), "account award is not idempotent")
	var reloaded := ProgressionStore.new()
	reloaded.load_from(session.progression_path)
	var config := ConfigFile.new()
	config.load(session.progression_path)
	_check(reloaded.weapon_masteries.get("floss_whip") == 1 and reloaded.hell_unlocked and reloaded.discovered_fusions == ["trinity_brush"] and config.get_value("unrelated", "keep") == "yes", "atomic save lost old progress or unrelated config")
	config.set_value("mastery", "weapons", {"unknown": 15, "uv_lamp": [], "trinity_brush": 15, "floss_whip": 1})
	config.save(session.progression_path)
	session.load_progression()
	_check(session.progression_data.weapon_masteries.size() == 1, "invalid stored mastery accepted")


func _legacy_and_validation() -> void:
	_new_game(&"water_jet")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	for broken in [[], {"eligible": []}, {"earned": {}}, {"pending": true}, {"starter_id": []}]:
		var invalid := saved.duplicate(true)
		invalid.weapon_mastery = broken
		_check(RunSaveData.normalize(invalid).is_empty(), "malformed mastery reached a typed restore")
	saved.erase("weapon_mastery")
	RunSnapshot.restore(game, saved)
	_check(game.weapon_mastery.starter_id == &"" and not game.weapon_mastery.eligible, "legacy resume guessed a starting weapon from equipment")
	game.weapon_mastery.record(session, &"victory", &"hell", 20)
	_check(game.weapon_mastery.earned.is_empty(), "historic save invented an achievement")
