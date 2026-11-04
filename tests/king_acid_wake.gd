extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session := root.get_node("GameSession")
	session.save_path = "user://king_acid_wake.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.selected_difficulty_id = &"hell"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.dodge_chance = 0
	game.player.stats.shield_charges = 0
	game.wave.current_wave = 15
	game.wave.difficulty_id = &"hell"
	game.wave.set_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.global_position = game.arena.arena_size * 0.5
	game.player.get_node("Camera2D").force_update_scroll()
	game._create_enemy(EnemyCatalog.CAVITY_KING, game.player.global_position - Vector2(260, 0))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	var court := boss.acid_king_encounter
	var trial := court.pressure
	var wake := court.acid_wake
	boss.health = boss.max_health * trial.profile.health_thresholds[0]
	court.advance(0.01)
	court.advance(trial.remaining)
	game.player.global_position = trial.stance(0)
	court.advance(trial.remaining)
	var direction := trial.aim
	var from := trial.origin
	game.player.global_position += direction.orthogonal() * 90
	court.advance(trial.remaining + trial.profile.firing_seconds)
	_check(trial.state == KingPressureTrial.State.RECOIL and trial.valves[0].broken and wake.streams.size() == 1, "fired shield ray left no acid stream or missed the valve")
	var stream: Dictionary = wake.streams[0]
	_check(stream.from.is_equal_approx(from + direction * trial.profile.acid_inner_gap) and stream.to.distance_to(stream.from) > 100, "stream changed its warned line or blocked the inner passage")
	_check(is_equal_approx(stream.life, 6), "Hell acid stream does not last six seconds")
	game.player.hurt_time = 0
	game.player.stats.health = 10000
	game.player.global_position = stream.from.lerp(stream.to, 0.1)
	wake.advance(trial.profile.acid_arm_seconds - 0.001)
	_check(game.player.stats.health == 10000, "acid damaged before its arming grace expired")
	wake.advance(0.01)
	_check(game.player.stats.health < 10000, "standing in the acid trail is harmless")
	var health: float = game.player.stats.health
	game.player.hurt_time = 0
	wake.advance(trial.profile.acid_tick_seconds * 0.5)
	_check(game.player.stats.health == health, "acid ignores its damage cadence")
	wake.advance(trial.profile.acid_tick_seconds)
	_check(game.player.stats.health < health, "acid stopped dealing periodic damage")
	game.player.hurt_time = 0
	game.player.stats.health = 10000
	game.player.global_position = from + direction * 120
	wake.advance(0.7)
	_check(game.player.stats.health == 10000, "the intended inner crossing is blocked by acid")
	# Save/reload real floor geometry, remaining life and damage cooldown.
	game._save_run()
	_check(not session.load_run().is_empty(), "acid-stream run failed validation")
	var saved := wake.save_data()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	boss = game.boss
	boss.set_simulation_enabled(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	court = boss.acid_king_encounter
	trial = court.pressure
	wake = court.acid_wake
	_check(wake.streams.size() == 1 and wake.streams[0].from == SnapshotValues.read_vector(saved.streams[0].from) and absf(wake.streams[0].life - saved.streams[0].life) < 0.05 and wake.streams[0].cooldown <= saved.streams[0].cooldown + 0.001, "reload moved, extended or reset the acid stream")
	var frozen := wake.save_data()
	await process_frame
	await process_frame
	_check(wake.save_data() == frozen, "pause aged the acid streams")
	# Count and lifetime are bounded, including misses; the warning never tracks.
	for index in 5:
		wake.add_beam(trial.anchor, trial.anchor + Vector2.from_angle(index * 0.5) * 900)
	_check(wake.streams.size() == trial.profile.acid_max_streams, "acid streams accumulate without a cap")
	game.player.global_position = Vector2(75, 75)
	wake.advance(7)
	_check(wake.streams.is_empty(), "acid streams do not expire")
	wake.add_beam(trial.anchor, trial.anchor + Vector2.RIGHT * 500)
	for valve in trial.valves: valve.broken = true
	trial.state = KingPressureTrial.State.RECOIL
	trial.remaining = 0.001
	trial.advance(0.002)
	_check(trial.state == KingPressureTrial.State.SHATTER and wake.streams.is_empty(), "shield break did not clear the counterattack floor")
	var legacy := court.save_data()
	legacy.version = 3
	legacy.erase("acid_wake")
	legacy.erase("companion")
	court.restore(legacy)
	wake.add_beam(trial.anchor, trial.anchor + Vector2.RIGHT * 500)
	_check(wake.legacy and wake.streams.is_empty() and court.companion.legacy, "old v3 fight acquired unannounced floor hazards or a minion")
	_check(not KingAcidWake.valid({"streams": [{"from": [0], "to": [1,2]}]}) and not AcidKingSnapshot.valid({"acid_wake": {"streams": "bad"}}), "malformed acid field snapshot passed validation")
	session.clear_run()
	if failures.is_empty(): print("PASS king_acid_wake: real ray remnants, six-second Hell life, delayed/periodic damage, safe crossing, capped fields, real reload, pause, shield cleanup and legacy")
	finish(0 if failures.is_empty() else 1)
