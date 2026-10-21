extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_difficulty_run.json"
	session.progression_path = "user://test_difficulty_progression.cfg"
	session.report_dir = "user://test_difficulty_reports"
	session.clear_run()
	if FileAccess.file_exists(session.progression_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	session.load_progression()
	if DifficultyCatalog.EASY.spawn_interval_multiplier <= DifficultyCatalog.NORMAL.spawn_interval_multiplier or DifficultyCatalog.HARD.spawn_interval_multiplier >= DifficultyCatalog.NORMAL.spawn_interval_multiplier or DifficultyCatalog.HELL.spawn_interval_multiplier >= DifficultyCatalog.HARD.spawn_interval_multiplier or DifficultyCatalog.HELL.boss_volley_bonus <= DifficultyCatalog.HARD.boss_volley_bonus:
		_fail("difficulty pressure does not rise from Easy to Hell")
		return
	if session.can_select_difficulty(&"hell") or session.select_difficulty(&"hell"):
		_fail("Hell was selectable before a Hard victory")
		return
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	menu._new_game()
	var hell_button: Button = menu.difficulty_buttons[&"hell"]
	if menu.page != &"difficulty" or hell_button == null or not hell_button.get_meta("locked", false):
		_fail("new-game menu did not lock Hell")
		return
	hell_button.pressed.emit()
	if menu.setup.difficulty_id == &"hell" or not menu.setup_selector.details.visible:
		_fail("locked difficulty changed the selection or hid its requirement")
		return
	menu.setup_selector.details.dismiss()
	menu.free()
	if not session.select_difficulty(&"hard"):
		_fail("Hard could not be selected")
		return
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	if game.wave.difficulty_id != &"hard" or session.load_run().get("difficulty_id", "") != "hard":
		_fail("new run did not save Hard before starter selection")
		return
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.current_wave = 7
	game.wave.start_next_wave()
	if game.wave.burst_times.size() != 4 or game.wave.elite_counts != [2]:
		_fail("Hard did not add a burst and earlier parallel elites")
		return
	if WaveController.elite_groups_for_wave(8) != [1] or WaveController.elite_groups_for_wave(8, &"easy") != [] or WaveController.elite_groups_for_wave(6, &"hell") != [3]:
		_fail("difficulty elite progression is wrong")
		return
	# Check the actual spawn path for trash, elites and bosses, including Endless.
	for data: EnemyData in [WaveController.ACID_SPITTER, load("res://data/enemies/plaque.tres"), load("res://data/enemies/acid_crown.tres"), load("res://data/enemies/cavity_king.tres")]:
		for wave_number in [1, 10, 20, 21, 50]:
			var previous_hp := 0.0
			var previous_defense := -1.0
			var previous_speed := 0.0
			var previous_contact := -1.0
			var previous_attack := -1.0
			for difficulty: DifficultyData in [DifficultyCatalog.NORMAL, DifficultyCatalog.HARD, DifficultyCatalog.HELL]:
				var probe := Enemy.new()
				probe.configure(data, game.player, wave_number, difficulty.id)
				if probe.max_health <= previous_hp or probe.damage_reduction <= previous_defense or probe.move_speed <= previous_speed or probe.damage_reduction > 0.56001 or (data.contact_damage > 0 and probe.contact_damage <= previous_contact) or (data.attack_damage > 0 and probe.attack_damage <= previous_attack):
					probe.free()
					_fail("difficulty stat curves do not increase safely")
					return
				if difficulty.id == &"normal" and (not is_equal_approx(probe.max_health, data.max_health * WaveController.health_multiplier(data, wave_number)) or not is_equal_approx(probe.move_speed, data.move_speed * WaveController.enemy_speed_multiplier(data, wave_number)) or not is_equal_approx(probe.damage_reduction, WaveController.damage_reduction(data, wave_number))):
					probe.free()
					_fail("Normal balance changed")
					return
				previous_hp = probe.max_health
				previous_defense = probe.damage_reduction
				previous_speed = probe.move_speed
				previous_contact = probe.contact_damage
				previous_attack = probe.attack_damage
				probe.free()
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		if not is_equal_approx(difficulty.damage_factor(1), difficulty.enemy_damage_multiplier) or not is_equal_approx(difficulty.damage_factor(20), difficulty.enemy_damage_multiplier + difficulty.enemy_damage_late_bonus) or difficulty.damage_factor(50) != difficulty.damage_factor(20):
			_fail("damage curve endpoints or Endless continuity changed")
			return
		for data: EnemyData in [WaveController.PLAQUE, WaveController.CAVITY_EMPEROR]:
			var previous_damage := 0.0
			for wave_number in [20, 21, 30, 40, 50, 100]:
				var probe := Enemy.new()
				probe.configure(data, game.player, wave_number, difficulty.id)
				if probe.contact_damage <= previous_damage or not is_equal_approx(probe.contact_damage, data.contact_damage * WaveController.enemy_damage_multiplier(data, wave_number) * difficulty.damage_factor(wave_number)):
					probe.free()
					_fail("actual contact damage stopped growing in Endless")
					return
				previous_damage = probe.contact_damage
				probe.free()
	for difficulty: DifficultyData in [DifficultyCatalog.HARD, DifficultyCatalog.HELL]:
		if difficulty.health_factor(15) - difficulty.health_factor(10) <= difficulty.health_factor(6) - difficulty.health_factor(1) or not is_equal_approx(difficulty.health_factor(20), 1.0 + difficulty.enemy_health_bonus.y) or difficulty.speed_factor(50) != difficulty.speed_factor(20) or difficulty.defense_bonus(50) != difficulty.defense_bonus(20):
			_fail("difficulty acceleration or Endless caps are wrong")
			return
	game._create_enemy(WaveController.ACID_SPITTER, game.player.global_position + Vector2(200.0, 0.0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	var normal_damage := WaveController.ACID_SPITTER.attack_damage * WaveController.enemy_damage_multiplier(WaveController.ACID_SPITTER, 8)
	if enemy.attack_damage <= normal_damage:
		_fail("Hard did not increase enemy damage")
		return
	game._save_run()
	var old_save: Dictionary = session.load_run()
	session.selected_difficulty_id = &"easy"
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.wave.difficulty_id != &"hard" or session.selected_difficulty_id != &"hard":
		_fail("resume changed the run difficulty")
		return
	game.wave.current_wave = WaveController.MAX_WAVES
	game._finish_run()
	if not session.can_select_difficulty(&"hell") or not session.hell_unlocked:
		_fail("Hard victory did not unlock Hell")
		return
	session.hell_unlocked = false
	session.load_progression()
	if not session.hell_unlocked or not session.select_difficulty(&"hell"):
		_fail("Hell unlock did not persist")
		return
	old_save.erase("difficulty_id")
	session.save_run(old_save)
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.wave.difficulty_id != &"normal":
		_fail("legacy run did not default to Normal")
		return
	session.clear_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	print("Denti difficulty levels test passed")
	finish(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	finish(1)
