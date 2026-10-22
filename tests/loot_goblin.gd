extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var arrivals := 0

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, reason: String) -> void:
	if not ok:
		failures.append(reason)
		push_error(reason)

func _goblin(game) -> Enemy:
	for mob: Enemy in game.get_node("Enemies").get_children():
		if mob.loot_goblin != null and not mob.is_queued_for_deletion(): return mob
	return null

func _run() -> void:
	var wave := WaveController.new()
	wave.goblin_profile = wave.goblin_profile.duplicate()
	wave.goblin_profile.spawn_chance = 1.0
	wave.loot_goblin_requested.connect(func() -> void: arrivals += 1)
	for number in [1, 7, 8, 9, 10, 15, 19, 20, 21]:
		wave.current_wave = number - 1
		wave.endless_enabled = number > 20
		wave.start_next_wave()
		_check(wave.goblin_reserved_slots() == (1 if number >= 8 and number % 5 != 0 else 0), "goblin reservation affects an ineligible wave")
		arrivals = 0
		wave.remaining = 25.1
		for step in 5: wave._process(0.1)
		var expected := 1 if number >= 8 and number % 5 != 0 else 0
		_check(arrivals == expected, "goblin eligibility or once-per-wave roll failed at wave %d" % number)
		_check(wave.goblin_reserved_slots() == 0, "goblin reservation was not released after the event roll")
		var resumed := WaveController.new()
		resumed.goblin_profile = wave.goblin_profile
		resumed.loot_goblin_requested.connect(func() -> void: arrivals += 1)
		resumed.restore_state(wave.save_state())
		resumed._process(0.1)
		_check(arrivals == expected, "resume rerolled the goblin event")
		resumed.free()
	wave.free()
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://loot_goblin_run.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.current_wave = 12
	game.wave.active = true
	game.wave.remaining = 23
	game.wave.goblin_checked = true
	game.player.global_position = Vector2(600, 600)
	game._spawn_loot_goblin()
	var thief := _goblin(game)
	_check(thief != null, "game did not create the goblin")
	thief.global_position = Vector2(1100, 600)
	game._spawn_loot(thief.position, &"coin", 12)
	game._spawn_loot(thief.position, &"xp", 5)
	game._spawn_loot(thief.position, &"chest", 4, &"metal_crown")
	var wallet: int = game.coins
	thief._physics_process(0.01)
	thief._physics_process(0.4)
	_check(thief.loot_goblin.carried == 12 and game.coins == wallet and game.xp == 0, "theft granted pickup effects or changed wallet/XP")
	_check(game.rewards.pending_chests.is_empty() and paused, "theft opened a reward choice")
	var pile: Loot
	game._spawn_loot(thief.position, &"coin", 50)
	pile = game.get_node("Loot").get_child(-1)
	_check(pile.take_for_goblin(7) == 7 and pile.amount == 43, "partial theft lost the remainder of a coin pile")
	game._spawn_loot(game.player.position + Vector2(30, 0), &"coin", 8)
	var protected: Loot = game.get_node("Loot").get_child(-1)
	_check(protected.take_for_goblin(30) == 0 and protected.amount == 8, "goblin stole player-magnet loot")
	var original_capsule: Dictionary = thief.loot_goblin.capsule.duplicate(true)
	var saved_grab_time: float = thief.loot_goblin.grab_time
	var valid_snapshot := RunSnapshot.capture(game)
	for invalid_payload in [{"capsule": {"kind": "affix", "options": {}}}, {"capsule": {"kind": "affix", "options": [{"damage": []}]}}, {"destination": [0, {}]}, {"carried": []}, {"grab_time": []}]:
		var corrupted := valid_snapshot.duplicate(true)
		for entry in corrupted.enemies:
			if entry.type == EnemyCatalog.LOOT_GOBLIN.resource_path: entry.loot_goblin = invalid_payload
		_check(RunSaveData.normalize(corrupted).is_empty(), "invalid goblin save was accepted")
	var invalid_metrics := valid_snapshot.duplicate(true)
	invalid_metrics.telemetry.goblin_stats = []
	_check(RunSaveData.normalize(invalid_metrics).is_empty(), "invalid goblin telemetry was accepted")
	game._save_run()
	game.free()
	session.resume_requested = true
	paused = false
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	paused = true
	thief = _goblin(game)
	_check(thief != null and thief.loot_goblin.carried == 12 and thief.loot_goblin.capsule == original_capsule, "JSON save/resume lost stolen gold or rerolled the capsule")
	_check(is_equal_approx(thief.loot_goblin.grab_time, saved_grab_time), "JSON resume reset the moving pickup cooldown")
	_check(game.wave.goblin_checked and int(game.telemetry.goblin_stats.get("stolen", 0)) == 12, "resume lost the event or theft telemetry")
	# Kill synchronously, snapshot before deferred deletion: no resurrection or double reward.
	thief.take_damage(1000000)
	var returned := 0
	var capsules := 0
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.is_queued_for_deletion(): continue
		if drop.reward_data.get("source", "") == "goblin_return": returned += drop.amount
		if drop.reward_id == WeaponAffixes.CHEST_ID: capsules += 1
	_check(returned == 12 and capsules == 1, "death lost or duplicated returned coins / golden capsule")
	var dead_snapshot := RunSnapshot.capture(game)
	for entry in dead_snapshot.enemies:
		_check(entry.type != EnemyCatalog.LOOT_GOBLIN.resource_path, "snapshot resurrects an already rewarded goblin")
	_check(game.rewards.pending_chests.is_empty(), "goblin death opened a combat reward modal")
	await process_frame
	game._spawn_loot_goblin()
	thief = _goblin(game)
	thief.loot_goblin.carried = 23
	game.wave.active = false
	game._on_wave_finished(12)
	_check(int(game.telemetry.goblin_stats.get("lost", 0)) == 23 and int(game.telemetry.goblin_stats.get("escaped", 0)) == 1, "wave-end escape did not remove carried gold exactly once")
	thief.loot_goblin.escape()
	_check(int(game.telemetry.goblin_stats.get("lost", 0)) == 23, "escape was counted twice")
	session.clear_run()
	paused = false
	game.free()
	if failures.is_empty(): print("Denti goblin scheduling, coin ownership, JSON resume, death and escape test passed")
	finish(0 if failures.is_empty() else 1)
