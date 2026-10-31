extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://docs/screenshots/weapon_masteries/achievements/"
var menu: GameMenu

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://mastery_menu_preview_run.json"
	session.progression_path = "user://mastery_menu_preview_progression.cfg"
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	session.progression_data.weapon_masteries.clear()
	for index in 4: session.record_weapon_mastery(WeaponCatalog.ALL[index].id, [15, 7, 3, 1][index])
	session.reduced_ui_motion = true
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	menu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for extent in [Vector2i(1280, 720), Vector2i(360, 640), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		menu._show_home()
		await _capture("home_%dx%d.png" % [extent.x, extent.y])
		print("home ", extent, " minimum=", menu.home.column.get_combined_minimum_size(), " available=", menu.home.available)
		menu.actions[&"achievements"].pressed.emit()
		await _capture("overview_%dx%d.png" % [extent.x, extent.y])
		menu.achievements_view.cards[1].pressed.emit()
		await _capture("requirements_%dx%d.png" % [extent.x, extent.y])
		menu.achievement_details.dismiss()
		menu.achievements_view.search.text = "Garotte"
		menu.achievements_view.search.text_changed.emit("Garotte")
		await _capture("search_%dx%d.png" % [extent.x, extent.y])
	root.content_scale_size = session.mobile_base_size(Vector2i(320, 568))
	root.size = Vector2i(320, 568)
	DisplayServer.window_set_size(root.size)
	menu._show_achievements()
	await _capture("mobile_project.png")
	session.clear_run()
	print("PASS native standalone achievements: main menu, overview, requirements, search and mobile project scaling")
	finish()

func _capture(filename: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)
