extends SceneTree

var failures: int = 0
var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _spawn(data: EnemyData, offset: Vector2, wave: int = 1) -> Enemy:
	var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	enemy.position = game.player.position + offset
	enemy.configure(data, game.player, wave)
	game.get_node("Enemies").add_child(enemy)
	enemy.special_timer = 10.0
	return enemy


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://test_enemy_facing.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	paused = true
	var center: Vector2 = game.player.position
	var biter := _spawn(WaveController.GUM_BITER, Vector2(250.0, 0.0))
	_check(biter.sprite.flip_h, "right-facing artwork did not initially look toward player on left")
	biter._physics_process(0.02)
	_check(biter.position.x < center.x + 250.0 and biter.sprite.flip_h, "leftward chase was not mirrored")
	biter.position = center - Vector2(250.0, 0.0)
	biter._physics_process(0.02)
	_check(biter.position.x > center.x - 250.0 and not biter.sprite.flip_h, "rightward chase stayed mirrored")
	biter.position = center + Vector2(250.0, 0.0)
	biter.special_timer = 0.0
	biter._physics_process(0.02)
	# Enter warning within its trigger range, then move the target across it.
	biter.position = center + Vector2(150.0, 0.0)
	biter._physics_process(0.02)
	_check(biter.special_phase == Enemy.SpecialPhase.WARNING and biter.sprite.flip_h, "dash warning did not face its locked direction")
	game.player.position = biter.position + Vector2(120.0, 0.0)
	biter._physics_process(biter.data.warning_time)
	var dash_start := biter.position
	biter._physics_process(0.02)
	_check(biter.position.x < dash_start.x and biter.sprite.flip_h, "dash facing followed target instead of actual locked movement")
	game.player.position = center
	var shooter := _spawn(WaveController.POISON_GERM, Vector2(100.0, 0.0), 12)
	var retreat_start := shooter.position
	shooter._physics_process(0.02)
	shooter._process(0.02)
	_check(shooter.position.x > retreat_start.x and not shooter.sprite.flip_h, "retreat faced player instead of travel direction, or render loop overwrote it")
	shooter.position = center - Vector2(100.0, 0.0)
	shooter._physics_process(0.02)
	shooter._process(0.02)
	_check(shooter.sprite.flip_h, "leftward retreat did not mirror")
	var lane := _spawn(WaveController.ACID_SPITTER, Vector2(350.0, 0.0), 14)
	lane._physics_process(0.02)
	_check(lane.active_special_attack == EnemyData.SpecialAttack.LANE and lane.sprite.flip_h, "advanced ranged role lost directional facing")
	lane.special_timer = 10.0
	lane.position = center + Vector2(0.0, 350.0)
	lane._physics_process(0.02)
	lane._process(0.02)
	_check(lane.sprite.flip_h, "vertical movement changed previous facing")
	var frontal := _spawn(WaveController.PLAQUE, Vector2(200.0, 0.0))
	frontal._physics_process(0.02)
	_check(not frontal.sprite.flip_h, "frontal artwork was unnecessarily mirrored")
	var left_art: EnemyData = WaveController.GUM_BITER.duplicate()
	left_art.sprite_facing = EnemyData.SpriteFacing.LEFT
	var left_enemy := _spawn(left_art, Vector2(250.0, 0.0))
	left_enemy._physics_process(0.02)
	_check(not left_enemy.sprite.flip_h, "left-facing source artwork was mirrored during leftward travel")
	left_enemy.position = center - Vector2(250.0, 0.0)
	left_enemy._physics_process(0.02)
	_check(left_enemy.sprite.flip_h, "left-facing source artwork did not mirror during rightward travel")
	left_enemy.free()
	# Preserve last horizontal facing during a stationary/vertical save and resume.
	game._save_run()
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var resumed_lane: Enemy = game.get_node("Enemies").get_child(2)
	_check(resumed_lane.sprite.flip_h, "save/resume lost facing for a vertically moving enemy")
	resumed_lane._physics_process(0.02)
	_check(resumed_lane.sprite.flip_h, "first vertical step after resume reset facing")
	game.free()
	session.clear_run()
	paused = false
	if failures == 0:
		print("PASS enemy_facing")
	quit(0 if failures == 0 else 1)
