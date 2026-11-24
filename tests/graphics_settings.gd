extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")

func _frames(policy: AdaptiveGraphics, fps: int, count: int) -> void:
	for frame in range(count):
		policy.observe_frame(1.0 / fps)

func _check_adaptive_policy() -> void:
	var policy: AdaptiveGraphics = load("res://scripts/systems/adaptive_graphics.gd").new()
	check(not policy.economy, "automatic graphics start at reduced resolution")
	check(not policy.observe_frame(3.0) and not policy.economy, "startup stall reduced the resolution")
	_frames(policy, 16, 32)
	check(not policy.economy, "two low-FPS windows triggered the fallback")
	_frames(policy, 32, 32)
	check(policy.low_fps_windows == 0, "recovered FPS did not interrupt the low-FPS streak")
	policy.observe_frame(2.0)
	check(not policy.economy, "a single long stall triggered the fallback")
	_frames(policy, 32, 32)
	_frames(policy, 20, 80)
	check(not policy.economy and policy.low_fps_windows == 0, "exactly 20 FPS triggered the fallback")
	_frames(policy, 16, 32)
	policy.suspend()
	check(policy.low_fps_windows == 0 and policy.sample_frames == 0, "pause retained a partial FPS sample")
	policy.observe_frame(3.0)
	_frames(policy, 16, 32)
	check(not policy.economy, "pause retained a prior low-FPS streak")
	_frames(policy, 16, 16)
	check(policy.economy, "three low-FPS windows did not trigger the fallback")
	_frames(policy, 60, 240)
	policy.suspend()
	check(policy.economy, "recovered FPS or a pause switched the resolution back during a run")
	policy.reset()
	check(not policy.economy and policy.warmup_elapsed == 0, "new run did not restore full resolution")

func _run() -> void:
	_check_adaptive_policy()
	var session: Node = root.get_node("GameSession")
	var prior_path: String = session.settings_path
	var prior_mode: int = session.graphics_mode
	session.settings_path = "user://test_graphics_settings.cfg"
	check(not session.use_economy_graphics(0, false) and session.use_economy_graphics(0, true), "automatic graphics do not follow the measured fallback state")
	check(session.use_economy_graphics(1, false) and not session.use_economy_graphics(2, true), "explicit graphics choice does not override automatic selection")
	root.size = Vector2i(2400, 1080)
	root.content_scale_size = Vector2i(1040, 600)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._show_options()
	menu.graphics_option.select(1)
	menu.graphics_option.item_selected.emit(1)
	await process_frame
	await process_frame
	check(session.graphics_mode == 1 and root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT, "economy choice did not limit rendering resolution")
	check(root.content_scale_size == Vector2i(1040, 600), "graphics mode changed the logical mobile layout")
	var logical_size := menu.root_control.size
	check(is_equal_approx(logical_size.y, 600), "economy mode changed logical height")
	var panel := menu.stage.panel.get_global_rect()
	check(panel.position.y >= 0 and panel.end.y <= 600, "landscape graphics options overflow the screen")
	check(menu.graphics_option.get_global_rect().end.x <= logical_size.x, "graphics selector overflowed the panel")
	menu.graphics_option.select(2)
	menu.graphics_option.item_selected.emit(2)
	await process_frame
	await process_frame
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and menu.root_control.size.is_equal_approx(logical_size), "full mode changed layout instead of rendering quality")
	var saved := ConfigFile.new()
	check(saved.load(session.settings_path) == OK and saved.get_value("display", "graphics_mode", -1) == 2, "graphics preference was not saved")
	session.graphics_mode = 0
	session._ready()
	check(session.graphics_mode == 2, "restart lost the graphics preference")
	menu._show_options()
	check(menu.graphics_option.selected == 2, "reopened options show the wrong preference")
	session.set_graphics_mode(0)
	check(not session.economy_graphics() and root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS, "automatic selection did not start at full resolution")
	session.adaptive_graphics.observe_frame(3.0)
	_frames(session.adaptive_graphics, 16, 32)
	session.graphics_sample_us = Time.get_ticks_usec() - 62500
	session.update_graphics_performance(false)
	check(session.graphics_sample_us == -1 and session.adaptive_graphics.low_fps_windows == 0, "intermission did not reset sampling")
	session.adaptive_graphics.observe_frame(3.0)
	_frames(session.adaptive_graphics, 16, 32)
	paused = true
	session.update_graphics_performance(true)
	check(session.graphics_sample_us == -1 and session.adaptive_graphics.low_fps_windows == 0, "paused combat retained sampling")
	paused = false
	session.adaptive_graphics.observe_frame(3.0)
	_frames(session.adaptive_graphics, 16, 32)
	session._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	session.update_graphics_performance(true)
	check(session.graphics_sample_us == -1 and session.adaptive_graphics.low_fps_windows == 0, "background tab retained sampling")
	session._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	session.adaptive_graphics.observe_frame(3.0)
	_frames(session.adaptive_graphics, 16, 47)
	session.graphics_sample_us = Time.get_ticks_usec() - 62500
	session.update_graphics_performance(true)
	check(session.economy_graphics() and root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT, "measured low FPS did not change the rendering mode")
	check(menu.root_control.size.is_equal_approx(logical_size), "automatic fallback changed logical layout")
	saved.load(session.settings_path)
	check(session.graphics_mode == 0 and saved.get_value("display", "graphics_mode", -1) == 0, "automatic fallback overwrote the saved preference")
	session.update_graphics_performance(false)
	check(session.economy_graphics(), "intermission undid the automatic fallback")
	session.begin_graphics_run()
	check(not session.economy_graphics() and root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS, "new run retained automatic low resolution")
	session.adaptive_graphics.economy = true
	session.set_graphics_mode(2)
	check(not session.economy_graphics(), "manual full mode did not override the fallback")
	menu.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.settings_path))
	session.settings_path = prior_path
	session.graphics_mode = prior_mode
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	session.apply_graphics()
	if failures.is_empty():
		print("Denti graphics settings test passed")
	finish_checks()
