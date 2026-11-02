extends "res://tests/support/test_runtime.gd"

const BRAIN = preload("res://tools/balance/bots/pilot_brain.gd")
const VIEWER = preload("res://tools/balance/bots/run_viewer.gd")
var failures := 0
var viewer_step_done := false
var viewer_decision_done := false

func _initialize() -> void: call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _world() -> Dictionary:
	return {"position": Vector2(960, 540), "arena": Vector2(1920, 1080), "speed": 230.0,
		"reach": 160.0, "dash_distance": 180.0, "dash_ready": true, "health": 1.0,
		"enemies": [], "projectiles": [], "hazards": [], "loot": [Vector2(1080, 540)]}

func _run() -> void:
	var brain := BRAIN.new()
	brain.configure("expert", "collector", 42)
	brain.profile = brain.profile.duplicate()
	brain.profile.reaction_ticks = 3
	brain.profile.decision_ticks = 1
	for frame in 3:
		_check(brain.step(frame, _world()) == Vector2.ZERO, "pilot reacted before its perception delay")
	_check(brain.step(3, _world()).x > 0.9, "pilot never applied its delayed observation")
	brain.begin_wave()
	_check(brain.direction == Vector2.ZERO and brain.pending.is_empty(), "a new wave inherited a stale target/input")
	# Reproducible mistakes, independent of the global combat RNG.
	var first := BRAIN.new()
	var second := BRAIN.new()
	first.configure("novice", "collector", 13579)
	second.configure("novice", "collector", 13579)
	seed(12345)
	var expected := randf()
	seed(12345)
	for frame in 600:
		_check(first.step(frame, _world()) == second.step(frame, _world()), "same pilot seed changed its input sequence")
	_check(randf() == expected and first.mistakes > 0 and first.metrics() == second.metrics(), "pilot mistakes are not isolated/reproducible")
	brain = BRAIN.new()
	brain.configure("expert", "collector", 7)
	brain.profile = brain.profile.duplicate()
	brain.profile.reaction_ticks = 0
	brain.profile.decision_ticks = 1
	var world := _world()
	world.projectiles = [{"position": Vector2(1080, 540), "velocity": Vector2(-300, 0), "radius": 21.0, "life": 2.0}]
	var action := brain.step(0, world)
	_check(absf(action.y) > 0.3 and brain.dash, "experienced pilot failed to evade/dash away from an approaching shot")
	world.dash_ready = false
	brain.step(1, world)
	_check(not brain.dash, "pilot requested a dash with no observed charge")
	world = _world()
	world.hazards = [{"shape": "sector", "position": Vector2(800, 540), "direction": Vector2.RIGHT, "radius": 350.0, "angle": 0.5, "time": 0.2}]
	_check(brain.danger(world, Vector2.ZERO) > 0, "pilot ignored a currently announced cloak sector")
	world.hazards[0].time = 2.0
	_check(brain.danger(world, Vector2.ZERO) == 0, "pilot treated a far future warning as an immediate hit")
	world.hazards[0].time = 0.7
	_check(brain.danger(world, Vector2.UP) < brain.danger(world, Vector2.ZERO), "starting inside a warning made a safe side exit look equally dangerous")
	world.hazards[0].time = 0.1
	_check(brain.danger(world, Vector2.UP) < brain.danger(world, Vector2.ZERO), "urgent warning gave no preference to progress toward safety")
	world.hazards[0].time = -0.2
	world.hazards[0].duration = 0.1
	_check(brain.danger(world, Vector2.ZERO) == 0, "pilot avoided a strike after its damage window ended")
	world.hazards = [{"shape": "sector", "position": Vector2(800, 540), "direction": Vector2.RIGHT,
		"radius": 340.0, "inner": 140.0, "angle": PI, "time": 0.7, "duration": 0.1}]
	_check(brain.danger(world, Vector2.LEFT) < brain.danger(world, Vector2.RIGHT), "pilot missed the safe inner opening of a warned ring")
	world.enemies = [{"position": Vector2(800, 540), "velocity": Vector2.ZERO, "radius": 48.0, "boss": true}]
	_check(brain.danger(world, Vector2.LEFT * 0.35) < brain.danger(world, Vector2.LEFT), "pilot failed to distinguish braking into a safe ring opening from crossing the boss")
	world.enemies = []
	world.frame = 0
	world.velocity = Vector2(100, 0)
	var predicted := brain._predict_observation(world, 6)
	_check(is_equal_approx(float(predicted.hazards[0].time), 0.6) and predicted.position == world.position + Vector2(10, 0), "pilot ignored the age of its delayed warning/self observation")
	_check(world.hazards[0].time == 0.7 and world.position == Vector2(960, 540), "prediction mutated a frozen delayed observation")
	world.enemies = [{"position": Vector2(1050, 540), "velocity": Vector2.ZERO, "radius": 20.0, "boss": false}]
	_check(brain.dash_risk(world, Vector2.RIGHT) >= 3, "dash planner ignored enemies along its path")
	world.enemies = []
	world.hazards = []
	world.projectiles = [{"position": Vector2(1050, 540), "velocity": Vector2.ZERO, "radius": 21.0, "life": 2.0}]
	_check(brain.dash_risk(world, Vector2.RIGHT) > 0, "dash planner checked landing only and crossed a projectile mid-route")
	world.projectiles[0].position = Vector2(1110, 540)
	_check(brain.dash_risk(world, Vector2.RIGHT * 0.35) == brain.dash_risk(world, Vector2.RIGHT), "partial walking input incorrectly shortened the real normalized dash")
	# Strategy changes a goal without changing reaction/avoidance settings.
	world = _world()
	world.enemies = [{"position": Vector2(1000, 540), "velocity": Vector2.ZERO, "radius": 20.0, "boss": false},
		{"position": Vector2(600, 540), "velocity": Vector2.ZERO, "radius": 40.0, "boss": true}]
	brain.strategy = "collector"
	_check(brain.goal_direction(world).x > 0.9, "collector did not seek visible loot")
	brain.strategy = "boss"
	_check(brain.goal_direction(world).x < 0, "boss strategy ignored the visible boss")
	# Conservative planning geometry must include every actual sector/ring hit,
	# including the circle around a sector's origin and its radial edge caps.
	for inner: float in [0.0, 130.0]:
		var hazard := {"shape": "sector", "position": Vector2.ZERO, "direction": Vector2.RIGHT,
			"radius": 340.0, "inner": inner, "angle": PI if inner > 0 else deg_to_rad(40.0)}
		for radius: float in [0.0, 10.0, 20.0, 70.0, 110.0, 130.0, 290.0, 309.0, 340.0, 360.0]:
			for index in 48:
				var point := Vector2.from_angle(TAU * index / 48.0) * radius
				var actual := HazardGeometry.circle_ring(point, Vector2.ZERO, inner, 340.0) if inner > 0 else HazardGeometry.circle_sector(point, Vector2.ZERO, Vector2.RIGHT, 340.0, deg_to_rad(40.0))
				_check(not actual or BRAIN._hazard_contains(hazard, point), "pilot marked an actual sector/ring collision as safe")
	await _viewer_controls()
	print("PASS bot pilots: delayed perception, isolated mistakes, projectile/sector avoidance, safe dash routes, distinct goals and invariant viewer clock")
	finish(1 if failures else 0)

