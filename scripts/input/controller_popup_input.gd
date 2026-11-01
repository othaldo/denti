class_name ControllerPopupInput
extends Node
## Embedded windows own their input viewport; keep device routing and held state shared.

static func attach(window: Window) -> void:
	if window.has_node("ControllerPopupInput"): return
	var bridge := ControllerPopupInput.new()
	bridge.name = "ControllerPopupInput"
	bridge.process_mode = Node.PROCESS_MODE_ALWAYS
	window.add_child(bridge, false, Node.INTERNAL_MODE_BACK)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if get_node("/root/GameInput").key_input(event, get_viewport()): get_viewport().set_input_as_handled()
		return
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion): return
	var viewport := get_viewport()
	var consumed: bool = get_node("/root/GameInput")._joy_input(event)
	if consumed and is_instance_valid(viewport): viewport.set_input_as_handled()
