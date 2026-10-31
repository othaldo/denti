extends "res://tests/support/test_runtime.gd"

var failures := 0
var menu: GameMenu
var session: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _settle() -> void:
	for frame in 8: await process_frame

func _physical(control: Control) -> Rect2:
	return control.get_viewport().get_screen_transform() * control.get_global_rect()

func _click(control: Control) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = control.get_global_rect().get_center()
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await _settle()

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	session = root.get_node("GameSession")
	session.save_path = "user://mastery_ui_run.json"
	session.progression_path = "user://mastery_ui_progression.cfg"
	session.clear_run()
	session.progression_data.weapon_masteries.clear()
	for pair in [[&"magic_toothbrush", 15], [&"turbo_drill", 7], [&"floss_whip", 3], [&"water_jet", 1]]:
		session.record_weapon_mastery(pair[0], pair[1])
	menu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _settle()
	_check(menu.actions.has(&"achievements"), "dedicated achievements action missing")
	# A real resumable run and setup draft must survive browsing achievements.
	var saved_run := {"wave": 8, "player": {"stats": {}}, "level": 9}
	session.save_run(saved_run)
	var original: Dictionary = session.load_run()
	await _click(menu.actions[&"achievements"])
	_check(menu.page == &"achievements" and not menu.setup_selector.visible and menu.stage.heading.text == "Achievements", "achievement browsing entered run preparation")
	var view: AchievementsMenu = menu.achievements_view
	if view == null:
		finish(1)
		return
	_check(view.cards.size() == 18 and view.total_label.text == "10/72", "catalogue or total mastery progress wrong")
	view.filter.select(2)
	view.filter.item_selected.emit(2)
	_check(view.cards.size() == 1 and view.cards[0].data.id == &"magic_toothbrush", "completed filter includes partial mastery")
	view.filter.select(1)
	view.filter.item_selected.emit(1)
	_check(view.cards.size() == 17, "open filter hides partial progress")
	view.filter.select(0)
	view.search.text = "Garotte"
	view.search.text_changed.emit(view.search.text)
	_check(view.cards.size() == 1 and view.cards[0].data.id == &"floss_garrote", "legacy weapon alias cannot be searched")
	view.search.text = "nothing_matches"
	view.search.text_changed.emit(view.search.text)
	_check(view.cards.is_empty() and view.empty_label.visible, "empty filter gives no clear state")
	view.search.clear()
	view.search.text_changed.emit("")
	var account: Dictionary = session.progression_data.weapon_masteries.duplicate()
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(360, 640), Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		await _settle()
		_check(Rect2(Vector2.ZERO, Vector2(extent)).grow(1).encloses(menu.stage.back_button.get_global_rect()), "achievements back action off-screen")
		_check(menu.stage.body_scroll.get_h_scroll_bar().max_value <= menu.stage.body_scroll.size.x + 1, "achievement cards require horizontal scrolling")
		for card in view.cards:
			_check(card.size.x >= 240 and card.size.y >= 48, "achievement touch card too small")
			for child in [card.heading, card.progress] + card.badges + card.captions:
				_check(card.get_global_rect().grow(1).encloses(child.get_global_rect()), "card content exceeds surface at %s" % extent)
		var card := view.cards[-1]
		menu.stage.body_scroll.ensure_control_visible(card)
		await _settle()
		_check(menu.stage.body_scroll.get_global_rect().grow(1).encloses(card.get_global_rect()), "last weapon cannot be reached at %s" % extent)
		card.pressed.emit()
		await _settle()
		_check(menu.achievement_details.visible and menu.achievement_details.body.text.contains("Zahnprüfung") and menu.achievement_details.body.text.contains("Hell"), "achievement requirements inaccessible")
		_check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(menu.achievement_details.panel.get_global_rect()), "achievement details overflow")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape, true)
		await _settle()
		_check(menu.page == &"achievements" and not menu.achievement_details.visible, "Escape skipped from details to home")
	# Actual mobile project scaling, not only a small logical canvas.
	root.content_scale_size = session.mobile_base_size(Vector2i(320, 568))
	root.size = Vector2i(320, 568)
	await _settle()
	_check(_physical(view.search).size.y >= 47 and _physical(view.filter).size.y >= 47, "mobile achievement controls shrink")
	menu._return_home()
	await _settle()
	_check(menu.actions[&"achievements"].has_focus() and session.load_run() == original and session.progression_data.weapon_masteries == account, "browsing changed run, account or return focus")
	# Preparation contains only weapon selection again.
	menu._choose_new_run()
	menu._advance_setup()
	await _settle()
	var selection := menu.setup_selector.weapon_view
	_check(selection.get_node_or_null("MasteryStrip") == null and not "mastery_button" in selection, "masteries remain embedded in preparation")
	for button in menu.setup_selector.icon_buttons: _check(not button.has_node("MasteryBadge"), "achievement seal remains on starter card")
	# Standalone menu is available while paused and never resumes the run.
	menu.free()
	session.pending_start_weapon_id = &"turbo_drill"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.set_process(false)
	game.game_menu.open_pause()
	game.game_menu.actions[&"achievements"].pressed.emit()
	await _settle()
	_check(paused and game.game_menu.page == &"achievements" and game.game_menu.stage.heading.text == "Achievements", "pause achievements alter combat state")
	game.game_menu._return_home()
	_check(paused, "returning from achievements resumes combat")
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	paused = false
	print("PASS dedicated achievements: main/pause navigation, saved run preservation, totals/filters/search, seven layouts/mobile scaling, readable cards/details, Escape/focus and clean preparation")
	finish(1 if failures else 0)
