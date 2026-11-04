extends "res://tests/support/test_runtime.gd"
## The diagnostic reserve must reproduce the real player's hit cadence.
const GAME = preload("res://tools/balance/comparison_game.gd")
const RESERVE_PLAYER = preload("res://tools/balance/boss_pressure_player.gd")
const SENSOR = preload("res://tools/balance/boss_pressure_observation.gd")
const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")
const SOUND = preload("res://tools/balance/boss_pressure_sound.gd")
var failures := 0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var sound := SOUND.new()
	root.add_child(sound)
	seed(12345)
	var expected := randf()
	seed(12345)
	sound.play_attack(&"drill")
	sound.play_cue(&"hit")
	sound.play_cue(&"pickup")
	if randf() != expected:
		push_error("Audit sound callbacks consumed combat RNG")
		failures += 1
	sound.queue_free()
	var baseline := await measure(false)
	var reserve := await measure(true)
	if baseline != reserve or baseline.hurt_time != Player.MAX_IFRAMES or baseline.second_hit != 0 or baseline.damage != 50:
		push_error("Diagnostic reserve changed normal hit protection: %s / %s" % [baseline, reserve])
		failures += 1
	for wave in [10, 15, 20]: await check_sensor(wave)
	root.get_node("GameSession").clear_run()
	finish(failures)

func measure(use_reserve: bool) -> Dictionary:
	var session := root.get_node("GameSession")
	session.save_path = "user://boss_pressure_probe_unused.json"
	session.resume_requested = false
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	game.set_script(GAME)
	if use_reserve: game.get_node("Player").set_script(RESERVE_PLAYER)
	root.add_child(game)
	current_scene = game
	paused = true
	game.player.stats.armor = 0
	game.player.stats.max_health = 130
	game.player.stats.health = 130
	if use_reserve:
		game.player.reference_max_health = 130
		game.player.stats.max_health = 100000
		game.player.stats.health = 100000
	var damage := [0.0]
	game.player.stats.damage_taken.connect(func(amount: float) -> void: damage[0] += amount)
	game.player.take_hit(30)
	var protection: float = game.player.hurt_time
	game.player._physics_process(0.25)
	var second: float = game.player.take_hit(30)
	game.player._physics_process(0.2)
	game.player.take_hit(20)
	if use_reserve and (game.player.stats.max_health != 100000 or game.player.stats.health != 99950): failures += 1
	var result := {"hurt_time": protection, "second_hit": second, "damage": damage[0]}
	_stop_audio(game)
	game.queue_free()
	await process_frame
	await process_frame
	return result

func check_sensor(wave: int) -> void:
	var session := root.get_node("GameSession")
	session.resume_requested = false
	session.selected_difficulty_id = &"hell"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	game.set_script(GAME)
	root.add_child(game)
	current_scene = game
	game.player.loadout.restore(PROFILES.setup("melee_single", wave, "base").equipment)
	game.debug_start_wave(wave)
	paused = true
	await process_frame
	var boss: Enemy = game.boss
	boss.global_position = game.player.global_position - Vector2(0, 280)
	if wave == 10:
		var c := boss.caramel_encounter
		c.bodyguard.advance(5)
		var actor := c.bodyguard.minion.caramel_enforcer
		actor.state = CaramelEnforcer.State.PUNCH_WARN
		actor.destination = game.player.global_position
		c.overload.state = CaramelOverload.State.BLAST
		c.overload.remaining = 1
		c.overload.anchor = boss.global_position
	elif wave == 15:
		var c := boss.acid_king_encounter
		c.companion.advance(6)
		var actor := c.companion.minion.acid_collector
		actor.state = AcidCollector.State.WARNING
		actor.destination = game.player.global_position
		c.pressure.state = KingPressureTrial.State.BLAST_WARNING
		c.pressure.remaining = 1
	else:
		var r := boss.crown_court_encounter.retinue
		boss.health = boss.max_health * 0.5
		r.begin()
		for minion in r.live_minions():
			var actor := minion.imperial_vassal
			actor.state = ImperialVassal.State.WARNING
			actor.origin = minion.global_position
			actor.destination = game.player.global_position
			actor.aim = actor.origin.direction_to(actor.destination)
		r.state = ImperialRetinue.State.FAILURE
		r.remaining = 1
	var world: Dictionary = SENSOR.new().capture(game, 0)
	if world.hazards.is_empty() or world.projectiles.is_empty() or world.enemies.size() != 1:
		push_error("Audit sensor wave %d: hazards=%d, shots=%d, contact bodies=%d" % [wave, world.hazards.size(), world.projectiles.size(), world.enemies.size()])
		failures += 1
	game._clear_arena(false)
	_stop_audio(game)
	game.queue_free()
	await process_frame
	await process_frame
