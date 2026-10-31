extends "res://tests/support/test_runtime.gd"
const BATCH := preload("res://scripts/vfx/telegraph_batch.gd")
var failures := 0
func _initialize() -> void: call_deferred("_run")
func _check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _shapes(canvas: CanvasItem) -> Array[int]:
	var result: Array[int] = []
	if not canvas.has_meta(BATCH.META): return result
	var batch = canvas.get_meta(BATCH.META)
	for index in batch.count: result.append(floori(batch.parameters[index].r) % 8)
	return result
func _settle() -> void:
	for frame in 3: await process_frame
func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_lane_endpoints.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.player.loadout.restore([])
	game.wave.active = false
	game.wave.current_wave = 17
	paused = true
	var spatial: EnemySpatialIndex = game.get_node("Enemies")
	var local := Node2D.new()
	game.add_child(local)
	var legacy := EnemyCatalog.CAVITY_EMPEROR.duplicate() as EnemyData
	legacy.crown_court_profile = null
	legacy.boss_signature = EnemyData.BossSignature.SPACE_ORB
	legacy.boss_guard_recharge_seconds = 2
	var cases := [
		[EnemyCatalog.SUGAR, EnemyData.SpecialAttack.DASH],
		[legacy, EnemyData.SpecialAttack.BOSS],
		[load("res://data/enemies/acid_crown.tres"), EnemyData.SpecialAttack.SPACE_ORB],
		[EnemyCatalog.ACID_SPITTER, EnemyData.SpecialAttack.LANE]]
	for shared in [true, false]:
		for row in cases:
			var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
			enemy.configure(row[0], game.player, 17)
			(spatial if shared else local).add_child(enemy)
			enemy.set_process(false)
			enemy.set_simulation_enabled(false)
			enemy.global_position = game.player.global_position - Vector2(200, 0)
			enemy.active_special_attack = row[1]
			enemy.special_phase = Enemy.SpecialPhase.WARNING
			enemy.special_direction = Vector2.RIGHT
			enemy.charge_aim_distance = 200
			enemy.boss_move = Enemy.BossMove.CHARGE
			enemy.boss_dash_end = enemy.global_position + Vector2(420, 0)
			for progress in [0.25, 0.85]:
				enemy.special_timer = enemy.data.warning_time * (1 - progress)
				enemy.queue_redraw()
				spatial._process(0)
				await _settle()
				var shapes := _shapes(spatial if shared else enemy)
				_check(shapes.count(BATCH.Shape.LANE) == 1 and not shapes.has(BATCH.Shape.CIRCLE), "lane retained an endpoint circle: attack %s, shared %s" % [row[1], shared])
			if row[1] == EnemyData.SpecialAttack.BOSS:
				enemy.boss_phase = 2
				enemy.boss_phase_timer = 1
				enemy.boss_phase_burst_fired = false
				enemy.queue_redraw()
				await _settle()
				var preview := _shapes(enemy)
				_check(preview.has(BATCH.Shape.LANE) and not preview.has(BATCH.Shape.CIRCLE), "boss orb preview retained an endpoint circle")
			enemy.free()
			spatial._process(0)
			await _settle()
	game.free()
	paused = false
	session.clear_run()
	if failures == 0: print("PASS lane_warning_endpoints: sugar/boss charges, orb and projectile lanes, boss preview, local/shared drawing and two charge stages")
	finish(0 if failures == 0 else 1)
