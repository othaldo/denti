extends SceneTree

var spawn_count: int = 0
var attack_counts: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var wave := WaveController.new()
	wave.enemy_requested.connect(_count_spawn)
	wave.current_wave = 1
	wave.remaining = WaveController.DURATION
	wave.active = true
	for frame in 2700:
		wave._process(1.0 / 60.0)
	var early_count := spawn_count
	spawn_count = 0
	wave.current_wave = 10
	wave.remaining = WaveController.DURATION
	wave.spawn_cooldown = 0.0
	wave.active = true
	for frame in 2700:
		wave._process(1.0 / 60.0)
	if early_count < 35 or spawn_count < early_count * 1.5:
		_fail("enemy density does not grow across waves")
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
	if game.get_node("Enemies").get_child_count() != game.MAX_ACTIVE_ENEMIES:
		_fail("active enemy cap did not protect late-wave performance")
		return
	wave.free()
	session.clear_run()
	print("Denti wave balance test passed; wave 1: %d, wave 10: %d, mini-boss: %.1fs" % [early_count, spawn_count, float(frames) / 60.0])
	quit(0)


func _count_spawn(_data: EnemyData) -> void:
	spawn_count += 1


func _record_attack(kind: StringName) -> void:
	attack_counts[kind] = int(attack_counts.get(kind, 0)) + 1


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
