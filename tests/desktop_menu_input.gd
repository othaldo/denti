extends "res://tests/support/test_runtime.gd"

var failures := 0
var game: Node2D
var input: Node
var bar: ControllerActionBar

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _settle() -> void:
	for frame in 12: await process_frame

func _key(code: Key, text: int = 0, echo: bool = false, shift: bool = false, viewport: Viewport = root) -> void:
	var window_id: int = viewport.get_window_id() if viewport is Window else 0
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.unicode = text
		event.shift_pressed = shift
		event.pressed = pressed
		event.echo = echo and pressed
		event.window_id = window_id
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	await _settle()

func _click_action(action: StringName) -> void:
	var target: Button
	for button in bar.click_targets:
		if button.get_meta("menu_action") == action: target = button
	_check(target != null, "missing clickable keyboard action: " + str(action))
	if target == null: return
	var clicks := [0]
	target.pressed.connect(func() -> void: clicks[0] += 1)
	var motion := InputEventMouseMotion.new()
	motion.position = target.get_global_rect().get_center()
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = target.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await _settle()
	_check(clicks[0] == 1, "keyboard action did not receive exactly one mouse click: %s clicks=%s rect=%s" % [action, clicks[0], target.get_global_rect() if is_instance_valid(target) else Rect2()])

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://desktop_menu_run.json"
	session.settings_path = "user://desktop_menu_settings.cfg"
	session.selected_story_mode = false
	session.resume_requested = false
	session.reduced_ui_motion = true
	session.set_controller_symbols(0)
	session.clear_run()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	input = root.get_node("GameInput")
	bar = input.action_bar
	for entry in [[&"ui_accept", "Enter"], [&"ui_cancel", "Esc"], [&"ui_reroll", "R"], [&"ui_confirm", "F"], [&"ui_details", "I"], [&"ui_pin", "P"], [&"ui_undo", "Backspace"], [&"ui_previous", "Q"], [&"ui_next", "E"]]:
		_check(DesktopMenuInput.key_label(entry[0]) == entry[1], "keyboard label differs from its actual binding: " + str(entry[0]))
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.coins = 10000
	game._open_shop()
	await _key(KEY_RIGHT)
	game.shop_panel.offer_buttons[0].grab_focus()
	await _settle()
	_check(bar.visible and not input.using_controller and bar.click_targets.size() == bar.entries.size(), "desktop menu lacks clickable keyboard hints")
	var coins: int = game.coins
	var cost: int = game.shop.reroll_cost
	await _key(KEY_R)
	_check(game.coins == coins - cost, "R did not reroll exactly once")
	coins = game.coins
	await _key(KEY_R, 0, true)
	_check(game.coins == coins, "held R rerolled the next offers")
	game.shop_panel.offer_buttons[0].grab_focus()
	await _key(KEY_P)
	_check(game.shop.reserved[0], "P did not pin the focused offer")
	var focus := root.gui_get_focus_owner()
	await _click_action(&"ui_pin")
	_check(not game.shop.reserved[0] and root.gui_get_focus_owner() == focus, "clicking the action bar stole focus or failed to unpin: pinned=%s focus=%s expected=%s" % [game.shop.reserved[0], root.gui_get_focus_owner(), focus])
	game.shop.offers[0] = ShopController.by_id(&"metal_crown")
	game._update_shop_panel()
	game.shop_panel.offer_buttons[0].grab_focus()
	var price: int = game.shop.offers[0].price
	await _key(KEY_ENTER)
	_check(game.coins == coins - price and game.shop.offers[0] == null, "Enter did not buy the marked offer")
	coins = game.coins
	await _key(KEY_ENTER, 0, true)
	_check(game.coins == coins, "held Enter purchased another offer")
	await _key(KEY_R)
	game.shop_panel.offer_buttons[0].grab_focus()
	await _settle()
	coins = game.coins
	price = game.shop.offers[0].price
	await _click_action(&"ui_accept")
	_check(game.coins == coins - price and game.shop.offers[0] == null, "clicking Kaufen did not buy the displayed offer")
	await _key(KEY_R)
	coins = game.coins
	game.shop_panel.offer_buttons[0].grab_focus()
	await _key(KEY_I)
	_check(game.shop_panel.expanded, "I did not inspect the focused offer")
	for code: Key in [KEY_R, KEY_F, KEY_P, KEY_Q, KEY_E]: await _key(code)
	_check(game.coins == coins and game.shop_panel.visible and game.shop_panel.expanded, "detail modal allowed a background shortcut")
	await _key(KEY_ESCAPE)
	_check(not game.shop_panel.expanded and not game.game_menu.visible, "Escape closed more than the detail view")
	await _key(KEY_Q)
	_check(game.shop_panel.controller_focus.area == ShopControllerFocus.Area.BUILD and ControllerFocus.contains(game.shop_panel.build_column, root.gui_get_focus_owner()), "Q did not select the build area")
	await _key(KEY_E)
	_check(game.shop_panel.controller_focus.area == ShopControllerFocus.Area.OFFERS, "E did not select the offers")
	focus = root.gui_get_focus_owner()
	await _key(KEY_TAB)
	_check(root.gui_get_focus_owner() != focus and ControllerFocus.contains(game.shop_panel.get_node("Root"), root.gui_get_focus_owner()), "Tab did not move within the current menu")
	await _key(KEY_TAB, 0, false, true)
	_check(root.gui_get_focus_owner() == focus, "Shift+Tab did not return to the preceding control")
	await _test_modes_and_layout()
	await _test_enchantments()
	await _test_native_popup()
	await _test_text_entry()
	await _click_action(&"ui_confirm")
	_check(game.run_flow.phase == RunFlow.Phase.COMBAT and not bar.visible, "clicking Welle starten did not enter combat and hide the menu bar")
	game.free()
	paused = false
	session.clear_run()
	if failures == 0: print("PASS desktop menu input: real keys, clickable hints, modal isolation, editing, repeat guards, focus, device switching and responsive layout")
	finish(0 if failures == 0 else 1)

