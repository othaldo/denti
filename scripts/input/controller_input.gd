extends Node

signal changed
signal controller_disconnected

const SWITCH_THRESHOLD := 0.55
const NEUTRAL_THRESHOLD := 0.2
const MOUSE_SWITCH_DISTANCE := 8.0
const MOUSE_SAMPLE_MS := 180
const ANALOG_SWITCH_COOLDOWN_MS := 600
var using_controller := false
var controller_active := false
var navigation_active := false
var controller_device := -1
var detected_family := "xbox"
var navigation: ControllerNavigation
var action_bar: ControllerActionBar
var held_buttons: Dictionary = {}
var bindings: ControllerBindings
var neutral_axes: Dictionary = {}
var last_controller_ms := -1000
var last_pointer_ms := -1000
var pointer_started_ms := -1000
var pointer_travel := Vector2.ZERO
var pause_menu: WeakRef
# Platform metadata is kept separate from event routing (also used by fixtures).
var device_info_provider: Callable = _read_device_info

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bindings = ControllerBindings.new()
	bindings.capture()
	navigation = ControllerNavigation.new()
	add_child(navigation)
	action_bar = ControllerActionBar.new()
	add_child(action_bar)
	Input.joy_connection_changed.connect(_connection_changed)
	apply_preferences()

func mode() -> int:
	return get_node("/root/GameSession").controller_symbols

func apply_preferences() -> void:
	if mode() == SessionSettings.ControllerMode.DISABLED:
		controller_device = -1
		held_buttons.clear()
		neutral_axes.clear()
		bindings.select_device(-1)
		_set_mode(false, navigation_active, false)
	else:
		_set_mode(controller_active, navigation_active, false)
	if navigation != null: navigation.reset_repeat()
	changed.emit()

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

static func gamepad_candidate(name: String, mapped: bool) -> bool:
	if not mapped: return false
	var lower := name.to_lower()
	for token in ["wheel", "lenkrad", "pedal", "hotas", "throttle", "flight", "yoke", "shifter", "side panel", "sidepanel", "heavy equipment", "farm", "tractor"]:
		if lower.contains(token): return false
	return true

func _eligible(device: int) -> bool:
	var info: Dictionary = device_info_provider.call(device)
	return gamepad_candidate(str(info.get("name", "")), bool(info.get("mapped", false)))

func _read_device_info(device: int) -> Dictionary:
	if device not in Input.get_connected_joypads(): return {}
	var info := Input.get_joy_info(device)
	return {"name": Input.get_joy_name(device), "vendor_id": int(info.get("vendor_id", 0)), "mapped": Input.is_joy_known(device)}

func pause_available() -> bool:
	var menu: Node = pause_menu.get_ref() if pause_menu != null else null
	return menu != null and menu.game != null and not menu.game.ended

