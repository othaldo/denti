extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_four_choice_layout.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 100
	game.player.loadout.restore([{"id": "turbo_drill", "tier": 1}, {"id": "floss_whip", "tier": 1}, {"id": "water_jet", "tier": 1}, {"id": "toothpick_spear", "tier": 1}, {"id": "prophylaxis_polisher", "tier": 1}, {"id": "plaque_scaler", "tier": 1}])
	var capture := "--capture" in OS.get_cmdline_user_args()
	var capture_path := ProjectSettings.globalize_path("res://.codex/economy-previews")
	if capture:
		DirAccess.make_dir_recursive_absolute(capture_path)
	for extent in [Vector2i(320, 568), Vector2i(360, 640), Vector2i(568, 320), Vector2i(640, 360), Vector2i(540, 960), Vector2i(720, 1280), Vector2i(800, 600), Vector2i(1024, 600), Vector2i(1280, 670), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(360, 640)]:
		root.content_scale_size = extent
		root.size = extent
		if capture:
			DisplayServer.window_set_size(extent)
		for frame in 5:
			await process_frame
		game.shop_panel.visible = false
		var bounds := Rect2(Vector2.ZERO, Vector2(extent))
		for start in [0, 4, 6]:
			var options: Array[UpgradeData] = []
			for index in 4:
				options.append(game.UPGRADES[(start + index) % game.UPGRADES.size()].with_tier(4))
			game.choice_panel.show_upgrades(options)
			for frame in 4:
				await process_frame
			if not bounds.encloses(game.choice_panel.dialog_panel.get_global_rect()):
				_fail("four-choice dialog exceeds %s: %s" % [extent, game.choice_panel.dialog_panel.get_global_rect()])
				return
			var rectangles: Array[Rect2] = []
			for card: UpgradeCard in game.choice_panel.buttons:
				var rect := card.get_global_rect()
				if not card.visible or not bounds.encloses(rect):
					_fail("upgrade card is missing or outside %s" % extent)
					return
				for previous in rectangles:
					if rect.intersects(previous):
						_fail("upgrade cards overlap at %s" % extent)
						return
				rectangles.append(rect)
				for control in [card.icon_rect, card.name_label, card.rarity_label, card.effect_label]:
					if not rect.encloses(control.get_global_rect()) or control.size.y + 1.0 < control.get_minimum_size().y:
						_fail("upgrade text/icon clipped at %s: %s in %s" % [extent, control.get_global_rect(), rect])
						return
		if capture and extent in [Vector2i(320, 568), Vector2i(720, 1280), Vector2i(1280, 720)]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_path + "/levelup_%dx%d.png" % [extent.x, extent.y])
		game.choice_panel.visible = false
		game._open_shop()
		for frame in 5:
			await process_frame
		var ui: ShopPanel = game.shop_panel
		var wide: bool = extent.x >= 1000 and extent.y >= 560
		if wide:
			if ui.offers_grid.columns != 4 or ui.offers_section.get_index() >= ui.main_scroll.get_index():
				_fail("wide shop does not place four offers above the build at %s" % extent)
				return
			var previous_right := -1.0
			var row_y := ui.offer_buttons[0].get_global_rect().position.y
			for card: OfferCard in ui.offer_buttons:
				var rect := card.get_global_rect()
				if not bounds.encloses(rect) or absf(rect.position.y - row_y) > 1.0 or rect.position.x < previous_right:
					_fail("wide shop offers overlap or leave their row at %s" % extent)
					return
				previous_right = rect.end.x
			# All catalog descriptions must fit the narrow cards, including long synergies.
			for template in ShopController.CATALOG:
				var card: OfferCard = ui.offer_buttons[0]
				card.show_offer(template, 100)
				for frame in 2:
					await process_frame
				for control in [card.icon_rect, card.name_label, card.rarity_label, card.effect_label, card.buy_button, card.reserve_button]:
					if not card.get_global_rect().encloses(control.get_global_rect()):
						_fail("compact catalog content exceeds card at %s: %s" % [extent, template.id])
						return
			game._update_shop_panel()
			for frame in 4:
				await process_frame
		if not bounds.encloses(ui.get_node("Root/Center/Panel").get_global_rect()) or not bounds.encloses(ui.continue_button.get_global_rect()):
			_fail("four-offer shop or continue action exceeds %s: panel %s, continue %s" % [extent, ui.get_node("Root/Center/Panel").get_global_rect(), ui.continue_button.get_global_rect()])
			return
		for card: OfferCard in ui.offer_buttons:
			if card.content.visible and (not card.get_global_rect().encloses(card.buy_button.get_global_rect()) or not card.get_global_rect().encloses(card.reserve_button.get_global_rect())):
				_fail("buy/reserve controls exceed shop card at %s: card %s, buy %s, reserve %s" % [extent, card.get_global_rect(), card.buy_button.get_global_rect(), card.reserve_button.get_global_rect()])
				return
		ui._select("equipment", 0)
		for frame in 4:
			await process_frame
		if not bounds.encloses(ui.get_node("Root/Center/Panel").get_global_rect()) or not bounds.encloses(ui.details.sell_button.get_global_rect()):
			_fail("full equipment or sell action exceeds %s: panel %s, sell %s" % [extent, ui.get_node("Root/Center/Panel").get_global_rect(), ui.details.sell_button.get_global_rect()])
			return
		ui._select("offer", 0)
		if capture and extent in [Vector2i(320, 568), Vector2i(720, 1280), Vector2i(1024, 600), Vector2i(1280, 670), Vector2i(1280, 720)]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_path + "/shop_%dx%d.png" % [extent.x, extent.y])
	# Fresh choices and save/resume preserve the fourth option and its effect.
	game.rewards.pending_levels = 1
	game.rewards.step = PostWaveRewards.Step.LEVELS
	game.in_shop = false
	game._show_level_choice()
	var saved := RunSnapshot.capture(game)
	var fourth: UpgradeData = game.choice_panel.current_upgrades[3]
	var before: float = game.player.stats.get(fourth.stat)
	RunSnapshot.restore(game, saved)
	game.choice_panel.buttons[3].pressed.emit()
	if not is_equal_approx(float(game.player.stats.get(fourth.stat)), before + fourth.amount):
		_fail("fourth level-up choice lost its effect after resume")
		return
	session.clear_run()
	paused = false
	print("Denti four-choice layout test passed")
	quit(0)

func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
