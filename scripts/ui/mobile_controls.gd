class_name MobileControls
extends Control

signal pause_requested

const TOUCH_DEADZONE := 10.0
const TOUCH_RADIUS := 64.0

@onready var pause_button: Button = $Pause

var touch_index: int = -1
var combat_active: bool = false
var player: Player
var touch_origin: Vector2
var held_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = DisplayServer.is_touchscreen_available()
	pause_button.visible = false
	pause_button.custom_minimum_size = Vector2(96, 52)
	DentiUIStyle.style_button(pause_button)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	get_viewport().size_changed.connect(_release_touch)


func set_combat_active(active: bool) -> void:
	combat_active = active
	if not active:
		_release_touch()
	pause_button.visible = active


func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		_release_touch()


func _input(event: InputEvent) -> void:
	# Finish an owned gesture even when the finger crosses a UI control.
	if not visible or not combat_active or get_tree().paused:
		_release_touch()
		return
	if event is InputEventScreenTouch and event.index == touch_index and not event.pressed:
		_release_touch()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_direction(event.position)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Buttons get the first chance to consume a touch; only the free playfield
	# starts movement. The first finger owns it until release.
	if not visible or not combat_active or get_tree().paused or not is_instance_valid(player):
		return
	if event is InputEventScreenTouch and event.pressed and touch_index == -1:
		if pause_button.get_global_rect().has_point(event.position):
			return
		touch_index = event.index
		touch_origin = event.position
		held_direction = Vector2.ZERO
		get_viewport().set_input_as_handled()


func _update_direction(screen_position: Vector2) -> void:
	var offset := screen_position - touch_origin
	# Let the gesture origin follow long drags so reversing stays within reach.
	if offset.length() > TOUCH_RADIUS:
		offset = offset.normalized() * TOUCH_RADIUS
		touch_origin = screen_position - offset
	held_direction = Vector2.ZERO if offset.length() <= TOUCH_DEADZONE else player.get_canvas_transform().affine_inverse().basis_xform(offset).normalized()


func movement_direction(_delta: float) -> Vector2:
	if touch_index < 0 or not visible or not combat_active or not is_instance_valid(player):
		return Vector2.ZERO
	return held_direction


func _release_touch() -> void:
	touch_index = -1
	held_direction = Vector2.ZERO
