extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_projectile_pool.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	paused = true
	game.wave.active = false
	game.player.loadout.restore([])
	var pool: EnemyProjectilePool = game.get_node("EnemyProjectiles")
	pool.prepare(12)
	var count := pool.created
	var at: Vector2 = game.player.global_position + Vector2(200, 0)
	var statuses: Array[Dictionary] = [{"kind": DentiStatus.Type.POISON, "damage": 2.0, "duration": 3.0}]
	EnemyProjectilePatterns.fire_space_orb(pool, at, Vector2.LEFT, 120, 7, 34, game.player, statuses)
	var orb: AcidProjectile = pool.get_child(0)
	var id := orb.get_instance_id()
	var body := orb.body_sprite
	var halo := orb.halo_sprite
	orb.lifetime = 0.0
	orb._physics_process(0.0)
	_check(pool.get_child_count() == 0 and not orb.is_inside_tree() and not orb.is_physics_processing() and RunSnapshot.capture(game).acid.is_empty(), "idle projectile still ticks, draws or enters the save")
	EnemyProjectilePatterns.fire_aimed_fan(pool, at, Vector2.RIGHT, 1, 100, 9, game.player)
	var reused: AcidProjectile = pool.get_child(0)
	_check(reused.get_instance_id() == id and reused.body_sprite == body and reused.halo_sprite == halo and not halo.visible, "reuse created new sprites or retained the orb halo")
	_check(reused.inflicted_statuses.is_empty() and reused.hit_radius == 21 and reused.visual_radius == 9 and reused.animation_time == 0 and reused.lifetime == 3.0 and reused.damage == 9, "reused projectile retained old combat state")
	reused.lifetime = 0.0
	reused._physics_process(0.0)
	for cycle in 50:
		EnemyProjectilePatterns.fire_aimed_fan(pool, at, Vector2.RIGHT, 9, 100, 1, null)
		for shot: AcidProjectile in pool.get_children():
			shot.lifetime = 0.0
			shot._physics_process(0.0)
	_check(pool.created == count and pool.get_child_count() == 0 and pool.idle.size() == count, "repeated salvos allocate new bullets or lose retired bullets")
	game.player.stats.armor = 0
	game.player.hurt_time = 0
	var before: float = game.player.stats.health
	EnemyProjectilePatterns.fire_aimed_fan(pool, game.player.global_position, Vector2.RIGHT, 1, 0, 5, game.player, EnemyProjectilePatterns.ACID_COLOR, 2.2, statuses)
	var hit: AcidProjectile = pool.get_child(0)
	hit._physics_process(0.0)
	_check(game.player.stats.health == before - 5.0 and game.player.status_effects.active.has(DentiStatus.Type.POISON) and pool.get_child_count() == 0, "retirement lost direct damage or poison payload")
	EnemyProjectilePatterns.fire_space_orb(pool, at, Vector2.LEFT, 120, 9, 42, game.player, statuses)
	var snapshot := RunSnapshot.capture(game)
	_check(snapshot.acid.size() == 1 and snapshot.acid[0].hit_radius == 42, "save includes reserve bullets or loses active orb geometry")
	game.free()
	_check(not is_instance_valid(reused), "exiting the pool leaked idle bullets")
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	RunSnapshot.restore(game, snapshot)
	pool = game.get_node("EnemyProjectiles")
	_check(pool.get_child_count() == 1 and pool.get_child(0).pool == pool and pool.get_child(0).hit_radius == 42 and pool.get_child(0).inflicted_statuses.size() == 1, "restored bullets bypass pool ownership or lose statuses")
	game.free()
	session.clear_run()
	paused = false
	if failures == 0:
		print("Denti enemy projectile pooling test passed")
	quit(0 if failures == 0 else 1)
