extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	for frame in 3:
		await process_frame


func _enemy(data: EnemyData, counter: Dictionary) -> Enemy:
	var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	enemy.configure(data, null, 17)
	root.add_child(enemy)
	enemy.set_process(false)
	enemy.set_simulation_enabled(false)
	enemy.draw.connect(func(): counter.count += 1)
	return enemy


func _run() -> void:
	var counter := {"count": 0}
	var enemy := _enemy(WaveController.PLAQUE, counter)
	await _settle()
	_check(counter.count > 0, "test did not render the initial enemy")
	var initial := int(counter.count)
	var starting_health := enemy.health
	for hit in 5:
		enemy.take_damage(1.0)
		await _settle()
	_check(counter.count == initial, "ordinary hits rebuilt unchanged drawing commands")
	_check(enemy.health == starting_health - 5.0 and enemy.hit_flash_time > 0.0 and enemy.modulate.r > 1.0, "avoiding redraw changed damage or hit flash")
	enemy._process(0.13)
	_check(enemy.modulate == Color.WHITE, "hit flash no longer resets")
	# Status start/end and stack-count changes must still redraw their indicators.
	for kind in ["wet", "exposure", "bleed"]:
		var before := int(counter.count)
		match kind:
			"wet": enemy.apply_wet(2.0)
			"exposure": enemy.apply_enamel_exposure(0.1, 2.0)
			"bleed": enemy.apply_bleed(0.1, 2.0, 1)
		await _settle()
		_check(counter.count == before + 1, "%s activation did not redraw" % kind)
		match kind:
			"wet": enemy.apply_wet(3.0)
			"exposure": enemy.apply_enamel_exposure(0.2, 3.0)
			"bleed": enemy.apply_bleed(0.2, 3.0, 1)
		await _settle()
		_check(counter.count == before + 1, "%s refresh redrew an unchanged indicator" % kind)
		enemy._physics_process(3.1)
		await _settle()
		_check(counter.count == before + 2, "%s expiry did not remove its indicator" % kind)
	enemy.apply_bleed(0.1, 2.0, 3)
	await _settle()
	var one_stack := int(counter.count)
	enemy.apply_bleed(0.1, 2.0, 3)
	await _settle()
	_check(enemy.bleed_stacks == 2 and counter.count == one_stack + 1, "changed bleed stack count did not redraw")
	enemy.free()
	for data in [WaveController.ACID_CROWN, WaveController.BOSS]:
		counter = {"count": 0}
		enemy = _enemy(data, counter)
		await _settle()
		initial = int(counter.count)
		enemy.take_damage(1.0)
		await _settle()
		_check(counter.count == initial + 1, "boss/elite health or guard bar stopped updating")
		enemy.free()
	if failures == 0:
		print("Denti enemy render updates test passed")
	quit(0 if failures == 0 else 1)
