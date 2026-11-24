extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	var transition: DentiSceneTransition = root.get_node("SceneTransitions")
	var previous_motion: bool = session.reduced_ui_motion
	session.reduced_ui_motion = false
	transition.set_process(false)
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	transition.play_snapshot(texture)
	check(transition.active and transition.blocks_input and transition.snapshot.texture == texture, "snapshot does not cover and protect the incoming screen")
	check(transition.snapshot.material.get_shader_parameter("progress") == 0.0, "transition starts with an already revealed outgoing screen")
	paused = true
	transition._process(0.01)
	transition._process(DentiSceneTransition.DURATION * 0.5)
	check(paused and is_equal_approx(transition.snapshot.material.get_shader_parameter("progress"), 0.5), "paused menus cannot finish their reveal independently")
	var elapsed := transition.elapsed
	transition.screen_key = &"rewards"
	transition.present(&"rewards")
	check(is_equal_approx(elapsed, transition.elapsed), "repeated reward presentation restarts the transition")
	transition.advance(DentiSceneTransition.DURATION)
	check(not transition.active and not transition.visible and not transition.blocks_input and transition.snapshot.texture == null, "completed transition retains a frame or blocks input")
	transition.play_snapshot(texture, false)
	check(not transition.blocks_input and transition.snapshot.mouse_filter == Control.MOUSE_FILTER_IGNORE, "combat reveal captures movement input")
	get_root().size_changed.emit()
	check(transition.active, "unchanged viewport dimensions cancel the transition during scene setup")
	var original_size := root.size
	root.size = original_size + Vector2i(137, 51)
	await process_frame
	check(not transition.active and transition.snapshot.texture == null, "resizing leaves a stretched snapshot on screen")
	root.size = original_size
	transition.play_snapshot(texture)
	session.reduced_ui_motion = true
	transition._process(0.01)
	check(not transition.active and not transition.blocks_input, "reduced motion leaves an active transition/input lock")
	transition.play_snapshot(texture)
	check(not transition.active, "reduced motion still starts crossfades")
	session.reduced_ui_motion = false
	transition.play_snapshot(texture)
	check(transition.change_scene("res://scenes/missing_transition_test.tscn") == ERR_FILE_NOT_FOUND and transition.active, "invalid destination destroys the current presentation")
	check(transition.change_scene("res://scenes/ui/game_menu.tscn") == OK, "valid scene change failed")
	check(transition.change_scene("res://scenes/game/game.tscn") == ERR_BUSY, "double activation queues another scene replacement")
	transition.present(&"combat", false)
	check(not transition.blocks_input, "incoming resumed combat cannot release movement before the scene blend ends")
	for frame in 6:
		await process_frame
	check(current_scene is GameMenu and paused, "scene transition changes pause ownership or loses the target scene")
	transition.advance(DentiSceneTransition.DURATION)
	check(not transition.active and transition.snapshot.texture == null, "scene change retains its outgoing snapshot")
	transition.set_process(true)
	session.reduced_ui_motion = previous_motion
	paused = false
	if failures.is_empty():
		print("Scene transitions: scene lifetime, paused UI, input, resize and reduced motion passed")
	finish_checks()
