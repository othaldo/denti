extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _settle() -> void:
	for frame in 8: await process_frame

func _click(control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = control.get_global_rect().get_center()
		root.push_input(event)
		await process_frame
	await _settle()

func _key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		root.push_input(event)
		await process_frame
	await _settle()

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://setup_ui_test.json"
	session.hell_unlocked = false
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._new_game()
	await _settle()
	var view := menu.setup_selector
	_check(view.step_buttons[&"weapon"].disabled, "unvisited weapon step can be skipped")
	var footer := view.footer.get_global_rect()
	var header := view.header.get_global_rect()
	await _click(menu.difficulty_buttons[&"hard"])
	_check(menu.setup.difficulty_id == &"hard" and menu.page == &"difficulty", "pointer difficulty choice advanced preparation")
	await _click(menu.difficulty_buttons[&"hell"])
	_check(view.details.visible and menu.setup.difficulty_id == &"hard", "locked Hell changed the valid choice")
	await _key(KEY_TAB)
	_check(view.details.close_button.has_focus(), "Tab escaped the detail modal")
	await _key(KEY_ESCAPE)
	_check(not view.details.visible and menu.page == &"difficulty", "Escape skipped the selection behind details")
	_check(menu.difficulty_buttons[&"hell"].has_focus(), "closing details lost their source focus")
	await _click(view.confirm_button)
	_check(menu.page == &"weapon" and view.selected_id == &"" and view.confirm_button.disabled, "Continue auto-selected or started a weapon")
	_check(view.header.get_global_rect() == header and view.footer.get_global_rect() == footer, "step change moved the navigation")
	await _click(view.icon_buttons[16])
	_check(menu.setup.weapon_id == WeaponCatalog.ALL[16].id and not session.has_run(), "pointer preview started combat or lost its weapon")
	await _click(view.step_buttons[&"difficulty"])
	_check(menu.page == &"difficulty" and not view.step_buttons[&"weapon"].disabled, "visited step navigation was forgotten")
	await _click(view.step_buttons[&"weapon"])
	_check(view.selected_id == WeaponCatalog.ALL[16].id, "step navigation lost the selected weapon")
	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.double_click = true
	double_click.pressed = true
	double_click.position = view.confirm_button.get_global_rect().get_center()
	root.push_input(double_click)
	double_click = double_click.duplicate()
	double_click.pressed = false
	root.push_input(double_click)
	await _settle()
	_check(current_scene == menu and not session.has_run(), "double-click continuation also confirmed Start")
	await _key(KEY_RIGHT)
	_check(view.keyboard_focus and view.icon_buttons[0].get_theme_stylebox("focus") is StyleBoxFlat, "keyboard focus has no separate visual treatment")
	var mouse := InputEventMouseMotion.new()
	mouse.position = Vector2(10, 10)
	root.push_input(mouse)
	await _settle()
	_check(not view.keyboard_focus and view.icon_buttons[0].get_theme_stylebox("focus") is StyleBoxEmpty, "pointer focus looks like selection")
	# A compact physical window retains usable controls with the actual mobile
	# project base, rather than silently shrinking the entire menu with combat.
	root.content_scale_size = session.mobile_base_size(Vector2i(320, 568))
	root.size = Vector2i(320, 568)
	await _settle()
	var transform := root.get_screen_transform()
	var physical := Rect2(0, 0, 320, 568)
	_check(physical.encloses(transform * view.panel.get_global_rect()), "mobile project stretch clips the preparation stage")
	for button in [view.back_button, view.confirm_button, view.details_button] + view.icon_buttons:
		var bounds: Rect2 = transform * button.get_global_rect()
		_check(bounds.size.x >= 47.9 and bounds.size.y >= 47.9, "mobile project stretch shrank a touch target")
	for index in view.options.size():
		var card: RunSetupChoice = view.icon_buttons[index]
		var unselected_rect := card.artwork.get_global_rect()
		view.select_weapon(index)
		await _settle()
		_check(card.artwork.get_global_rect() == unselected_rect, "selection marker moved the weapon art")
		var image := card.artwork.texture.get_image()
		var visible := image.get_used_rect()
		var image_size := Vector2(image.get_size())
		var art_rect: Rect2 = transform * card.artwork.get_global_rect()
		var fit := minf(art_rect.size.x / image_size.x, art_rect.size.y / image_size.y)
		var painted := Rect2(art_rect.position + (art_rect.size - image_size * fit) * 0.5 + Vector2(visible.position) * fit, Vector2(visible.size) * fit)
		var card_rect: Rect2 = transform * card.get_global_rect()
		_check(painted.get_center().distance_to(card_rect.get_center()) < 0.75, "visible weapon art is off-center: %s" % view.options[index].id)
		_check(card_rect.grow(-5).encloses(painted), "weapon art touches the frame: %s" % view.options[index].id)
		_check(card.artwork.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and card.mark.visible, "selection stretched art or lost its marker")
		_check(view.weapon_view.preview.get_global_rect().encloses(view.weapon_name.get_global_rect()), "long weapon name escapes the compact preview")
		for stat in view.weapon_view.stat_buttons:
			_check(stat.get_global_rect().encloses(stat.get_child(0).get_child(0).get_global_rect()), "stat icon/value group overlaps its neighbor")
	view.details_button.pressed.emit()
	await _settle()
	_check(view.details.visible and view.details.body.text.contains(view.weapon_view.selected_weapon().combat_text()), "optional details lost weapon mechanics")
	await _key(KEY_ESCAPE)
	_check(not view.details.visible and menu.page == &"weapon", "detail close changed the preparation step")
	_check(not session.has_run() and root.get_node_or_null("Game") == null, "UI inspection loaded combat")
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	finish(0 if failures.is_empty() else 1)
