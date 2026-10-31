extends "res://tests/support/test_runtime.gd"

const INPUT = preload("res://scripts/input/controller_input.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _axis(axis: JoyAxis, value: float, device: int = 7) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func _run() -> void:
	var input := root.get_node("GameInput")
	var session := root.get_node("GameSession")
	session.settings_path = "user://controller_settings.cfg"
	_check(INPUT.family_for("Xbox Series Controller") == "xbox", "Xbox detection failed")
	_check(INPUT.family_for("Xbox Wireless Controller") == "xbox", "Xbox wireless was mistaken for PlayStation")
	_check(INPUT.family_for("DualSense Wireless Controller") == "playstation", "DualSense detection failed")
	_check(INPUT.family_for("PS4 Controller") == "playstation", "DualShock detection failed")
	_check(INPUT.family_for("Wireless Controller (STANDARD GAMEPAD Vendor: 054c Product: 09cc)") == "playstation", "browser PlayStation identifier was not recognized")
	_check(INPUT.family_for("unknown", 0x054c) == "playstation", "Sony vendor detection failed")
	_check(INPUT.family_for("Generic USB Gamepad") == "xbox", "unknown devices lack a predictable fallback")
	for device in [0, 7]:
		for binding in [[JOY_BUTTON_A, &"ui_accept"], [JOY_BUTTON_B, &"ui_cancel"], [JOY_BUTTON_START, &"pause"], [JOY_BUTTON_RIGHT_SHOULDER, &"dash"], [JOY_BUTTON_X, &"ui_reroll"], [JOY_BUTTON_Y, &"ui_details"]]:
			var event := InputEventJoypadButton.new()
			event.device = device
			event.button_index = binding[0]
			event.pressed = true
			_check(event.is_action_pressed(binding[1]), "%s does not match device %d" % [binding[1], device])
	await _axis(JOY_AXIS_LEFT_X, 1.0)
	_check(Input.get_vector("move_left", "move_right", "move_up", "move_down").is_equal_approx(Vector2.RIGHT), "full stick does not move at full speed")
	await _axis(JOY_AXIS_LEFT_X, 0.6)
	_check(is_equal_approx(Input.get_vector("move_left", "move_right", "move_up", "move_down").x, 0.5), "partial stick lost analog speed")
	await _axis(JOY_AXIS_LEFT_X, 0.1)
	_check(Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx(), "stick drift moves the player")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	await _axis(JOY_AXIS_LEFT_X, 1.0)
	await _axis(JOY_AXIS_LEFT_Y, 1.0)
	_check(is_equal_approx(Input.get_vector("move_left", "move_right", "move_up", "move_down").length(), 1.0), "diagonal movement exceeds full speed")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	await _axis(JOY_AXIS_LEFT_Y, 0.0)
	var pointer := InputEventMouseMotion.new()
	pointer.relative = Vector2(8, 0)
	root.push_input(pointer)
	_check(not input.using_controller, "mouse does not restore pointer mode")
	await _axis(JOY_AXIS_LEFT_X, 0.1)
	_check(not input.using_controller, "stick drift steals pointer mode")
	await _axis(JOY_AXIS_LEFT_X, 0.8)
	_check(input.using_controller and input.controller_device == 7, "deliberate input does not select its controller")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	session.set_controller_symbols(2)
	_check(input.family() == "playstation", "PlayStation override does not affect prompts")
	var saved := SessionSettings.new()
	saved.load_from(session.settings_path)
	_check(saved.controller_symbols == 2, "symbol preference did not survive reload")
	session.set_controller_symbols(1)
	_check(input.family() == "xbox", "Xbox override does not affect prompts")
	session.set_controller_symbols(0)
	input.detected_family = "playstation"
	_check(input.family() == "playstation", "automatic preference ignores the detected family")
	for family: String in ControllerGlyphs.TEXTURES:
		for action: StringName in ControllerGlyphs.TEXTURES[family]:
			var texture := ControllerGlyphs.texture(action, family)
			_check(texture != null and texture.get_size() == Vector2(64, 64), "missing/scaled incorrectly: %s %s" % [family, action])
			var art := texture.get_image()
			_check(not art.is_empty() and art.get_used_rect().size.x > 20, "empty controller glyph: %s %s" % [family, action])
	_check(ControllerGlyphs.texture(&"ui_accept", "xbox") != ControllerGlyphs.texture(&"ui_accept", "playstation"), "families use the same accept glyph")
	var disconnected := {"count": 0}
	input.controller_disconnected.connect(func() -> void: disconnected.count += 1)
	input._connection_changed(2, false)
	_check(input.using_controller, "unrelated controller disconnect changed the active device")
	input._connection_changed(7, false)
	_check(not input.using_controller and input.controller_device == -1 and disconnected.count == 1, "active controller loss was not reported")
	input._connection_changed(7, true)
	_check(not input.using_controller, "reconnection switches devices without deliberate input")
	var screen := Control.new()
	root.add_child(screen)
	screen.size = Vector2(800, 100)
	var buttons: Array[Button] = []
	for index in 8:
		var button := Button.new()
		button.text = str(index)
		button.position = Vector2(index * 90, 0)
		button.size = Vector2(80, 48)
		screen.add_child(button)
		buttons.append(button)
	ControllerFocus.register(screen)
	input.use_controller(7)
	for frame in 3: await process_frame
	var held := InputEventJoypadButton.new()
	held.device = 7
	held.button_index = JOY_BUTTON_DPAD_RIGHT
	held.pressed = true
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	for frame in 55: await process_frame
	_check(buttons.find(root.gui_get_focus_owner()) >= 3, "holding D-pad does not repeat navigation")
	held.pressed = false
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	buttons[0].grab_focus()
	await _axis(JOY_AXIS_LEFT_X, 0.65)
	await _axis(JOY_AXIS_LEFT_X, 0.72)
	await _axis(JOY_AXIS_LEFT_X, 0.68)
	_check(buttons[1].has_focus(), "stick jitter repeats focus movement before the repeat delay")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	buttons[0].grab_focus()
	var activations := {"count": 0}
	buttons[0].pressed.connect(func() -> void: activations.count += 1)
	held.button_index = JOY_BUTTON_A
	held.pressed = true
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	for frame in 20: await process_frame
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	for frame in 20: await process_frame
	held.pressed = false
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	await process_frame
	_check(activations.count == 1, "held/duplicate accept activates more than once")
	var slider := HSlider.new()
	slider.position = Vector2(0, 60)
	slider.size = Vector2(300, 40)
	slider.value = 50
	screen.add_child(slider)
	slider.grab_focus()
	await _axis(JOY_AXIS_LEFT_X, 1.0)
	for frame in 45: await process_frame
	_check(slider.value > 51, "held direction does not retain native slider adjustment")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	print("Controller bindings, analog movement, device selection and symbol persistence checked")
	finish(0 if failures.is_empty() else 1)
