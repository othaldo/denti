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
		{"id": "magic_toothbrush", "tier": 4, "affix_slots": 4, "affixes": [{"id": "poison", "rarity": 4, "rank": 1, "damage": 39.8}, {"id": "range", "rarity": 2, "rank": 3, "damage": 12.5, "progress": 0.5}, {"id": "tempo", "rarity": 4, "rank": 3, "damage": 36, "progress": 0.5}, {"id": "bleed", "rarity": 4, "rank": 3, "damage": 66.8, "progress": 0.5}]},
		{"id": "uv_lamp", "tier": 4, "affix_slots": 1, "affixes": [{"id": "range", "rarity": 4, "rank": 2, "damage": 30}]}
	])
	var panel: WeaponChestPanel = game.weapon_chest_panel
	var reward := {"options": [{"id": "poison", "rarity": 4, "damage": 25}, {"id": "range", "rarity": 2, "damage": 7}, {"id": "ice", "rarity": 2, "damage": 7}], "replace": -1}
	for extent in [Vector2i(1280, 720), Vector2i(360, 640), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		panel.show_chest(reward, game.player.loadout, game.player.stats, 7)
		for target in [0, 1]:
			panel._select_weapon(target)
			for frame in 8:
				await process_frame
			for card in panel.buttons:
				for control in [card.icon_rect, card.name_label, card.keep_label, card.rarity_label, card.effect_label, card.progress_bar]:
					if control.visible and not card.get_global_rect().grow(0.5).encloses(control.get_global_rect()):
						push_error("Affix content escapes card at %s: %s / %s" % [extent, control.get_global_rect(), card.get_global_rect()])
						quit(1)
						return
			if "--capture" in OS.get_cmdline_user_args() and target == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.godot/affix_full_%dx%d.png" % [extent.x, extent.y])
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
