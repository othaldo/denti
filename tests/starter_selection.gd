extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in 8: await process_frame

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://starter_selection_test.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _settle()
	var view: StarterSelection = game.choice_panel.starter_selection
	_check(view.options.size() == WeaponCatalog.ALL.size() and view.options.size() == 18, "starter catalog incomplete")
	_check(view.selected_id == &"" and view.confirm_button.disabled, "new selection was implicitly confirmed")
	_check(view.icon_buttons[0].has_focus(), "initial keyboard focus missing")
	view.confirm_selection()
	_check(game.starter_pending and game.player.loadout.equipped().is_empty(), "empty confirmation started combat")
	var ids: Array[StringName] = []
	for index in view.options.size():
		var weapon := view.options[index]
		_check(weapon.id not in ids and weapon.evolution_kind == &"", "duplicate or evolution offered")
		ids.append(weapon.id)
		view.icon_buttons[index].pressed.emit()
		_check(view.selected_id == weapon.id and view.weapon_name.text.replace("\n", "").replace(" ", "") == weapon.display_name.replace(" ", ""), "preview and selected icon differ")
		_check(view.weapon_view.stat_buttons[0].value == str(roundi(weapon.damage_at_tier(1))) and view.weapon_view.roots_label.text == weapon.roots_text(), "preview lost starting damage or roots")
		_check(game.starter_pending and game.player.loadout.equipped().is_empty() and not game.wave.active, "icon click started a run")
	_check(session.load_run().get("starter_preview", "") == str(view.selected_id), "preview not persisted")
	var saved: Dictionary = session.load_run()
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		await _settle()
		var screen := Rect2(Vector2.ZERO, Vector2(extent))
		_check(screen.encloses(view.panel.get_global_rect()), "starter panel overflow at %s: %s" % [extent, view.panel.get_global_rect()])
		_check(view.panel.get_global_rect().encloses(view.confirm_button.get_global_rect()), "confirmation inaccessible at %s" % extent)
		_check(not view.catalog_scroll.get_global_rect().intersects(view.confirm_button.get_global_rect()), "catalog overlaps confirmation")
		for button in view.icon_buttons:
			_check(button.size.x >= 48 and button.size.y >= 48, "small touch target")
		view.catalog_scroll.ensure_control_visible(view.icon_buttons[-1])
		await _settle()
		_check(view.catalog_scroll.get_global_rect().encloses(view.icon_buttons[-1].get_global_rect()), "last weapon inaccessible at %s" % extent)
		_check(view.weapon_view.preview.get_global_rect().encloses(view.weapon_name.get_global_rect()), "weapon name exceeds preview at %s: %s in %s" % [extent, view.weapon_name.get_global_rect(), view.weapon_view.preview.get_global_rect()])
		_check(not view.details.visible, "details clutter the default preview")
		view.details_button.pressed.emit()
		await _settle()
		view.details.scroll.scroll_vertical = 10000
		await _settle()
		_check(screen.encloses(view.details.panel.get_global_rect()) and view.details.panel.get_global_rect().encloses(view.details.close_button.get_global_rect()), "details cannot be closed at %s" % extent)
		_check(view.details.scroll.get_global_rect().end.y + 1 >= view.details.body.get_global_rect().end.y, "details cannot be read to the end at %s" % extent)
		view.details.dismiss()
	game.queue_free()
	await _settle()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _settle()
	view = game.choice_panel.starter_selection
	_check(game.starter_pending and view.selected_id == StringName(saved.starter_preview) and game.player.loadout.equipped().is_empty(), "resume equipped an unconfirmed preview or forgot it")
	var selected := view.selected_id
	_check(view.icon_buttons[-1].has_focus(), "resume focus differs from saved preview")
	view.confirm_button.pressed.emit()
	view.confirm_button.pressed.emit()
	_check(game.wave.active and game.wave.current_wave == 1 and game.player.loadout.equipped().size() == 1, "confirmation did not start exactly one run")
	_check(game.player.loadout.equipped()[0].data.id == selected and game.player.loadout.equipped()[0].tier == 1, "wrong starting weapon or tier")
	game._on_starter_chosen(WeaponCatalog.ALL[0])
	_check(game.player.loadout.equipped().size() == 1, "late confirmation granted another weapon")
	game.queue_free()
	await _settle()
	# Old saves with no preview are still an unconfirmed choice.
	saved.erase("starter_preview")
	session.save_run(saved)
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _settle()
	_check(game.choice_panel.starter_selection.selected_id == &"" and game.choice_panel.starter_selection.confirm_button.disabled, "old save auto-selected a weapon")
	game.queue_free()
	await _settle()
	# Every catalog entry must start through the same public UI, at Mk I,
	# with no random rolls, enchantments or hidden extra equipment.
	for index in WeaponCatalog.ALL.size():
		session.clear_run()
		session.resume_requested = false
		game = load("res://scenes/game/game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		view = game.choice_panel.starter_selection
		view.icon_buttons[index].pressed.emit()
		view.confirm_button.pressed.emit()
		var equipped: Array[WeaponInstance] = game.player.loadout.equipped()
		_check(equipped.size() == 1 and equipped[0].data.id == WeaponCatalog.ALL[index].id and equipped[0].tier == 1, "catalog weapon could not start: %s" % WeaponCatalog.ALL[index].id)
		_check(equipped[0].data.rolls.is_empty() and equipped[0].data.chest_upgrades.is_empty(), "starter received rolled bonuses")
		_check(game.wave.current_wave == 1 and game.wave.active, "starter did not begin wave one")
		game.queue_free()
		await _settle()
	session.clear_run()
	finish(0 if failures.is_empty() else 1)
