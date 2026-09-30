extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	if session.mobile_base_size(Vector2i(576, 1086)) != Vector2i(720, 1280) or session.mobile_base_size(Vector2i(1086, 576)) != Vector2i(1040, 600):
		_fail("mobile scaling did not follow device orientation")
		return
	root.size = Vector2i(1280, 720)
	var controls: MobileControls = load("res://scenes/ui/mobile_controls.tscn").instantiate().get_node("Root")
	var layer := controls.get_parent()
	root.add_child(layer)
	controls.visible = true
	controls.set_combat_active(true)
	await process_frame
	var center := Vector2(102, 618)
	var down := InputEventScreenTouch.new()
	down.index = 2
	down.position = center
	down.pressed = true
	controls._input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = center + Vector2(140, 0)
	controls._input(drag)
	if controls.direction.distance_to(Vector2.RIGHT) > 0.01:
		_fail("touch stick did not clamp to the right")
		return
	var other := InputEventScreenTouch.new()
	other.index = 3
	other.position = center + Vector2(0, -60)
	other.pressed = false
	controls._input(other)
	if controls.direction == Vector2.ZERO:
		_fail("another finger released the stick")
		return
	down.pressed = false
	controls._input(down)
	if controls.direction != Vector2.ZERO:
		_fail("stick did not stop on release")
		return
	controls.set_combat_active(false)
	if controls.pause_button.visible or controls.direction != Vector2.ZERO:
		_fail("controls remained active outside combat")
		return
	print("Denti mobile controls test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