func _wait_viewer(view: CanvasLayer) -> void:
	await view.before_step()
	viewer_step_done = true

func _wait_decision(view: CanvasLayer) -> void:
	await view.present_decision("Shop", "Angebote")
	viewer_decision_done = true

func _viewer_controls() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var view := VIEWER.new()
	root.add_child(view)
	var hz := Engine.physics_ticks_per_second
	var scale := Engine.time_scale
	view.set_speed(1)
	_check(view.pace_delay(1000000) == 0 and view.next_tick_at == 1016667, "viewer started with a backlog of accelerated ticks")
	view.set_speed(8)
	_check(view.pace_delay(2000000) == 0 and view.next_tick_at == 2002083, "changing speed fabricated catch-up time")
	await view.before_step()
	view.set_speed(16)
	await view.before_step()
	_check(view.ticks == 2 and Engine.physics_ticks_per_second == hz and Engine.time_scale == scale, "viewer speed changed simulation time/physics")
	for frame in 3: await process_frame
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = view.speeds[2].get_global_rect().get_center()
		root.push_input(click, true)
		await process_frame
	_check(view.speed == 8, "native speed button did not receive pointer input")
	var pause_key := InputEventKey.new()
	pause_key.keycode = KEY_SPACE
	pause_key.pressed = true
	root.push_input(pause_key, true)
	call_deferred("_wait_viewer", view)
	for frame in 3: await process_frame
	_check(not viewer_step_done and view.ticks == 2 and paused, "paused viewer continued stepping combat")
	root.push_input(pause_key, true)
	for frame in 3: await process_frame
	_check(viewer_step_done and view.ticks == 3, "viewer did not resume from the same pending step")
	view.decision_remaining = 2.0
	view.set_speed(1)
	view.advance_reading_time(0.25)
	_check(is_equal_approx(view.decision_remaining, 1.75), "1x shop reading time did not use the base duration")
	view.set_speed(16)
	view.advance_reading_time(0.1)
	_check(is_equal_approx(view.decision_remaining, 0.15), "changing speed mid-purchase did not accelerate the remaining reading time")
	view.toggle_pause()
	view.advance_reading_time(1.0)
	_check(is_equal_approx(view.decision_remaining, 0.15), "paused shop reading time kept counting down")
	view.toggle_pause()
	view.decision_seconds = 0.02
	view.toggle_pause()
	call_deferred("_wait_decision", view)
	for frame in 6: await process_frame
	_check(not viewer_decision_done and view.ticks == 3 and paused and view.decision_detail == "Angebote", "paused reading time hid the shop or advanced combat")
	view.toggle_pause()
	while not viewer_decision_done: await process_frame
	_check(view.ticks == 3 and view.next_tick_at == 0 and Engine.physics_ticks_per_second == hz and Engine.time_scale == scale, "intermission presentation fabricated combat/catch-up time")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	_check(not await view.before_step() and view.ticks == 3, "viewer cancellation added another simulation step")
	view.free()
	paused = false
