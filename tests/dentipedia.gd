extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	# Godot 4.7 scroll containers use emulated mouse events for touch scrolling.
	Input.emulate_touch_from_mouse = true
	var session: Node = root.get_node("GameSession")
	session.progression_path = "user://test_dentipedia_progression.cfg"
	session.save_path = "user://test_dentipedia_run.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	session.load_progression()
	session.clear_run()
	var hidden := DentipediaData.entries(0, session.discovered_fusions)
	check(hidden.size() == WeaponCatalog.ALL.size() + WeaponEvolutions.ALL.size(), "weapon list incomplete")
	for index in WeaponEvolutions.ALL.size():
		var entry: Dictionary = hidden[WeaponCatalog.ALL.size() + index]
		check(entry.get("locked", false) and not entry.has("recipe"), "undiscovered recipe exposed")
		check(not str(entry).contains(WeaponEvolutions.ALL[index].result.display_name), "secret weapon name exposed")
	for category in DentipediaData.CATEGORIES.size():
		check(not DentipediaData.entries(category, []).is_empty(), "empty category")
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game._open_shop()
	var recipe: WeaponEvolutionRecipe = WeaponEvolutions.ALL[0]
	game.player.loadout.restore([])
	game.player.loadout.acquire(WeaponCatalog.by_id(recipe.base_weapon), 4)
	for family in recipe.families:
		for item in ShopController.CATALOG:
			if item.family_id == family:
				game.items.acquire(item)
				break
	for id in recipe.items:
		game.items.acquire(ShopController.by_id(id))
	game._on_shop_evolve(0, recipe.id)
	check(session.discovered_fusions.has(str(recipe.id)), "successful fusion did not unlock entry")
	session.unlock_hell()
	session.discovered_fusions.clear()
	session.load_progression()
	check(session.discovered_fusions == [str(recipe.id)] and session.hell_unlocked, "progression saves overwrite each other")
	game.player.loadout.sell(0)
	session.clear_run()
	session.load_progression()
	check(session.discovered_fusions.has(str(recipe.id)), "sale or new run erased discovery")
	var revealed := DentipediaData.entries(0, session.discovered_fusions)
	check(revealed[WeaponCatalog.ALL.size()].title == recipe.result.display_name and revealed[WeaponCatalog.ALL.size()].has("recipe"), "discovered entry lacks recipe")
	check(revealed[WeaponCatalog.ALL.size()].body.contains("Mk V:") and not revealed[WeaponCatalog.ALL.size()].body.contains("Mk IV:"), "Dentipedia special weapon has wrong tier")
	check(DentipediaData.ingredients(recipe).size() == 1 + recipe.families.size() + recipe.items.size(), "recipe ingredients incomplete")
	game.game_menu.open_pause()
	var found := false
	for child in game.game_menu.rows.get_children():
		if child is Button and child.text == "Dentipedia":
			found = true
			child.pressed.emit()
			break
	check(found and game.game_menu.page == &"dentipedia", "pause menu entry missing")
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 15:
			await process_frame
		var pedia: Dentipedia = game.game_menu.dentipedia
		check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.game_menu.build_panel.get_global_rect()), "Dentipedia escaped viewport %s" % extent)
		pedia.search.text = WeaponEvolutions.ALL[1].result.display_name
		pedia._refresh()
		check(pedia.listing.get_child_count() == 0, "search exposed undiscovered name")
		pedia.search.text = ""
		pedia._refresh()
		pedia._show(revealed[-1])
		var image: TextureRect = pedia.detail.get_child(0).get_child(0)
		check(image.material is ShaderMaterial, "locked artwork is not a silhouette")
		if "--capture" in OS.get_cmdline_user_args() and extent.x == 1280:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/dentipedia-locked.png")
		pedia._show(revealed[WeaponCatalog.ALL.size()])
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/dentipedia-%d.png" % extent.x)
		pedia.category.selected = 4
		pedia._refresh()
		pedia.category.selected = 1
		pedia._refresh()
		for frame in 5:
			await process_frame
		pedia.list_scroll.scroll_vertical = 0
		for frame in 5:
			await process_frame
		var start: Vector2 = pedia.listing.get_child(1).get_global_rect().get_center()
		var touch := InputEventMouseButton.new()
		touch.button_index = MOUSE_BUTTON_LEFT
		touch.position = start
		touch.pressed = true
		root.push_input(touch, true)
		await process_frame
		for step in 5:
			var drag := InputEventMouseMotion.new()
			drag.button_mask = MOUSE_BUTTON_MASK_LEFT
			drag.position = start - Vector2(0, (step + 1) * 12)
			drag.relative = Vector2(0, -12)
			root.push_input(drag, true)
			await process_frame
		touch.position = start - Vector2(0, 60)
		touch.pressed = false
		root.push_input(touch, true)
		await process_frame
		check(pedia.list_scroll.scroll_vertical > 0, "item list cannot be swiped %s" % extent)
		for frame in 90:
			await process_frame
		pedia.category.selected = 0
		pedia._refresh()
	game.game_menu._show_home()
	check(paused, "reading encyclopedia resumed combat")
	session.clear_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	paused = false
	var main_menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(main_menu)
	var main_entry := false
	for child in main_menu.rows.get_children():
		if child is Button and child.text == "Dentipedia":
			main_entry = true
			child.pressed.emit()
			break
	check(main_entry and main_menu.page == &"dentipedia", "main menu Dentipedia entry missing")
	if failures.is_empty():
		print("Denti Dentipedia test passed")
	quit(0 if failures.is_empty() else 1)
