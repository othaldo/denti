extends "res://tests/support/test_runtime.gd"

## Captures the Dentipedia class entries and the talent tree help.
## Output: .godot/pedia_classes_<w>x<h>.png, .godot/talent_help_1280x720.png

func _initialize() -> void:
	_run.call_deferred()

func _capture(name: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/" + name + ".png")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://class_help_preview.json"
	session.reduced_ui_motion = true
	session.clear_run()
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu._show_dentipedia()
	var pedia: Control = menu.dentipedia
	for extent in [Vector2i(1280, 720), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		pedia.select_category(DentipediaData.CATEGORIES.size() - 1)
		pedia._refresh()
		pedia._show(pedia.entries[3])
		await _capture("pedia_classes_%dx%d" % [extent.x, extent.y])
	menu.free()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	session.pending_start_class_id = &"ember"
	session.pending_start_weapon_id = &"turbo_drill"
	session.pending_talent_run = true
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.set_process(false)
	game._award_xp(5 + 8)
	game.wave.active = false
	game._begin_loot_collection()
	for frame in 60:
		await process_frame
		if game.talent_panel.visible: break
	game.talent_panel.help_button.pressed.emit()
	await _capture("talent_help_1280x720")
	session.clear_run()
	finish()
