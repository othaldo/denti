class_name ControllerBindings
extends RefCounted

# Keep the project's action map, but bind its gamepad events to one device only.
# Removing bindings also protects Input.get_vector() and native GUI controls.
var templates: Dictionary = {}
var device := -1

func capture() -> void:
	for action in InputMap.get_actions():
		var events: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				events.append(event.duplicate())
		if not events.is_empty(): templates[action] = events
	_rebind()

func select_device(value: int) -> void:
	if device == value: return
	_release_actions()
	device = value
	_rebind()
	_restore_desktop_state()

func _rebind() -> void:
	for action: StringName in templates:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
		if device < 0: continue
		for template: InputEvent in templates[action]:
			var event := template.duplicate() as InputEvent
			event.device = device
			InputMap.action_add_event(action, event)

func clear_state() -> void:
	_release_actions()
	_restore_desktop_state()

func _release_actions() -> void:
	for action: StringName in templates:
		Input.action_release(action)

func _restore_desktop_state() -> void:
	# InputMap changes reset action state, so restore held desktop inputs last.
	for action: StringName in templates:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				var pressed := Input.is_physical_key_pressed(event.physical_keycode) if event.physical_keycode != 0 else Input.is_key_pressed(event.keycode)
				if pressed: Input.action_press(action)
			elif event is InputEventMouseButton and Input.is_mouse_button_pressed(event.button_index):
				Input.action_press(action)

func uses_button(button: JoyButton) -> bool:
	for events: Array in templates.values():
		for event: InputEvent in events:
			if event is InputEventJoypadButton and event.button_index == button: return true
	return false