func _unhandled_input(event: InputEvent) -> void:
	if not navigation_active or not event.is_action_pressed("ui_details"): return
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and focus.has_meta("controller_details"):
		var inspect: Callable = focus.get_meta("controller_details")
		inspect.call()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_joy_input(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		last_pointer_ms = Time.get_ticks_msec()
		_set_mode(false, true)
	elif event is InputEventMouseMotion:
		if not _deliberate_pointer(event): return
		last_pointer_ms = Time.get_ticks_msec()
		_set_mode(false, false)
	elif ((event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed) or event is InputEventScreenDrag:
		last_pointer_ms = Time.get_ticks_msec()
		_set_mode(false, false)
	if navigation_active: navigation.ensure_focus()

func _joy_input(event: InputEvent) -> bool:
	if mode() == SessionSettings.ControllerMode.DISABLED or (controller_device >= 0 and event.device != controller_device):
		get_viewport().set_input_as_handled()
		return true
	if controller_device < 0 and not _eligible(event.device):
		get_viewport().set_input_as_handled()
		return true
	var deliberate := false
	if event is InputEventJoypadMotion:
		if event.axis not in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_RIGHT]:
			get_viewport().set_input_as_handled()
			return true
		var key := Vector2i(event.device, event.axis)
		if event.axis == JOY_AXIS_TRIGGER_RIGHT:
			# A trigger is a press, not a repeating analog direction. It must be
			# released before another wave can start, including across shop visits.
			if absf(event.axis_value) <= NEUTRAL_THRESHOLD:
				neutral_axes[key] = true
			elif event.axis_value > InputMap.action_get_deadzone(&"ui_confirm") and bool(neutral_axes.get(key, false)):
				neutral_axes[key] = false
				deliberate = true
			if not deliberate:
				get_viewport().set_input_as_handled()
				return true
		elif absf(event.axis_value) <= NEUTRAL_THRESHOLD:
			neutral_axes[key] = true
		elif absf(event.axis_value) >= SWITCH_THRESHOLD and bool(neutral_axes.get(key, false)):
			neutral_axes[key] = false
			deliberate = Time.get_ticks_msec() - last_pointer_ms >= ANALOG_SWITCH_COOLDOWN_MS
	if event is InputEventJoypadButton:
		if not bindings.uses_button(event.button_index):
			get_viewport().set_input_as_handled()
			return true
		var key := Vector2i(event.device, event.button_index)
		if not event.pressed:
			held_buttons.erase(key)
			return false
		if held_buttons.has(key):
			get_viewport().set_input_as_handled()
			return true
		deliberate = true
	# Replay the acquiring event once after rebinding. This updates Godot's global
	# action state and delivers that first button press to native GUI controls.
	if deliberate and bindings.device != event.device:
		use_controller(event.device)
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
			neutral_axes[Vector2i(event.device, event.axis)] = true
		Input.parse_input_event(event.duplicate())
		get_viewport().set_input_as_handled()
		return true
	if controller_device < 0:
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventJoypadButton:
		var key := Vector2i(event.device, event.button_index)
		held_buttons[key] = true
	if deliberate:
		last_controller_ms = Time.get_ticks_msec()
		_set_mode(true, true)
	if event.is_action_pressed("pause") and pause_available():
		var menu: Node = pause_menu.get_ref()
		if menu.visible: menu.close_pause()
		else: menu.open_pause()
		get_viewport().set_input_as_handled()
		return true
	if navigation_active: navigation.ensure_focus()
	if controller_active: navigation.handle_event(event)
	return false

func _deliberate_pointer(event: InputEventMouseMotion) -> bool:
	if event.relative.length() < 1.0 or Time.get_ticks_msec() - last_controller_ms < ANALOG_SWITCH_COOLDOWN_MS: return false
	var now := Time.get_ticks_msec()
	if now - pointer_started_ms > MOUSE_SAMPLE_MS:
		pointer_started_ms = now
		pointer_travel = Vector2.ZERO
	pointer_travel += event.relative
	if pointer_travel.length() < MOUSE_SWITCH_DISTANCE: return false
	pointer_travel = Vector2.ZERO
	return true

func use_controller(device: int) -> void:
	if mode() == SessionSettings.ControllerMode.DISABLED: return
	var previous := controller_device
	controller_device = device
	bindings.select_device(device)
	# Web platforms may omit vendor IDs. The explicit preference remains available.
	var info: Dictionary = device_info_provider.call(device)
	var name := str(info.get("name", ""))
	var previous_family := detected_family
	detected_family = family_for(name, int(info.get("vendor_id", 0)))
	var was_controller := using_controller
	last_controller_ms = Time.get_ticks_msec()
	_set_mode(true, true)
	if was_controller and (previous != device or previous_family != detected_family): changed.emit()

func _set_mode(controller: bool, navigate: bool, notify: bool = true) -> void:
	controller = controller and mode() != SessionSettings.ControllerMode.DISABLED
	var show_controller := mode() in [SessionSettings.ControllerMode.XBOX, SessionSettings.ControllerMode.PLAYSTATION] or controller
	if using_controller == show_controller and controller_active == controller and navigation_active == navigate: return
	controller_active = controller
	using_controller = show_controller
	navigation_active = navigate
	if not controller: bindings.select_device(-1)
	if navigation != null: navigation.reset_repeat()
	if notify: changed.emit()

func _connection_changed(device: int, connected: bool) -> void:
	if connected or device != controller_device: return
	held_buttons.clear()
	neutral_axes.clear()
	controller_device = -1
	bindings.select_device(-1)
	_set_mode(false, true)
	controller_disconnected.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		held_buttons.clear()
		neutral_axes.clear()
		if bindings != null: bindings.clear_state()
		if navigation != null: navigation.reset_repeat()
