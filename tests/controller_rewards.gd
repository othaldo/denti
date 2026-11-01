extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in 8: await process_frame

func _button(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 2
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func _joy(button: JoyButton) -> void:
	await _button(button, true)
	await _button(button, false)
	await _settle()

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://controller_rewards_run.json"
	session.resume_requested = false
	root.get_node("GameInput").device_info_provider = func(_device: int) -> Dictionary: return {"name": "Xbox Controller", "mapped": true}
	session.pending_start_weapon_id = &"magic_toothbrush"
	session.reduced_ui_motion = true
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game.wave.set_process(false)
	game._on_loot_collected(&"xp", 25)
	game._on_loot_collected(&"chest", 4, &"metal_crown")
	game._on_loot_collected(&"chest", 5, &"fluoride_gel")
	game.rewards.queue_affix_chest(WeaponAffixes.roll_chest(3, 0, game.player.loadout))
	_check(not paused and not game.choice_panel.visible and game.rewards.pending_levels == 3, "combat rewards interrupted controller movement")
	game.wave.active = false
	game.coins = 100
	game.rewards.begin_collection()
	game.rewards.finish_collection(false)
	game._advance_post_wave_rewards()
	await _settle()
	await _joy(JOY_BUTTON_X)
	_check(game.coins < 100 and game.rewards.pending_levels == 3, "X did not reroll only the current level choice")
	await _button(JOY_BUTTON_A, true)
	var after_press: int = game.rewards.pending_levels
	await _button(JOY_BUTTON_A, true)
	for frame in 50: await process_frame
	_check(game.rewards.pending_levels == after_press, "holding A skipped reward choices")
	await _button(JOY_BUTTON_A, false)
	await _settle()
	_check(game.rewards.pending_levels == 2, "A did not resolve exactly one earned level")
	for index in 2: await _joy(JOY_BUTTON_A)
	_check(game.choice_panel.mode == &"chest" and not game.shop_panel.visible, "level choices did not lead to the item chest")
	await _joy(JOY_BUTTON_B)
	_check(game.choice_panel.mode == &"chest" and game.rewards.pending_chests.size() == 3, "B skipped a mandatory chest decision")
	await _joy(JOY_BUTTON_A)
	_check(game.items.count(&"metal_crown") == 1 and game.rewards.pending_chests.size() == 2, "A did not keep the chest item")
	game.choice_panel.buttons[1].grab_focus()
	var coins_before: int = game.coins
	await _joy(JOY_BUTTON_A)
	_check(game.coins == coins_before + 5 and game.items.count(&"fluoride_gel") == 0, "A did not scrap the second chest")
	var capsule: WeaponChestPanel = game.weapon_chest_panel
	_check(capsule.visible and capsule.weapon_buttons[0].has_focus(), "legacy upgrade capsule has no initial controller target")
	capsule.buttons[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(not capsule.visible and game.shop_panel.visible, "capsule choice did not advance to the shop")
	game.shop_panel.controller_focus.change(-1)
	await _settle()
	var stat := game.shop_panel.stat_chips[0] as Button
	stat.grab_focus()
	await _joy(JOY_BUTTON_A)
	var popups := stat.get_children().filter(func(node: Node) -> bool: return node is PopupPanel)
	_check(not popups.is_empty() and popups[0].visible, "controller cannot inspect an attribute")
	coins_before = game.coins
	await _joy(JOY_BUTTON_X)
	_check(game.coins == coins_before, "X rerolled behind a native attribute popup")
	await _joy(JOY_BUTTON_B)
	_check(popups.is_empty() or not is_instance_valid(popups[0]) or not popups[0].visible, "B does not close an attribute popup")
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 7, "damage": 1.0}]},
		{"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 6, "damage": 1.0}]}])
	game._update_shop_panel()
	await _settle()
	game.shop_panel.controller_focus.change(-1)
	await _settle()
	game.shop_panel.inventory_row.get_child(0).get_child(0).grab_focus()
	await _joy(JOY_BUTTON_A)
	game.shop_panel.details.merge_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(game.weapon_fusion_panel.visible and game.weapon_fusion_panel.cancel_button.has_focus(), "fusion preview has no safe controller focus")
	await _joy(JOY_BUTTON_B)
	_check(not game.weapon_fusion_panel.visible and game.shop_panel.expanded, "B did not return from fusion to weapon details")
	game.shop_panel.details.merge_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	game.weapon_fusion_panel.confirm_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	_check(game.player.loadout.equipped().size() == 1 and game.player.loadout.equipped()[0].tier == 2 and not game.weapon_fusion_panel.visible, "A did not commit the fusion")
	print("Controller level/chest queue, held buttons, capsule compatibility and fusion checked")
	finish(0 if failures.is_empty() else 1)
