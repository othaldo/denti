extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_build_overview.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.game_menu.open_pause()
	var menu: GameMenu = game.game_menu
	menu._show_items()
	if menu.rows.get_child_count() != 3 or not menu.rows.get_child(1).text.contains("Keine Items"):
		_fail("empty inventory has explanatory filler or a decorative portrait")
		return
	game.items.acquire(ShopController.by_id(&"metal_crown"))
	game.items.acquire(ShopController.by_id(&"metal_crown"))
	game.items.acquire(ShopController.by_id(&"polish_paste"))
	game.relics.acquire(&"tidal_seal")
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(1040, 600)]:
		root.content_scale_size = extent
		root.size = extent
		menu._show_stats()
		for frame in 4:
			await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(extent))
		if not bounds.encloses(menu.build_panel.get_global_rect()) or menu.rows.get_child(0).text != "Stats":
			_fail("compact stats exceed viewport %s" % extent)
			return
		var weapons: HBoxContainer = menu.rows.get_child(5)
		weapons.get_child(0).pressed.emit()
		for frame in 3:
			await process_frame
		if menu.item_details.heading.text != game.player.loadout.equipped()[0].data.display_name or not bounds.encloses(menu.build_panel.get_global_rect()):
			_fail("weapon inspection from stats is missing or exceeds viewport")
			return
		menu._show_items()
		for frame in 4:
			await process_frame
		if menu.build_grid.get_child_count() != 3 or not bounds.encloses(menu.build_panel.get_global_rect()) or menu.build_scroll.custom_minimum_size.y > 65:
			_fail("small item collection has excess space or exceeds viewport")
			return
		var first: Button = menu.build_grid.get_child(0)
		if first.get_child(0).texture == null or first.get_child(1).text != "×2" or not first.tooltip_text.contains("Metallkrone"):
			_fail("inventory icon lacks artwork, count or effect tooltip")
			return
		menu.build_grid.get_child(1).pressed.emit()
		if menu.item_details.heading.text != "Polierpaste" or menu.item_details.effect.text.is_empty():
			_fail("inventory selection did not show the chosen effect")
			return
	# Large collections stay bounded and scroll only when needed.
	for item in ShopController.CATALOG:
		if item.weapon_data == null:
			game.items.acquire(item)
	menu._show_items()
	for frame in 5:
		await process_frame
	if not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(menu.build_panel.get_global_rect()) or menu.build_scroll.get_v_scroll_bar().max_value <= menu.build_scroll.size.y:
		_fail("large item collection does not scroll within the panel")
		return
	menu.rows.get_child(menu.rows.get_child_count()-1).pressed.emit()
	if menu.page != &"home" or not paused:
		_fail("returning from inventory incorrectly resumed combat")
		return
	paused = false
	session.clear_run()
	print("Denti build overview test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
