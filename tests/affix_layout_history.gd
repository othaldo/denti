extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_affix_layout_history.json"
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 4, "affix_slots": 4, "affixes": [{"id": "poison", "rarity": 4, "rank": 1, "damage": 39.8}, {"id": "range", "rarity": 2, "rank": 3, "damage": 12.5, "progress": 0.5}, {"id": "tempo", "rarity": 4, "rank": 3, "damage": 36, "progress": 0.5}, {"id": "bleed", "rarity": 4, "rank": 3, "damage": 66.8, "progress": 0.5}]},
		{"id": "uv_lamp", "tier": 4, "affix_slots": 1, "affixes": [{"id": "range", "rarity": 4, "rank": 2, "damage": 30}]},
		{"id": "mouthwash_mortar", "tier": 4, "affixes": [{"id": "bleed", "rarity": 4, "damage": 25}]},
		{"id": "turbo_drill", "tier": 4, "affixes": [{"id": "electric", "rarity": 3, "damage": 14}]}
	])
	var panel: WeaponChestPanel = game.weapon_chest_panel
	var reward := {"options": [{"id": "poison", "rarity": 4, "damage": 25}, {"id": "range", "rarity": 2, "damage": 7}, {"id": "ice", "rarity": 2, "damage": 7}], "replace": -1}
	for extent in [Vector2i(1280, 720), Vector2i(360, 640), Vector2i(568, 320), Vector2i(320, 568), Vector2i(844, 390), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		for offer_set in [reward, {"options": [{"id": "wet", "rarity": 2, "damage": 7}, {"id": "holy", "rarity": 4, "damage": 25}, {"id": "leech", "rarity": 3, "damage": 14}], "replace": -1}]:
			panel.show_chest(offer_set, game.player.loadout, game.player.stats, 7, game.items)
			for target in [0, 1]:
				panel._select_weapon(target)
				for frame in 8:
					await process_frame
				for selector in panel.weapon_buttons:
					for label: Label in selector.get_meta("labels"):
						if not selector.get_global_rect().grow(0.5).encloses(label.get_global_rect()):
							push_error("Enchanted weapon name escapes selector at %s: %s" % [extent, label.text])
							finish(1)
							return
						for line in label.text.split("\n"):
							if label.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x > label.size.x + 1:
								push_error("Enchanted weapon name is clipped at %s: %s" % [extent, label.text])
								finish(1)
								return
				for card in panel.buttons:
					for control in [card.icon_rect, card.name_label, card.keep_label, card.rarity_label, card.effect_label, card.progress_bar]:
						if control.visible and not card.get_global_rect().grow(0.5).encloses(control.get_global_rect()):
							push_error("Affix content escapes card at %s: %s / %s" % [extent, control.get_global_rect(), card.get_global_rect()])
							finish(1)
							return
				if "--capture" in OS.get_cmdline_user_args() and target == 0:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://.godot/%s_%dx%d.png" % ["affix_full" if offer_set == reward else "affix_utility", extent.x, extent.y])
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
						finish(1)
						return
	session.clear_run()
	print("PASS affix layout is independent of weapon selection history")
	finish(0)

func _snapshot(panel: WeaponChestPanel) -> Array:
	var result: Array = []
	for card in panel.buttons:
		result.append(card.size.round())
		for control in [card.name_label, card.rarity_label, card.keep_label, card.effect_label]:
			result.append([control.text, (control.global_position - card.global_position).round(), control.size.round()])
	return result
