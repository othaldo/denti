extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 12:
		await process_frame


func _physical_rect(control: Control) -> Rect2:
	return root.get_screen_transform() * control.get_global_rect()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _touch_target(control: Control, name: String) -> void:
	var bounds := _physical_rect(control)
	_check(bounds.size.x >= 47.9 and bounds.size.y >= 47.9,
		"reward project stretch shrank %s below a 48 px touch target: %s" % [name, bounds.size])


func _check_stage(stage: RewardStage, extent: Vector2i) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(extent)).grow(0.5)
	_check(screen.encloses(_physical_rect(stage.panel)), "reward stage escapes the physical screen at %s" % extent)
	_check(not stage.body_scroll.get_h_scroll_bar().visible, "reward content needs horizontal scrolling at %s" % extent)
	_check(stage.title_label.is_visible_in_tree(), "reward title disappeared at %s" % extent)
	_check(screen.encloses(_physical_rect(stage.title_label)), "reward title leaves the physical screen at %s" % extent)


func _check_choices(stage: RewardStage, cards: Array[UpgradeCard], extent: Vector2i) -> void:
	var rectangles: Array[Rect2] = []
	for card in cards:
		if not card.is_visible_in_tree():
			continue
		_touch_target(card, "reward card")
		var rect := _physical_rect(card)
		var content_rect := Rect2(card.position, card.size)
		for previous in rectangles:
			_check(not content_rect.intersects(previous), "reward choices overlap at %s" % extent)
		rectangles.append(content_rect)
		for control in [card.icon_rect, card.name_label, card.rarity_label, card.effect_label, card.keep_label, card.progress_bar]:
			if control.is_visible_in_tree():
				_check(rect.grow(0.5).encloses(_physical_rect(control)), "reward content leaves its card at %s" % extent)
		stage.body_scroll.ensure_control_visible(card)
		await _settle()
		var scroll_bounds := _physical_rect(stage.body_scroll)
		if rect.size.y <= scroll_bounds.size.y:
			_check(scroll_bounds.grow(1.0).encloses(_physical_rect(card)), "reward choice cannot be reached by scrolling at %s" % extent)
		else:
			# Short landscape can show only part of a tall description at once.
			# Its final decision text must still be reachable through one scroll.
			var last: Control = card.keep_label if card.keep_label.is_visible_in_tree() else card.effect_label
			stage.body_scroll.ensure_control_visible(last)
			await _settle()
			_check(scroll_bounds.grow(1.0).encloses(_physical_rect(last)), "the last reward line is unreachable at %s" % extent)
	stage.body_scroll.scroll_vertical = 0
	await _settle()


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://reward_stage_run.json"
	session.settings_path = "user://reward_stage_settings.cfg"
	session.progression_path = "user://reward_stage_progression.cfg"
	session.selected_story_mode = false
	session.resume_requested = false
	session.reduced_ui_motion = true
	session.pending_start_weapon_id = &"magic_toothbrush"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _settle()
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	var panel: ChoicePanel = game.choice_panel
	var capsule: WeaponChestPanel = game.weapon_chest_panel
	var upgrades: Array[UpgradeData] = [
		load("res://data/upgrades/bisskraft.tres").with_tier(1),
		load("res://data/upgrades/haerte.tres").with_tier(2),
		load("res://data/upgrades/glanz.tres").with_tier(3),
		load("res://data/upgrades/fernschaden.tres").with_tier(4),
	]
	var relics: Array[RelicData] = [RelicCatalog.CATALOG[0], RelicCatalog.CATALOG[1], RelicCatalog.CATALOG[2]]
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 4, "affix_slots": 2, "affixes": [{"id": "fire", "rarity": 3, "damage": 14}, {"id": "ice", "rarity": 2, "damage": 7}]},
		{"id": "uv_lamp", "tier": 3}, {"id": "turbo_drill", "tier": 2}, {"id": "prophylaxis_polisher", "tier": 1},
	])
	var chest := {"kind": "affix", "options": [{"id": "fire", "rarity": 2, "damage": 7}, {"id": "poison", "rarity": 3, "damage": 14}, {"id": "slot", "rarity": 4}], "scrap_coins": 7}
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(360, 640), Vector2i(720, 1280), Vector2i(1920, 1080)]:
		# Use the real gameplay base, not a logical viewport equal to the phone.
		root.content_scale_size = session.mobile_base_size(extent) if extent.x < 700 else Vector2i(1280, 720)
		root.size = extent
		capsule.hide()
		panel.show_upgrades(upgrades)
		panel.update_level_reroll(100, 5, 12)
		await _settle()
		_check_stage(panel.stage, extent)
		_check(panel.dialog_panel == panel.stage.panel, "modern reward dialog ref points at the hidden legacy dialog")
		_check(not panel.subtitle_label.is_visible_in_tree() or panel.subtitle_label.text.is_empty(), "level choices regained a recurring instruction sentence")
		_touch_target(panel.reroll_button, "level reroll")
		_check(Rect2(Vector2.ZERO, Vector2(extent)).grow(0.5).encloses(_physical_rect(panel.reroll_button)), "level reroll is not fixed on screen")
		await _check_choices(panel.stage, panel.buttons, extent)
		if extent.x == 1280:
			for card in panel.buttons:
				_check(is_equal_approx(card.icon_rect.get_global_rect().get_center().y, panel.buttons[0].icon_rect.get_global_rect().get_center().y), "desktop stat art has inconsistent vertical alignment")
				_check(is_equal_approx(card.effect_label.get_global_rect().position.y, panel.buttons[0].effect_label.get_global_rect().position.y), "desktop stat values do not share a comparison row")
		_check(Rect2(Vector2.ZERO, Vector2(extent)).grow(0.5).encloses(_physical_rect(panel.reroll_button)), "scrolling choices hid the reroll action")
		panel.show_relics(relics)
		await _settle()
		_check_stage(panel.stage, extent)
		_check(not panel.level_actions.is_visible_in_tree(), "relic choices inherited the level reroll footer")
		await _check_choices(panel.stage, panel.buttons, extent)
		panel.show_chest(ShopController.by_id(&"metal_crown"), 7)
		await _settle()
		_check_stage(panel.stage, extent)
		_touch_target(panel.buttons[1], "item capsule scrap")
		_check(panel.stage.footer.is_ancestor_of(panel.buttons[1]), "item scrap no longer sits in the fixed footer")
		var reward_cards: Array[UpgradeCard] = [panel.buttons[0]]
		await _check_choices(panel.stage, reward_cards, extent)
		_check(Rect2(Vector2.ZERO, Vector2(extent)).grow(0.5).encloses(_physical_rect(panel.buttons[1])), "scrolling an item hid its scrap action")
		panel.hide()
		capsule.show_chest(chest.duplicate(true), game.player.loadout, game.player.stats, 7, game.items)
		await _settle()
		_check_stage(capsule.stage, extent)
		_touch_target(capsule.scrap_button, "weapon capsule scrap")
		_check(capsule.stage.footer.is_ancestor_of(capsule.scrap_button), "weapon scrap no longer sits in the fixed footer")
		for selector in capsule.weapon_buttons:
			_touch_target(selector, "weapon target")
		for replacement in capsule.replacement_buttons:
			_touch_target(replacement, "replacement effect")
		await _check_choices(capsule.stage, capsule.buttons, extent)
		_check(Rect2(Vector2.ZERO, Vector2(extent)).grow(0.5).encloses(_physical_rect(capsule.scrap_button)), "scrolling enchantments hid the scrap action")
	session.clear_run()
	if failures.is_empty():
		print("Denti shared reward stage, physical targets, rotation and fixed actions test passed")
	finish(0 if failures.is_empty() else 1)
