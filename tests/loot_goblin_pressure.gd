extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, reason: String) -> void:
	if not ok:
		failures.append(reason)
		push_error(reason)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://goblin_pressure.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.set_process(false)
	game.wave.current_wave = 11
	game.wave.difficulty_id = &"normal"
	game.wave.active = true
	game.player.position = Vector2(800, 850)
	game._spawn_loot_goblin()
	var thief: Enemy = game.get_node("Enemies").get_child(-1)
	thief.position = Vector2(1040, 850)
	game._spawn_loot(thief.position + Vector2(40, 0), &"coin", 5)
	game._spawn_loot(thief.position + Vector2(60, 0), &"coin", 7)
	game._spawn_loot(thief.position, &"xp", 5)
	game._spawn_loot(thief.position, &"chest", 4, &"metal_crown")
	game._spawn_loot(game.player.position + Vector2(30, 0), &"coin", 9)
	var protected: Loot = game.get_node("Loot").get_child(-1)
	var wallet: int = game.coins
	thief._physics_process(0.01)
	_check(thief.loot_goblin.carried == 12 and thief.loot_goblin.state == LootGoblin.State.SPRINT and thief.loot_goblin.walking, "fleeing goblin failed to scoop nearby piles while moving")
	_check(thief.loot_goblin.grab_animation_time > 0 and int(game.telemetry.goblin_stats.get("stolen", 0)) == 12, "moving scoop has no animation or batch telemetry")
	game._spawn_loot(thief.position + Vector2(30, 0), &"coin", 6)
	thief._physics_process(0.05)
	_check(thief.loot_goblin.carried == 12, "scoop ignored its cooldown")
	thief._physics_process(0.09)
	_check(thief.loot_goblin.carried == 18, "next nearby pile was not scooped within a fraction of a second")
	game._spawn_loot(thief.position + Vector2(40, 0), &"coin", 50)
	var remainder: Loot = game.get_node("Loot").get_child(-1)
	thief._physics_process(0.13)
	thief._physics_process(0.13)
	_check(thief.loot_goblin.carried == 30 and remainder.amount == 38, "moving scoop exceeded bag capacity or lost a partial pile")
	_check(protected.amount == 9 and game.coins == wallet and game.xp == 0 and game.rewards.pending_chests.is_empty(), "moving scoop stole protected loot or triggered player rewards")
	# Reproduce the W11 feedback with real weapon damage and an actual pursuit.
	# This checks a fight duration rather than freezing the chosen health values.
	game._clear_arena(false)
	await process_frame
	game.player.position = Vector2(850, 850)
	game.player.stats.damage_bonus = 50
	game.player.stats.melee_damage = 14
	game.player.stats.ranged_damage = 12
	game.player.stats.attack_speed = 45
	var weapons: Array[Dictionary] = []
	for id in ["magic_toothbrush", "turbo_drill", "water_jet", "toothpick_spear", "prophylaxis_polisher"]:
		weapons.append({"id": id, "tier": 3})
	game.player.loadout.restore(weapons)
	seed(20261022)
	game._spawn_loot_goblin()
	thief = game.get_node("Enemies").get_child(-1)
	thief.position = Vector2(1090, 850)
	var frame := 0
	paused = false
	while is_instance_valid(thief) and not thief.is_queued_for_deletion() and frame < 900:
		game.player.position = game.player.position.move_toward(thief.position, PlayerStats.BASE_MOVE_SPEED / 60)
		await physics_frame
		frame += 1
	_check(frame >= 180 and frame < 720, "W11 goblin melted or became a sponge against the configured Mk III pursuit: %.2fs" % (frame / 60.0))
	session.clear_run()
	game.free()
	paused = false
	if failures.is_empty(): print("Denti moving loot scoops, capacity, pickup priority and W11 pursuit durability passed: %.2fs" % (frame / 60.0))
	finish(0 if failures.is_empty() else 1)
