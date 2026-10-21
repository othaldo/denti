extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var menu: GameMenu
var session: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in 8: await process_frame

func _menu() -> void:
	menu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _settle()

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://menu_setup_test.json"
	session.selected_story_mode = false
	session.resume_requested = false
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	await _menu()
	menu._new_game()
	menu.difficulty_buttons[&"hard"].pressed.emit()
	_check(menu.page == &"difficulty" and not session.has_run(), "difficulty click started a run")
	menu._advance_setup()
	menu.setup_selector.select_weapon(7)
	menu.setup_selector.back_button.pressed.emit()
	_check(menu.page == &"difficulty" and menu.setup.difficulty_id == &"hard", "back forgot the difficulty")
	menu._advance_setup()
	_check(menu.setup_selector.selected_id == WeaponCatalog.ALL[7].id, "forward forgot the weapon")
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		await _settle()
		var screen := Rect2(Vector2.ZERO, Vector2(extent))
		var view := menu.setup_selector
		_check(screen.encloses(view.panel.get_global_rect()) and view.panel.get_global_rect().encloses(view.back_button.get_global_rect()) and view.panel.get_global_rect().encloses(view.confirm_button.get_global_rect()), "weapon navigation overflow at %s" % extent)
		menu._setup_back()
		await _settle()
		_check(screen.encloses(view.panel.get_global_rect()), "difficulty overflow at %s: %s" % [extent, view.panel.get_global_rect()])
		for card: Button in menu.difficulty_buttons.values():
			for label_name in ["Title", "Requirement"]:
				var label: Label = card.get_node(label_name)
				_check(card.get_global_rect().grow(0.5).encloses(label.get_global_rect()), "difficulty caption overflow at %s" % extent)
		menu._advance_setup()
		await _settle()
		_check(current_scene == menu and root.get_node_or_null("Game") == null and not session.has_run(), "arena instantiated during preparation")
	# Restarting the app/menu must preserve the draft without inventing a combat save.
	menu.queue_free()
	await _settle()
	await _menu()
	menu._continue_game()
	_check(menu.page == &"weapon" and menu.setup_selector.selected_id == WeaponCatalog.ALL[7].id and menu.setup.difficulty_id == &"hard", "draft resume lost step or choices")
	menu.setup_selector.confirm_button.pressed.emit()
	menu.setup_selector.confirm_button.pressed.emit()
	await _settle()
	var game: Node2D = current_scene
	_check(game.name == "Game" and game.wave.current_wave == 1 and game.wave.active and not paused, "prepared run did not start wave one")
	_check(game.wave.difficulty_id == &"hard" and game.player.loadout.equipped().size() == 1 and game.player.loadout.equipped()[0].data.id == WeaponCatalog.ALL[7].id, "prepared loadout/difficulty wrong")
	_check(not game.choice_panel.visible and session.pending_start_weapon_id == &"", "start replayed weapon selection")
	game.coins = 73
	game._save_run()
	var existing: Dictionary = session.load_run()
	game.queue_free()
	await _settle()
	await _menu()
	menu._new_game()
	menu._show_difficulty()
	menu.difficulty_buttons[&"easy"].pressed.emit()
	menu._advance_setup()
	menu.setup_selector.select_weapon(0)
	menu._setup_back()
	menu._setup_back()
	_check(session.load_run() == existing, "preparation/cancel replaced the existing run")
	# Legacy pending selections also stay in the menu until confirmation.
	menu.queue_free()
	await _settle()
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	session.selected_story_mode = false
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.starter_selection.select_weapon(3)
	game.queue_free()
	await _settle()
	await _menu()
	menu._continue_game()
	_check(current_scene == menu and menu.page == &"weapon" and menu.setup.resume_pending and menu.setup_selector.selected_id == WeaponCatalog.ALL[3].id, "legacy selection loaded the arena")
	menu.setup_selector.select_weapon(4)
	menu._setup_back()
	menu._setup_back()
	menu.queue_free()
	await _settle()
	await _menu()
	menu._continue_game()
	_check(menu.page == &"difficulty" and menu.setup.weapon_id == WeaponCatalog.ALL[4].id, "migrated draft changes were lost")
	menu._advance_setup()
	menu.setup_selector.confirm_button.pressed.emit()
	await _settle()
	game = current_scene
	_check(game.wave.current_wave == 1 and game.wave.active and game.player.loadout.equipped().size() == 1, "legacy preparation skipped wave one or duplicated equipment")
	game.queue_free()
	await _settle()
	session.clear_run()
	await _menu()
	menu._new_story_game()
	menu._advance_setup()
	menu.setup_selector.select_weapon(1)
	menu.setup_selector.confirm_selection()
	await _settle()
	game = current_scene
	_check(game.story_dialogue.visible and not game.wave.active and game.player.loadout.equipped().size() == 1, "story start skipped intro or lost prepared weapon")
	game._save_run()
	game.queue_free()
	await _settle()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_check(game.story_dialogue.visible and game.player.loadout.equipped().size() == 1, "intro resume lost prepared weapon")
	for index in 32:
		if not game.story_dialogue.visible: break
		game._on_story_advance()
	_check(game.wave.active and game.wave.current_wave == 1 and not game.choice_panel.visible and game.player.loadout.equipped().size() == 1, "intro repeated the weapon choice or skipped wave one")
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	finish(0 if failures.is_empty() else 1)
