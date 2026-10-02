extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var last_traits := -1
	var last_specialists := -1
	var last_potency := 0.0
	for difficulty in DifficultyCatalog.ALL:
		var rng := RandomNumberGenerator.new()
		var trait_count := 0
		var poison_count := 0
		var bleed_count := 0
		for index in 3000:
			rng.seed = index + 9800
			var attacks := EnemyStatusRules.attacks_for(WaveController.PLAQUE, 20, difficulty, rng)
			_check(attacks.size() <= 1, "ordinary enemy acquired multiple traits")
			if not attacks.is_empty():
				trait_count += 1
				poison_count += int(attacks[0]["kind"] == DentiStatus.Type.POISON)
				bleed_count += int(attacks[0]["kind"] == DentiStatus.Type.BLEED)
		_check(trait_count > last_traits and poison_count > 0 and bleed_count > 0, "status distribution did not rise with difficulty or omitted one trait")
		last_traits = trait_count
		_check(WaveController.PLAQUE.inflicted_statuses.is_empty(), "per-instance trait mutated shared enemy resource")
		_check(EnemyStatusRules.attacks_for(WaveController.BACTERIA, difficulty.status_trait_first_wave - 1, difficulty, rng).is_empty(), "ordinary traits appeared too early")
		_check(EnemyStatusRules.attacks_for(WaveController.CAVITY_EMPEROR, 100, difficulty, rng).is_empty(), "random traits altered boss mechanics")
		_check(EnemyStatusRules.trait_chance(100000, difficulty) <= difficulty.status_trait_chance_cap and EnemyStatusRules.trait_chance(100000, difficulty, true) <= 0.45, "endless trait probability escaped its cap")
		var poison_attacks := EnemyStatusRules.attacks_for(WaveController.POISON_GERM, 20, difficulty)
		var potency: float = poison_attacks[0]["damage"]
		_check(potency > last_potency and poison_attacks[0]["duration"] <= 6.0, "difficulty did not scale specialist damage/duration")
		last_potency = potency
		_check(EnemyStatusRules.damage_factor(100000, difficulty) < 3.0, "endless status damage grew without bound")
		var wave := WaveController.new()
		wave.difficulty_id = difficulty.id
		wave.current_wave = difficulty.poison_first_wave - 1
		wave.duration = 45.0
		wave.remaining = 20.0
		seed(7429)
		for roll in 1000:
			var enemy := wave._choose_enemy()
			_check(enemy != WaveController.POISON_GERM and enemy != WaveController.GUM_BITER, "specialist spawned before first wave")
		wave.current_wave = 20
		var specialists := 0
		seed(7429)
		for roll in 4000:
			var enemy := wave._choose_enemy()
			specialists += int(enemy == WaveController.POISON_GERM or enemy == WaveController.GUM_BITER)
		_check(specialists > last_specialists and specialists < 2000, "difficulty did not distribute specialists or replaced most trash with them")
		last_specialists = specialists
		wave.free()
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_status_enemy_distribution.json"
	session.resume_requested = false
	session.selected_difficulty_id = &"normal"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.wave.current_wave = 12
	paused = true
	game._create_enemy(WaveController.POISON_GERM, game.player.position + Vector2(180, 0))
	game._create_enemy(WaveController.GUM_BITER, game.player.position + Vector2(-180, 0))
	var shooter: Enemy = game.get_node("Enemies").get_child(0)
	var biter: Enemy = game.get_node("Enemies").get_child(1)
	_check(shooter.inflicted_statuses.size() == 1 and biter.inflicted_statuses.size() == 1 and shooter.data.sprite != biter.data.sprite, "specialists lack traits or independent art")
	shooter.special_direction = Vector2.LEFT
	shooter._activate_special()
	_check(game.get_node("EnemyProjectiles").get_child_count() == 3, "poison specialist did not fire its fixed readable fan")
	var projectile: AcidProjectile = game.get_node("EnemyProjectiles").get_child(0)
	_check(projectile.inflicted_statuses == shooter.inflicted_statuses and projectile.projectile_color == DentiStatus.COLORS[DentiStatus.Type.POISON], "projectile lost owner payload or status color")
	# A landed real projectile applies its payload after the enemy can be gone.
	projectile.position = game.player.position
	game.player.stats.dodge_chance = 0.0
	projectile._physics_process(0.0)
	_check(game.player.status_effects.active.has(DentiStatus.Type.POISON), "actual projectile collision did not poison player")
	game.player.hurt_time = 0.0
	biter.position = game.player.position
	biter.special_timer = 2.0
	biter._physics_process(0.0)
	_check(game.player.status_effects.active.has(DentiStatus.Type.BLEED), "actual biter contact did not bleed player")
	var traits := shooter.inflicted_statuses.duplicate(true)
	var projectile_traits := (game.get_node("EnemyProjectiles").get_child(1) as AcidProjectile).inflicted_statuses.duplicate(true)
	game._save_run()
	var saved: Dictionary = session.load_run()
	_check(saved["acid"].size() == 2, "snapshot saved an already consumed status projectile")
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_check(game.get_node("Enemies").get_child_count() == 2, "resume omitted specialist enemies")
	shooter = game.get_node("Enemies").get_child(0)
	biter = game.get_node("Enemies").get_child(1)
	_check(shooter.inflicted_statuses == traits and biter.data == WaveController.GUM_BITER, "resume rerolled traits or changed specialist type")
	_check((game.get_node("EnemyProjectiles").get_child(0) as AcidProjectile).inflicted_statuses == projectile_traits, "resume lost in-flight projectile ailments")
	# Resume must preserve an intentionally trait-free old mob at a late wave.
	for entry: Dictionary in saved["enemies"]:
		entry["type"] = WaveController.PLAQUE.resource_path
		entry.erase("inflicted_statuses")
	saved["player"].erase("status_effects")
	saved["player"]["presentation"] = {}
	game.free()
	session.save_run(saved)
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for enemy: Enemy in game.get_node("Enemies").get_children():
		_check(enemy.inflicted_statuses.is_empty(), "legacy mob received a random trait on resume")
	_check(game.player.status_effects.active.is_empty(), "legacy save gave player new status damage")
	game.free()
	paused = false
	session.clear_run()
	if failures == 0:
		print("PASS status_enemy_distribution")
	quit(0 if failures == 0 else 1)
