extends SceneTree

const OUTPUT := "res://.godot/reward_preview/"
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
	session.reduced_ui_motion = true
	session.selected_story_mode = false
	session.resume_requested = false
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	for extent in [Vector2i(1280,720),Vector2i(320,568),Vector2i(568,320),Vector2i(360,640),Vector2i(720,1280),Vector2i(1920,1080)]:
		root.content_scale_size = session.mobile_base_size(extent) if extent.x < 1000 else Vector2i(1280,720)
		DisplayServer.window_set_size(extent)
		root.size = extent
		for frame in 5: await process_frame
		var ui: ChoicePanel = load("res://scenes/ui/choice_panel.tscn").instantiate()
		root.add_child(ui)
		current_scene = ui
		var upgrades: Array[UpgradeData] = []
		for index in 4:
			var id: String = ["bisskraft","haerte","glanz","wurzelkraft"][index]
			upgrades.append(load("res://data/upgrades/" + id + ".tres").with_tier(index + 1))
		ui.show_upgrades(upgrades)
		ui.set_progress(1,5)
		ui.update_level_reroll(150,5,11)
		await _capture("levelup",extent)
		ui.stage.body_scroll.scroll_vertical = 10000
		await _capture("levelup_bottom",extent)
		ui.show_relics([RelicCatalog.CATALOG[0],RelicCatalog.CATALOG[1],RelicCatalog.CATALOG[2]])
		ui.set_progress(5,5)
		await _capture("relics",extent)
		ui.stage.body_scroll.scroll_vertical = 10000
		await _capture("relics_bottom",extent)
		ui.show_chest(ItemCatalog.by_id(&"conductive_varnish"),11)
		ui.set_progress(3,5)
		await _capture("item",extent)
		ui.free()
		await process_frame
		session.pending_start_weapon_id = &"magic_toothbrush"
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		game.wave.active = false
		game.run_flow.enter(RunFlow.Phase.REWARDS)
		paused = true
		game.choice_panel.hide()
		game.player.loadout.restore([{"id":"fluoride_sprayer","tier":2},{"id":"water_jet","tier":1},{"id":"prophylaxis_polisher","tier":1},{"id":"turbo_drill","tier":1}])
		var capsule: WeaponChestPanel = game.weapon_chest_panel
		var reward := {"kind":"affix","golden":false,"options":[{"id":"fire","rarity":1,"damage":3.0},{"id":"electric","rarity":3,"damage":14.0},{"id":"ice","rarity":4,"damage":25.0}]}
		capsule.show_chest(reward,game.player.loadout,game.player.stats,11,game.items)
		capsule.set_progress(4,5)
		await _capture("capsule",extent)
		capsule.scroll.scroll_vertical = 10000
		await _capture("capsule_bottom",extent)
		var weapon: WeaponInstance = game.player.loadout.equipped()[0]
		weapon.affixes.assign([{"id":"fire","rarity":1,"damage":3.0,"progress":0.4}])
		capsule.show_chest(reward,game.player.loadout,game.player.stats,11,game.items)
		await _capture("capsule_full",extent)
		if not capsule.replacement_buttons.is_empty(): capsule.replacement_buttons[0].pressed.emit()
		capsule.scroll.scroll_vertical = 10000
		await _capture("capsule_replace",extent)
		reward.golden = true
		capsule.show_chest(reward,game.player.loadout,game.player.stats,11,game.items)
		await _capture("capsule_golden",extent)
		game.free()
		paused = false
		session.clear_run()
		await process_frame
	quit()

func _capture(view: String, extent: Vector2i) -> void:
	if root.gui_get_focus_owner() != null: root.gui_get_focus_owner().release_focus()
	var pointer := InputEventMouseMotion.new()
	pointer.position = Vector2(2,2)
	root.push_input(pointer,true)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUTPUT + "%s_%dx%d.png" % [view,extent.x,extent.y])
	root.get_texture().get_image().save_png(path)
	print("REWARD PREVIEW: ", path)
