extends SceneTree


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
	var hell_button: Button
	for child in menu.rows.get_children():
		if child is Button and child.text.begins_with("Hell"):
			hell_button = child
	if menu.page != &"difficulty" or hell_button == null or not hell_button.disabled:
		_fail("new-game menu did not lock Hell")
		return
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
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.current_wave = 7
	game.wave.start_next_wave()
	if game.wave.burst_times.size() != 4 or game.wave.elite_counts != [2]:
		_fail("Hard did not add a burst and earlier parallel elites")
		return
	if WaveController.elite_groups_for_wave(8) != [1] or WaveController.elite_groups_for_wave(8, &"easy") != [] or WaveController.elite_groups_for_wave(6, &"hell") != [3]:
		_fail("difficulty elite progression is wrong")
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
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
