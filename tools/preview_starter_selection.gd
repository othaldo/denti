extends SceneTree

const OUTPUT := "res://docs/screenshots/starter_selection/"
var menu: GameMenu

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://starter_preview_only.json"
	session.progression_path = "user://starter_preview_progression.cfg"
	session.load_progression()
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	AudioServer.set_bus_mute(0, true)
	menu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._new_game()
	menu._advance_setup()
	menu.setup_selector.select_weapon(15)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		await _capture("%dx%d.png" % [extent.x, extent.y])
		menu._setup_back()
		await _capture("difficulty_%dx%d.png" % [extent.x, extent.y])
		menu._advance_setup()
	# Normal desktop stretch: only the physical window changes.
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(root.size)
	await _capture("desktop_project_stretch.png")
	menu._setup_back()
	await _capture("difficulty_project_stretch.png")
	# Actual mobile project base, not a 320-unit canvas pretending to be mobile.
	root.content_scale_size = session.mobile_base_size(Vector2i(320, 568))
	root.size = Vector2i(320, 568)
	DisplayServer.window_set_size(root.size)
	await _capture("mobile_project_difficulty.png")
	menu._advance_setup()
	await _capture("mobile_project_weapon.png")
	menu.setup_selector.details_button.pressed.emit()
	await _capture("mobile_project_details.png")
	menu.setup_selector.details.dismiss()
	# Empty preview and a long name use the same stage.
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	menu.setup.weapon_id = &""
	menu._show_setup_weapons()
	await _capture("weapon_unselected.png")
	menu.setup_selector.select_weapon(7)
	await _capture("weapon_long_name.png")
	menu.setup_selector.details_button.pressed.emit()
	await _capture("weapon_details.png")
	menu.setup_selector.details.dismiss()
	menu._setup_back()
	menu.difficulty_buttons[&"hell"].pressed.emit()
	await _capture("hell_requirement.png")
	menu.setup_selector.details.dismiss()
	# Exercise actual GUI hit testing and keyboard back navigation.
	await _click(menu.setup_selector.confirm_button)
	assert(menu.page == &"weapon")
	await _click(menu.setup_selector.icon_buttons[0])
	assert(menu.setup.weapon_id == WeaponCatalog.ALL[0].id)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await _settle()
	assert(menu.page == &"difficulty")
	print("Native setup: pointer selection, Weiter and Escape verified.")
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	quit()

func _click(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = position
		root.push_input(event)
		await process_frame
	await _settle()

func _settle() -> void:
	for frame in 20: await process_frame

func _capture(filename: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)
	print(filename, " canvas=", menu.root_control.size, " UI scale=", menu.setup_selector.panel.scale)
