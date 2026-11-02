extends "res://tests/support/test_runtime.gd"
## Native snapshots of the actual weapon-choice views; isolated preview data only.

const OUTPUT := "res://.godot/weapon_scaling/"

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 20: await process_frame

func _resize(extent: Vector2i) -> void:
	root.content_scale_size = extent
	root.size = extent
	DisplayServer.window_set_size(extent)
	await _settle()

func _capture(filename: String) -> void:
	var pointer := InputEventMouseMotion.new()
	pointer.position = Vector2(2, 2)
	root.push_input(pointer, true)
	await _settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)
	print(OUTPUT + filename)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://scaling_preview_run.json"
	session.progression_path = "user://scaling_preview_progression.cfg"
	session.load_progression()
	session.resume_requested = false
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._new_game()
	menu._advance_setup()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280)]:
		await _resize(extent)
		for index in [13, 15, 7]:
			menu.setup_selector.select_weapon(index)
			await _capture("starter_%d_%dx%d.png" % [index, extent.x, extent.y])
	menu.free()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.coins = 150
	game.player.loadout.restore([{"id": "uv_lamp", "tier": 2}, {"id": "floss_garrote", "tier": 1}, {"id": "turbo_drill", "tier": 1}])
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"uv_lamp"), ShopController.by_id(&"floss_garrote"), ShopController.by_id(&"turbo_drill"), ShopController.by_id(&"water_turbine")])
	game._update_shop_panel()
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(320, 568), Vector2i(1040, 600)]:
		await _resize(extent)
		game.shop_panel.close_details()
		game.shop_panel.main_scroll.scroll_vertical = 0
		await _capture("shop_%dx%d.png" % [extent.x, extent.y])
		if extent.x == 320:
			game.shop_panel.main_scroll.ensure_control_visible(game.shop_panel.offer_buttons[0])
			await _capture("shop_offers_%dx%d.png" % [extent.x, extent.y])
		game.shop_panel._select("offer", 0)
		await _capture("details_%dx%d.png" % [extent.x, extent.y])
	game.shop_panel.close_details()
	game.game_menu.visible = true
	game.game_menu._show_dentipedia()
	var pedia: Dentipedia = game.game_menu.dentipedia
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280)]:
		await _resize(extent)
		pedia.select_category(0)
		pedia._show(pedia.entries[13])
		await _capture("dentipedia_%dx%d.png" % [extent.x, extent.y])
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	finish()
