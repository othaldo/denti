extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/test_shop_interaction.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 100
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"turbo_drill"), ShopController.by_id(&"conductive_varnish"), ShopController.by_id(&"damage_1"), ShopController.by_id(&"cavity_bounty")])
	game._update_shop_panel()
	var ui: ShopPanel = game.shop_panel
	var capture := "--capture" in OS.get_cmdline_user_args()
	var path := ProjectSettings.globalize_path("res://.godot/shop-interaction")
	if capture:
		DirAccess.make_dir_recursive_absolute(path)
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(720, 1280), Vector2i(568, 320), Vector2i(320, 568)]:
		root.content_scale_size = extent
		root.size = extent
		if capture:
			DisplayServer.window_set_size(extent)
		ui.close_details()
		for frame in 12:
			await process_frame
		var before: Array[Rect2] = []
		for card: OfferCard in ui.offer_buttons:
			before.append(card.get_global_rect())
		var coins_before: int = game.coins
		ui.offer_buttons[0].pressed.emit()
		for frame in 12:
			await process_frame
		if game.coins != coins_before or not ui.expanded or not ui.detail_overlay.visible:
			_fail("inspection purchased an offer or failed to open")
			return
		for index in ui.offer_buttons.size():
			if not ui.offer_buttons[index].is_visible_in_tree() or not ui.offer_buttons[index].get_global_rect().is_equal_approx(before[index]):
				_fail("inspection hides or moves other offers at %s" % extent)
				return
		if not Rect2(Vector2.ZERO, Vector2(extent)).encloses(ui.detail_popup.get_global_rect()) or ui.detail_popup.size.x > 520:
			_fail("details are not a bounded compact popup at %s" % extent)
			return
		for control in [ui.details.close_button, ui.detail_buy_button, ui.detail_pin_button]:
			if not control.is_visible_in_tree() or not ui.detail_popup.get_global_rect().encloses(control.get_global_rect()):
				_fail("popup loses close, purchase or reservation actions")
				return
		if capture and extent in [Vector2i(1280, 720), Vector2i(720, 1280)]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(path + "/details_%dx%d.png" % [extent.x, extent.y])
		ui.close_details()
	# An unavailable purchase must explain itself before the player opens details.
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	game.coins = 0
	game._update_shop_panel()
	for frame in 10:
		await process_frame
	var card: OfferCard = ui.offer_buttons[0]
	if card.disabled or not card.buy_button.disabled or card.buy_caption.text != "Zu teuer" or not card.buy_button.tooltip_text.contains("Es fehlen") or card.price_label.get_theme_color("font_color") != DentiUIStyle.CORAL:
		_fail("unaffordable purchase lacks a visible reason or cannot be inspected")
		return
	await _click(card.buy_button.get_global_rect().get_center())
	if game.coins != 0 or game.shop.offers[0] == null:
		_fail("unaffordable button pointer click bought an offer")
		return
	card.pressed.emit()
	if not ui.details.action_hint.text.contains("Es fehlen"):
		_fail("inspection does not explain the missing coins")
		return
	ui.close_details()
	if capture:
		for frame in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path + "/unaffordable.png")
	card.show_offer(game.shop.offers[0], 100, false)
	if not card.buy_button.disabled or card.buy_caption.text != "Belegt" or not card.buy_button.tooltip_text.contains("Wurzeln"):
		_fail("full equipment lacks a separate purchase reason")
		return
	game.coins = 100
	game._update_shop_panel()
	var previous_motion: bool = session.reduced_ui_motion
	session.reduced_ui_motion = false
	card.buy_button.mouse_entered.emit()
	await create_timer(0.2, true).timeout
	if card.buy_button.scale.x <= 1.01 or card.scale != Vector2.ONE or card.buy_caption.text != "Kaufen":
		_fail("purchase hover does not provide independent button feedback")
		return
	card.buy_button.mouse_exited.emit()
	await create_timer(0.2, true).timeout
	if not card.buy_button.scale.is_equal_approx(Vector2.ONE):
		_fail("purchase hover does not reset")
		return
	session.reduced_ui_motion = true
	card.reserve_button.mouse_entered.emit()
	await create_timer(0.2, true).timeout
	if not card.reserve_button.scale.is_equal_approx(Vector2.ONE):
		_fail("reduced motion does not suppress action hover")
		return
	session.reduced_ui_motion = previous_motion
	# Actual pointer clicks distinguish inspect from purchase and outside dismissal.
	await _click(card.get_global_rect().get_center())
	if not ui.expanded or game.coins != 100:
		_fail("card click is not inspection")
		return
	await _click(Vector2(5, 5))
	if ui.expanded or game.coins != 100:
		_fail("outside click did not dismiss inspection safely")
		return
	var price: int = game.shop.offers[0].price
	await _click(card.buy_button.get_global_rect().get_center())
	if game.coins != 100 - price or game.shop.offers[0] != null:
		_fail("purchase button pointer click did not buy immediately")
		return
	paused = false
	session.clear_run()
	print("Denti shop interaction test passed")
	quit(0)


func _click(position: Vector2) -> void:
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)
	for frame in 5:
		await process_frame


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
