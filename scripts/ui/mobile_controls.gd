class_name MobileControls
extends Control

signal pause_requested

const STICK_RADIUS := 70.0
const THUMB_RADIUS := 29.0
const EDGE_MARGIN := 32.0

@onready var pause_button: Button = $Pause

var direction: Vector2 = Vector2.ZERO
var touch_index: int = -1
var combat_active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = DisplayServer.is_touchscreen_available()
	pause_button.visible = false
	pause_button.custom_minimum_size = Vector2(96, 52)
	DentiUIStyle.style_button(pause_button)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())


func set_combat_active(active: bool) -> void:
	if combat_active == active:
		return
	combat_active = active
	if not active:
		touch_index = -1
		direction = Vector2.ZERO
	pause_button.visible = active
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not combat_active or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1 and event.position.distance_to(_stick_center()) <= STICK_RADIUS + 35.0:
			touch_index = event.index
			_set_direction(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			direction = Vector2.ZERO
			queue_redraw()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_set_direction(event.position)
		get_viewport().set_input_as_handled()


func _set_direction(position: Vector2) -> void:
	direction = ((position - _stick_center()) / STICK_RADIUS).limit_length()
	if direction.length() < 0.12:
		direction = Vector2.ZERO
	queue_redraw()


func _stick_center() -> Vector2:
	return Vector2(STICK_RADIUS + EDGE_MARGIN, size.y - STICK_RADIUS - EDGE_MARGIN)


func _draw() -> void:
	if not combat_active:
		return
	var center := _stick_center()
	draw_circle(center, STICK_RADIUS, Color(0.18, 0.12, 0.17, 0.42))
	draw_arc(center, STICK_RADIUS, 0.0, TAU, 64, Color(1.0, 0.94, 0.75, 0.72), 3.0, true)
	draw_circle(center + direction * STICK_RADIUS, THUMB_RADIUS, Color(1.0, 0.94, 0.75, 0.88))
	draw_arc(center + direction * STICK_RADIUS, THUMB_RADIUS, 0.0, TAU, 48, Color(0.43, 0.25, 0.25, 0.85), 2.0, true)
