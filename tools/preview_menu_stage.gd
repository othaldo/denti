extends SceneTree

# Actual native views, with all writable session paths isolated from the player.
const OUTPUT := "res://.godot/menu_preview/"
var session: Node

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	session = root.get_node("GameSession")
	session.save_path = OUTPUT + "run.json"
	session.settings_path = OUTPUT + "settings.cfg"
	session.progression_path = OUTPUT + "progression.cfg"
	session.report_dir = OUTPUT + "reports"
	session.settings_data = SessionSettings.new()
	session.progression_data = ProgressionStore.new()
	session.resume_requested = false
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(360, 640), Vector2i(720, 1280), Vector2i(1920, 1080)]:
		await _resize(extent)
		var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
		root.add_child(menu)
		current_scene = menu
		await _capture("home", extent)
		menu._show_options()
		await _capture("settings", extent)
		menu.stage.body_scroll.scroll_vertical = 10000
		await _capture("settings_bottom", extent)
		menu._show_home()
		session.save_run({"player":{},"wave":8,"level":11,"difficulty_id":"hard"})
		assert(session.has_run(), "Preview fixture must be a valid run save")
		menu._show_home()
		await _capture("continue", extent)
		menu._new_game()
		await _capture("confirm", extent)
		menu.free()
		session.clear_run()
		RunStore.clear(session.save_path + ".setup.json")
		await process_frame
		session.pending_start_weapon_id = &"magic_toothbrush"
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		game.wave.active = false
		game.game_menu.open_pause()
		await _capture("pause", extent)
		game.game_menu._show_options()
		await _capture("pause_settings", extent)
		game.free()
		paused = false
		session.clear_run()
		await process_frame
	quit()

func _resize(extent: Vector2i) -> void:
	root.content_scale_size = session.mobile_base_size(extent) if extent.x < 1000 else Vector2i(1280, 720)
	DisplayServer.window_set_size(extent)
	root.size = extent
	for frame in 5: await process_frame

func _capture(view: String, extent: Vector2i) -> void:
	if root.gui_get_focus_owner() != null: root.gui_get_focus_owner().release_focus()
	var pointer := InputEventMouseMotion.new()
	pointer.position = Vector2(2, 2)
	root.push_input(pointer, true)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUTPUT + "%s_%dx%d.png" % [view, extent.x, extent.y])
	root.get_texture().get_image().save_png(path)
	print("MENU PREVIEW: ", path)
