extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_affix_layout_history.json"
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 4, "affix_slots": 3, "affixes": [{"id": "fire", "rarity": 4, "rank": 3, "damage": 35}]},
		{"id": "uv_lamp", "tier": 4, "affix_slots": 1, "affixes": [{"id": "range", "rarity": 4, "rank": 2, "damage": 30}]}
	])
	var panel: WeaponChestPanel = game.weapon_chest_panel
	var reward := {"options": [{"id": "range", "rarity": 2, "damage": 7}, {"id": "fire", "rarity": 3, "damage": 14}, {"id": "slot", "rarity": 2, "damage": 0}], "replace": -1}
	for extent in [Vector2i(1280, 720), Vector2i(360, 640), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		panel.show_chest(reward, game.player.loadout, game.player.stats, 7)
		for target in [0, 1]:
			panel._select_weapon(target)
			for frame in 8:
				await process_frame
			var expected := _snapshot(panel)
			for repeat in 3:
				panel._select_weapon(1 - target)
				for frame in 8:
					await process_frame
				panel._select_weapon(target)
				for frame in 8:
					await process_frame
				if _snapshot(panel) != expected:
					push_error("Affix layout depends on selection history at %s, weapon %d: %s != %s" % [extent, target, _snapshot(panel), expected])
					quit(1)
					return
	session.clear_run()
	print("PASS affix layout is independent of weapon selection history")
	quit(0)

func _snapshot(panel: WeaponChestPanel) -> Array:
	var result: Array = []
	for card in panel.buttons:
		result.append(card.size.round())
		for control in [card.name_label, card.rarity_label, card.keep_label, card.effect_label]:
			result.append([control.text, (control.global_position - card.global_position).round(), control.size.round()])
	return result
