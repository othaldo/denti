extends "res://tests/support/test_runtime.gd"

var _frame := 0
var _directory: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(960, 540)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(960, 540))
	root.size = Vector2i(960, 540)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://scene_transition_preview.json"
	session.report_dir = "user://scene_transition_reports"
	session.selected_story_mode = false
	session.resume_requested = false
	session.reduced_ui_motion = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	_directory = ProjectSettings.globalize_path("res://.godot/scene_transition_frames")
	DirAccess.make_dir_recursive_absolute(_directory)
	root.size_changed.connect(func() -> void: print("Viewport resize at preview frame %d" % _frame))
	root.get_node("SceneTransitions").completed.connect(func() -> void: print("Transition completed at preview frame %d" % _frame))
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _record(24)
	menu._start_new_game(&"normal")
	await _record(30)
	var game: Node2D = current_scene
	game.choice_panel._on_choice_pressed(0)
	await _record(30)
	game.wave.active = false
	game._award_xp(13)
	game._on_wave_finished(1)
	await _record(30)
	while game.rewards.pending_levels > 0:
		game.choice_panel._on_choice_pressed(0)
		await _record(15)
	await _record(15)
	game._on_shop_continue()
	await _record(30)
	game.game_menu._to_main_menu()
	await _record(30)
	session.clear_run()
	print("Native transition frames: %d in %s" % [_frame, _directory])
	finish()


func _record(amount: int) -> void:
	for frame in amount:
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_directory.path_join("frame_%03d.png" % _frame))
		_frame += 1
