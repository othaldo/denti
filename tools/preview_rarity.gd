extends SceneTree

const OUTPUT := "res://.godot/rarity_preview/"
var session: Node

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	session = root.get_node("GameSession")
	session.save_path = OUTPUT + "run.json"
	session.settings_path = OUTPUT + "settings.cfg"
	session.progression_path = OUTPUT + "progression.cfg"
	session.report_dir = OUTPUT + "reports"
	session.settings_data = SessionSettings.new()
	session.progression_data = ProgressionStore.new()
	session.resume_requested = false
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	session.clear_run()
	AudioServer.set_bus_mute(0, true)
	for extent in [Vector2i(1280, 720), Vector2i(360, 640), Vector2i(568, 320)]:
		root.content_scale_size = session.mobile_base_size(extent) if extent.x < 700 else Vector2i(1280, 720)
		root.size = extent
		DisplayServer.window_set_size(extent)
		for frame in 5: await process_frame
		var choices: ChoicePanel = load("res://scenes/ui/choice_panel.tscn").instantiate()
		root.add_child(choices)
		current_scene = choices
		var upgrades: Array[UpgradeData] = []
		for index in 4:
			upgrades.append(load("res://data/upgrades/" + ["bisskraft", "haerte", "glanz", "wurzelkraft"][index] + ".tres").with_tier(index + 1))
		choices.show_upgrades(upgrades)
		choices.update_level_reroll(150, 5, 11)
		await _capture("levelup", extent)
		choices.show_chest(_item(5), 11)
		await _capture("mythic_item", extent)
		choices.show_relics([RelicCatalog.CATALOG[0], RelicCatalog.CATALOG[1], RelicCatalog.CATALOG[2]])
		await _capture("relics", extent)
		choices.free()
		session.pending_start_weapon_id = &"magic_toothbrush"
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		game.wave.active = false
		game.wave.current_wave = 12
		game.run_flow.enter(RunFlow.Phase.REWARDS)
		paused = true
		game.choice_panel.hide()
		game.player.loadout.restore([
			{"id": "magic_toothbrush", "tier": 4, "affix_slots": 2, "affixes": [{"id": "fire", "rarity": 2, "damage": 7}, {"id": "electric", "rarity": 3, "damage": 14}]},
			{"id": "water_jet", "tier": 1}, {"id": "turbo_drill", "tier": 2}, {"id": "fluoride_sprayer", "tier": 3}])
		var chest := {"kind": "affix", "options": [{"id": "fire", "rarity": 4, "damage": 25}, {"id": "poison", "rarity": 3, "damage": 14}, {"id": "slot", "rarity": 4}], "scrap_coins": 11}
		game.weapon_chest_panel.show_chest(chest, game.player.loadout, game.player.stats, 11, game.items)
		await _capture("capsule", extent)
		game.weapon_chest_panel.replacement_buttons[0].pressed.emit()
		game.weapon_chest_panel.scroll.scroll_vertical = 10000
		await _capture("capsule_replace", extent)
		chest.golden = true
		game.weapon_chest_panel.show_chest(chest, game.player.loadout, game.player.stats, 11, game.items)
		await _capture("capsule_golden", extent)
		game.weapon_chest_panel.hide()
		for tier in range(1, 6): game.items.acquire(_item(tier))
		game.coins = 150
		game._open_shop()
		var weapon := ShopController.weapon_offer(ShopController.by_id(&"turbo_drill"), 2)
		weapon.weapon_data = WeaponRolls.resolve(weapon.weapon_data, {"quality": 4, "damage": 1.65, "interval": 1.35, "range": 1.1, "crit": 0.09})
		game.shop.offers.assign([weapon, _item(3), _item(4), _item(5)])
		game._update_shop_panel()
		await _capture("shop", extent)
		game.shop_panel._select("offer", 3)
		await _capture("shop_details", extent)
		game.shop_panel.close_details()
		game.shop_panel.hide()
		game.game_menu.visible = true
		game.game_menu._show_items()
		await _capture("owned", extent)
		game.game_menu._show_dentipedia()
		game.game_menu.dentipedia.category.selected = 1
		game.game_menu.dentipedia._refresh()
		var item_entries := DentipediaData.entries(1, [])
		for entry in item_entries:
			if int(entry.rarity_tier) == 5:
				game.game_menu.dentipedia._show(entry)
				break
		await _capture("dentikon", extent)
		game.free()
		session.clear_run()
		paused = false
		await process_frame
	quit()

func _item(tier: int) -> ShopOfferData:
	for item in ItemCatalog.ALL:
		if item.rarity_tier == tier: return item
	return null

func _capture(view: String, extent: Vector2i) -> void:
	if root.gui_get_focus_owner() != null: root.gui_get_focus_owner().release_focus()
	var pointer := InputEventMouseMotion.new()
	pointer.position = Vector2(2, 2)
	root.push_input(pointer, true)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT + "%s_%dx%d.png" % [view, extent.x, extent.y]))
	print("RARITY: %s %s" % [view, extent])