func _test_modes_and_layout() -> void:
	input.device_info_provider = func(_device: int) -> Dictionary: return {"name": "Xbox Controller", "mapped": true}
	input.use_controller(4)
	await _settle()
	_check(input.using_controller and bar.click_targets.is_empty(), "controller input did not replace keyboard keycaps")
	await _key(KEY_RIGHT)
	_check(not input.using_controller and not bar.click_targets.is_empty(), "keyboard did not restore keyboard keycaps")
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(320, 568), Vector2i(568, 320), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		game.shop_panel.offer_buttons[0].grab_focus()
		await _settle()
		if extent.x < 1000 or extent.y < 560:
			_check(not bar.visible and is_zero_approx(ControllerActionBar.reserve(game.shop_panel.get_node("Root"))), "mobile layout retained keyboard hints or reserved their space")
		else:
			_check(bar.visible and Rect2(Vector2.ZERO, Vector2(extent)).grow(1).encloses(bar.panel.get_global_rect()), "keyboard bar leaves the screen at " + str(extent))
			for index in bar.entries.size():
				_check(bar.panel.get_global_rect().grow(1).encloses(bar.click_targets[index].get_global_rect()), "keyboard click target is clipped")
				_check(Rect2(Vector2.ZERO, bar.strip.size).grow(1).encloses(bar.text_rects[index]), "keyboard label is clipped")
				_check(bar.glyph_rects[index].end.x < bar.text_rects[index].position.x, "keycap overlaps its action label")
		if "--capture" in OS.get_cmdline_user_args():
			DirAccess.make_dir_recursive_absolute("res://.godot/keyboard-preview")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/keyboard-preview/shop_%dx%d.png" % [extent.x, extent.y])
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2.ZERO
	touch.pressed = true
	root.push_input(touch, true)
	await _settle()
	_check(not bar.visible and is_zero_approx(ControllerActionBar.reserve(game.shop_panel.get_node("Root"))), "touch input retained the keyboard bar")
	touch.pressed = false
	root.push_input(touch, true)
	await _key(KEY_RIGHT)
	_check(bar.visible, "keyboard did not restore hints after touch input")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)

func _test_enchantments() -> void:
	game.shop_panel.hide()
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 2}, {"id": "turbo_drill", "tier": 2}])
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	state.points = 8
	_check(state.plan(game.player.loadout, game.player.loadout.equipped()[0].instance_uid, &"fire"), "cannot prepare an enchantment draft")
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	panel.show_upgrades(state, game.player.loadout, game.player.stats, game.items, null, game.coins)
	await _settle()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/keyboard-preview/enchant_1280x720.png")
	await _key(KEY_E)
	_check(panel.selected_weapon == 1, "E did not select the next weapon")
	await _key(KEY_Q)
	_check(panel.selected_weapon == 0, "Q did not select the previous weapon")
	await _key(KEY_BACKSPACE)
	_check(state.actions.is_empty() and state.remaining() == 8, "Backspace did not undo the planned enchantment")
	panel.hide()
	game._open_shop()
	await _settle()

func _test_native_popup() -> void:
	game.shop_panel.hide()
	game.choice_panel.show_chest(ShopController.by_id(&"metal_crown"), 5)
	game.choice_panel.buttons[0].grab_focus()
	await _key(KEY_I)
	var popups := root.get_embedded_subwindows().filter(func(window: Window) -> bool: return window.visible)
	_check(popups.size() == 1, "I did not open native reward details")
	if not popups.is_empty():
		await _key(KEY_F, 0, false, false, popups[0])
		_check(popups[0].visible and game.choice_panel.visible, "native details allowed a background confirmation")
		await _key(KEY_ESCAPE, 0, false, false, popups[0])
		_check((not is_instance_valid(popups[0]) or not popups[0].visible) and game.choice_panel.visible, "Escape did not close only native details")
	game.choice_panel.hide()
	game._open_shop()
	await _settle()

func _test_text_entry() -> void:
	await _click_action(&"pause")
	_check(game.game_menu.visible, "clicking Pause did not open the pause menu")
	game.game_menu._show_dentipedia()
	await _settle()
	var encyclopedia: Dentipedia = game.game_menu.dentipedia
	encyclopedia.search.grab_focus()
	var category := encyclopedia.category_index
	var coins: int = game.coins
	for code: Key in [KEY_R, KEY_F, KEY_I, KEY_P, KEY_Q, KEY_E]: await _key(code, code + 32)
	_check(encyclopedia.search.text == "rfipqe" and encyclopedia.category_index == category and game.coins == coins, "search text triggered menu shortcuts")
	await _key(KEY_BACKSPACE)
	_check(encyclopedia.search.text == "rfipq", "Backspace did not edit the search text")
	for entry in bar.entries:
		_check(entry.action in [&"ui_cancel", &"pause"], "text field advertises an unavailable shortcut")
	game.game_menu.close_pause()
	game.shop_panel.offer_buttons[0].grab_focus()
	await _settle()
