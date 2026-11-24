extends "res://tests/support/test_runtime.gd"

## Knockback, pulls and shoves must never move enemies through the arena walls.

var game: Node2D


func _initialize() -> void: call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_arena_knockback_bounds.json"
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
	var size: Vector2 = game.arena.arena_size
	var near := DentiArena.WALL_WIDTH + 70.0
	var cases := {
		Vector2.LEFT: Vector2(near, size.y / 2.0),
		Vector2.RIGHT: Vector2(size.x - near, size.y / 2.0),
		Vector2.UP: Vector2(size.x / 2.0, near),
		Vector2.DOWN: Vector2(size.x / 2.0, size.y - near),
		Vector2(-1, -1).normalized(): Vector2(near, near),
	}
	for direction: Vector2 in cases:
		var enemy := _enemy(cases[direction])
		enemy.apply_push(direction * 5000.0)
		check(_inside(enemy), "push moved an enemy through the wall: %s -> %s" % [direction, enemy.global_position])
		check(enemy.global_position.distance_to(cases[direction]) > 1.0, "push next to a wall did not move the enemy at all: %s" % direction)
	# A weapon hit at the wall uses the same bounded push.
	var weapon: WeaponData = load("res://data/weapons/turbo_drill.tres").duplicate(true)
	weapon.knockback = 5000.0
	weapon.knockback_tiers = PackedFloat32Array([5000.0, 5000.0, 5000.0, 5000.0])
	var target := _enemy(Vector2(size.x - near, size.y / 2.0))
	var start := target.global_position
	WeaponAttackShapes.hit(target, weapon, 1, 1.0, false, null, Vector2.RIGHT, [], 1.0, false)
	check(target.global_position.x > start.x, "weapon knockback fixture did not push")
	check(_inside(target), "weapon knockback moved an enemy through the wall: " + str(target.global_position))
	# Resistant enemies still stand firm.
	var anchor := _enemy(size / 2.0)
	anchor.data = anchor.data.duplicate(true)
	anchor.data.knockback_resistance = 1.0
	anchor.apply_push(Vector2.RIGHT * 300.0)
	check(anchor.global_position.is_equal_approx(size / 2.0), "fully resistant enemy was pushed")
	_arena_helpers(game.arena)
	session.clear_run()
	if failures.is_empty():
		print("PASS arena knockback bounds: pushes, pulls and weapon knockback stay inside the walls")
	finish_checks()


func _arena_helpers(arena: DentiArena) -> void:
	var size := arena.arena_size
	var wall := DentiArena.enemy_margin(20)
	check(is_equal_approx(wall, DentiArena.WALL_WIDTH + 20 + DentiArena.ENEMY_WALL_GAP), "enemy margin changed its formula")
	check(arena.clamp_enemy(Vector2(-500, size.y + 500), 20).is_equal_approx(Vector2(wall, size.y - wall)), "enemy clamp left the floor")
	check(arena.clamp_player(size * 2).is_equal_approx(size - Vector2.ONE * DentiArena.PLAYER_MARGIN), "player clamp left the floor")
	check(arena.clamp_inside(size / 2, 60).is_equal_approx(size / 2), "clamp moved a central point")
	var inner := arena.inner_rect(60)
	check(inner.position.is_equal_approx(Vector2.ONE * 60) and inner.end.is_equal_approx(size - Vector2.ONE * 60), "inner rect has the wrong edges")


func _enemy(at: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, at)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 10000
	enemy.max_health = 10000
	return enemy


func _inside(enemy: Enemy) -> bool:
	var margin := DentiArena.WALL_WIDTH + enemy.data.radius
	var size: Vector2 = game.arena.arena_size
	var at := enemy.global_position
	return at.x >= margin and at.y >= margin and at.x <= size.x - margin and at.y <= size.y - margin
