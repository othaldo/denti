extends SceneTree

var failures := 0
var batch: EnemySpatialIndex

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _enemy(at: Vector2, data: EnemyData = null) -> Enemy:
	var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	enemy.configure(WaveController.ACID_SPITTER if data == null else data, null, 17)
	enemy.position = at
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	batch.add_child(enemy)
	enemy.special_phase = Enemy.SpecialPhase.WARNING
	enemy.special_direction = Vector2.RIGHT
	enemy.special_timer = enemy.data.warning_time * 0.2
	if enemy.data.is_boss:
		enemy.boss_move = Enemy.BossMove.CHARGE
		enemy.boss_dash_end = at + Vector2(550, 0)
	return enemy

func _clear() -> void:
	for child in batch.get_children():
		child.free()

func _run() -> void:
	batch = EnemySpatialIndex.new()
	root.add_child(batch)
	batch.process_mode = Node.PROCESS_MODE_DISABLED
	# Identical overlapping strips must retain every warning, while bounding
	# cumulative fill opacity even at the most opaque point of the artwork.
	for index in 20:
		_enemy(Vector2(100, 100))
	batch._process(0.0)
	_check(batch.warning_density.scales.size() == 20 and batch.shadow_batch.warning_count == 20, "dense warnings were omitted instead of reducing their fill")
	var alpha := 0.0
	for enemy in batch.shadow_batch.enemies:
		var values: PackedFloat32Array = batch.warning_density.scales.get(enemy.get_instance_id(), PackedFloat32Array())
		_check(values.size() == 9, "dense strip has no complete opacity profile")
		if values.size() == 9:
			alpha = 1.0 - (1.0 - alpha) * (1.0 - 0.62 * 0.9 * values[4])
		_check(enemy.special_phase == Enemy.SpecialPhase.WARNING and enemy.special_timer == enemy.data.warning_time * 0.2 and enemy.health == enemy.max_health, "visual density altered an attack or enemy health")
	_check(alpha < 0.6 and alpha > 0.2, "twenty ground fills obscure the floor or become invisible")
	# A distant warning must remain fully visible despite a dense group.
	var isolated := _enemy(Vector2(100, 1500))
	batch._process(0.0)
	_check(not batch.warning_density.scales.has(isolated.get_instance_id()), "an isolated warning was dimmed by distant enemies")
	# Cached profiles are only refreshed when needed, rather than every frame.
	var remaining := batch.warning_density.remaining
	batch._process(0.01)
	_check(batch.warning_density.remaining < remaining, "density refresh is not throttled")
	_clear()
	# Major attacks must remain visible among ordinary warning fills.
	var boss := _enemy(Vector2(100, 100), WaveController.CAVITY_COUNT)
	for index in 19:
		_enemy(Vector2(100, 100))
	batch._process(0.0)
	var boss_values: PackedFloat32Array = batch.warning_density.scales.get(boss.get_instance_id(), PackedFloat32Array())
	_check(boss_values.size() == 9 and boss_values[4] >= WarningVisualDensity.BOSS_MIN_FILL - 0.0001, "a boss charge is lost in ordinary ground warnings")
	_clear()
	# Twenty separated enemies must not trigger global population-based fading.
	for index in 20:
		_enemy(Vector2(index * 800, 100))
	batch._process(0.0)
	_check(batch.warning_density.scales.is_empty(), "separated warning strips lose their full opacity")
	for child in batch.get_children().slice(1):
		child.free()
	batch._process(0.0)
	_check(batch.warning_density.scales.is_empty() and batch.shadow_batch.warning_count == 1, "ended warnings left obsolete opacity profiles")
	_check(batch.shadow_batch.attack_enemies.size() == 1, "active warning list retained removed enemies")
	if "--benchmark" in OS.get_cmdline_user_args():
		for count in [10, 20, 60]:
			_clear()
			for index in count:
				_enemy(Vector2(100, 100))
			var elapsed := 0
			for sample in 30:
				batch.warning_density.invalidate()
				var start := Time.get_ticks_usec()
				batch._process(0.0)
				elapsed += Time.get_ticks_usec() - start
			print("%d coincident warnings: density refresh %.3f ms, at most 10 refreshes/sec with stable count" % [count, elapsed / 30000.0])
	batch.free()
	if failures == 0:
		print("Warning visual density: overlap opacity, isolated visibility, unchanged attacks and cleanup passed")
	quit(0 if failures == 0 else 1)
