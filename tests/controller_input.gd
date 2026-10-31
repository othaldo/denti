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
	# Real input events, with deterministic OS metadata for virtual fixture IDs.
	input.device_info_provider = func(device: int) -> Dictionary:
		return {"name": "Xbox Controller", "mapped": true} if device == 7 else {"name": "Logitech G29 Racing Wheel", "mapped": true}
	_check(INPUT.family_for("Xbox Series Controller") == "xbox", "Xbox detection failed")
	_check(INPUT.family_for("Xbox Wireless Controller") == "xbox", "Xbox wireless was mistaken for PlayStation")
	_check(INPUT.family_for("DualSense Wireless Controller") == "playstation", "DualSense detection failed")
	_check(INPUT.family_for("PS4 Controller") == "playstation", "DualShock detection failed")
	_check(INPUT.family_for("Wireless Controller (STANDARD GAMEPAD Vendor: 054c Product: 09cc)") == "playstation", "browser PlayStation identifier was not recognized")
	_check(INPUT.family_for("unknown", 0x054c) == "playstation", "Sony vendor detection failed")
	_check(INPUT.family_for("Generic USB Gamepad") == "xbox", "unknown devices lack a predictable fallback")
	input.use_controller(7)
	for device in [0, 7]:
		for binding in [[JOY_BUTTON_A, &"ui_accept"], [JOY_BUTTON_B, &"ui_cancel"], [JOY_BUTTON_START, &"pause"], [JOY_BUTTON_RIGHT_SHOULDER, &"dash"], [JOY_BUTTON_X, &"ui_reroll"], [JOY_BUTTON_Y, &"ui_details"]]:
			var event := InputEventJoypadButton.new()
			event.device = device
			event.button_index = binding[0]
			event.pressed = true
			_check(event.is_action_pressed(binding[1]) == (device == 7), "%s is not limited to the active device" % binding[1])
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
	input.last_controller_ms = -1000
	root.push_input(pointer)
	_check(not input.using_controller, "mouse does not restore pointer mode")
	await _axis(JOY_AXIS_LEFT_X, 0.1)
	_check(not input.using_controller, "stick drift steals pointer mode")
	input.last_pointer_ms = -1000
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
	await _routing_regressions(input, session, screen, buttons)
	print("Controller bindings, analog movement, device selection and symbol persistence checked")
	finish(0 if failures.is_empty() else 1)

