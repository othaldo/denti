extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://test_enemy_death_once.json"
	var game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	paused = true
	game.player.loadout.restore([{"id": "trinity_brush", "tier": 4}])
	game.wave.current_wave = 1
	game.wave.active = true
	game.rewards.chest_spawned = true
	var data := WaveController.PLAQUE.duplicate() as EnemyData
	data.coin_drop_chance = 1.0
	game._create_enemy(data, game.player.global_position + Vector2(100, 0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.health = 25
	enemy.max_health = 100
	enemy.damage_reduction = 0
	var events := {"died": 0, "defeated": 0}
	enemy.died.connect(func(_enemy, _amount): events.died += 1)
	enemy.defeated.connect(func(_at, _data): events.defeated += 1)
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	WeaponAttackShapes.hit(enemy, weapon.data, 4, 10, false, game.items, Vector2.RIGHT)
	assert(enemy.health == 15 and weapon.evolution.marks.size() == 1)
	WeaponAttackShapes.hit(enemy, weapon.data, 4, 10, false, game.items, Vector2.RIGHT)
	_check(enemy.health == 0, "the detonation must still kill its source target")
	_check(events.died == 1 and events.defeated == 1, "a nested lethal hit emitted death twice")
	_check(game.telemetry.kills == 1, "a nested lethal hit counted two kills")
	_check(game.get_node("Loot").get_child_count() == 2, "a nested lethal hit duplicated XP/coins")
	_check(game.telemetry.total_damage == 25, "nested damage changed actual damage accounting")
	game.queue_free()
	await process_frame
	await process_frame
	finish(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
