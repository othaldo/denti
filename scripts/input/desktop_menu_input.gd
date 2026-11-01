class_name DesktopMenuInput
extends RefCounted

const SHORTCUTS: Array[StringName] = [&"ui_accept", &"ui_cancel", &"ui_confirm", &"ui_reroll", &"ui_details", &"ui_pin", &"ui_undo", &"ui_previous", &"ui_next", &"pause"]
const MIN_DESKTOP_SIZE := Vector2i(1000, 560)

static func available(viewport: Viewport) -> bool:
	if OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available()): return false
	var extent := viewport.get_window().size
	# Compact phone/tablet layouts keep their space for the touch controls.
	return extent.x >= MIN_DESKTOP_SIZE.x and extent.y >= MIN_DESKTOP_SIZE.y

static func editing(viewport: Viewport) -> bool:
	var focus := viewport.gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit

static func shortcut(event: InputEventKey) -> bool:
	for action in SHORTCUTS:
		if event.is_action(action): return true
	return false

static func key_label(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if not event is InputEventKey: continue
		var key: int = event.keycode
		if key == 0:
			if DisplayServer.get_name() != "headless": key = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
			if key == 0: key = event.physical_keycode
		match key:
			KEY_ENTER, KEY_KP_ENTER: return "Enter"
			KEY_ESCAPE: return "Esc"
			KEY_BACKSPACE: return "Backspace"
			_: return OS.get_keycode_string(key)
	return ""
