extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	_run.call_deferred()

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

func _axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 3
	event.axis = JOY_AXIS_TRIGGER_RIGHT
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await _settle()

func _confirm() -> void:
	await _axis(0.0)
	await _axis(0.95)
	await _axis(0.0)

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://controller_schema_run.json"
	session.settings_path = "user://controller_schema_settings.cfg"
	session.resume_requested = false
	session.reduced_ui_motion = true
	session.clear_run()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	AudioServer.set_bus_mute(0, true)
	var input := root.get_node("GameInput")
	input.device_info_provider = func(_device: int) -> Dictionary: return {"name": "Xbox Controller", "mapped": true}
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.set_process(false)
	game.wave.set_process(false)
	game.wave.active = false
	game.coins = 1000
	game.player.loadout.restore([{"id": "floss_garrote", "tier": 4}, {"id": "turbo_drill", "tier": 1}])
	game.items.acquire(ShopController.by_id(&"gold_probe"))
	var target: WeaponInstance = game.player.loadout.equipped()[0]
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	state.points = 20
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"damage_1"), ShopController.by_id(&"metal_crown"), ShopController.by_id(&"fluoride_gel"), ShopController.by_id(&"conductive_varnish")])
	game._update_shop_panel()
	input.use_controller(3)
	await _settle()
	var shop: ShopPanel = game.shop_panel
	var scope: Control = shop.get_node("Root")
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		for family in [1, 2]:
			session.set_controller_symbols(family)
			await _settle()
			check(ControllerFocus.controls(scope).size() == 4, "offers include statistics or nested actions in their focus group")
			shop.offer_buttons[2].grab_focus()
			for direction in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
				for step in 4: await _joy(direction)
				check(root.gui_get_focus_owner() is OfferCard, "direction escaped the offer group")
			shop.offer_buttons[2].grab_focus()
			await _joy(JOY_BUTTON_LEFT_SHOULDER)
			check(shop.controller_focus.area == ShopControllerFocus.Area.BUILD and ControllerFocus.controls(scope).size() == 15, "build focus does not include the visible weapons, stats and collected item")
			check(shop.left_scroll.visible and shop.offer_scroll.visible and shop.stat_grid.visible and shop.inventory_scroll.visible, "focus switching hides comparison information")
			var stat := shop.stat_chips[-1]
			stat.grab_focus()
			await _joy(JOY_BUTTON_DPAD_DOWN)
			check(root.gui_get_focus_owner() == shop.items_row.get_child(0), "Down skips collected items in the shop build")
			await _joy(JOY_BUTTON_DPAD_UP)
			check(stat.has_focus(), "Up from collected items loses its build focus")
			await _joy(JOY_BUTTON_RIGHT_SHOULDER)
			check(shop.offer_buttons[2].has_focus(), "switching areas lost the remembered offer")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await _settle()
	await _joy(JOY_BUTTON_LEFT_SHOULDER)
	var equipped := shop.inventory_row.get_child(0).get_child(0) as Button
	equipped.grab_focus()
	await _settle()
	var weapon_icon := equipped.get_node("WeaponIcon") as TextureRect
	var weapon_tier := equipped.get_node("WeaponTier") as Label
	var icon_rect := weapon_icon.get_rect()
	var tier_rect := weapon_tier.get_rect()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SHIFT
	key.pressed = true
	root.push_input(key)
	await _settle()
	check(not input.controller_active and equipped.has_focus(), "controller to keyboard loses the equipped weapon")
	check(weapon_icon.get_rect().is_equal_approx(icon_rect) and weapon_tier.get_rect().is_equal_approx(tier_rect) and not equipped.has_node("WeaponName"), "equipped weapon changes presentation between keyboard and controller")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click)
	click.pressed = false
	root.push_input(click)
	await _settle()
	check(not input.navigation_active and equipped.get_theme_stylebox("focus") is StyleBoxEmpty, "switching to the mouse leaves a navigation focus outline")
	await _joy(JOY_BUTTON_DPAD_LEFT)
	check(input.controller_active and equipped.has_focus(), "controller reacquisition loses the leftmost equipped weapon")
	await _joy(JOY_BUTTON_DPAD_DOWN)
	check(shop.inventory_row.get_child(1).get_child(0).has_focus(), "Down skips the next equipped row for an aligned stat")
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	shop.offer_buttons[3].grab_focus()
	await _joy(JOY_BUTTON_A)
	check(game.shop.offers[3] == null and shop.offer_buttons[2].has_focus(), "last-column purchase jumps to the first offer")
	await _joy(JOY_BUTTON_B)
	check(not game.game_menu.visible, "B opens pause from the shop root")
	await _joy(JOY_BUTTON_START)
	check(game.game_menu.visible, "Options does not open pause from the shop")
	game.game_menu._show_options()
	await _settle()
	game.game_menu.settings_view.graphics_option.grab_focus()
	await _joy(JOY_BUTTON_A)
	check(game.game_menu.settings_view.graphics_option.get_popup().visible, "settings dropdown did not open")
	await _joy(JOY_BUTTON_START)
	check(not game.game_menu.visible and not input.navigation.popup_open(), "Options does not close the full pause while a dropdown is open")
	check(shop.offer_buttons[2].has_focus(), "pause does not restore the offer")
	await _joy(JOY_BUTTON_RIGHT_STICK)
	check(shop.expanded, "R3 does not open offer details")
	var coins: int = game.coins
	await _joy(JOY_BUTTON_START)
	check(game.game_menu.visible and shop.expanded, "Options does not pause over offer details")
	await _confirm()
	check(game.coins == coins and shop.expanded, "RT acts on the shop behind pause")
	await _joy(JOY_BUTTON_START)
	check(shop.expanded and ControllerFocus.contains(shop.detail_popup, root.gui_get_focus_owner()), "pause lost the detail modal")
	await _joy(JOY_BUTTON_B)
	await _joy(JOY_BUTTON_LEFT_SHOULDER)
	var weapon: Control = shop.inventory_row.get_child(0).get_child(0)
	weapon.grab_focus()
	await _joy(JOY_BUTTON_RIGHT_STICK)
	check(shop.expanded and not shop.details.sell_button.visible and not shop.details.enchant_button.visible, "R3 exposes weapon management actions")
	await _joy(JOY_BUTTON_B)
	await _joy(JOY_BUTTON_A)
	check(shop.details.sell_button.visible and shop.details.enchant_button.visible, "A does not expose the selected weapon's actions")
	shop.details.enchant_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	var enchant: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	check(enchant.visible and str(enchant.models[enchant.selected_weapon].uid) == target.instance_uid, "enchant action targets another weapon")
	await _joy(JOY_BUTTON_X)
	check(enchant.visible and state.actions.is_empty(), "X still confirms enchantments")
	enchant.focus_rows[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	for effect in enchant.effect_buttons:
		if effect.get_meta("effect_id") == &"crit":
			effect.grab_focus()
			await _joy(JOY_BUTTON_A)
			break
	await _axis(0.0)
	await _axis(0.95)
	check(state.actions.size() == 1 and enchant.visible and enchant.picking_slot < 0, "RT did not apply exactly one planned enchantment")
	await _axis(0.99)
	check(enchant.visible and state.actions.size() == 1 and target.affixes.is_empty(), "held RT also finished the new overview")
	await _confirm()
	check(not enchant.visible and target.affixes.size() == 1 and state.points == 18, "fresh RT did not finish the draft")
	shop.inventory_row.get_child(0).get_child(0).grab_focus()
	await _joy(JOY_BUTTON_A)
	shop.details.enchant_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	enchant.focus_rows[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	var draft := state.save_data()
	await _joy(JOY_BUTTON_START)
	check(game.game_menu.visible and enchant.visible, "Options does not pause over enchantments")
	await _confirm()
	check(state.save_data() == draft, "RT changed the draft behind pause")
	await _joy(JOY_BUTTON_START)
	check(enchant.focus_rows[0].has_focus(), "pause did not restore the effect row")
	await _joy(JOY_BUTTON_B)
	check(enchant.exit_dialog.visible and state.save_data() == draft, "B implicitly committed or discarded a dirty draft")
	check(input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action == &"ui_cancel") and input.action_bar.entries.any(func(entry: Dictionary) -> bool: return entry.action == &"pause"), "exit decision hides Back behind the global Pause hint")
	await _confirm()
	check(enchant.exit_dialog.visible and state.save_data() == draft, "RT answers the discard decision automatically")
	await _joy(JOY_BUTTON_START)
	check(game.game_menu.visible, "Options does not pause over the exit decision")
	await _joy(JOY_BUTTON_START)
	await _joy(JOY_BUTTON_B)
	check(not enchant.exit_dialog.visible and enchant.focus_rows[0].has_focus(), "canceling exit lost the editing row")
	await _joy(JOY_BUTTON_B)
	await _axis(0.95)
	enchant.exit_dialog.buttons[1].grab_focus()
	await _joy(JOY_BUTTON_A)
	check(not enchant.visible and state.actions.is_empty() and state.points == 18 and target.affixes[0].level == 1, "discard spends points or modifies committed equipment")
	game._on_shop_enchant(target.get_instance_id())
	await _settle()
	enchant.focus_rows[0].grab_focus()
	await _joy(JOY_BUTTON_A)
	await _joy(JOY_BUTTON_B)
	enchant.exit_dialog.buttons[2].grab_focus()
	await _joy(JOY_BUTTON_A)
	check(not enchant.visible and state.points == 16 and target.affixes[0].level == 2, "explicit Finish in the exit decision does not commit the planned upgrade")
	shop.stat_chips[0].grab_focus()
	await _joy(JOY_BUTTON_RIGHT_STICK)
	check(input.navigation.popup_open(), "R3 does not open attribute details")
	check(input.action_bar.entries.size() == 2 and input.action_bar.entries[1].action == &"pause", "native details hide their global Pause mapping")
	input._set_mode(false, true)
	await _axis(0.0)
	await _axis(0.95)
	await _joy(JOY_BUTTON_START)
	check(game.game_menu.visible and not input.navigation.popup_open(), "native popup covers or traps the pause menu")
	await _joy(JOY_BUTTON_START)
	check(input.navigation.popup_open(), "closing pause does not restore native attribute details")
	await _joy(JOY_BUTTON_B)
	shop.inventory_row.get_child(0).get_child(0).grab_focus()
	await _joy(JOY_BUTTON_A)
	shop.details.sell_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	check(shop.details.cancel_button.has_focus(), "opening sale confirmation does not focus its safe action")
	await _joy(JOY_BUTTON_A)
	check(shop.details.sell_button.has_focus() and game.player.loadout.equipped().size() == 2, "canceling the sale loses focus or sells the weapon")
	await _joy(JOY_BUTTON_A)
	shop.details.confirm_button.grab_focus()
	await _joy(JOY_BUTTON_A)
	check(not shop.expanded and game.player.loadout.equipped().size() == 1 and shop.inventory_row.get_child(0).get_child(0).has_focus(), "sale confirmation loses the build and its next equipped weapon")
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	for index in game.shop.offers.size(): game.shop.offers[index] = null
	game._update_shop_panel()
	await _settle()
	check(shop.controller_focus.empty.has_focus(), "all-sold shop loses its offer-area focus")
	coins = game.coins
	await _joy(JOY_BUTTON_X)
	check(game.coins < coins and root.gui_get_focus_owner() is OfferCard, "X cannot reroll the sold-out shop")
	await _axis(0.99)
	check(shop.visible, "held trigger started a wave after returning to shop")
	await _confirm()
	check(not shop.visible and game.run_flow.is_combat(), "fresh RT does not start the next wave")
	await _joy(JOY_BUTTON_B)
	check(not game.game_menu.visible, "B pauses combat")
	await _joy(JOY_BUTTON_START)
	check(game.game_menu.visible, "Options does not pause combat")
	await _joy(JOY_BUTTON_START)
	session.clear_run()
	print("Shared controller schema: shop areas, stable purchases, R3, global pause, RT context boundaries and explicit draft exit checked")
	finish_checks()
