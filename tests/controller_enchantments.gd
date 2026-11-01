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

func _confirm() -> void:
	await _trigger(0.0)
	await _trigger(0.95)
	await _trigger(0.0)

func _key(key: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	await _settle()

func _stick(axis: JoyAxis, value: float) -> void:
	for amount in [0.0, value, 0.0]:
		var event := InputEventJoypadMotion.new()
		event.device = 3
		event.axis = axis
		event.axis_value = amount
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
	game._on_shop_enchant()
	await _settle()
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	_check(panel.visible, "shop enchant shortcut did not open the editor")
	_check(not panel.stage.footer.visible and not panel.finish_button.visible, "controller editor leaves duplicate footer buttons")
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	_check(panel.selected_weapon == 1 and panel.focus_rows[0].has_focus(), "next weapon shortcut must keep focus in the action list")
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
	_check(panel.selected_weapon == 1 and panel.focus_rows[0].has_focus(), "reopening the persisted cursor focuses another weapon")
	# Layout changes and both glyph families must keep exactly one action list.
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		for family in [1, 2]:
			session.set_controller_symbols(family)
			await _settle()
			var targets := ControllerFocus.controls(panel.stage)
			_check(targets.size() == 5 and targets[0] == panel.ascension_button, "overview needs ascension followed by four complete effect rows")
			_check(panel.stage.header.get_minimum_size().x <= panel.stage.panel.size.x + 1, "persistent weapon heading overflows the header")
			panel.focus_rows[3].grab_focus()
			await _stick(JOY_AXIS_LEFT_X, -0.9)
			await _stick(JOY_AXIS_LEFT_X, 0.9)
			_check(panel.focus_rows[3].has_focus(), "horizontal stick input escaped the effect list")
			for step in 5: await _joy(JOY_BUTTON_DPAD_UP)
			_check(panel.ascension_button.has_focus(), "up must reach and stop on ascension")
			for step in 5: await _joy(JOY_BUTTON_DPAD_DOWN)
			_check(panel.focus_rows[3].has_focus(), "down must reach and stop on the last slot")
			await _joy(JOY_BUTTON_RIGHT_SHOULDER)
			_check(panel.selected_weapon == 2 and panel.focus_rows[3].has_focus(), "weapon switch lost the corresponding effect slot")
			await _joy(JOY_BUTTON_LEFT_SHOULDER)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await _settle()
	panel.focus_rows[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(state.actions.is_empty() and panel.focus_rows[0].has_focus(), "MAX row must remain focusable without spending points")
	await _joy(JOY_BUTTON_RIGHT_STICK)
	_check(panel.details.visible and panel.details.body.text.contains("Maximalstufe"), "R3 does not explain the blocked row")
	await _joy(JOY_BUTTON_B)
	_check(panel.focus_rows[0].has_focus(), "closing row details did not restore the marked row")
	panel.focus_rows[3].grab_focus()
	await _joy(JOY_BUTTON_A)
	await _confirm()
	_check(panel.visible and panel.picking_slot == 3 and state.actions.is_empty(), "confirm without an effect spends points or exits")
	await _range(panel)
	var picker_goal: String = root.gui_get_focus_owner().get_meta("controller_focus_key")
	for direction in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN]:
		for step in 4: await _joy(direction)
		_check(root.gui_get_focus_owner() in panel.effect_buttons, "direction escaped the effect picker")
	var picker_focus: Control = root.gui_get_focus_owner()
	for button in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]: await _joy(button)
	panel._ascend()
	_check(panel.picking_slot == 3 and panel.selected_weapon == 1 and picker_focus.has_focus() and state.actions.is_empty() and panel.ascension_button == null, "picker permits weapon changes or ascension")
	for effect in panel.effect_buttons:
		if str(effect.get_meta("controller_focus_key")) == picker_goal: effect.grab_focus()
	_check(not panel.finish_button.disabled, "selected range effect has no available primary action")
	await _confirm()
	_check(state.actions.size() == 1 and state.remaining() == 6 and str(state.actions[0].uid) == target.instance_uid, "confirm shortcut did not enchant the selected duplicate")
	_check(panel.picking_slot < 0 and panel.focus_rows[3].has_focus(), "enchanting lost the newly created slot's focus: %s" % str(root.gui_get_focus_owner().get_meta("controller_focus_key", "untagged") if root.gui_get_focus_owner() != null else "none"))
	_check(target.affixes.size() == 3, "preview mutated combat equipment before finishing: %s" % [target.affixes])
	var draft := state.save_data()
	await _joy(JOY_BUTTON_B)
	_check(panel.exit_dialog.visible and panel.visible and not game.shop_panel.visible and state.save_data() == draft and target.affixes.size() == 3 and game.coins == 4958, "B/Circle confirmed or changed a pending enchantment draft")
	await _joy(JOY_BUTTON_B)
	await _joy(JOY_BUTTON_Y)
	_check(state.actions.is_empty() and state.remaining() == 8 and panel.focus_rows[3].has_focus(), "undo shortcut lost the draft budget or affected slot")
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
	_check(state.actions.is_empty() and panel.upgrade_buttons[3].has_focus(), "footer undo loses focus during queued refreshes")
	panel.finish_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(panel.visible and state.actions.is_empty() and not panel.stage.footer.visible and ControllerFocus.available(root.gui_get_focus_owner()), "switching from the focused footer to controller executes an unintended action or loses focus")
	panel.open_picker(3)
	await _settle()
	await _range(panel)
	state.points = 1
	panel.refresh()
	await _settle()
	await _confirm()
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
	_check(state.actions.is_empty(), "blocked ascension changed the draft")
	panel.focus_rows[0].grab_focus()
	await _joy(JOY_BUTTON_DPAD_UP)
	_check(panel.ascension_button.has_focus(), "insufficient gold hides the ascension focus target")
	await _joy(JOY_BUTTON_A)
	_check(state.actions.is_empty() and panel.ascension_button.has_focus(), "focused ascension bypassed its gold price")
	await _joy(JOY_BUTTON_RIGHT_STICK)
	_check(panel.details.visible and panel.details.body.text.contains("Gold nötig"), "blocked ascension does not expose its missing gold")
	await _joy(JOY_BUTTON_B)
	game.coins = 4958
	panel.coins = 4958
	panel.refresh()
	await _settle()
	panel.ascension_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(state.actions.size() == 1 and StringName(state.actions[0].id) == WeaponAscension.ID and game.in_shop, "focused ascension failed or started a wave")
	await _joy(JOY_BUTTON_Y)
	_check(state.actions.is_empty() and state.gold_spent() == 0 and panel.ascension_button.has_focus(), "undo does not restore ascension gold and focus")
	state.points = 40
	panel.refresh()
	await _settle()
	panel.focus_rows[0].grab_focus()
	await _joy(JOY_BUTTON_DPAD_UP)
	await _joy(JOY_BUTTON_A)
	_check(WeaponAscension.level(state.preview_data(target)) == 1 and panel.ascension_button.has_focus(), "focused A did not plan Mk V and retain the ascension row")
	await _joy(JOY_BUTTON_A)
	_check(WeaponAscension.level(state.preview_data(target)) == 2 and panel.ascension_button.has_focus(), "focused A did not reach Mk VI")
	_check(WeaponAscension.level(target.data) == 0, "ascension preview modified equipment before finishing")
	await _joy(JOY_BUTTON_Y)
	await _joy(JOY_BUTTON_Y)
	state.points = 8
	panel.refresh()
	await _settle()
	panel.open_picker(3)
	await _settle()
	await _range(panel)
	await _confirm()
	await _confirm()
	_check(not panel.visible and game.shop_panel.visible and target.affixes.size() == 4 and WeaponAffixes.find(target.affixes, &"range") >= 0, "finish shortcut did not commit the enchantment and return to the shop: panel=%s, shop=%s, affixes=%s" % [panel.visible, game.shop_panel.visible, target.affixes])
	# Spending the last point and reaching MAX must not evict the focused row.
	game.player.loadout.restore([{"id": "turbo_drill", "tier": 1, "affixes": [{"id": "crit", "level": 9, "damage": 1}]}])
	state.points = 1
	game._on_shop_enchant()
	await _settle()
	panel.focus_rows[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(state.actions.size() == 1 and state.remaining() == 0 and int(panel.models[0].effects[0].level) == 10 and panel.focus_rows[0].has_focus(), "reaching MAX with the last point loses focus")
	await _joy(JOY_BUTTON_A)
	_check(state.actions.size() == 1, "MAX row remains purchasable")
	await _joy(JOY_BUTTON_Y)
	_check(state.actions.is_empty() and panel.focus_rows[0].has_focus(), "undo of MAX does not return to the affected row")
	state.points = 0
	panel.refresh()
	await _settle()
	await _joy(JOY_BUTTON_A)
	_check(state.actions.is_empty() and panel.focus_rows[0].blocked_reason.contains("Punkte nötig"), "zero points remove row focus or permit spending")
	panel.focus_rows[1].grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(panel.picking_slot < 0 and panel.focus_rows[1].has_focus() and panel.focus_rows[1].blocked_reason == "Erst ab Mk II", "locked slot cannot be inspected or permits editing")
	panel.ascension_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(state.actions.is_empty() and panel.ascension_button.has_focus(), "Mk I ascension is actionable")
	await _joy(JOY_BUTTON_RIGHT_STICK)
	root.size = Vector2i(320, 568)
	root.content_scale_size = root.size
	await _settle()
	await _confirm()
	_check(panel.details.visible and panel.visible and state.actions.is_empty(), "resize allows confirmation behind details")
	await _joy(JOY_BUTTON_B)
	_check(panel.ascension_button.has_focus(), "closing details after resize loses its row")
	await _confirm()
	game.player.loadout.restore([])
	state.points = 2
	game._on_shop_enchant()
	await _settle()
	await _confirm()
	_check(not panel.visible and game.shop_panel.visible and state.points == 2, "empty equipment traps controller navigation or loses banked points")
	session.clear_run()
	print("Controller enchantment focus groups, vertical rows, Mk V/VI, blocked details, modal/picker isolation, input switching, undo and commit checked")
	finish(0 if failures.is_empty() else 1)
