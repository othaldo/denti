extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var bar: ControllerActionBar

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in 12: await process_frame

func _actions() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry in bar.entries: result.append(entry.action)
	return result

func _geometry(content: Control) -> void:
	_check(bar.visible and bar.strip.is_visible_in_tree(), "controller action bar is absent")
	var bounds := bar.strip.get_global_rect()
	var panel_bounds := bar.panel.get_global_rect()
	var safe := HUDLayout.safe_rect(root.get_visible_rect().size)
	_check(is_equal_approx(panel_bounds.position.x, safe.position.x) and is_equal_approx(panel_bounds.size.x, safe.size.x), "controller panel stops at the content margins instead of filling the safe width")
	_check(panel_bounds.grow(0.5).encloses(bounds), "controller panel clips its button contents")
	_check(is_equal_approx(panel_bounds.size.y, bounds.size.y), "controller panel does not grow with its rows")
	_check(Rect2(Vector2.ZERO, root.get_visible_rect().size).grow(1).encloses(bounds), "action bar leaves the viewport")
	_check(content.get_global_rect().end.y <= bounds.position.y + 1, "controller bar overlays the screen's content")
	_check(bar.glyph_rects.size() == bar.entries.size(), "action bar did not lay out its entries")
	for index in bar.glyph_rects.size():
		var glyph := bar.glyph_rects[index]
		var text := bar.text_rects[index]
		_check(is_equal_approx(glyph.size.x, glyph.size.y), "controller glyph was stretched")
		_check(glyph.end.x + 5 <= text.position.x and is_equal_approx(glyph.get_center().y, text.get_center().y), "glyph and action label are not an aligned pair")
		_check(Rect2(Vector2.ZERO, bar.strip.size).grow(0.5).encloses(glyph) and Rect2(Vector2.ZERO, bar.strip.size).grow(0.5).encloses(text), "controller entry is clipped")
		if index > 0 and is_equal_approx(bar.glyph_rects[index - 1].position.y, glyph.position.y):
			_check(bar.text_rects[index - 1].end.x + 8 <= glyph.position.x, "adjacent controller actions overlap")
		for previous in index:
			_check(not bar.text_rects[previous].intersects(text), "controller rows overlap")
	for prompt: ControllerPrompt in get_nodes_in_group("controller_prompts"):
		if not prompt.target is DashButton:
			_check(not prompt.visible, "a controller glyph is still floating on a menu button/card")

