extends SceneTree
## Interactive local fixture; the PowerShell launcher isolates all user data.

const PROFILES = preload("res://tools/balance/build_comparison_profiles.gd")

func _initialize() -> void:
	call_deferred("_start")

func _argument(name: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--" + name + "="): return argument.get_slice("=", 1)
	return fallback

func _start() -> void:
	var number := int({"count": 5, "prince": 10, "king": 15, "emperor": 20}.get(_argument("boss", "prince"), 10))
	var build := _argument("build", "ranged_single")
	if not PROFILES.BUILDS.has(build): build = "ranged_single"
	var session := root.get_node("GameSession")
	session.save_path = "user://boss_stage_playtest.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.pending_start_weapon_id = &"magic_toothbrush"
	session.selected_difficulty_id = DifficultyCatalog.by_id(StringName(_argument("difficulty", "normal"))).id
	DisplayServer.window_set_title("Denti · %s · %s · Boss-Test" % [WaveController.boss_for_wave(number).display_name, DifficultyCatalog.by_id(session.selected_difficulty_id).display_name])
	root.get_node("SceneTransitions").enabled = false
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var config: Dictionary = PROFILES.setup(build, number, "base")
	game.player.loadout.restore(config.equipment)
	for stat: String in config.stats: game.player.stats.set(stat, config.stats[stat])
	game.player.stats.health = game.player.stats.max_health
	game.weapon_mastery.eligible = false
	game.debug_start_wave(number)
	await process_frame
	if number == 10 and "--trial" in OS.get_cmdline_user_args():
		var boss: Enemy = game.boss
		boss.global_position = game.player.global_position + Vector2(0, -120)
		boss.boss_phase = 2
		boss.health = boss.max_health / 3.0
		boss.boss_phase_timer = 1.0
	elif number == 15 and "--trial" in OS.get_cmdline_user_args():
		var boss: Enemy = game.boss
		boss.global_position = game.player.global_position + Vector2(-220, -100)
		boss.boss_phase = 1
		boss.health = boss.max_health * 2 / 3
		boss.boss_phase_timer = 1.0
	elif number == 20 and "--trial" in OS.get_cmdline_user_args():
		var boss: Enemy = game.boss
		boss.global_position = game.player.global_position + Vector2(0, -140)
		boss.health = boss.max_health * boss.crown_court_encounter.retinue.profile.thresholds[0]
		boss.boss_phase = 0 if boss.health / boss.max_health > 0.67 else 1
		boss.boss_phase_timer = 1.0
	game._refresh_hud()
	game._save_run()
	if "--start-paused" in OS.get_cmdline_user_args(): game.game_menu.open_pause()
	print("Boss playtest: ", number, " / ", build, ". F4: build and full waves. Separate playtest save.")

