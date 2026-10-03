extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event

func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_mobile_controls.json"
	session.clear_run()
	_check(session.mobile_base_size(Vector2i(576, 1086)) == Vector2i(720, 1280) and session.mobile_base_size(Vector2i(1086, 576)) == Vector2i(1040, 600), "mobile scaling did not follow orientation")
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	var controls: MobileControls = game.mobile_controls
	controls.visible = true
	for extent in [Vector2i(720, 1280), Vector2i(1040, 600)]:
		root.size = extent
		await process_frame
		controls.set_combat_active(true)
		game.player.global_position = game.player.arena.arena_size * 0.5
		var origin: Vector2 = game.player.global_position
		var start := Vector2(extent) * 0.5
		controls._unhandled_input(_touch(2, start, true))
		_check(controls.touch_index == 2 and controls.target == origin, "touch away from Denti teleported target")
		_check(controls.movement_direction(1.0 / 60.0) == Vector2.ZERO, "tap alone moved player")
		var offset: Vector2 = game.player.get_canvas_transform().basis_xform(Vector2(80, 0))
		controls._input(_drag(2, start + offset))
		_check(controls.target.distance_to(origin + Vector2(80, 0)) < 0.01, "drag did not preserve world/screen offset")
		_check(controls.movement_direction(1.0 / 60.0).distance_to(Vector2.RIGHT) < 0.01, "drag did not move toward target")
		game.player._physics_process(1.0 / 60.0)
		_check(game.player.global_position.x > origin.x and game.player.global_position.x - origin.x <= game.player.stats.move_speed / 60.0 + 0.01, "direct drag bypassed move speed")
		controls._unhandled_input(_touch(3, start + Vector2(0, 80), true))
		controls._input(_touch(3, start, false))
		_check(controls.touch_index == 2, "second finger stole or released movement")
		game.player.global_position = controls.target - Vector2(0.25, 0)
		game.player._physics_process(1.0 / 60.0)
		_check(game.player.global_position.distance_to(controls.target) < 0.01, "player overshot nearby drag target")
		_check(controls.movement_direction(1.0 / 60.0).length() < 0.01, "player kept moving after reaching target")
		controls._input(_drag(2, Vector2(-10000, -10000)))
		_check(controls.target == Vector2.ONE * DentiArena.PLAYER_MARGIN, "touch target escaped arena")
		controls._input(_touch(2, start, false))
		_check(controls.touch_index == -1 and controls.movement_direction(1.0 / 60.0) == Vector2.ZERO, "release did not stop movement")
		controls._unhandled_input(_touch(4, controls.pause_button.get_global_rect().get_center(), true))
		_check(controls.touch_index == -1, "pause touch started movement")
		controls._unhandled_input(_touch(2, start, true))
		paused = true
		_check(controls.touch_index == -1, "pause retained old gesture")
		paused = false
		controls._unhandled_input(_touch(2, start, true))
		controls._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
		_check(controls.touch_index == -1, "lost focus retained movement")
		controls.set_combat_active(false)
		controls._unhandled_input(_touch(2, start, true))
		_check(controls.touch_index == -1 and not controls.pause_button.visible, "touch controls remained active in intermission")
	# Exercise real input dispatch as well as gesture math: UI must receive
	# pause touches before the playfield handler starts a gesture.
	game.wave.active = true
	await process_frame
	controls.set_combat_active(true)
	var playfield := Vector2(root.size) * 0.5
	root.push_input(_touch(6, playfield, true), true)
	_check(controls.touch_index == 6, "real playfield touch never reached direct controls")
	root.push_input(_touch(6, playfield, false), true)
	var pause_at := controls.pause_button.get_global_rect().get_center()
	root.push_input(_touch(7, pause_at, true), true)
	root.push_input(_touch(7, pause_at, false), true)
	await process_frame
	_check(game.game_menu.visible and controls.touch_index == -1, "real pause touch moved Denti or failed to open menu")
	paused = false
	session.clear_run()
	if failures.is_empty():
		print("Denti mobile controls test passed")
	quit(0 if failures.is_empty() else 1)
