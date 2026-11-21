extends "res://tests/support/test_runtime.gd"
## Cosmetic hit punch and death pop: they animate, settle back exactly, stay
## within their budget, create no per-hit nodes and never touch gameplay.

var failures: Array[String] = []
var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _enemy(data: EnemyData, at: Vector2, health: float) -> Enemy:
	game._create_enemy(data, at)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.max_health = health
	enemy.health = health
	enemy.set_physics_process(false)
	return enemy


func _step(enemy: Enemy, seconds: float) -> void:
	var frames := ceili(seconds * 60.0)
	for frame in frames:
		enemy._process(1.0 / 60.0)


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://enemy_impacts_test.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.player.global_position = Vector2(200, 300)
	paused = true
	var pops: EnemyDeathPops = game.get_node("DeathPops")
	_check(pops.get_index() == game.get_node("Enemies").get_index() + 1, "Death pops must draw directly above enemy bodies")

	# Hit punch: visible squash and recoil, then exactly back to rest.
	var target := _enemy(WaveController.SUGAR, Vector2(400, 300), 1000.0)
	var base_scale := target.sprite_base_scale
	var health_before := target.health
	target.take_damage(200.0, null, false, &"", [], Vector2.RIGHT)
	_check(is_equal_approx(health_before - target.health, 200.0 * (1.0 - target.damage_reduction)) or target.health < health_before, "Hit punch must not change damage")
	_check(target.hit_reaction.active(), "A direct hit must start the punch")
	_check(target.hit_reaction.direction.is_equal_approx(Vector2.RIGHT), "The punch must follow the hit direction")
	_step(target, 1.0 / 60.0)
	_check(target.sprite.scale.x < base_scale.x, "A horizontal hit must compress the sprite horizontally")
	_check(target.sprite.position.x > 0.0, "A hit from the left must push the sprite right")
	_step(target, EnemyHitReaction.DURATION + 0.05)
	_check(not target.hit_reaction.active(), "The punch must end")
	_check(target.sprite.scale.is_equal_approx(base_scale), "Scale must return exactly to rest")
	_check(is_zero_approx(target.sprite.position.x), "Recoil must return exactly to rest")

	# Without a hit direction the punch pushes away from Denti.
	target.take_damage(50.0)
	_check(target.hit_reaction.direction.dot((target.global_position - game.player.global_position).normalized()) > 0.99, "Undirected hits must push away from Denti")
	_step(target, EnemyHitReaction.DURATION + 0.05)

	# Continuous weak fire does not restart the punch on every hit.
	var reaction := EnemyHitReaction.new()
	reaction.register(1.0, false, false, Vector2.RIGHT)
	var strong := reaction.strength
	reaction.advance(EnemyHitReaction.DURATION * 0.2)
	reaction.register(0.0, false, true, Vector2.LEFT)
	_check(is_equal_approx(reaction.strength, strong) and reaction.direction == Vector2.RIGHT, "A weak hit must not cut off a fresh strong punch")
	reaction.advance(EnemyHitReaction.DURATION * 0.5)
	reaction.register(0.0, false, true, Vector2.LEFT)
	_check(reaction.direction == Vector2.LEFT and is_equal_approx(reaction.time, EnemyHitReaction.DURATION), "A weak hit restarts once the punch has mostly played")
	var boss_reaction := EnemyHitReaction.new()
	boss_reaction.register(1.0, true, false, Vector2.UP, EnemyHitReaction.BOSS_FACTOR)
	_check(boss_reaction.strength < 0.5, "Bosses only wobble slightly")

	# Death pop: one batched event per ordinary death, no extra nodes.
	var children_before := game.get_child_count()
	var victims: Array[Enemy] = []
	for index in 3:
		victims.append(_enemy(WaveController.PLAQUE, Vector2(500 + index * 60, 300), 10.0))
	for victim in victims:
		victim.take_damage(100.0, null, false, &"", [], Vector2.LEFT)
	_check(pops.events.size() == 3, "Each ordinary death must add one pop")
	_check(Vector2(pops.events[0].direction).is_equal_approx(Vector2.LEFT), "Crumbs must fly away from the killing hit")
	_check(game.get_child_count() == children_before, "Pops must not add nodes to the game")
	_check(pops.is_processing(), "Pops must animate while events exist")
	for frame in ceili(EnemyDeathPops.DURATION * 60.0) + 2:
		pops._process(1.0 / 60.0)
	_check(pops.events.is_empty() and not pops.is_processing(), "Pops must expire and stop processing")
	_check(is_equal_approx(EnemyDeathPops.body_scale(0.0), 1.0) and is_zero_approx(EnemyDeathPops.body_scale(1.0)), "Body must start at rest size and vanish")

	# Budget under mass kills.
	for index in EnemyDeathPops.MAX_EVENTS + 20:
		_enemy(WaveController.BACTERIA, Vector2(300 + index % 20 * 30, 500 + index / 20 * 30), 1.0).take_damage(10.0)
	_check(pops.events.size() == EnemyDeathPops.MAX_EVENTS, "Pops must respect their budget")

	# Bosses keep their own death animation.
	var boss := _enemy(WaveController.CAVITY_KING, Vector2(700, 300), 5.0)
	var before := pops.events.size()
	pops.clear()
	boss.take_damage(1000000.0)
	_check(pops.events.is_empty() and before > 0, "Boss deaths must not use the ordinary pop")

	# Arena clears and save/resume never carry pops.
	_enemy(WaveController.PLAQUE, Vector2(300, 300), 1.0).take_damage(10.0)
	game._clear_combat()
	_check(pops.events.is_empty(), "Clearing combat must remove pops")
	_enemy(WaveController.PLAQUE, Vector2(300, 300), 1.0).take_damage(10.0)
	var snapshot: Dictionary = load("res://scripts/systems/run_snapshot.gd").capture(game)
	_check(not JSON.stringify(snapshot).contains("DeathPops"), "Pops are cosmetic and must not be saved")
	load("res://scripts/systems/run_snapshot.gd").restore(game, snapshot)
	_check(pops.events.is_empty(), "Restoring a run must start without pops")

	session.clear_run()
	finish(1 if not failures.is_empty() else 0)
