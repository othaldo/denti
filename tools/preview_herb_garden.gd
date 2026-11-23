extends SceneTree
## Renders the Kräuterzahn with a small garden (sage, shrub, totem, clove) and
## a few enemies to .godot/herb_preview/garden.png for a visual check.

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
	game.player.class_combat.powers = {"skill_shrub": 1.0, "skill_totem": 1.0, "skill_clove": 1.0}
	var origin: Vector2 = game.player.global_position
	var spots := [Vector2(-90, -40), Vector2(-40, 60), Vector2(30, -70), Vector2(80, 30), Vector2(-120, 50), Vector2(10, 10), Vector2(120, -20), Vector2(-60, -100)]
	for spot in spots: herbs.plant(origin + spot)
	herbs.plants[4].kind = HerbSkills.Kind.SHRUB
	for index in 6:
		game._create_enemy(WaveController.PLAQUE, origin + Vector2(260, -120 + index * 50))
	for frame in 60: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT + "garden.png"))
	session.clear_run()
	quit()
