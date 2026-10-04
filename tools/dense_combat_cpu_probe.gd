extends SceneTree

# Deterministic CPU work only. No FPS/GPU claim: run separately from rendered probes.
const TICKS := 300
var game: Node2D
var drops: Array[Node]
var shots: Array[WeaponProjectile] = []
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/dense_cpu_run.json"
	session.resume_requested = false
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.player.loadout.restore([])
	game.wave.active = false
	var center: Vector2 = game.player.global_position
	for number in 400:
		game._create_enemy(WaveController.PLAQUE, center + Vector2(-800 + number % 25 * 65, -480 + number / 25 * 60))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 1e9
		enemy.max_health = 1e9
	_measure("nearest_6_searches_per_tick", func():
		for number in 6:
			game.items._nearest_other(center + Vector2(number * 5, 0), null, 430))
	var data: WeaponData = WeaponCatalog.by_id(&"trinity_brush").duplicate()
	data.range_tiers = PackedFloat32Array([1e8, 1e8, 1e8, 1e8])
	data.pierce_tiers = PackedInt32Array([10000, 10000, 10000, 10000])
	data.projectile_speed = 0
	for number in 360:
		var shot := WeaponProjectile.new()
		game.get_node("Projectiles").add_child(shot)
		shot.launch(center + Vector2(-600 + number % 30 * 40, -260 + number / 30 * 42), Vector2.RIGHT, 0, data, null, false, 4)
		shots.append(shot)
	_measure("400_enemies_360_projectile_ticks", func():
		for shot in shots:
			shot._physics_process(1.0 / 60))
	for shot in shots:
		shot.free()
	for enemy in game.get_node("Enemies").get_children():
		enemy.free()
	for number in 1800:
		game._spawn_loot(center + Vector2(300 + number % 60 * 19, -300 + number / 60 * 20), &"xp" if number % 2 == 0 else &"coin", 1)
	drops = game.get_node("Loot").get_children()
	_measure("1800_distant_loot_ticks", _loot_tick)
	var label := "local"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=").validate_filename()
	var report := {"label": label, "display": DisplayServer.get_name(), "ticks_per_sample": TICKS, "samples": results}
	FileAccess.open("res://docs/dense_combat_cpu_%s.json" % label, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	session.clear_run()
	game.free()
	paused = false
	quit()

func _loot_tick() -> void:
	var container: Node = game.get_node("Loot")
	if container.has_method("_physics_process"):
		container._physics_process(1.0 / 60)
	else:
		for drop in drops:
			drop._physics_process(1.0 / 60)

func _measure(label: String, work: Callable) -> void:
	var samples: Array[float] = []
	for sample in 7:
		var started := Time.get_ticks_usec()
		for tick in TICKS:
			work.call()
		samples.append(float(Time.get_ticks_usec() - started) / TICKS)
	samples.sort()
	results.append({"scenario": label, "cpu_us_per_tick_median": samples[3], "cpu_us_per_tick_min": samples[0], "cpu_us_per_tick_max": samples[-1]})
