extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _settle() -> void:
	for frame in 12:
		await process_frame


func _escape() -> void:
	await _key(KEY_ESCAPE)


func _key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		root.push_input(event)
		await process_frame
	await _settle()


func _physical_rect(control: Control) -> Rect2:
	return root.get_screen_transform() * control.get_global_rect()


func _touch_target(control: Control, name: String) -> void:
	var bounds := _physical_rect(control)
	_check(bounds.size.x >= 47.9 and bounds.size.y >= 47.9,
		"menu project stretch shrank %s below a 48 px touch target: %s" % [name, bounds.size])


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://menu_stage_run.json"
	session.settings_path = "user://menu_stage_settings.cfg"
	session.progression_path = "user://menu_stage_progression.cfg"
	session.selected_story_mode = false
	session.resume_requested = false
	session.reduced_ui_motion = true
	session.code_entry_unlocked = false
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _settle()
	_check(menu.home.primary_button == menu.actions[&"new_run"], "empty menu does not emphasize New Run")
	# Physical mobile dimensions with the real combat canvas base expose shrinking
	# that logical-only viewport tests cannot detect. Rotation must keep settings usable.
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(360, 640), Vector2i(720, 1280), Vector2i(1920, 1080)]:
		root.content_scale_size = session.mobile_base_size(extent) if extent.x < 700 else Vector2i(1280, 720)
		root.size = extent
		menu._show_home()
		await _settle()
		var screen := Rect2(Vector2.ZERO, Vector2(extent)).grow(0.5)
		_check(screen.encloses(_physical_rect(menu.stage.panel)), "menu stage escapes the physical screen at %s" % extent)
		for id in menu.actions:
			_touch_target(menu.actions[id], str(id))
		_check(screen.encloses(_physical_rect(menu.home.primary_button)), "primary menu action is off screen at %s" % extent)
		_check(not menu.stage.body_scroll.get_v_scroll_bar().visible, "home has an unnecessary scrollbar at %s" % extent)
		_check(not menu.stage.body_scroll.get_h_scroll_bar().visible, "home cannot fit its horizontal content at %s" % extent)
		await _key(KEY_TAB)
		(menu.actions[&"settings"] as Button).grab_focus()
		await _key(KEY_ENTER)
		_check(menu.page == &"options" and menu.stage.visible and not menu.stage.content is MenuHome, "settings did not replace the home content")
		_check(screen.encloses(_physical_rect(menu.stage.panel)), "settings stage escapes the physical screen at %s" % extent)
		var controls: Array[Control] = [menu.fullscreen_toggle, menu.fps_toggle, menu.graphics_option,
			menu.master_slider, menu.music_slider, menu.sfx_slider, menu.ui_sound_toggle, menu.motion_toggle]
		for control in controls:
			_touch_target(control, control.get_class())
		_touch_target(menu.actions[&"back"], "settings back")
		_check(screen.encloses(_physical_rect(menu.actions[&"back"])), "settings back action scrolled out of view")
		_check(menu.stage.back_button.get_theme_stylebox("focus") is StyleBoxFlat, "keyboard focus has no distinct menu treatment")
		var pointer := InputEventMouseMotion.new()
		pointer.position = Vector2(1, 1)
		root.push_input(pointer)
		await _settle()
		_check(menu.stage.back_button.get_theme_stylebox("focus") is StyleBoxEmpty, "pointer focus retains the keyboard outline")
		menu.stage.body_scroll.ensure_control_visible(menu.motion_toggle)
		# Reaching the bottom manually must expose the last whole touch target;
		# Godot's focus scroll rounds the requested position down to whole units.
		menu.stage.body_scroll.scroll_vertical = ceili(menu.stage.body_scroll.get_v_scroll_bar().max_value)
		await _settle()
		_check(_physical_rect(menu.stage.body_scroll).grow(0.5).encloses(_physical_rect(menu.motion_toggle)), "last setting is unreachable at %s: scroll %s, setting %s" % [extent, _physical_rect(menu.stage.body_scroll), _physical_rect(menu.motion_toggle)])
		await _escape()
		_check(menu.page == &"home" and menu.home.visible and current_scene == menu and not session.has_run(), "Escape from settings started combat or lost home")
		_check(menu.actions[&"settings"].has_focus(), "return from settings lost the keyboard source focus")
	session.save_run({"wave":8,"level":11,"difficulty_id":"hard","player":{}})
	menu._show_home()
	await _settle()
	_check(menu.home.primary_button == menu.actions[&"continue"] and menu.home.context.text == "Welle 8 · Level 11 · Hard", "resume action lost the saved run context")
	session.clear_run()
	menu._show_home()
	# A reused options page must not count as another visit for the hidden code.
	session.settings_visit_streak = 0
	menu._show_options()
	menu._show_options()
	_check(session.settings_visit_streak == 1, "settings rebuild counted as a second visit")
	menu._show_home()
	menu.queue_free()
	await _settle()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	session.pending_start_weapon_id = &"magic_toothbrush"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _settle()
	game.wave.active = false
	game.game_menu.open_pause()
	await _settle()
	_check(paused and game.game_menu.visible and game.game_menu.actions.has(&"build"), "pause has no build entry or does not pause combat")
	(game.game_menu.actions[&"settings"] as Button).pressed.emit()
	await _settle()
	await _escape()
	_check(paused and game.game_menu.visible and game.game_menu.page == &"home", "Escape from pause settings resumed combat")
	await _escape()
	_check(not paused and not game.game_menu.visible, "Escape from pause home did not resume combat")
	game._open_shop()
	game.game_menu.open_pause()
	await _settle()
	await _escape()
	_check(paused and game.shop_panel.visible and not game.game_menu.visible, "closing pause during the shop resumed combat")
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	if failures.is_empty():
		print("Denti shared menu stage, physical touch targets, rotation and pause navigation test passed")
	finish(0 if failures.is_empty() else 1)
