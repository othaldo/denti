extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason); push_error(reason)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://goblin_motion.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.current_wave = 12
	game.wave.active = true
	game.player.global_position = Vector2(700, 600)
	game._spawn_loot_goblin()
	var thief: Enemy = game.get_node("Enemies").get_child(-1)
	thief.global_position = Vector2(1000, 600)
	for point in [Vector2(1100, 670), Vector2(1125, 690)]: game._create_enemy(EnemyCatalog.SUGAR, point)
	var cover := thief.loot_goblin.choose_cover()
	var blockers := 0
	for mob: Enemy in game.get_node("Enemies").get_children():
		if mob == thief: continue
		var closest := Geometry2D.get_closest_point_to_segment(mob.position, game.player.position, cover)
		if closest.distance_to(mob.position) <= mob.data.radius + 28: blockers += 1
	_check(blockers > 0 and cover.distance_to(game.player.position) > thief.position.distance_to(game.player.position), "goblin did not put the existing mob group between itself and Denti")
	game._clear_combat()
	await process_frame
	for difficulty in DifficultyCatalog.ALL:
		game.wave.difficulty_id = difficulty.id
		game.player.position = Vector2(850, 850)
		game._spawn_loot_goblin()
		thief = game.get_node("Enemies").get_child(-1)
		thief.position = Vector2(1140, 850)
		var windows := 0
		for frame in 720:
			game.get_node("Enemies").motion.step(game.get_node("Enemies"), 1.0 / 60)
			game.player.position = game.player.position.move_toward(thief.position, PlayerStats.BASE_MOVE_SPEED / 60)
			if game.player.position.distance_to(thief.position) < 95: windows += 1
		_check(windows >= 30, "%s goblin has no sustained melee opportunity in a 12 second pursuit" % difficulty.id)
		var index := game.get_node("Enemies") as EnemySpatialIndex
		_check(index.in_circle(thief.position, 1).has(thief), "custom movement left the targeting index stale")
		var normal_speed := thief._movement_speed()
		thief.apply_wet(2)
		_check(thief._movement_speed() < normal_speed, "wet cannot help pursue the goblin")
		var hp: float = game.player.stats.health
		game.player.stats.shield_charges = 2
		thief.try_contact_hit()
		_check(game.player.stats.health == hp and game.player.stats.shield_charges == 2, "harmless goblin contact consumed health or shields")
		thief.free()
	session.clear_run()
	game.free()
	paused = false
	if failures.is_empty(): print("Denti goblin cover, central motion, four-difficulty melee pursuit and wet test passed")
	finish(0 if failures.is_empty() else 1)
