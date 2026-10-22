extends SceneTree

const OUTPUT := "res://.godot/goblin_preview/"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var session: Node = root.get_node("GameSession")
	session.save_path = OUTPUT + "run.json"
	session.settings_path = OUTPUT + "settings.cfg"
	session.progression_path = OUTPUT + "progression.cfg"
	session.report_dir = OUTPUT + "reports"
	session.settings_data = SessionSettings.new()
	session.progression_data = ProgressionStore.new()
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	session.pending_start_weapon_id = &"magic_toothbrush"
	session.reduced_ui_motion = true
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	if OS.get_cmdline_user_args().has("--play"):
		game.player.stats.max_health = 300
		game.player.stats.health = 300
		game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 2}, {"id": "turbo_drill", "tier": 2}, {"id": "water_jet", "tier": 2}])
		game.wave.current_wave = 11
		game.wave.goblin_profile = game.wave.goblin_profile.duplicate()
		game.wave.goblin_profile.spawn_chance = 1.0
		game._start_combat_wave()
		return
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.wave.current_wave = 12
	game.wave.remaining = 24
	game.wave.active = true
	game.player.loadout.restore([])
	var center: Vector2 = game.arena.arena_size * 0.5
	game.player.position = center + Vector2(-260, 0)
	game._spawn_loot_goblin()
	var thief: Enemy = game.get_node("Enemies").get_child(-1)
	thief.position = center + Vector2(80, 0)
	for offset in [Vector2(180, 100), Vector2(245, 90), Vector2(210, -80), Vector2(310, 40)]:
		game._create_enemy(EnemyCatalog.SUGAR, center + offset)
	for i in 12:
		game._spawn_loot(center + Vector2(80 + (i % 4) * 32, (i / 4) * 35), &"coin", 2)
	for frame in 10: await process_frame
	print("Native scoop check: ", thief.loot_goblin.carried, " coins in bag")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT + "desktop.png"))
	# A larger native rig view makes joint placement and alpha edges inspectable.
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color("211b2a")
	bg.size = Vector2(1280, 720)
	canvas.add_child(bg)
	canvas.layer = 80
	var rig := LootGoblinRig.new()
	canvas.add_child(rig)
	rig.position = Vector2(640, 370)
	rig.scale = Vector2.ONE * 2.2
	for frame in 10: await process_frame
	for frame in 48:
		rig.sample(float(frame) / 24, true, frame >= 24, false, 0.8, 1)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT + "rig_%03d.png" % frame))
	canvas.free()
	game.free()
	session.clear_run()
	print("Goblin native captures: ", ProjectSettings.globalize_path(OUTPUT))
	quit()
