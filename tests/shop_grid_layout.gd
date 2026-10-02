extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_shop_grid.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 500
	game._open_shop()
	game.shop.offers.assign([ShopController.by_id(&"turbo_drill"), ShopController.by_id(&"prophylaxis_polisher"), ShopController.by_id(&"damage_1"), ShopController.by_id(&"cavity_bounty")])
	var ui: ShopPanel = game.shop_panel
	for extent in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1040, 600)]:
		root.content_scale_size = extent
		root.size = extent
		for costs in [[2, 2, 1], [2, 2, 2], [1, 2, 1, 2], [1, 1, 1, 1, 1, 1]]:
			var weapons: Array[Dictionary] = []
			for cost in costs:
				weapons.append({"id": "magic_toothbrush" if cost == 2 else "amalgam_slingshot", "tier": 1})
			game.player.loadout.restore(weapons)
			game._update_shop_panel()
			ui.close_details()
			for frame in 8:
				await process_frame
			var occupied: Array[Rect2] = []
			for slot in ui.inventory_row.get_children():
				var button: Button = slot.get_child(0)
				var rect := button.get_global_rect()
				if not ui.inventory_scroll.get_global_rect().encloses(rect):
					_fail("root grid leaves its six-slot area for %s at %s: %s outside %s" % [costs, extent, rect, ui.inventory_scroll.get_global_rect()])
					return
				for previous in occupied:
					if rect.intersects(previous):
						_fail("root slots overlap for %s at %s" % [costs, extent])
						return
				occupied.append(rect)
			if costs == [2, 2, 1]:
				var last_weapon: Button = ui.inventory_row.get_child(2).get_child(0)
				var free_root: Button = ui.inventory_row.get_child(3).get_child(0)
				if not is_equal_approx(last_weapon.global_position.y, free_root.global_position.y):
					_fail("free root fell below the single-root weapon")
					return
			if ui.reroll_button.get_global_rect().end.y > ui.offers_grid.global_position.y or not is_equal_approx(ui.offers_grid.global_position.y, ui.left_scroll.global_position.y):
				_fail("reroll creates an extra row or cards start below the build")
				return
			var first: OfferCard = ui.offer_buttons[0]
			for card: OfferCard in ui.offer_buttons:
				for pair in [[card.name_label, first.name_label], [card.category_label, first.category_label], [card.summary_row, first.summary_row], [card.effect_label, first.effect_label], [card.buy_button, first.buy_button]]:
					if not is_equal_approx(pair[0].global_position.y, pair[1].global_position.y):
						_fail("card fields lose their common baseline at %s" % extent)
						return
				if card.rarity_label.visible or card.tooltip_text.find("Seltenheit:") < 0:
					_fail("rarity returned as a large label or lost its accessible name")
					return
	# The compact text must use the current weapon tier, rather than a range of
	# possible future bonuses from the description.
	var drill: WeaponData = WeaponCatalog.by_id(&"turbo_drill")
	if not WeaponPresentation.card_effect(drill, 1).contains("25 %") or not WeaponPresentation.card_effect(drill, 4).contains("40 %"):
		_fail("card effect does not reflect the actual weapon tier")
		return
	paused = false
	session.clear_run()
	print("Denti shop grid layout test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
