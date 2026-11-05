extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	_run.call_deferred()

func _capture(name: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/" + name + ".png")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://class_talent_preview.json"
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	session.clear_run()
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._new_game()
	menu._advance_setup()
	menu._select_setup_class(&"assassin")
	menu.setup_selector.class_view.selected_id = &"assassin"
	menu.setup_selector.class_view.refresh()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		await _capture("class_pick_%dx%d" % [extent.x, extent.y])
	menu.free()
	session.pending_start_class_id = &"assassin"
	session.pending_start_weapon_id = &"turbo_drill"
	session.pending_talent_run = true
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.set_process(false)
	game._award_xp(5 + 8 + 11 + 14 + 17)
	game.wave.active = false
	game._begin_loot_collection()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		game.talent_panel.selected = &""
		game.talent_panel.tab = "talent"
		game.talent_panel.refresh()
		await _capture("talent_tree_%dx%d" % [extent.x, extent.y])
		game.talent_panel._select(&"venom_opener")
		await _capture("talent_detail_%dx%d" % [extent.x, extent.y])
		game.talent_panel.tab = "stat"
		game.talent_panel._select(&"melee_damage")
		game.talent_panel.refresh()
		await _capture("talent_stats_%dx%d" % [extent.x, extent.y])
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	game._on_talent_requested(&"venom_opener")
	game._on_talent_requested(&"venom_stride")
	game.talent_panel.tab = "talent"
	game.talent_panel._select(&"venom_stride")
	game.talent_panel.refresh()
	await _capture("talent_draft_1280x720")
	# Inspect the second shipping tree in the same native component.
	var molar := new_stats()
	molar.begin_class(ClassCatalog.DEFAULT)
	var progress := TalentProgression.new()
	progress.enabled = true
	progress.prepare(3, 2, 0)
	game.talent_panel.present(progress, molar, game.UPGRADES, 3)
	root.content_scale_size = Vector2i(320, 568)
	root.size = root.content_scale_size
	await _capture("talent_molar_320x568")
	session.clear_run()
	finish()
