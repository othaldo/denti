extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var input: Node

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in 12: await process_frame

func _joy(button: JoyButton) -> void:
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 7
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	await _settle()

func _confirm() -> void:
	for value in [0.0, 0.95, 0.0]:
		var event := InputEventJoypadMotion.new()
		event.device = 7
		event.axis = JOY_AXIS_TRIGGER_RIGHT
		event.axis_value = value
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _settle()

func _graph(scope: Control, label: String) -> void:
	var controls := ControllerFocus.controls(scope)
	_check(not controls.is_empty(), label + ": no focus target")
	if controls.is_empty(): return
	var visited: Array[Control] = [controls[0]]
	var index := 0
	while index < visited.size():
		for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var neighbor := ControllerFocus.neighbor(scope, visited[index], side)
			if neighbor == null: continue
			_check(neighbor in controls, label + ": direction escapes the active scope")
			if neighbor in controls and neighbor not in visited: visited.append(neighbor)
		index += 1
	_check(visited.size() == controls.size(), "%s: %d/%d reachable focus targets" % [label, visited.size(), controls.size()])

func _visible_targets(scope: Control, label: String) -> void:
	for control in ControllerFocus.controls(scope):
		control.grab_focus()
		ControllerFocus.reveal(control)
		for frame in 3: await process_frame
		var safe := ControllerActionBar.content_rect(scope, Rect2(Vector2.ZERO, root.get_visible_rect().size))
		if control.size.y <= safe.size.y:
			_check(safe.grow(1).encloses(control.get_global_rect()), label + ": focused action is outside the visible screen")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://controller_views_run.json"
	session.settings_path = "user://controller_views_settings.cfg"
	session.progression_path = "user://controller_views_progression.cfg"
	session.resume_requested = false
	session.reduced_ui_motion = true
	session.clear_run()
	input = root.get_node("GameInput")
	input.device_info_provider = func(_device: int) -> Dictionary: return {"name": "Xbox Controller", "mapped": true}
	AudioServer.set_bus_mute(0, true)
	input.use_controller(7)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		for family in [1, 2]:
			session.set_controller_symbols(family)
			menu._show_home()
			await _settle()
			_graph(menu.root_control, "home")
			menu._show_options()
			await _settle()
			_graph(menu.stage, "settings")
			menu._show_achievements()
			await _settle()
			_graph(menu.stage, "masteries")
			var card: Button = menu.achievements_view.cards[2]
			card.grab_focus()
			await _joy(JOY_BUTTON_RIGHT_STICK)
			_check(menu.achievement_details.visible, "R3 does not inspect a mastery card")
			if menu.achievement_details.visible:
				await _joy(JOY_BUTTON_B)
				_check(card.has_focus(), "closing mastery details loses its source")
			menu._show_dentipedia()
			await _settle()
			_graph(menu.stage, "dentipedia")
			var row: Button = menu.dentipedia.listing.get_child(2)
			row.grab_focus()
			await _joy(JOY_BUTTON_RIGHT_STICK)
			_check(menu.dentipedia.detail_open and menu.dentipedia.selected == row.get_meta("entry"), "R3 does not inspect the focused encyclopedia entry")
			if menu.dentipedia.portrait and menu.dentipedia.detail_open:
				await _joy(JOY_BUTTON_B)
				_check(row.has_focus(), "portrait encyclopedia Back loses the selected row")
			await _joy(JOY_BUTTON_RIGHT_SHOULDER)
			_check(menu.dentipedia.category_index == 1 and ControllerFocus.contains(menu.dentipedia.listing, root.gui_get_focus_owner()), "R1/RB does not switch to the next encyclopedia tab and its entries")
			_check(root.gui_get_focus_owner().get_theme_stylebox("focus") is StyleBoxFlat, "rebuilt encyclopedia entries have no visible controller focus")
			_check(input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action == &"ui_previous") and input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action == &"ui_next"), "encyclopedia shoulder mappings are missing from the action bar")
			await _joy(JOY_BUTTON_LEFT_SHOULDER)
			_check(menu.dentipedia.category_index == 0 and str(root.gui_get_focus_owner().get_meta("entry", {}).get("title", "")) == str(menu.dentipedia.entries[2].title), "L1/LB does not restore the remembered entry")
			await _joy(JOY_BUTTON_LEFT_SHOULDER)
			_check(menu.dentipedia.category_index == 0, "left shoulder wraps unexpectedly at the first encyclopedia tab")
			for step in 6: await _joy(JOY_BUTTON_RIGHT_SHOULDER)
			_check(menu.dentipedia.category_index == 5 and not input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action == &"ui_next"), "last encyclopedia tab does not stop at its boundary")
			var category: int = menu.dentipedia.category_index
			await _confirm()
			_check(menu.dentipedia.category_index == category, "R2/RT is also mapped to encyclopedia navigation")
			menu.dentipedia.search.text = "no_matching_entry_9382"
			await _settle()
			menu.dentipedia.category_buttons[5].grab_focus()
			await _joy(JOY_BUTTON_LEFT_SHOULDER)
			_check(menu.dentipedia.category_buttons[4].has_focus() and menu.dentipedia.listing.get_child_count() == 0, "empty filtered tabs lose their controller focus")
			menu._show_options()
			await _settle()
			_check(not input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action in [&"ui_previous", &"ui_next"]), "encyclopedia tab hints leak into another menu")
	menu._new_game()
	await _settle()
	menu.setup_selector.difficulty_view.buttons[&"hell"].grab_focus()
	await _joy(JOY_BUTTON_RIGHT_STICK)
	_check(menu.setup_selector.details.heading.text == "Hell" and menu.setup_selector.current_difficulty == &"normal", "setup R3 describes the selected difficulty instead of the focused locked card")
	await _joy(JOY_BUTTON_B)
	menu.setup_selector.confirm_selection()
	_check(menu.page == &"class", "class selection is absent from controller preparation")
	menu.setup_selector.confirm_selection()
	menu.setup_selector.select_weapon(1)
	await _settle()
	var starter: Button = menu.setup_selector.weapon_view.icon_buttons[3]
	starter.grab_focus()
	await _joy(JOY_BUTTON_RIGHT_STICK)
	_check(menu.setup_selector.details.heading.text == menu.setup_selector.weapon_view.options[3].display_name and menu.setup_selector.weapon_view.selected_id == menu.setup_selector.weapon_view.options[1].id, "R3 does not describe the focused weapon without changing selection")
	await _joy(JOY_BUTTON_B)
	_check(starter.has_focus(), "setup details return to the footer instead of the inspected weapon")
	menu.queue_free()
	await _settle()
	session.pending_start_weapon_id = &"magic_toothbrush"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game.wave.set_process(false)
	game.wave.active = false
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 7, "damage": 1.0}]}, {"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 6, "damage": 1.0}]}])
	game.coins = 1000
	game._open_shop()
	var fusion: WeaponFusionPanel = game.weapon_fusion_panel
	fusion.show_plan(game.player.loadout.fusion_plan(0))
	await _settle()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		await _settle()
		_graph(fusion.stage, "fusion")
		for button in fusion.slot_buttons:
			_check(not ControllerFocus.available(button), "fusion has duplicate or empty slot focus targets")
		fusion.effect_buttons[0].grab_focus()
		await _joy(JOY_BUTTON_RIGHT_STICK)
		_check(input.navigation.popup_open(), "R3 does not describe a fusion effect")
		if input.navigation.popup_open(): await _joy(JOY_BUTTON_B)
		fusion.effect_buttons[0].grab_focus()
		await _joy(JOY_BUTTON_A)
		_check(fusion.effect_buttons[0].has_focus(), "fusion toggle/reflow loses its effect row")
	var fusion_confirmed := [false]
	fusion.confirmed.connect(func(_plan: WeaponFusionPlan) -> void: fusion_confirmed[0] = true)
	await _confirm()
	_check(fusion_confirmed[0], "RT does not complete the fusion workflow")
	fusion.hide()
	game.shop_panel.hide()
	game.weapon_enchantment_panel.show_upgrades(game.rewards.weapon_upgrades, game.player.loadout, game.player.stats, game.items)
	await _settle()
	var details: RunSetupDetails = game.weapon_enchantment_panel.details
	details.present("Prüfung", "Details hinter Pause", game.weapon_enchantment_panel.focus_rows[0])
	await _joy(JOY_BUTTON_START)
	await _joy(JOY_BUTTON_B)
	_check(not game.game_menu.visible and details.visible, "B reaches a detail modal behind pause")
	if game.game_menu.visible: game.game_menu.close_pause()
	details.hide()
	game.weapon_enchantment_panel.exit_dialog.present()
	await _joy(JOY_BUTTON_START)
	await _joy(JOY_BUTTON_B)
	_check(not game.game_menu.visible and game.weapon_enchantment_panel.exit_dialog.visible, "B reaches an exit decision behind pause")
	if game.game_menu.visible: game.game_menu.close_pause()
	game.weapon_enchantment_panel.exit_dialog.hide()
	game.weapon_enchantment_panel.hide()
	game.game_menu.open_pause()
	game.game_menu._show_stats()
	await _settle()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		await _settle()
		await _visible_targets(game.game_menu.root_control, "pause build")
	var equipped: Button = game.game_menu.rows.get_node("WeaponScroll").get_child(0).get_child(0)
	equipped.grab_focus()
	await _joy(JOY_BUTTON_RIGHT_STICK)
	await _joy(JOY_BUTTON_B)
	_check(game.game_menu.page == &"stats" and game.game_menu.item_details == null, "B skips the build page when leaving weapon details")
	_check(game.game_menu.rows.get_node("WeaponScroll").get_child(0).get_child(0).has_focus(), "returning to the build loses the inspected weapon")
	for item in ShopController.CATALOG:
		if item.weapon_data == null: game.items.acquire(item)
	game.relics.acquire(&"tidal_seal")
	game.game_menu._show_items()
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720)]:
		root.size = extent
		root.content_scale_size = extent
		await _settle()
		await _visible_targets(game.game_menu.root_control, "pause items")
	game.game_menu._return_home()
	await _settle()
	_check(game.game_menu.actions[&"build"].has_focus(), "leaving the build loses its pause-menu entry")
	game.game_menu.close_pause()
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4, "affixes": [{"id": "fire", "level": 10, "damage": 1.0}, {"id": "leech", "level": 10, "damage": 1.0}, {"id": "crit", "level": 10, "damage": 1.0}, {"id": "tempo", "level": 10, "damage": 1.0}]}])
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		for family in [1, 2]:
			session.set_controller_symbols(family)
			game.choice_panel.show_upgrades(game.UPGRADES.slice(0, 4), game.player.stats)
			game.choice_panel.update_level_reroll(100, 2)
			await _settle()
			_graph(game.choice_panel.stage, "level reward")
			_check(ControllerFocus.controls(game.choice_panel.stage).size() == 4 and not ControllerFocus.available(game.choice_panel.reroll_button), "level reward has a duplicate reroll focus target beside X")
			game.choice_panel.buttons[1].grab_focus()
			await _joy(JOY_BUTTON_RIGHT_STICK)
			_check(input.navigation.popup_open(), "R3 does not inspect a level reward")
			if input.navigation.popup_open(): await _joy(JOY_BUTTON_B)
			_check(game.choice_panel.buttons[1].has_focus(), "reward details lost the inspected choice")
			await _confirm()
			await _joy(JOY_BUTTON_B)
			_check(game.choice_panel.visible and game.choice_panel.mode == &"upgrade", "RT or B resolves a mandatory reward without a choice")
			game.choice_panel.show_chest(ShopController.by_id(&"metal_crown"), 5)
			await _settle()
			_graph(game.choice_panel.stage, "item chest")
			_check(input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action == &"ui_accept" and entry.label == "Behalten"), "item chest does not name its primary Keep action")
			game.choice_panel.show_relics(RelicCatalog.CATALOG.slice(0, 3))
			await _settle()
			_graph(game.choice_panel.stage, "relic reward")
			game.choice_panel.hide()
			game.weapon_chest_panel.show_chest(WeaponAffixes.roll_chest(3, 0, game.player.loadout), game.player.loadout, game.player.stats, 5, game.items)
			await _settle()
			_graph(game.weapon_chest_panel.stage, "legacy capsule")
			game.weapon_chest_panel.weapon_buttons[0].grab_focus()
			await _joy(JOY_BUTTON_RIGHT_STICK)
			_check(input.navigation.popup_open(), "R3 does not inspect a capsule's target weapon")
			for window in root.get_embedded_subwindows():
				if window.visible: _check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(Rect2(Vector2(window.position), Vector2(window.size))), "native weapon details overflow the viewport")
			if input.navigation.popup_open(): await _joy(JOY_BUTTON_B)
			game.weapon_chest_panel.hide()
	session.reduced_ui_motion = false
	game.story_dialogue.set_process(false)
	game.story_dialogue.show_line({"speaker": "Denti", "text": "Ein langer Satz wartet auf die Rückkehr aus der Pause."}, StoryCatalog.chapter(0), 0, 2)
	await _settle()
	_graph(game.story_dialogue.root_control, "story dialogue")
	var cursor: int = game.story_dialogue.cursor
	await _joy(JOY_BUTTON_START)
	game.story_dialogue._process(1.0)
	_check(game.story_dialogue.cursor == cursor, "dialogue reveals text behind pause")
	await _joy(JOY_BUTTON_B)
	_check(game.story_dialogue.next_button.has_focus(), "pause does not restore the dialogue action")
	game.story_dialogue.hide()
	var travel := StoryProgress.new()
	travel.travel_target = 1
	travel.revealed_chapters = 1
	travel.travel_progress = 0.2
	game.story_travel.set_process(false)
	game.story_travel.present(travel)
	await _settle()
	_graph(game.story_travel.root_control, "story travel")
	await _joy(JOY_BUTTON_START)
	game.story_travel._process(StoryTravel.DURATION)
	_check(is_equal_approx(travel.travel_progress, 0.2), "travel reaches its destination behind pause")
	await _joy(JOY_BUTTON_B)
	_check(game.story_travel.next_button.has_focus(), "pause does not restore the travel action")
	game.story_travel.hide()
	session.reduced_ui_motion = true
	game.choice_panel.show_upgrades(game.UPGRADES.slice(0, 4), game.player.stats)
	game.choice_panel.update_level_reroll(100, 2)
	input._set_mode(false, true)
	await _settle()
	game.choice_panel.reroll_button.grab_focus()
	var choices := [0]
	game.choice_panel.upgrade_chosen.connect(func(_upgrade: UpgradeData) -> void: choices[0] += 1)
	await _joy(JOY_BUTTON_A)
	_check(choices[0] == 0 and game.choice_panel.visible, "controller acquisition on desktop Reroll accidentally chooses a reward")
	game.ended = true
	game.choice_panel.show_end(false, 10)
	game.choice_panel._show_credits()
	await _settle()
	_check(not input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action in [&"ui_accept", &"pause"]), "end credits advertise duplicate Back actions or an unavailable Pause")
	await _joy(JOY_BUTTON_B)
	_check(game.choice_panel.mode == &"end", "B does not return from end-screen credits")
	session.clear_run()
	print("Controller views: reachable focus graphs, R3 inspection, modal priority, fusion workflow, reward actions and Back checked")
	finish(0 if failures.is_empty() else 1)
