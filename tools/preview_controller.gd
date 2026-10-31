extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://.godot/controller-preview/"
var session: Node

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	session = root.get_node("GameSession")
	session.save_path = OUTPUT + "run.json"
	session.settings_path = OUTPUT + "settings.cfg"
	session.progression_path = OUTPUT + "progression.cfg"
	session.report_dir = OUTPUT + "reports"
	session.settings_data = SessionSettings.new()
	session.reduced_ui_motion = true
	session.resume_requested = false
	session.selected_story_mode = false
	AudioServer.set_bus_mute(0, true)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		for family in [1, 2]:
			session.clear_run()
			RunStore.clear(session.save_path + ".setup.json")
			session.set_controller_symbols(family)
			root.get_node("GameInput").use_controller(0)
			var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
			root.add_child(menu)
			current_scene = menu
			menu._new_game()
			menu.setup_selector.confirm_selection()
			menu.setup_selector.select_weapon(1)
			for frame in 4: await process_frame
			menu.setup_selector.confirm_button.grab_focus()
			await _capture("setup", family, extent)
			menu._show_options()
			menu.settings_view.controller_option.grab_focus()
			ControllerFocus.reveal(menu.settings_view.controller_option)
			await _capture("settings", family, extent)
			menu.settings_view.controller_option.show_popup()
			await _capture("settings_modes", family, extent)
			menu.settings_view.controller_option.get_popup().hide()
			var pointer := InputEventMouseMotion.new()
			pointer.position = menu.settings_view.controller_option.get_global_rect().get_center()
			root.push_input(pointer, true)
			menu.ui_sound_toggle.grab_focus()
			ControllerFocus.reveal(menu.ui_sound_toggle)
			await _capture("settings_focus", family, extent)
			menu.free()
			session.pending_start_weapon_id = &"magic_toothbrush"
			var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
			root.add_child(game)
			current_scene = game
			game.wave.active = false
			game.wave.set_process(false)
			game.set_process(false)
			game.coins = 100
			game.game_menu.open_pause()
			await _capture("pause", family, extent)
			game.game_menu.actions[&"dentipedia"].grab_focus()
			await _capture("pause_dentipedia", family, extent)
			game.game_menu.close_pause()
			game._open_shop()
			game.shop.offers.assign([ShopController.by_id(&"turbo_drill"), ShopController.by_id(&"conductive_varnish"), ShopController.by_id(&"damage_1"), ShopController.by_id(&"cavity_bounty")])
			game.rewards.weapon_upgrades.points = 8
			game._update_shop_panel()
			game.shop_panel.offer_buttons[0].grab_focus()
			await _capture("shop", family, extent)
			game.shop_panel._select("offer", 0)
			game.shop_panel.detail_buy_button.grab_focus()
			await _capture("details", family, extent)
			game.shop_panel.close_details()
			game.rewards.weapon_upgrades.points = 8
			var original_equipment: Array = game.player.loadout.save_data()
			game.player.loadout.restore([
				{"id": "floss_garrote", "tier": 4, "affixes": [{"id": "ice", "level": 10, "damage": 1}, {"id": "leech", "level": 10, "damage": 1}, {"id": "tempo", "level": 10, "damage": 1}, {"id": "impact", "level": 10, "damage": 1}]},
				{"id": "floss_garrote", "tier": 4, "affixes": [{"id": "poison", "level": 10, "damage": 1}, {"id": "tempo", "level": 10, "damage": 1}, {"id": "leech", "level": 10, "damage": 1}]},
				{"id": "mouthwash_mortar", "tier": 4}])
			game._on_shop_enchant()
			for frame in 8: await process_frame
			game.weapon_enchantment_panel.select_weapon(1)
			for frame in 8: await process_frame
			game.weapon_enchantment_panel.open_picker(3)
			for frame in 8: await process_frame
			for button in game.weapon_enchantment_panel.effect_buttons:
				if button.get_meta("effect_id") == &"range":
					button.pressed.emit()
					break
			for frame in 8: await process_frame
			if extent.x >= 720:
				game.weapon_enchantment_panel.weapon_buttons[0].grab_focus()
			else:
				for button in game.weapon_enchantment_panel.effect_buttons:
					if button.get_meta("effect_id") == &"range":
						button.grab_focus()
						break
			await _capture("enchant", family, extent)
			game.weapon_enchantment_panel._confirm()
			for frame in 8: await process_frame
			game.weapon_enchantment_panel.upgrade(3)
			await _capture("enchant_overview", family, extent)
			game.weapon_enchantment_panel.hide()
			game.rewards.weapon_upgrades.actions.clear()
			game.rewards.weapon_upgrades.cursor.clear()
			game.player.loadout.restore(original_equipment)
			game.shop_panel.hide()
			game.rewards.pending_levels = 1
			game.rewards.step = PostWaveRewards.Step.LEVELS
			game._advance_post_wave_rewards()
			await _capture("levelup", family, extent)
			game.choice_panel.show_chest(ShopController.by_id(&"metal_crown"), 5)
			await _capture("chest", family, extent)
			game.choice_panel.hide()
			game.player.loadout.restore([
				{"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 7, "damage": 1.0}]},
				{"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 6, "damage": 1.0}]}])
			game.weapon_fusion_panel.show_plan(game.player.loadout.fusion_plan(0))
			for frame in 4: await process_frame
			game.weapon_fusion_panel.effect_buttons[0].grab_focus()
			await _capture("fusion", family, extent)
			game.weapon_fusion_panel.hide()
			paused = false
			game.run_flow.enter(RunFlow.Phase.COMBAT)
			game.wave.active = true
			game._refresh_hud()
			await _capture("hud", family, extent)
			game.free()
			await process_frame
	print("Controller previews: ", ProjectSettings.globalize_path(OUTPUT))
	finish()

func _capture(view: String, family: int, extent: Vector2i) -> void:
	root.get_node("GameInput").use_controller(0)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	var filename := "%s_%s_%dx%d.png" % [view, "ps" if family == 2 else "xbox", extent.x, extent.y]
	root.get_texture().get_image().save_png(OUTPUT + filename)
