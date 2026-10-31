extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in 12: await process_frame

func _joy(button: JoyButton) -> void:
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 3
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	await _settle()

func _trigger(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 3
	event.axis = JOY_AXIS_TRIGGER_RIGHT
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await _settle()

func _key(key: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	await _settle()

func _range(panel: WeaponEnchantmentPanel) -> void:
	for button in panel.effect_buttons:
		if button.get_meta("effect_id") == &"range":
			button.grab_focus()
			await _joy(JOY_BUTTON_A)
			return
	_check(false, "range choice missing")

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://controller_enchantments.json"
	session.settings_path = "user://controller_enchantments.cfg"
	session.clear_run()
	session.resume_requested = false
	session.reduced_ui_motion = true
	var input := root.get_node("GameInput")
	input.device_info_provider = func(_device: int) -> Dictionary: return {"name": "Xbox Controller", "mapped": true}
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	AudioServer.set_bus_mute(0, true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.set_process(false)
	game.wave.set_process(false)
	game.wave.active = false
	game.wave.current_wave = 24
	game.coins = 4958
	game.player.loadout.restore([
		{"id": "floss_garrote", "tier": 4, "affixes": [{"id": "ice", "level": 10, "damage": 1}, {"id": "leech", "level": 10, "damage": 1}, {"id": "tempo", "level": 10, "damage": 1}, {"id": "impact", "level": 10, "damage": 1}]},
		{"id": "floss_garrote", "tier": 4, "affixes": [{"id": "poison", "level": 10, "damage": 1}, {"id": "tempo", "level": 10, "damage": 1}, {"id": "leech", "level": 10, "damage": 1}]},
		{"id": "mouthwash_mortar", "tier": 4}])
	var target: WeaponInstance = game.player.loadout.equipped()[1]
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	state.points = 8
	game._open_shop()
	input.use_controller(3)
	await _settle()
	await _joy(JOY_BUTTON_LEFT_SHOULDER)
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	_check(panel.visible, "shop enchant shortcut did not open the editor")
	_check(not panel.stage.footer.visible and not panel.finish_button.visible, "controller editor leaves duplicate footer buttons")
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	_check(panel.selected_weapon == 1 and panel.weapon_buttons[1].has_focus(), "next weapon shortcut loses selection/focus")
	await _joy(JOY_BUTTON_LEFT_SHOULDER)
	_check(panel.selected_weapon == 0, "previous weapon shortcut failed")
	await _joy(JOY_BUTTON_LEFT_SHOULDER)
	_check(panel.selected_weapon == 2, "previous weapon shortcut does not wrap")
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	_check(panel.selected_weapon == 1, "weapon shortcuts selected the wrong duplicate")
	panel.weapon_buttons[0].grab_focus()
	panel.show_upgrades(state, game.player.loadout, game.player.stats, game.items, null, game.coins, game.wave.current_wave)
	await _settle()
	_check(panel.selected_weapon == 1 and panel.weapon_buttons[1].has_focus(), "reopening the persisted cursor focuses another weapon")
	panel.upgrade_buttons[3].grab_focus()
	await _joy(JOY_BUTTON_A)
	await _joy(JOY_BUTTON_X)
	_check(panel.visible and panel.picking_slot == 3 and state.actions.is_empty(), "confirm without an effect spends points or exits")
	await _range(panel)
	_check(not panel.finish_button.disabled, "selected range effect has no available primary action")
	await _joy(JOY_BUTTON_X)
	_check(state.actions.size() == 1 and state.remaining() == 6 and str(state.actions[0].uid) == target.instance_uid, "confirm shortcut did not enchant the selected duplicate")
	_check(panel.picking_slot < 0 and panel.upgrade_buttons[3].has_focus(), "enchanting lost the newly created slot's focus: %s" % str(root.gui_get_focus_owner().get_meta("controller_focus_key", "untagged") if root.gui_get_focus_owner() != null else "none"))
	_check(target.affixes.size() == 3, "preview mutated combat equipment before finishing: %s" % [target.affixes])
	var draft := state.save_data()
	await _joy(JOY_BUTTON_B)
	_check(panel.visible and not game.shop_panel.visible and state.save_data() == draft and target.affixes.size() == 3 and game.coins == 4958, "B/Circle confirmed or changed a pending enchantment draft")
	await _joy(JOY_BUTTON_Y)
	_check(state.actions.is_empty() and state.remaining() == 8 and panel.weapon_buttons[1].has_focus(), "undo shortcut lost the draft budget or selected weapon")
	panel.open_picker(3)
	await _settle()
	await _range(panel)
	# Keyboard users retain both footer actions and their focus paths.
	input._set_mode(false, true)
	await _settle()
	_check(panel.stage.footer.visible and panel.finish_button.visible, "keyboard input did not restore the editor footer")
	var last: Button
	for button in panel.effect_buttons:
		if ControllerFocus.available(button): last = button
	last.grab_focus()
	await _key(KEY_DOWN)
	_check(panel.finish_button.has_focus(), "effect grid cannot reach the primary action")
	panel.weapon_buttons.back().grab_focus()
	await _key(KEY_DOWN)
	_check(panel.finish_button.has_focus(), "weapon rail cannot reach the primary action")
	await _key(KEY_ENTER)
	_check(state.actions.size() == 1, "focused Enter did not confirm the enchantment")
	panel.back_button.grab_focus()
	await _key(KEY_ENTER)
	_check(state.actions.is_empty() and panel.weapon_buttons[1].has_focus(), "footer undo loses focus during queued refreshes")
	panel.finish_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(panel.visible and state.actions.is_empty() and not panel.stage.footer.visible and ControllerFocus.available(root.gui_get_focus_owner()), "switching from the focused footer to controller executes an unintended action or loses focus")
	panel.open_picker(3)
	await _settle()
	await _range(panel)
	state.points = 1
	panel.refresh()
	await _settle()
	await _joy(JOY_BUTTON_X)
	_check(panel.visible and panel.finish_button.disabled and state.actions.is_empty(), "shortcut bypassed insufficient points")
	state.points = 8
	panel.refresh()
	await _settle()
	var selected := panel.selected_weapon
	panel.details.present("Details", "Controller modal", panel.weapon_buttons[selected])
	await _settle()
	for button in [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]: await _joy(button)
	await _trigger(0.0)
	await _trigger(0.95)
	_check(panel.details.visible and panel.selected_weapon == selected and state.actions.is_empty(), "enchant shortcuts activate behind a detail modal")
	await _joy(JOY_BUTTON_B)
	_check(not panel.details.visible and panel.visible, "modal close skipped the enchantment view")
	await _joy(JOY_BUTTON_B)
	game.coins = 0
	panel.coins = 0
	panel.refresh()
	await _settle()
	await _trigger(0.0)
	await _trigger(0.95)
	_check(state.actions.is_empty(), "ascension shortcut bypassed its gold price")
	game.coins = 4958
	panel.coins = 4958
	panel.refresh()
	await _settle()
	await _trigger(0.0)
	await _trigger(0.95)
	_check(state.actions.size() == 1 and StringName(state.actions[0].id) == WeaponAscension.ID and game.in_shop, "ascension shortcut failed or started a wave")
	await _joy(JOY_BUTTON_Y)
	_check(state.actions.is_empty() and state.gold_spent() == 0, "undo does not restore ascension gold")
	panel.open_picker(3)
	await _settle()
	await _range(panel)
	await _joy(JOY_BUTTON_X)
	await _joy(JOY_BUTTON_X)
	_check(not panel.visible and game.shop_panel.visible and target.affixes.size() == 4 and WeaponAffixes.find(target.affixes, &"range") >= 0, "finish shortcut did not commit the enchantment and return to the shop: panel=%s, shop=%s, affixes=%s" % [panel.visible, game.shop_panel.visible, target.affixes])
	session.clear_run()
	print("Controller enchantment actions, duplicate targets, keyboard footer, input switching, blocked costs, modals, ascension, undo and commit checked")
	finish(0 if failures.is_empty() else 1)
