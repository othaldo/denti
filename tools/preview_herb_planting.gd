extends SceneTree
## Captures the Kräuterzahn planting animation (staff jab, seed arc, soil burst)
## at a few moments to .godot/herb_preview/planting_<n>.png.

const OUTPUT := "res://.godot/herb_preview/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var session: Node = root.get_node("GameSession")
	session.save_path = OUTPUT + "run.json"
	session.progression_path = OUTPUT + "progression.cfg"
	session.reduced_ui_motion = true
	session.resume_requested = false
	session.clear_run()
	session.pending_start_class_id = &"herb_druid"
	session.pending_start_weapon_id = &"planting_staff"
	session.pending_talent_run = true
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 5: await process_frame
	game.wave.set_process(false)
	game.wave.active = true
	var herbs := HerbSkills.for_player(game.player)
	var staff := herbs.staff()
	staff.affixes.assign([{"id": "ice", "rarity": 2, "damage": 6.0}])
	staff.data = WeaponRolls.with_affixes(WeaponCatalog.by_id(&"planting_staff"), staff.affixes)
	staff.refresh_skin()
	var origin: Vector2 = game.player.global_position
	for index in 3: game._create_enemy(WaveController.PLAQUE, origin + Vector2(250, -60 + index * 60))
	herbs.plant(origin + Vector2(40, 30), staff)
	var shots := [2, 7, 14, 24]
	var frame_index := 0
	for capture in shots.size():
		while frame_index < shots[capture]:
			await process_frame
			frame_index += 1
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var screen := Vector2i(game.player.get_global_transform_with_canvas().origin)
		image = image.get_region(Rect2i(screen - Vector2i(140, 130), Vector2i(320, 240)))
		image.resize(640, 480, Image.INTERPOLATE_LANCZOS)
		image.save_png(ProjectSettings.globalize_path(OUTPUT + "planting_%d.png" % capture))
	session.clear_run()
	quit()
