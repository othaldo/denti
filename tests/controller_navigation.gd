extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in 10: await process_frame

func _button(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 3
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func _joy(button: JoyButton) -> void:
	await _button(button, true)
	await _button(button, false)
	await _settle()

func _scroll(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 3
	event.axis = JOY_AXIS_RIGHT_Y
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://controller_navigation_run.json"
	session.settings_path = "user://controller_navigation_settings.cfg"
	session.progression_path = "user://controller_navigation_progression.cfg"
	session.resume_requested = false
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _settle()
	(menu.actions[&"settings"] as Button).grab_focus()
	await _joy(JOY_BUTTON_A)
	menu.settings_view.controller_option.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(menu.settings_view.controller_option.get_popup().visible, "A does not open controller preferences")
	await _joy(JOY_BUTTON_DPAD_DOWN)
	await _joy(JOY_BUTTON_A)
	_check(not menu.settings_view.controller_option.get_popup().visible and session.controller_symbols == 1, "controller cannot choose its symbol preference")
	await _joy(JOY_BUTTON_B)
	menu.home.primary_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(menu.page == &"difficulty", "A does not enter run preparation")
	await _joy(JOY_BUTTON_DPAD_RIGHT)
	_check(menu.difficulty_buttons[&"hard"].has_focus(), "D-pad does not follow difficulty layout")
	await _joy(JOY_BUTTON_A)
	_check(menu.setup.difficulty_id == &"hard" and menu.page == &"difficulty", "A advanced instead of selecting difficulty")
	menu.setup_selector.confirm_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(menu.page == &"weapon" and menu.setup_selector.selected_id == &"", "Continue auto-selected a weapon")
	menu.setup_selector.icon_buttons[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(menu.setup_selector.selected_id != &"" and not session.has_run(), "weapon selection started combat")
	await _joy(JOY_BUTTON_Y)
	_check(menu.setup_selector.details.visible, "Y does not inspect the selected weapon")
	for direction in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN]:
		await _joy(direction)
		_check(menu.setup_selector.details.close_button.has_focus(), "direction escaped the setup modal")
	await _joy(JOY_BUTTON_B)
	_check(not menu.setup_selector.details.visible and menu.page == &"weapon", "B skipped the screen behind details")
	session.set_controller_symbols(2)
	_check(menu.setup_selector.confirm_button.get_node("ControllerPrompt").texture == ControllerGlyphs.texture(&"ui_accept", "playstation"), "PlayStation override did not update an existing button")
	var before := menu.setup_selector.confirm_button.get_global_rect()
	session.set_controller_symbols(1)
	await _settle()
	_check(menu.setup_selector.confirm_button.get_node("ControllerPrompt").texture == ControllerGlyphs.texture(&"ui_accept", "xbox"), "Xbox override did not update an existing button")
	_check(menu.setup_selector.confirm_button.get_global_rect().is_equal_approx(before), "changing symbol families moved the primary action")
	await _joy(JOY_BUTTON_B)
	await _joy(JOY_BUTTON_B)
	_check(menu.page == &"home", "B does not return through preparation")
	menu.queue_free()
	await _settle()
	session.pending_start_weapon_id = &"magic_toothbrush"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _settle()
	game.set_process(false)
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	await _joy(JOY_BUTTON_B)
	_check(not paused, "B unexpectedly pauses combat")
	await _joy(JOY_BUTTON_START)
	_check(paused and game.game_menu.visible, "Start does not pause combat")
	_check(game.game_menu.home.primary_button.get_node("ControllerPrompt").action == &"pause", "pause menu omits the Menu/Options shortcut")
	await _joy(JOY_BUTTON_START)
	_check(not paused and not game.game_menu.visible, "Start does not resume combat")
	game.player.dash.reset_wave()
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	_check(game.player.dash.active and game.player.dash.charge < game.player.dash.capacity, "RB does not dash")
	game.player.dash.finish()
	root.get_node("GameInput")._connection_changed(3, false)
	_check(paused and game.game_menu.visible, "disconnect does not pause combat")
	root.get_node("GameInput")._connection_changed(3, true)
	_check(paused, "reconnection resumed combat")
	await _joy(JOY_BUTTON_START)
	game.wave.active = false
	game.coins = 1000
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"turbo_drill"), ShopController.by_id(&"conductive_varnish"), ShopController.by_id(&"damage_1"), ShopController.by_id(&"cavity_bounty")])
	game._update_shop_panel()
	await _settle()
	var shop: ShopPanel = game.shop_panel
	_check(ControllerFocus.available(root.gui_get_focus_owner()) and ControllerFocus.contains(shop.get_node("Root"), root.gui_get_focus_owner()), "shop opens without usable focus")
	shop.offer_buttons[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(shop.expanded, "A does not inspect a shop offer")
	for step in 16:
		await _joy([JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP][step % 4])
		_check(ControllerFocus.contains(shop.detail_popup, root.gui_get_focus_owner()), "shop modal leaked focus to the background")
	var coins_before: int = game.coins
	await _joy(JOY_BUTTON_X)
	_check(game.coins == coins_before, "reroll shortcut activated behind a modal")
	shop.detail_buy_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(game.coins < coins_before and game.shop.offers[0] == null, "A does not purchase inspected equipment")
	_check(ControllerFocus.available(root.gui_get_focus_owner()), "purchase left focus on a sold/disabled button")
	var equipment_button: Control = shop.inventory_row.get_child(0).get_child(0)
	equipment_button.grab_focus()
	var id: String = equipment_button.get_meta("controller_focus_key")
	game._update_shop_panel()
	await _settle()
	_check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().get_meta("controller_focus_key", "") == id, "shop refresh lost the equipped weapon's focus")
	await _joy(JOY_BUTTON_START)
	_check(game.game_menu.visible, "Start does not pause from the shop")
	await _joy(JOY_BUTTON_B)
	_check(paused and not game.game_menu.visible and ControllerFocus.contains(shop.get_node("Root"), root.gui_get_focus_owner()), "closing pause did not restore shop focus/pause state")
	game.rewards.weapon_upgrades.points = 8
	game._update_shop_panel()
	shop.enchant_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	var enchant: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	_check(enchant.visible and not shop.visible, "A does not open enchantments")
	enchant.upgrade_buttons[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(enchant.picking_slot == 0 and root.gui_get_focus_owner() in enchant.effect_buttons, "empty slot does not focus its effects")
	_check(enchant.back_button.get_node("ControllerPrompt").action == &"ui_cancel", "picker back does not advertise the actual B/Circle action")
	root.size = Vector2i(320, 568)
	root.content_scale_size = root.size
	await _settle()
	enchant.effect_buttons[0].grab_focus()
	await _settle()
	var scroll_before := enchant.stage.body_scroll.scroll_vertical
	await _scroll(1.0)
	for frame in 25: await process_frame
	await _scroll(0.0)
	var scrolled := enchant.stage.body_scroll.scroll_vertical
	await _settle()
	_check(scrolled > scroll_before and enchant.stage.body_scroll.scroll_vertical == scrolled, "right stick cannot scroll details independently of focus")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await _settle()
	var effect := enchant.effect_buttons[0]
	var effect_key: String = effect.get_meta("controller_focus_key")
	effect.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(enchant.selected_effect != &"" and root.gui_get_focus_owner().get_meta("controller_focus_key", "") == effect_key, "selecting an effect lost focus during rebuild")
	await _joy(JOY_BUTTON_B)
	_check(enchant.visible and enchant.picking_slot < 0, "B exited enchantments instead of its picker")
	_check(enchant.finish_button.get_node("ControllerPrompt").action == &"ui_cancel", "enchantment overview omits the actual B/Circle finish action")
	await _joy(JOY_BUTTON_B)
	_check(not enchant.visible and shop.visible and ControllerFocus.available(root.gui_get_focus_owner()), "B did not finish enchantments and restore shop")
	root.size = Vector2i(320, 568)
	root.content_scale_size = root.size
	await _settle()
	shop.continue_button.grab_focus()
	ControllerFocus.reveal(shop.continue_button)
	_check(shop.main_scroll.follow_focus and shop.left_scroll.follow_focus and shop.details_scroll.follow_focus, "shop scroll containers do not follow navigation")
	await _joy(JOY_BUTTON_A)
	_check(not shop.visible and not paused and game.run_flow.is_combat(), "A did not start the next wave")
	print("Controller route through preparation, combat, pause, shop and enchantments checked")
	finish(0 if failures.is_empty() else 1)
