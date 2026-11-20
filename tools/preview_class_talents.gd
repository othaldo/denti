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
	for extent in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		await _capture("class_pick_%dx%d" % [extent.x, extent.y])
	menu._select_setup_class(&"good_old_molar")
	menu.setup_selector.class_view.selected_id = &"good_old_molar"
	menu.setup_selector.class_view.refresh()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	await _capture("class_pick_molar_1280x720")
	menu._select_setup_class(&"tooth_fairy")
	menu.setup_selector.class_view.selected_id = &"tooth_fairy"
	menu.setup_selector.class_view.refresh()
	menu._advance_setup()
	await _capture("weapon_pick_tooth_fairy_1280x720")
	# Future-proofing: the same step with many classes (placeholder copies).
	var shipped := ClassCatalog.profiles.duplicate()
	for copy in 10: ClassCatalog.profiles.append(shipped[copy % shipped.size()])
	var crowded: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(crowded)
	crowded._new_game()
	crowded._advance_setup()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		await _capture("class_pick_many_%dx%d" % [extent.x, extent.y])
	crowded.free()
	ClassCatalog.profiles.assign(shipped)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
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
	for extent in [Vector2i(3840, 1600), Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		game.talent_panel._select(&"venom_dose")
		await _capture("talent_tree_%dx%d" % [extent.x, extent.y])
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	for id in [&"venom_dose", &"silk_a_melee", &"silk_a_melee", &"silk_edge"]:
		game._on_talent_requested(id)
	game.talent_panel._select(&"venom_bloom")
	await _capture("talent_draft_1280x720")
	game.talent_panel._select(&"care_free_1")
	await _capture("talent_free_1280x720")
	# Inspect the second shipping tree in the same native component.
	var molar := new_stats()
	molar.begin_class(ClassCatalog.DEFAULT)
	var progress := TalentProgression.new()
	progress.enabled = true
	# Committed Standfest points with one root bound to Härte, then a fresh draft.
	progress.prepare(5, 2, 0)
	for id in [&"stand_a_health", &"stand_a_health", &"stand_a_armor"]:
		progress.plan_talent(id, molar, game.UPGRADES, 5)
	progress.plan_talent(&"stand_free_1", molar, game.UPGRADES, 5, &"armor")
	progress.plan_talent(&"stand_free_1", molar, game.UPGRADES, 5)
	progress.commit(molar, game.UPGRADES, 5)
	progress.prepare(3, 7, 0)
	game.talent_panel.present(progress, molar, game.UPGRADES, 3)
	game.talent_panel._select(&"tool_variety")
	await _capture("talent_molar_1280x720")
	game.talent_panel._select(&"stand_free_1")
	await _capture("talent_bound_1280x720")
	game.talent_panel._select(&"tool_mix_key")
	await _capture("talent_keystone_1280x720")
	game.talent_panel._select(&"tool_rehearsal")
	await _capture("talent_skill_1280x720")
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = root.content_scale_size
	await _capture("talent_skill_1920x1080")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	root.content_scale_size = Vector2i(320, 568)
	root.size = root.content_scale_size
	await _capture("talent_molar_320x568")
	# Roster trees in the same native component.
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	for class_id in [&"tooth_fairy", &"ember", &"rinser", &"frost_warden"]:
		var roster := new_stats()
		roster.begin_class(ClassCatalog.by_id(class_id))
		var roster_progress := TalentProgression.new()
		roster_progress.enabled = true
		roster_progress.prepare(3, 2, 0)
		game.talent_panel.present(roster_progress, roster, game.UPGRADES, 3)
		for node in roster.class_data.talent_tree.nodes:
			if node.is_skill():
				game.talent_panel._select(node.id)
				break
		await _capture("talent_%s_1280x720" % class_id)
	session.clear_run()
	finish()
