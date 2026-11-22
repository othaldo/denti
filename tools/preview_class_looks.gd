extends "res://tests/support/test_runtime.gd"

## Renders every class in a real combat scene to check that the class look
## replaces the base Denti at the same size and foot line.
## Usage: Godot --path . --script res://tools/preview_class_looks.gd
## Output: .godot/class_look_<id>.png

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://class_look_preview.json"
	session.reduced_ui_motion = true
	for id in ClassCatalog.MASTERY_CLASSES:
		if str(id) not in session.progression_data.class_wins:
			session.progression_data.class_wins.append(str(id))
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	for profile in ClassCatalog.profiles:
		session.clear_run()
		session.pending_start_class_id = profile.id
		session.pending_start_weapon_id = &"turbo_drill"
		for weapon in WeaponCatalog.starters_for(profile):
			if WeaponEligibility.starter(weapon, profile, profile.root_capacity):
				session.pending_start_weapon_id = weapon.id
				break
		session.pending_talent_run = true
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		for frame in 20: await process_frame
		game.wave.set_process(false)
		paused = true
		for frame in 6: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/class_look_%s.png" % profile.id)
		paused = false
		game.queue_free()
		await process_frame
	session.clear_run()
	finish()
