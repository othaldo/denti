class_name MobileControls
extends Control

signal pause_requested

@onready var pause_button: Button = $Pause

var touch_index: int = -1
var combat_active: bool = false
var player: Player
var touch_origin: Vector2
var player_origin: Vector2
var target: Vector2


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
		_update_target(event.position)
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
		player_origin = player.global_position
		target = player_origin
		get_viewport().set_input_as_handled()


func _update_target(screen_position: Vector2) -> void:
	var canvas_inverse := player.get_canvas_transform().affine_inverse()
	var offset := canvas_inverse.basis_xform(screen_position - touch_origin)
	target = (player_origin + offset).clamp(Vector2.ONE * DentiArena.PLAYER_MARGIN,
		player.arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN)


func movement_direction(delta: float) -> Vector2:
	if touch_index < 0 or not visible or not combat_active or not is_instance_valid(player):
		return Vector2.ZERO
	var distance := target - player.global_position
	# Keep movement stats meaningful and avoid overshooting a nearby target.
	return distance / maxf(player.stats.move_speed * delta, 0.001) if distance.length() < player.stats.move_speed * delta else distance.normalized()


func _release_touch() -> void:
	touch_index = -1
