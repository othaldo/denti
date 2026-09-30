extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://cheat_menu_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var menu: DebugCheatMenu = game.get_node("DebugCheatMenu")
	menu.controls.add_weapon(&"water_jet", 4)
	menu.controls.add_weapon(&"toothpick_spear", 2)
	menu.controls.add_item(&"fluoride_gel", 3)
	menu.controls.add_item(&"conductive_varnish", 2)
	menu.controls.set_coins(500)
	menu.open_menu()
	var tabs: TabContainer = menu.root_control.get_child(1).get_child(0).get_child(1)
	for tab in tabs.get_tab_count():
		tabs.current_tab = tab
		for frame in 8:
			await process_frame
		root.get_texture().get_image().save_png("res://.godot/cheat_menu_%d.png" % tab)
	session.clear_run()
	quit()