func _routing_regressions(input: Node, session: Node, screen: Control, buttons: Array[Button]) -> void:
	_check(not INPUT.gamepad_candidate("USB Gamepad", false), "unmapped joystick was accepted automatically")
	for name in ["Logitech G29 Racing Wheel", "Saitek Heavy Equipment Side Panel", "FarmStick", "HOTAS", "USB Pedals"]:
		_check(not INPUT.gamepad_candidate(name, true), "simulator device accepted: " + name)
	_check(INPUT.gamepad_candidate("Generic USB Gamepad", true), "mapped third-party gamepad rejected")
	var changes := {"count": 0}
	input.changed.connect(func() -> void: changes.count += 1)
	var before: int = changes.count
	for cycle in 12:
		await _axis(JOY_AXIS_LEFT_X, 0.9, 9)
		await _axis(JOY_AXIS_TRIGGER_LEFT, -1.0, 9)
		await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.0, 9)
		await _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0, 9)
		await _axis(JOY_AXIS_RIGHT_X, 0.9)
		var jitter := InputEventMouseMotion.new()
		jitter.relative = Vector2(0.2, 0)
		root.push_input(jitter)
	_check(changes.count == before and input.using_controller and input.navigation_active, "simulator / mouse noise still flips prompts or focus")
	input.last_controller_ms = Time.get_ticks_msec()
	var incidental := InputEventMouseMotion.new()
	incidental.relative = Vector2(12, 0)
	root.push_input(incidental)
	_check(input.using_controller, "mouse motion bypasses the analog switch cooldown")
	_check(Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx(), "inactive simulator steers the player")
	buttons[0].grab_focus()
	var activations := {"count": 0}
	buttons[0].pressed.connect(func() -> void: activations.count += 1)
	var press := InputEventJoypadButton.new()
	press.device = 9
	press.button_index = JOY_BUTTON_A
	press.pressed = true
	Input.parse_input_event(press)
	press = press.duplicate()
	press.pressed = false
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await process_frame
	_check(activations.count == 0 and input.controller_device == 7, "second device activates GUI or steals selection")
	# Fixed glyphs remain visible while pointer input changes only navigation focus.
	for preference in [1, 2]:
		session.set_controller_symbols(preference)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		input._input(click)
		_check(input.using_controller and not input.navigation_active and not input.controller_active, "fixed symbols are hidden by pointer input")
		session.set_controller_symbols(0)
		_check(not input.using_controller, "automatic mode did not restore pointer presentation")
		input.use_controller(7)
	await _axis(JOY_AXIS_LEFT_X, 1.0)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	input.use_controller(7)
	await _axis(JOY_AXIS_LEFT_X, 1.0)
	session.set_controller_symbols(3)
	_check(not input.using_controller and input.controller_device == -1, "Off retains controller presentation or device")
	_check(not Input.is_action_pressed("move_right") and Input.is_action_pressed("move_up"), "Off leaves a held stick active or clears a held keyboard key (right=%s, up=%s, W=%s)" % [Input.is_action_pressed("move_right"), Input.is_action_pressed("move_up"), Input.is_physical_key_pressed(KEY_W)])
	var saved := SessionSettings.new()
	saved.load_from(session.settings_path)
	_check(saved.controller_symbols == 3, "Off was not persisted")
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	buttons[0].grab_focus()
	for button in [JOY_BUTTON_A, JOY_BUTTON_START, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_DPAD_RIGHT]:
		for down in [true, false]:
			press = InputEventJoypadButton.new()
			press.device = 7
			press.button_index = button
			press.pressed = down
			Input.parse_input_event(press)
			Input.flush_buffered_events()
	await _axis(JOY_AXIS_LEFT_X, 1.0)
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.95)
	_check(not Input.is_action_pressed("ui_next_wave"), "Off permits the trigger shortcut")
	_check(activations.count == 0 and buttons[0].has_focus(), "Off permits gamepad GUI activation or navigation")
	_check(Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx() and not Input.is_action_pressed("dash") and not Input.is_action_pressed("pause"), "Off permits movement, dash or pause")
	session.set_controller_symbols(0)
	await _axis(JOY_AXIS_LEFT_X, 0.9, 9)
	_check(input.controller_device == -1, "simulator auto-acquired after re-enabling input")
	# A stick must pass through neutral before it may acquire a gamepad.
	await _axis(JOY_AXIS_LEFT_X, 0.9)
	_check(input.controller_device == -1, "resting non-neutral axis auto-acquired a device")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	input.last_pointer_ms = -1000
	await _axis(JOY_AXIS_LEFT_X, 0.9)
	_check(input.controller_device == 7 and input.using_controller and Input.is_action_pressed("move_right"), "deliberate stick acquisition lost the first input")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	input._connection_changed(7, false)
	buttons[0].grab_focus()
	for down in [true, false]:
		press = InputEventJoypadButton.new()
		press.device = 7
		press.button_index = JOY_BUTTON_A
		press.pressed = down
		Input.parse_input_event(press)
		Input.flush_buffered_events()
		await process_frame
	_check(activations.count == 1 and input.controller_device == 7, "first acquiring button press was lost or delivered twice")
	_check(ControllerFocus.contains(screen, root.gui_get_focus_owner()), "device acquisition lost GUI focus")
	input._connection_changed(7, false)
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.95)
	_check(input.controller_device == -1, "held trigger acquired a controller without first reaching neutral")
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.95)
	_check(input.controller_device == 7 and input.using_controller and Input.is_action_pressed("ui_next_wave"), "deliberate trigger acquisition lost its first press")
