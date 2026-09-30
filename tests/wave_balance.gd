extends SceneTree

var spawn_count: int = 0
var burst_count: int = 0
var burst_types: Array[String] = []
var attack_counts: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var wave := WaveController.new()
	wave.enemy_requested.connect(_count_spawn)
	wave.horde_requested.connect(_count_horde)
	wave.start_next_wave()
	for frame in ceili(wave.duration * 60.0):
		wave._process(1.0 / 60.0)
	var early_count := spawn_count
	var early_bursts := burst_count
	spawn_count = 0
	burst_count = 0
	burst_types.clear()
	wave.current_wave = 9
	wave.start_next_wave()
	for frame in ceili(wave.duration * 60.0):
		wave._process(1.0 / 60.0)
	var middle_count := spawn_count
	if early_count < 40 or middle_count < 125 or middle_count < early_count * 2 or early_bursts != 2 or burst_count != 3 or not burst_types.has("Säurespucker"):
		_fail("early and middle waves lack frequent mixed pressure: %d / %d enemies, %d / %d bursts" % [early_count, middle_count, early_bursts, burst_count])
		return
	spawn_count = 0
	burst_count = 0
	wave.current_wave = 18
	wave.start_next_wave()
	for frame in ceili(wave.duration * 60.0):
		wave._process(1.0 / 60.0)
	var late_count := spawn_count
	if late_count < 230 or late_count < middle_count * 1.5 or burst_count != 4:
		_fail("late waves do not grow beyond middle-wave pressure: %d / %d" % [middle_count, late_count])
		return
	wave.current_profile_id = &""
	seed(12345)
	var plaque_choices := 0
	var threat_choices := 0
	for index in 1000:
		var choice: EnemyData = wave._choose_enemy()
		if choice == WaveController.PLAQUE:
			plaque_choices += 1
		elif choice == WaveController.SUGAR or choice == WaveController.ACID_SPITTER:
			threat_choices += 1
	if plaque_choices > 220 or threat_choices < 500:
		_fail("late wave composition still favors fodder: %d Plaque / %d threats" % [plaque_choices, threat_choices])
		return
	spawn_count = 0
	burst_count = 0
	wave.start_next_wave()
	for frame in ceili(wave.duration * 60.0):
		wave._process(1.0 / 60.0)
	var boss_wave_count := spawn_count
	if burst_count != 3 or boss_wave_count >= late_count:
		_fail("boss wave inherited the new normal-wave pressure: %d / %d spawns, %d bursts" % [boss_wave_count, late_count, burst_count])
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_wave_balance_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.player.loadout.acquire(WeaponCatalog.by_id(&"turbo_drill"))
	game.player.loadout.acquire(WeaponCatalog.by_id(&"water_jet"))
	game.player.attack_performed.connect(_record_attack)
	game.wave.current_wave = 5
	game._create_enemy(WaveController.BOSS, game.player.position + Vector2(90.0, 0.0))
	var boss: Enemy = game.boss
	if boss.max_health < 1500.0 or boss.damage_reduction < 0.13:
		_fail("mini-boss has too little health or defense")
		return
	var health_before := boss.health
	boss.take_damage(100.0)
	var actual_damage := health_before - boss.health
	if actual_damage >= 100.0 or actual_damage <= 55.0:
		_fail("armor did not reduce damage by a moderate amount")
		return
	boss.health = boss.max_health
	boss.special_timer = 0.0
	var player_health: float = game.player.stats.health
	boss._physics_process(0.01)
	if boss.special_phase != Enemy.SpecialPhase.WARNING or boss.boss_move != Enemy.BossMove.CHARGE or game.player.stats.health != player_health:
		_fail("boss attack was not announced")
		return
	boss._physics_process(boss.data.warning_time)
	if game.player.stats.health != player_health or boss.special_phase != Enemy.SpecialPhase.ACTIVE:
		_fail("boss charge hit before its announced path became active")
		return
	boss._physics_process(boss.data.attack_duration)
	if game.player.stats.health >= player_health:
		_fail("announced boss charge did not hit")
		return
	game.player.stats.max_health = 10000.0
	game.player.stats.health = 10000.0
	var frames := 0
	while is_instance_valid(boss) and frames < 2700:
		await physics_frame
		frames += 1
	if frames < 480 or is_instance_valid(boss):
		_fail("mini-boss fight duration is outside the 8–45 second target: %.1fs, HP %.0f/%.0f, Denti %.0f, weapons %d, attacks %s, player %s, boss %s, viewport %s" % [float(frames) / 60.0, boss.health if is_instance_valid(boss) else 0.0, boss.max_health if is_instance_valid(boss) else 0.0, game.player.stats.health, game.player.loadout.equipped().size(), str(attack_counts), str(game.player.global_position), str(boss.global_position) if is_instance_valid(boss) else "dead", str(root.size)])
		return
	game.wave.current_wave = 20
	game._create_enemy(WaveController.FINAL_BOSS, game.player.position + Vector2(90.0, 0.0))
	var final_boss: Enemy = game.boss
	if final_boss.max_health < 15000.0 or final_boss.damage_reduction < 0.3:
		_fail("final boss did not scale above mini-boss")
		return
	final_boss.free()
	game.boss = null
	for index in 130:
		game._spawn_enemy(WaveController.PLAQUE)
	if game.get_node("Enemies").get_child_count() != game.MAX_ACTIVE_ENEMIES - 1 or game.telemetry.wave_spawns_blocked < 20:
		_fail("active enemy cap did not reserve a slot for elite pressure")
		return
	game._spawn_enemy(WaveController.ACID_CROWN)
	if game.get_node("Enemies").get_child_count() != game.MAX_ACTIVE_ENEMIES:
		_fail("reserved elite slot could not be used")
		return
	wave.free()
	session.clear_run()
	print("Denti wave balance test passed; wave 1: %d, wave 10: %d, wave 19: %d, boss wave 20: %d, mini-boss: %.1fs" % [early_count, middle_count, late_count, boss_wave_count, float(frames) / 60.0])
	quit(0)


func _count_spawn(_data: EnemyData) -> void:
	spawn_count += 1


func _count_horde(data: EnemyData, count: int) -> void:
	spawn_count += count
	burst_count += 1
	burst_types.append(data.display_name)


func _record_attack(kind: StringName) -> void:
	attack_counts[kind] = int(attack_counts.get(kind, 0)) + 1


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
