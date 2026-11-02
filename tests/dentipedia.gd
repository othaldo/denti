extends "res://tests/support/test_runtime.gd"

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
		check(entry.get("locked", false) and not entry.has("recipe") and not entry.has("weapon_data"), "undiscovered recipe or form selector exposed")
		check(not str(entry).contains(WeaponEvolutions.ALL[index].result.display_name), "secret weapon name exposed")
	for category in DentipediaData.CATEGORIES.size():
		check(not DentipediaData.entries(category, []).is_empty(), "empty category")
	var items := DentipediaData.entries(DentipediaData.CATEGORIES.find("Items"), [])
	var expected_items := 0
	for offer in ShopController.CATALOG:
		if offer.weapon_data == null:
			expected_items += 1
	check(items.size() == expected_items, "item category includes weapon offers")
	for weapon in WeaponCatalog.ALL:
		check(not items.any(func(entry: Dictionary) -> bool: return entry.title == weapon.display_name), "weapon leaked into item category")
	# Scaling belongs to the visible summary, including discovered evolutions.
	var described: Array[WeaponData] = WeaponCatalog.ALL.duplicate()
	for recipe in WeaponEvolutions.ALL:
		described.append(recipe.result)
	for weapon in described:
		var body := VBoxContainer.new()
		root.add_child(body)
		DentipediaWeaponDetails.build(body, weapon, "")
		var metadata: Label = body.get_child(1)
		check(metadata.is_visible_in_tree() and metadata.text.contains(weapon.roots_text()) and metadata.text.contains(weapon.scaling_label()), "Dentipedia hides the weapon's scaling: " + str(weapon.id))
		check(not (body.get_child(2) as Label).text.contains(weapon.scaling_text()), "Dentipedia repeats scaling in the mechanics paragraph")
		body.free()
	var enchantment_category := DentipediaData.CATEGORIES.find("Verzauberungen")
	check(enchantment_category >= 0, "dedicated enchantment category missing")
	var enchantments := DentipediaData.entries(enchantment_category, [])
	check(enchantments.size() == WeaponAffixes.ALL.size() + 1, "enchantment overview or individual entries missing")
	var enchantment_entries: Dictionary = {}
	for entry in enchantments:
		if entry.has("enchantment_id"):
			enchantment_entries[entry.enchantment_id] = entry
		for index in str(entry.body).length():
			var code := str(entry.body).unicode_at(index)
			check(code <= 32 or DentiUIStyle.FONT.has_char(code), "enchantment entry has an unsupported glyph: U+%04X" % code)
	for data in WeaponAffixes.ALL:
		check(enchantment_entries.has(str(data.id)), "missing enchantment entry: " + str(data.id))
		var entry: Dictionary = enchantment_entries.get(str(data.id), {})
		check(entry.get("title") == data.display_name and entry.get("icon") != null and str(entry.get("body", "")).contains("Passt zu deinem Build:"), "enchantment entry lacks name, icon or synergies")
	check(str(enchantment_entries["wet"].body).contains("Leitlack") and str(enchantment_entries["electric"].body).contains("Ein Sprung") and str(enchantment_entries["electric"].body).contains("Kettenitems"), "wet/electric synergy documentation missing")
	check(str(enchantment_entries["leech"].body).contains("DoTs und Folgeeffekte heilen nicht"), "leech limitations missing")
	check(str(DentipediaData.TOPICS["Strom & Nass"]).contains("auch ohne dieses Item"), "legacy electricity topic contradicts intrinsic chains")
	var mechanics := DentipediaData.entries(4, [])
	for title in ["Waffenpunkte & Effektplätze", "Manuelle Verzauberungsfusion", "Elemente & Waffenformen", "Wurzelsprung & Ausdauer", "Zahnseidenpeitsche & Schneide", "Goldzahn-Gauner", "Speichern & Fortsetzen", "Alte Spielstände"]:
		check(mechanics.any(func(entry: Dictionary) -> bool: return entry.title == title and not str(entry.body).is_empty()), "current feature lacks a mechanics entry: " + title)
	for entry in mechanics:
		for index in str(entry.body).length():
			var code := str(entry.body).unicode_at(index)
			check(code <= 32 or DentiUIStyle.FONT.has_char(code), "mechanics entry has an unsupported glyph: U+%04X" % code)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
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
	check(game.weapon_fusion_panel.visible and not session.discovered_fusions.has(str(recipe.id)), "unconfirmed fusion revealed the discovery")
	game.weapon_fusion_panel.confirm_button.pressed.emit()
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
	check(revealed[WeaponCatalog.ALL.size()].body.contains("Mk IV:") and not revealed[WeaponCatalog.ALL.size()].body.contains("Mk V:"), "Dentipedia special weapon has wrong tier")
	check(DentipediaData.ingredients(recipe).size() == 1 + recipe.families.size() + recipe.items.size(), "recipe ingredients incomplete")
	game.game_menu.open_pause()
	var entry: Button = game.game_menu.actions.get(&"dentipedia")
	var found := entry != null
	if found:
		entry.pressed.emit()
	check(found and game.game_menu.page == &"dentipedia", "pause menu entry missing")
	for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(320, 568), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 15:
			await process_frame
		var pedia: Dentipedia = game.game_menu.dentipedia
		check(game.game_menu.stage.visible and not game.game_menu.menu_stage.visible, "Dentipedia still uses the framed dialog")
		check(pedia.find_children("*", "OptionButton", true, false).is_empty() and pedia.category_buttons.size() == DentipediaData.CATEGORIES.size(), "category dropdown was not replaced by visible navigation")
		for index in pedia.category_buttons.size():
			var tab := pedia.category_buttons[index]
			check(tab.visible and Rect2(Vector2.ZERO, Vector2(extent)).encloses(tab.get_global_rect()) and tab.size.x >= 48 and tab.size.y >= 48, "category is clipped or too small for touch at %s" % extent)
			tab.pressed.emit()
			check(pedia.category_index == index and tab.button_pressed, "category button does not select its entries")
		pedia.select_category(0)
		check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.game_menu.stage.panel.get_global_rect()), "Dentipedia escaped viewport %s" % extent)
		pedia.search.text = WeaponEvolutions.ALL[1].result.display_name
		pedia._refresh()
		check(pedia.listing.get_child_count() == 0, "search exposed undiscovered name")
		pedia.search.text = ""
		pedia._refresh()
		pedia._show(revealed[-1])
		check(pedia.detail.find_children("*", "HFlowContainer", false, false).is_empty(), "locked entry offers elemental forms")
		var image: TextureRect = pedia.detail.get_child(0).get_child(0)
		check(image.material is ShaderMaterial, "locked artwork is not a silhouette")
		if "--capture" in OS.get_cmdline_user_args() and extent.x == 1280:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/dentipedia-locked.png")
		pedia._show(revealed[WeaponCatalog.ALL.size()])
		if pedia.portrait:
			check(pedia.detail_scroll.visible and not pedia.list_scroll.visible, "portrait detail remains squeezed beside the listing")
			game.game_menu.stage.back_button.pressed.emit()
			check(game.game_menu.page == &"dentipedia" and pedia.list_scroll.visible and not pedia.detail_scroll.visible and paused, "portrait back did not restore the listing and pause")
			pedia._show(revealed[WeaponCatalog.ALL.size()])
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/dentipedia-%d.png" % extent.x)
		pedia.select_category(4)
		pedia._refresh()
		check(pedia.listing.get_child(0).get_meta("entry").title == "Verzauberungen", "mechanics overview is not reachable")
		pedia.select_category(enchantment_category)
		pedia.search.text = "Lebensraub"
		pedia._refresh()
		var found_leech := false
		for button in pedia.listing.get_children():
			if button.get_meta("entry").get("enchantment_id", "") == "leech":
				button.pressed.emit()
				found_leech = true
				break
		check(found_leech and pedia.selected.get("enchantment_id", "") == "leech", "search cannot open new enchantment entry")
		pedia.search.text = ""
		pedia._refresh()
		pedia._show(enchantments[0])
		for frame in 5:
			await process_frame
		check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.game_menu.stage.panel.get_global_rect()), "enchantment overview escaped viewport %s" % extent)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/dentipedia-enchantments-%dx%d.png" % [extent.x, extent.y])
		pedia._show(enchantment_entries["holy"])
		for frame in 5:
			await process_frame
		check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.game_menu.stage.panel.get_global_rect()), "individual enchantment escaped viewport %s" % extent)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/dentipedia-holy-%dx%d.png" % [extent.x, extent.y])
		# Former names remain searchable, and a form preview must never enchant the build.
		pedia.select_category(0)
		pedia.search.text = "Garotte"
		pedia._refresh()
		check(pedia.listing.get_child_count() == 1, "former Garotte name is not searchable")
		var form_rows := pedia.detail.find_children("*", "HFlowContainer", false, false)
		check(form_rows.size() == 1 and form_rows[0].get_child_count() == 7, "weapon is missing normal or elemental previews")
		var art: TextureRect = pedia.detail.get_child(0).get_child(0)
		var template := WeaponCatalog.by_id(&"floss_garrote")
		var original_art := template.sprite
		for button: Button in form_rows[0].get_children():
			button.button_pressed = true
			button.pressed.emit()
			var kind := str(button.get_meta("element"))
			var texture := art.texture as AtlasTexture
			check(texture != null and texture.atlas.resource_path.ends_with("/%s.png" % ("normal" if kind.is_empty() else kind)), "form button displays another element")
			check(button.button_group.get_pressed_button() == button, "form preview selection is ambiguous")
		check(template.sprite == original_art and template.element_skin == &"", "encyclopedia preview changed the weapon catalog")
		for frame in 5: await process_frame
		check(form_rows[0].size.x <= pedia.detail_scroll.size.x + 1, "form choices overflow horizontally at %s" % extent)
		pedia.detail_scroll.scroll_vertical = 500
		for frame in 2: await process_frame
		pedia.select_category(4)
		pedia.search.text = "Wurzelsprung"
		pedia._refresh()
		check(pedia.selected.get("title") == "Wurzelsprung & Ausdauer", "new dash topic cannot be found")
		for frame in 3: await process_frame
		check(pedia.detail_scroll.scroll_vertical == 0, "opening another topic retains the previous scroll offset")
		pedia.search.text = ""
		pedia.select_category(1)
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
		pedia.select_category(0)
		pedia._refresh()
	game.game_menu._show_home()
	check(paused, "reading encyclopedia resumed combat")
	session.clear_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	paused = false
	var main_menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(main_menu)
	var main_button: Button = main_menu.actions.get(&"dentipedia")
	var main_entry := main_button != null
	if main_entry:
		main_button.pressed.emit()
	check(main_entry and main_menu.page == &"dentipedia", "main menu Dentipedia entry missing")
	if failures.is_empty():
		print("Denti Dentipedia test passed")
	finish(0 if failures.is_empty() else 1)
