extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	var prior_path: String = session.settings_path
	var prior_mode: int = session.graphics_mode
	session.settings_path = "user://test_graphics_settings.cfg"
	_check(session.use_economy_graphics(0, true) and not session.use_economy_graphics(0, false), "automatic graphics do not follow touchscreen detection")
	_check(session.use_economy_graphics(1, false) and not session.use_economy_graphics(2, true), "explicit graphics choice does not override automatic selection")
	root.size = Vector2i(2400, 1080)
	root.content_scale_size = Vector2i(1040, 600)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._show_options()
	menu.graphics_option.select(1)
	menu.graphics_option.item_selected.emit(1)
	await process_frame
	await process_frame
	_check(session.graphics_mode == 1 and root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT, "economy choice did not limit rendering resolution")
	_check(root.content_scale_size == Vector2i(1040, 600), "graphics mode changed the logical mobile layout")
	var logical_size := menu.root_control.size
	_check(is_equal_approx(logical_size.y, 600), "economy mode changed logical height")
	var panel := menu.build_panel.get_global_rect()
	_check(panel.position.y >= 0 and panel.end.y <= 600, "landscape graphics options overflow the screen")
	_check(menu.graphics_option.get_global_rect().end.x <= logical_size.x, "graphics selector overflowed the panel")
	menu.graphics_option.select(2)
	menu.graphics_option.item_selected.emit(2)
	await process_frame
	await process_frame
	_check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and menu.root_control.size.is_equal_approx(logical_size), "full mode changed layout instead of rendering quality")
	var saved := ConfigFile.new()
	_check(saved.load(session.settings_path) == OK and saved.get_value("display", "graphics_mode", -1) == 2, "graphics preference was not saved")
	session.graphics_mode = 0
	session._ready()
	_check(session.graphics_mode == 2, "restart lost the graphics preference")
	menu._show_options()
	_check(menu.graphics_option.selected == 2, "reopened options show the wrong preference")
	menu.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.settings_path))
	session.settings_path = prior_path
	session.graphics_mode = prior_mode
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	session.apply_graphics()
	if failures.is_empty():
		print("Denti graphics settings test passed")
	quit(0 if failures.is_empty() else 1)
