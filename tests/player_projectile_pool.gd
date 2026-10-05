extends SceneTree

var failures := 0
var game: Node2D
var pool: PlayerProjectilePool
const MAGIC: WeaponData = preload("res://data/weapons/magic_toothbrush.tres")
const HALO: WeaponData = preload("res://data/weapons/halo.tres")
const ROCKET: WeaponData = preload("res://data/weapons/fluoride_rocket.tres")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _shot(data: WeaponData, tier: int = 4, inventory: ItemInventory = null) -> WeaponProjectile:
	var shot := pool.acquire(data, tier)
	shot.launch(game.player.global_position + Vector2(200, 0), Vector2.RIGHT, 100, data, inventory, false, tier)
	return shot

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_player_projectile_pool.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	paused = true
	game.wave.active = false
	game.player.loadout.restore([])
	game.items.restore({})
	pool = game.get_node("Projectiles")
	pool.prepare(MAGIC, 4, 12)
	var count := pool.created
	var shot := _shot(MAGIC)
	var body := shot.body_sprite
	var tail := shot.tail_sprite
	var outline := shot.outline_sprite
	# Exercise actual expiry before stressing all state that can survive reuse.
	shot._physics_process(10)
	_check(shot.retired and not shot.is_inside_tree() and not shot.is_physics_processing() and RunSnapshot.capture(game).player_projectiles.is_empty(), "retired player shot still ticks, draws or enters the save")
	shot.retire()
	pool.recycle(shot)
	_check(pool.idle_count == 12 and not shot.is_queued_for_deletion(), "retiring twice duplicates or deletes a reserve shot")
	shot = _shot(MAGIC)
	shot.traveled = 123
	shot.animation_time = 9
	shot.impact_time = 0.1
	shot.hit_ids.append(12345)
	shot.return_factor = 1.5
	shot.returning = true
	shot.return_rearmed = true
	shot.return_hits_left = 3
	shot.orbit_time = 0.5
	shot.orbit_center = Vector2(90, 20)
	shot.orbit_finished = true
	shot.orbit_hits.append(67890)
	shot.critical = true
	shot._sync_visuals()
	shot.retire()
	shot = _shot(MAGIC)
	var reference: WeaponProjectile = PlayerProjectilePool.PROJECTILE.instantiate()
	pool.add_child(reference)
	reference.launch(shot.global_position, Vector2.RIGHT, 100, MAGIC, null, false, 4)
	_check(shot.save_state({}) == reference.save_state({}), "reused player shot retained old hit, impact, return or orbit state")
	_check(shot.body_sprite == body and shot.tail_sprite == tail and shot.outline_sprite == outline and body.visible and tail.visible and outline.visible, "reuse created sprites or retained hidden impact visuals")
	reference.free()
	shot.retire()
	for cycle in 50:
		for number in 9:
			_shot(MAGIC)
		for live: WeaponProjectile in pool.get_children():
			live._physics_process(10)
	_check(pool.created == count and pool.idle_count == 12 and pool.get_child_count() == 0, "repeated salvos allocate new player bullets or lose reserve bullets")
	# Same ID in a distinct resource must not reuse incompatible visuals.
	var colored: WeaponData = MAGIC.duplicate()
	colored.projectile_color = Color.RED
	var red := _shot(colored)
	var low_tier := _shot(MAGIC, 1)
	var rocket := _shot(ROCKET)
	_check(red.body_sprite.texture != body.texture and low_tier != shot and rocket.tail_sprite == null and rocket.outline_sprite == null, "pool mixed resource identities, tiers or rocket/orb sprites")
	rocket._physics_process(10)
	_check(rocket.impact_time > 0 and not rocket.body_sprite.visible and not rocket.retired, "rocket expiry lost the visible explosion lifetime")
	rocket._physics_process(WeaponProjectile.IMPACT_DURATION)
	_check(rocket.retired, "exploded rocket did not return to the pool")
	red.retire()
	low_tier.retire()
	# A pooled piercing projectile must still hit in geometric order, with no
	# stale hit exclusion from its previous flight.
	var piercing: WeaponData = MAGIC.duplicate()
	piercing.pierce = 2
	var enemies: Array[Enemy] = []
	var indices: Dictionary = {}
	for number in 3:
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(260 + number * 40, 0))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_simulation_enabled(false)
		enemy.health = 10000
		enemy.max_health = 10000
		enemies.append(enemy)
		indices[enemy.get_instance_id()] = number
	var pierced := _shot(piercing)
	pierced._physics_process(1)
	_check(pierced.save_state(indices).hits == [0, 1, 2] and pierced.impact_time > 0, "pooled pierce changed hit order or hit limit")
	for enemy in enemies:
		_check(enemy.health == 9900, "pooled pierce lost direct damage")
	pierced._physics_process(WeaponProjectile.IMPACT_DURATION)
	pierced = _shot(piercing)
	pierced._physics_process(1)
	for enemy in enemies:
		_check(enemy.health == 9800, "reused piercing bullet incorrectly excluded a previous victim")
	pierced.retire()
	# Orbit and returning shots survive full save/resume, including hit IDs.
	game.items.acquire(ShopController.by_id(&"return_drill"))
	var halo := _shot(HALO, 4, game.items)
	halo._physics_process(0.2)
	_check(halo.orbit_time > 0 and not halo.returning, "pooled halo skipped its orbit on contact")
	halo._physics_process(0.01)
	_check(not halo.orbit_hits.is_empty() and enemies[1].health < 9800, "pooled orbit lost splash damage")
	var returning := _shot(MAGIC, 4, game.items)
	returning._physics_process(0.2)
	_check(returning.returning and is_equal_approx(returning.damage, 35), "pooled shot lost return item damage")
	var snapshot := RunSnapshot.capture(game)
	_check(snapshot.player_projectiles.size() == 2, "save included reserves or lost active player shots")
	game.free()
	_check(not is_instance_valid(shot) and not is_instance_valid(rocket), "exiting the pool leaked reserve bullets")
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	RunSnapshot.restore(game, snapshot)
	pool = game.get_node("Projectiles")
	var restored_indices: Dictionary = {}
	for number in game.get_node("Enemies").get_child_count():
		restored_indices[game.get_node("Enemies").get_child(number).get_instance_id()] = number
	_check(pool.get_child_count() == 2, "resume duplicated player projectiles")
	for number in pool.get_child_count():
		var resumed: WeaponProjectile = pool.get_child(number)
		_check(resumed.pool == pool and resumed.save_state(restored_indices) == snapshot.player_projectiles[number], "resume bypassed pool ownership or changed orbit/return/hit state")
	var resumed_halo: WeaponProjectile = pool.get_child(0)
	resumed_halo._physics_process(HALO.evolution_duration)
	_check(resumed_halo.returning and resumed_halo.orbit_time == 0, "resumed halo did not finish its orbit and return")
	resumed_halo.global_position = game.player.global_position
	resumed_halo._physics_process(0)
	_check(resumed_halo.retired, "arrival at Denti did not retire the returned halo")
	game._clear_combat()
	_check(pool.get_child_count() == 0 and pool.idle_count == 2, "wave cleanup destroyed player bullets instead of recycling them")
	# Equipment changes retire only obsolete reserves, never live shots. Also
	# verify the bound and a burst larger than the prepared reserve.
	var equipped := WeaponInstance.new()
	equipped.configure(MAGIC, 1)
	var loadout: Array[WeaponInstance] = [equipped]
	pool.prepare_loadout(loadout)
	var previous_tier := _shot(MAGIC, 1)
	var previous_body := previous_tier.body_sprite
	var live_previous_tier := _shot(MAGIC, 1)
	previous_tier.retire()
	equipped.tier = 2
	pool.prepare_loadout(loadout)
	_check(not is_instance_valid(previous_body) and live_previous_tier.is_inside_tree() and not live_previous_tier.retired and pool.idle_count == PlayerProjectilePool.PREPARE_PER_STYLE, "fusion retained obsolete reserves or interrupted live bullets")
	live_previous_tier.retire()
	pool.prepare_loadout(loadout)
	pool.prepare(MAGIC, 2, PlayerProjectilePool.MAX_IDLE + 10)
	_check(pool.idle_count == PlayerProjectilePool.MAX_IDLE, "preparation exceeded the idle memory bound")
	var burst: Array[WeaponProjectile] = []
	for number in PlayerProjectilePool.MAX_IDLE + 1:
		burst.append(_shot(MAGIC, 2))
	_check(pool.get_child_count() == PlayerProjectilePool.MAX_IDLE + 1, "reserve exhaustion capped gameplay projectile count")
	for live in burst:
		live.retire()
	_check(pool.idle_count == PlayerProjectilePool.MAX_IDLE and pool.get_child_count() == 0, "large burst retirement exceeded the idle bound")
	equipped.free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		game.player.loadout.acquire(MAGIC, 1)
		game.player.loadout.acquire(MAGIC, 1)
		game.player.loadout.merge(0)
		_check(pool.idle.has(MAGIC) and pool.idle[MAGIC].has(2) and not pool.idle[MAGIC].has(1) and pool.idle_count == PlayerProjectilePool.PREPARE_PER_STYLE, "real loadout fusion failed to prepare the upgraded projectile style")
	game.free()
	session.clear_run()
	paused = false
	if failures == 0:
		print("Denti player projectile pooling test passed")
	quit(0 if failures == 0 else 1)
