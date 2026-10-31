extends "res://tests/support/test_runtime.gd"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_upgrade_layout.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	var loadout: WeaponLoadout = game.player.loadout
	var equipment: Array[Dictionary] = []
	for index in 6:
		equipment.append({"id": "turbo_drill", "tier": 4, "affixes": [
			{"id": "fire", "damage": 1, "level": 1}, {"id": "crit", "damage": 1, "level": 2},
			{"id": "range", "damage": 1, "level": 3}, {"id": "leech", "damage": 1, "level": 10}]})
	loadout.restore(equipment)
	var state := WeaponUpgradeState.new()
	state.points = 3
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(360, 640), Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		panel.show_upgrades(state, loadout, game.player.stats, game.items)
		for target in [0, 5, 0]:
			panel.select_weapon(target)
			await _settle()
			_check_text(panel.body)
			_check(panel.weapon_buttons.size() == 6 and panel.upgrade_buttons.size() == 4, "equipment or slots disappeared")
			_check(panel.upgrade_buttons[3].disabled and panel.upgrade_buttons[3].text == "MAX", "maximum-rank state disappeared")
			_check(panel.stage.panel.get_global_rect().encloses(panel.finish_button.get_global_rect()), "completion is outside the stage")
			_check(panel.stage.body_scroll.get_h_scroll_bar().max_value <= panel.stage.body_scroll.size.x + 1, "view needs horizontal scrolling")
		# Catalogue, four Mk gates and the empty-inventory state use the same view.
		loadout.restore([{"id": "magic_toothbrush", "tier": 3}])
		panel.show_upgrades(state, loadout, game.player.stats, game.items)
		await _settle()
		panel.open_picker(0)
		await _settle()
		panel.selected_effect = &"leech"
		panel._save_cursor()
		panel._refresh()
		await _settle()
		_check_text(panel.body)
		_check(panel.effect_buttons.size() == 12, "catalogue needs six elements and six supports")
		_check(is_instance_valid(panel.selection_preview) and panel.stage.body_scroll.get_global_rect().intersects(panel.selection_preview.get_global_rect()), "selected value is outside the scroll viewport")
		panel._back()
		await _settle()
		_check(panel.upgrade_buttons[3].disabled and panel.upgrade_buttons[3].text == "Ab Mk IV", "Mk IV lock disappeared")
		_check_text(panel.body)
		loadout.restore(equipment)
	loadout.restore([])
	panel.show_upgrades(state, loadout, game.player.stats, game.items)
	await _settle()
	_check(not panel.finish_button.disabled and panel.upgrade_buttons.is_empty(), "empty equipment traps banked points")
	_check_text(panel.body)
	# Reject malformed cursor/action containers before any typed restore call.
	var saved := RunSnapshot.capture(game)
	for broken in [{"points": []}, {"cursor": []}, {"actions": {}}, {"actions": true}, {"actions": "bad"}, {"actions": [[]]}, {"economy_version": []}, {"actions": [{"cost": []}]}]:
		var invalid := saved.duplicate(true)
		invalid.rewards["weapon_upgrades"] = broken
		_check(RunSaveData.normalize(invalid).is_empty(), "malformed weapon draft entered the restore path")
	session.clear_run()
	paused = false
	print("PASS weapon upgrade layout: seven extents, six copies, four filled slots, Mk locks, catalogue, text/glyph bounds and empty equipment")
	finish(1 if failures > 0 else 0)


func _check_text(parent: Control) -> void:
	for child in parent.get_children():
		if child is Label:
			_check(Rect2(Vector2.ZERO, parent.size).grow(1).encloses(child.get_rect()), "text escapes its surface: " + child.text)
			for index in child.text.length():
				var code: int = child.text.unicode_at(index)
				if code > 32: _check(DentiUIStyle.FONT.has_char(code), "bundled font misses U+%04X in %s" % [code, child.text])
		if child is Control: _check_text(child)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _settle() -> void:
	for frame in 8: await process_frame
