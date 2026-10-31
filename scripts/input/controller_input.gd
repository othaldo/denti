extends Node

signal changed
signal controller_disconnected

const SWITCH_THRESHOLD := 0.25
var using_controller := false
var navigation_active := false
var controller_device := -1
var detected_family := "xbox"
var navigation: ControllerNavigation
var action_bar: ControllerActionBar
var held_buttons: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	navigation = ControllerNavigation.new()
	add_child(navigation)
	action_bar = ControllerActionBar.new()
	add_child(action_bar)
	Input.joy_connection_changed.connect(_connection_changed)

func family() -> String:
	var preference: int = get_node("/root/GameSession").controller_symbols
	return "xbox" if preference == 1 else ("playstation" if preference == 2 else detected_family)

static func family_for(name: String, vendor_id: int = 0) -> String:
	var lower := name.to_lower()
	if vendor_id == 0x054c: return "playstation"
	if vendor_id == 0x045e or lower.contains("xbox"): return "xbox"
	if lower.begins_with("wireless controller") or lower.contains("vendor: 054c") or lower.contains("vendor:054c"): return "playstation"
	for token in ["playstation", "dualshock", "dualsense", "sony", "ps3", "ps4", "ps5"]:
		if lower.contains(token): return "playstation"
	return "xbox"

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and absf(event.axis_value) < SWITCH_THRESHOLD:
		if using_controller: navigation.handle_event(event)
		return
	if event is InputEventJoypadButton:
		var key := Vector2i(event.device, event.button_index)
		if not event.pressed:
			held_buttons.erase(key)
			return
		if held_buttons.has(key):
			get_viewport().set_input_as_handled()
			return
		held_buttons[key] = true
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		use_controller(event.device)
	elif event is InputEventKey and event.pressed:
		_set_mode(false, true)
	elif event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_mode(false, false)
	if navigation_active: navigation.ensure_focus()
	if using_controller: navigation.handle_event(event)

func use_controller(device: int) -> void:
	var previous := controller_device
	controller_device = device
	# Web platforms may omit vendor IDs. The explicit preference remains available.
	var info := Input.get_joy_info(device) if device in Input.get_connected_joypads() else {}
	var name := Input.get_joy_name(device) if device in Input.get_connected_joypads() else ""
	var previous_family := detected_family
	detected_family = family_for(name, int(info.get("vendor_id", 0)))
	var was_controller := using_controller
	_set_mode(true, true)
	if was_controller and (previous != device or previous_family != detected_family): changed.emit()

func _set_mode(controller: bool, navigate: bool) -> void:
	if using_controller == controller and navigation_active == navigate: return
	using_controller = controller
	navigation_active = navigate
	if navigation != null: navigation.reset_repeat()
	changed.emit()

func _connection_changed(device: int, connected: bool) -> void:
	if connected or device != controller_device: return
	held_buttons.clear()
	controller_device = -1
	_set_mode(false, true)
	controller_disconnected.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		held_buttons.clear()
		if navigation != null: navigation.reset_repeat()