func _run() -> void:
	var session := root.get_node("GameSession")
	var input := root.get_node("GameInput")
	bar = input.action_bar
	session.save_path = "user://controller_layout_run.json"
	session.settings_path = "user://controller_layout_settings.cfg"
	session.resume_requested = false
	session.reduced_ui_motion = true
	session.clear_run()
	RunStore.clear(session.save_path + ".setup.json")
	AudioServer.set_bus_mute(0, true)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._new_game()
	menu.setup_selector.confirm_selection()
	menu.setup_selector.select_weapon(1)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(1920, 1080)]:
		root.size = extent
		root.content_scale_size = extent
		for family in [1, 2]:
			session.set_controller_symbols(family)
			input.use_controller(4)
			await _settle()
			menu.setup_selector.confirm_button.grab_focus()
			await _settle()
			_geometry(menu.setup_selector.panel)
			_check(_actions() == [&"ui_accept", &"ui_cancel", &"ui_details"] and bar.entries[0].label == "Starten", "setup action legend does not match the focused action and its shortcuts")
			var original := menu.setup_selector.confirm_button.get_global_rect()
			session.set_controller_symbols(3 - family)
			await _settle()
			_check(menu.setup_selector.confirm_button.get_global_rect().is_equal_approx(original), "switching glyph family moves a button")
		menu.setup_selector.show_details()
		await _settle()
		_geometry(menu.setup_selector.details.panel)
		_check(_actions() == [&"ui_cancel"], "modal advertises shortcuts from the selection screen behind it")
		menu.setup_selector.details.dismiss()
	# Exercise the mobile canvas scale used by GameSession, not only a viewport
	# whose logical pixels happen to equal its physical window dimensions.
	for extent in [Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = session.mobile_base_size(extent)
		input.use_controller(4)
		await _settle()
		menu.setup_selector.confirm_button.grab_focus()
		await _settle()
		_geometry(menu.setup_selector.panel)
		var physical := root.get_screen_transform() * bar.strip.get_global_rect()
		_check(Rect2(Vector2.ZERO, Vector2(extent)).grow(1).encloses(physical), "action bar escapes the physical mobile screen")
		_check(physical.size.y >= 47 and physical.size.y <= 49, "mobile canvas scaling changes the physical action-row height")
	var pointer := InputEventMouseMotion.new()
	session.set_controller_symbols(0)
	input.last_controller_ms = -1000
	pointer.relative = Vector2(8, 0)
	root.push_input(pointer)
	await _settle()
	_check(not input.using_controller and bar.visible == DesktopMenuInput.available(root), "pointer input does not restore the appropriate desktop/mobile hints")
	menu.queue_free()
	await _settle()
	root.size = Vector2i(320, 568)
	root.content_scale_size = root.size
	session.pending_start_weapon_id = &"magic_toothbrush"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	game.wave.set_process(false)
	game.coins = 100
	game._open_shop()
	game.rewards.weapon_upgrades.points = 8
	game._update_shop_panel()
	input.use_controller(4)
	await _settle()
	game.shop_panel.offer_buttons[0].grab_focus()
	await _settle()
	_geometry(game.shop_panel.get_node("Root/Center/Panel"))
	_check(game.shop_panel.offer_buttons[0].icon_rect.get_global_rect().position.y >= game.shop_panel.main_scroll.get_global_rect().position.y - 1, "focusing a tall shop card clips its identifying artwork")
	_check(_actions() == [&"ui_accept", &"ui_reroll", &"ui_confirm", &"ui_pin", &"ui_details", &"ui_previous", &"pause"] and bar.entries[0].label == "Kaufen", "shop lacks its purchase/pin/build/start actions")
	_check(not game.shop_panel.reroll_button.visible and not game.shop_panel.enchant_button.visible and not game.shop_panel.continue_button.visible, "controller action bar leaves duplicate shop buttons")
	_check(bar.entries.filter(func(entry: Dictionary) -> bool: return entry.action == &"ui_reroll")[0].label.contains(str(game.shop.reroll_cost)), "hidden reroll button loses its visible price")
	session.set_controller_symbols(1)
	input._set_mode(false, true)
	await _settle()
	for control in [game.shop_panel.enchant_button, game.shop_panel.continue_button]:
		control.grab_focus()
		await _settle()
		_check(&"ui_accept" in _actions() and (&"ui_confirm" in _actions() or control == game.shop_panel.continue_button), "focused footer action lost A or its independent shortcut")
	input.use_controller(4)
	await _settle()
	game.shop_panel.offer_buttons[0].grab_focus()
	await _settle()
	_check(bar.visible_height > ControllerActionBar.HEIGHT, "narrow shop shortcuts did not wrap into readable rows")
	var before_inspection: Rect2 = game.shop_panel.offer_buttons[0].get_global_rect()
	game.shop_panel._select("offer", 0)
	game.shop_panel.detail_buy_button.grab_focus()
	await _settle()
	_geometry(game.shop_panel.detail_popup)
	_check(game.shop_panel.offer_buttons[0].get_global_rect().is_equal_approx(before_inspection), "inspection reflowed the offers behind the popup")
	_check(_actions() == [&"ui_accept", &"ui_cancel", &"pause"] and bar.entries[0].label == "Kaufen", "inspection advertises a hidden reroll or the wrong primary action")
	game.shop_panel.close_details()
	game.shop_panel.hide()
	var enchant: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	game.player.loadout.restore([{"id": "floss_garrote", "tier": 4}, {"id": "floss_garrote", "tier": 4}, {"id": "mouthwash_mortar", "tier": 4}])
	enchant.show_upgrades(game.rewards.weapon_upgrades, game.player.loadout, game.player.stats, game.items, null, game.coins)
	await _settle()
	enchant.open_picker(0)
	await _settle()
	for effect in enchant.effect_buttons:
		if effect.get_meta("effect_id") == &"range":
			effect.pressed.emit()
			break
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320), Vector2i(1920, 1080)]:
		root.size = extent
		root.content_scale_size = extent
		for family in [1, 2]:
			session.set_controller_symbols(family)
			input.use_controller(4)
			await _settle()
			_geometry(enchant.stage.panel)
			_check(&"ui_confirm" in _actions() and &"ui_details" in _actions() and &"ui_previous" not in _actions() and &"ui_next" not in _actions() and &"ui_ascend" not in _actions(), "enchantment picker must offer confirm/details without weapon or ascension shortcuts")
			var confirm: Dictionary = bar.entries.filter(func(entry: Dictionary) -> bool: return entry.action == &"ui_confirm")[0]
			_check(confirm.label == enchant.finish_button.text and confirm.label.contains("2"), "enchantment shortcut omits its primary action or point price")
		enchant.details.present("Details", "Modal", enchant.weapon_buttons[0])
		await _settle()
		_check(_actions() == [&"ui_cancel", &"pause"], "enchantment mappings leak into its detail modal")
		enchant.details.dismiss()
	enchant._back()
	await _settle()
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		for family in [1, 2]:
			session.set_controller_symbols(family)
			input.use_controller(4)
			await _settle()
			_geometry(enchant.stage.panel)
			var done := bar.entries.filter(func(entry: Dictionary) -> bool: return entry.label == "Fertig")
			_check(done.size() == 1 and done[0].action == &"ui_confirm" and &"ui_cancel" in _actions(), "finish must use RT while B remains Back")
			_check(not enchant.stage.footer.visible and not enchant.finish_button.visible, "controller overview repeats the finish action as a screen button")
			if extent.x >= 720:
				_check(enchant.body.custom_minimum_size.y <= enchant.stage.last_extent.y + 0.5, "desktop action list creates an unnecessary scrollbar")
			var footprint: float = enchant.stage.body_scroll.position.y + enchant.stage.body_scroll.size.y
			_check(is_equal_approx(footprint, enchant.stage.panel.size.y), "hidden controller footer still wastes body space")
	enchant.hide()
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 7, "damage": 1.0}]},
		{"id": "magic_toothbrush", "tier": 1, "affixes": [{"id": "fire", "level": 6, "damage": 1.0}]}])
	var fusion: WeaponFusionPanel = game.weapon_fusion_panel
	fusion.show_plan(game.player.loadout.fusion_plan(0))
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720)]:
		root.size = extent
		root.content_scale_size = extent
		await _settle()
		_geometry(fusion.stage.panel)
		var bounds := fusion.stage.panel.get_global_rect().grow(0.5)
		for control in [fusion.cancel_button, fusion.confirm_button, fusion.refund_label]:
			_check(bounds.encloses(control.get_global_rect()), "fusion footer/counter is clipped at %s" % extent)
	fusion.hide()
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	paused = false
	await _settle()
	_check(not bar.visible, "menu action legend remains in active combat")
	var prompt := game.hud.dash_indicator.get_node("ControllerPrompt") as ControllerPrompt
	_check(prompt.visible and is_equal_approx(prompt.get_rect().get_center().x, game.hud.dash_indicator.size.x * 0.5) and prompt.position.y >= game.hud.dash_indicator.size.y, "dash glyph is not centered beneath its stamina indicator")
	game.game_menu.open_pause()
	session.set_controller_symbols(2)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = extent
		input.use_controller(4)
		game.game_menu.actions[&"dentipedia"].grab_focus()
		await _settle()
		_geometry(game.game_menu.stage.panel)
		_check(_actions() == [&"ui_accept", &"ui_cancel"], "pause legend lost its focused action or Back")
	print("Controller action rows, glyph/text alignment, safe area, modal context and pointer fallback checked")
	finish(0 if failures.is_empty() else 1)
