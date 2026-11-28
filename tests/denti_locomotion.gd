extends "res://tests/support/test_runtime.gd"

const ACTIONS := [
	[&"move_up"], [&"move_right", &"move_up"], [&"move_right"], [&"move_right", &"move_down"],
	[&"move_down"], [&"move_left", &"move_down"], [&"move_left"], [&"move_left", &"move_up"],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_denti_locomotion.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	var player: Player = game.player
	var visual := player.locomotion
	var face := player.expressions
	face.set_process(false)
	check(visual.visible and player.sprite.self_modulate.a == 0.0 and visual.frame == DentiLocomotion.Heading.SOUTH,
		"new run did not start on the directional body")
	for heading in ACTIONS.size():
		var origin := player.position
		for action in ACTIONS[heading]:
			Input.action_press(action)
		for tick in 6:
			await physics_frame
		for action in ACTIONS[heading]:
			Input.action_release(action)
		check(player.position.distance_to(origin) > 1.0 and visual.facing == heading and visual.frame == heading,
			"gameplay input did not turn and move Denti toward heading %d" % heading)
		check(face.face_sprite.visible == (heading in [3, 4, 5]), "face visibility disagrees with heading %d" % heading)
		check(not face.face_sprite.visible or face.face_sprite.flip_h == (heading == 3), "incorrect face projection")
		if heading == DentiLocomotion.Heading.SOUTHEAST:
			face.next_blink = 0.0
			face._process(0.01)
			check(face.face_sprite.visible and face.current_face == DentiExpressions.Face.BLINK, "diagonal view lost blinking")
			face._process(face.settings.blink_duration + 0.01)
	var breath := visual.breath_phase
	for tick in 16:
		await physics_frame
	check(visual.facing == DentiLocomotion.Heading.NORTHWEST and visual.frame == visual.facing,
		"returning to idle changed facing")
	check(visual.step_weight == 0.0 and not is_equal_approx(visual.breath_phase, breath),
		"idle did not settle the feet and keep breathing")
	face.celebrate()
	check(visual.frame == DentiLocomotion.Heading.SOUTH and face.face_sprite.visible, "celebration did not show the front expression")
	face._process(face.settings.celebrate_duration + 0.01)
	check(visual.frame == DentiLocomotion.Heading.NORTHWEST and not face.face_sprite.visible, "ending a reaction did not restore the last heading")
	var saved := RunSnapshot.capture(game)
	check(saved.player.presentation.facing == DentiLocomotion.Heading.NORTHWEST, "snapshot omitted the last heading")
	visual.restore_facing(null)
	check(visual.frame == DentiLocomotion.Heading.SOUTH, "legacy save did not use the front default")
	RunSnapshot.restore(game, JSON.parse_string(JSON.stringify(saved)))
	check(visual.frame == DentiLocomotion.Heading.NORTHWEST, "a real JSON snapshot lost the last heading")
	for profile in ClassCatalog.profiles:
		player.stats.class_data = profile
		player.apply_class_look()
		check(visual.visible and visual.texture == DentiLocomotion.ART[profile.id], "directional class atlas not shown for %s" % profile.id)
		check(face.visible == (profile.combat_sprite == null), "class face layer not updated for %s" % profile.id)
	player.stats.class_data = ClassCatalog.DEFAULT
	player.apply_class_look()
	player.stats.take_damage(1000.0)
	check(paused and visual.frame == DentiLocomotion.Heading.SOUTH and face.current_face == DentiExpressions.Face.DEAD,
		"death from a rear heading must show the front expression before the tree pauses")
	game.free()
	paused = false
	session.clear_run()
	if failures.is_empty():
		print("PASS denti_locomotion")
	finish_checks()
