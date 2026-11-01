class_name ControllerNavigation
extends Node

const REPEAT_DELAY := 0.35
const REPEAT_INTERVAL := 0.11
const SCROLL_SPEED := 650.0
const DIRECTIONS := {&"ui_left": SIDE_LEFT, &"ui_right": SIDE_RIGHT, &"ui_up": SIDE_TOP, &"ui_down": SIDE_BOTTOM}
var scopes: Array[Dictionary] = []
var repeat_action: StringName = &""
var repeat_remaining := 0.0
var active_scope := 0
var last_focus := 0
var last_rect := Rect2()
var last_viewport := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().gui_focus_changed.connect(_focus_changed)

func register_scope(scope: Control, preferred: Callable, priority: int) -> void:
	var layer := 0
	var ancestor: Node = scope
	while ancestor != null:
		if ancestor is CanvasLayer:
			layer = ancestor.layer
			break
		ancestor = ancestor.get_parent()
	scopes.append({"scope": weakref(scope), "preferred": preferred, "priority": layer * 1000 + priority, "key": ""})

func top_scope() -> Dictionary:
	var best: Dictionary = {}
	for index in range(scopes.size() - 1, -1, -1):
		var scope: Control = scopes[index].scope.get_ref()
		if scope == null:
			scopes.remove_at(index)
			continue
		if ControllerFocus.visible(scope) and (best.is_empty() or int(scopes[index].priority) > int(best.priority)):
			best = scopes[index]
	return best

func ensure_focus() -> void:
	if popup_open(): return
	var entry := top_scope()
	if entry.is_empty(): return
	var scope: Control = entry.scope.get_ref()
	var focus := get_viewport().gui_get_focus_owner()
	if ControllerFocus.accepts(scope, focus):
		_decorate(focus)
		return
	var target: Control
	for candidate in ControllerFocus.controls(scope):
		if not str(entry.key).is_empty() and ControllerFocus.key(scope, candidate) == str(entry.key):
			target = candidate
			break
	if target == null and entry.preferred.is_valid(): target = entry.preferred.call()
	if not ControllerFocus.available(target):
		var choices := ControllerFocus.controls(scope)
		target = choices[0] if not choices.is_empty() else null
	if target != null:
		target.grab_focus()
		ControllerFocus.reveal(target)

func _focus_changed(control: Control) -> void:
	var entry := top_scope()
	if entry.is_empty(): return
	var scope: Control = entry.scope.get_ref()
	if ControllerFocus.contains(scope, control): entry.key = ControllerFocus.key(scope, control)
	_decorate(control)

func _decorate(control: Control) -> void:
	if control is OptionButton: ControllerPopupInput.attach(control.get_popup())
	if get_parent().using_controller and control != null and not control is Range and not control is OptionButton and not control is CheckButton and not control is CheckBox:
		ControllerPrompt.bind(control)

func handle_event(event: InputEvent) -> void:
	if event is InputEventKey:
		if popup_open() or DesktopMenuInput.editing(get_viewport()): return
		for action: StringName in DIRECTIONS:
			if event.is_action_pressed(action, true):
				if _navigate(action): get_viewport().set_input_as_handled()
				return
		if event.is_action_pressed("ui_focus_next", true) or event.is_action_pressed("ui_focus_prev", true):
			var entry := top_scope()
			if entry.is_empty(): return
			var choices := ControllerFocus.controls(entry.scope.get_ref())
			if choices.is_empty(): return
			var step := -1 if event.is_action_pressed("ui_focus_prev", true) else 1
			var index := choices.find(get_viewport().gui_get_focus_owner())
			if index < 0 and step < 0: index = 0
			choices[posmod(index + step, choices.size())].grab_focus()
			ControllerFocus.reveal(get_viewport().gui_get_focus_owner())
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion): return
	for action: StringName in DIRECTIONS:
		if event.is_action_pressed(action):
			# A held stick reports many slightly different values. Only its first
			# threshold crossing moves focus; the repeat timer owns subsequent steps.
			if repeat_action == action:
				get_viewport().set_input_as_handled()
				return
			repeat_action = action
			repeat_remaining = REPEAT_DELAY
			if _navigate(action): get_viewport().set_input_as_handled()
			return
		if event.is_action_released(action) and repeat_action == action: reset_repeat()

func _navigate(action: StringName) -> bool:
	if popup_open(): return false
	var entry := top_scope()
	if entry.is_empty(): return false
	ensure_focus()
	var scope: Control = entry.scope.get_ref()
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null: return false
	# Sliders retain their native left/right adjustment, including repeated input.
	if focus is HSlider and action in [&"ui_left", &"ui_right"]: return false
	var next := ControllerFocus.neighbor(scope, focus, DIRECTIONS[action])
	if next != null:
		next.grab_focus()
		ControllerFocus.reveal(next)
	return true

func reset_repeat() -> void:
	repeat_action = &""
	repeat_remaining = 0.0

func _process(delta: float) -> void:
	var input := get_parent()
	if not input.navigation_active: return
	ensure_focus()
	if popup_open():
		reset_repeat()
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and not popup_open():
		var rect := ControllerFocus.layout_rect(focused)
		var extent := get_viewport().get_visible_rect().size
		if last_focus != focused.get_instance_id() or not rect.is_equal_approx(last_rect) or extent != last_viewport:
			ControllerFocus.reveal(focused)
		last_focus = focused.get_instance_id()
		last_rect = rect
		last_viewport = extent
	var entry := top_scope()
	var scope: Control = entry.scope.get_ref() if not entry.is_empty() else null
	var id := scope.get_instance_id() if scope != null else 0
	if id != active_scope:
		active_scope = id
		reset_repeat()
	if not input.using_controller: return
	_scroll(delta)
	if repeat_action == &"": return
	if not Input.is_action_pressed(repeat_action):
		reset_repeat()
		return
	repeat_remaining -= delta
	if repeat_remaining > 0.0: return
	repeat_remaining = REPEAT_INTERVAL
	if not _navigate(repeat_action):
		# Feed only GUI events; never modify the physical action's held state.
		for down in [true, false]:
			var event := InputEventAction.new()
			event.action = repeat_action
			event.pressed = down
			get_viewport().push_input(event)

func _scroll(delta: float) -> void:
	var amount := Input.get_axis("ui_scroll_up", "ui_scroll_down")
	if is_zero_approx(amount) or popup_open(): return
	var entry := top_scope()
	if entry.is_empty(): return
	var scope: Control = entry.scope.get_ref()
	var parent: Node = get_viewport().gui_get_focus_owner()
	var target: ScrollContainer
	while parent != null and ControllerFocus.contains(scope, parent as Control):
		if parent is ScrollContainer:
			target = parent
			break
		parent = parent.get_parent()
	if target == null:
		for candidate: ScrollContainer in scope.find_children("*", "ScrollContainer", true, false):
			if ControllerFocus.visible(candidate) and candidate.get_v_scroll_bar().max_value > candidate.get_v_scroll_bar().page:
				target = candidate
				break
	if target != null: target.scroll_vertical += roundi(amount * SCROLL_SPEED * delta)

func popup_open() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	if focus is OptionButton and focus.get_popup().visible: return true
	return not get_viewport().get_embedded_subwindows().filter(func(window: Window) -> bool: return window.visible).is_empty()
