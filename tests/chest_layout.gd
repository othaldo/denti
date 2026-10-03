extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var panel: ChoicePanel = load("res://scenes/ui/choice_panel.tscn").instantiate()
	root.add_child(panel)
	var capture := "--capture" in OS.get_cmdline_user_args()
	var capture_path := ProjectSettings.globalize_path("res://.godot/chest-spacing")
	if capture:
		DirAccess.make_dir_recursive_absolute(capture_path)
	var decisions: Array[bool] = []
	panel.chest_resolved.connect(func(keep: bool) -> void: decisions.append(keep))
	for extent in [Vector2i(320, 568), Vector2i(360, 640), Vector2i(540, 960), Vector2i(720, 1280), Vector2i(568, 320), Vector2i(640, 360), Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		if capture:
			DisplayServer.window_set_size(extent)
		for frame in 3:
			await process_frame
		for item in ShopController.CATALOG:
			if item.weapon_data != null:
				continue
			panel.show_chest(item, 5)
			for frame in 3:
				await process_frame
			var bounds := Rect2(Vector2.ZERO, Vector2(extent))
			var reward: UpgradeCard = panel.buttons[0]
			var scrap: UpgradeCard = panel.buttons[1]
			if not bounds.encloses(panel.dialog_panel.get_global_rect()):
				_fail("chest dialog exceeds %s for %s: %s" % [extent, item.id, panel.dialog_panel.get_global_rect()])
				return
			if panel.cards.columns != 1 or absf(reward.size.x - scrap.size.x) > 1.0 or scrap.size.y > 48.0 or scrap.size.y < 44.0:
				_fail("reward is narrow or scrap occupies a full card at %s" % extent)
				return
			for control in [reward.icon_rect, reward.name_label, reward.rarity_label, reward.effect_label, reward.keep_label]:
				if not control.is_visible_in_tree() or not reward.get_global_rect().encloses(control.get_global_rect()) or control.size.y < control.get_minimum_size().y:
					_fail("reward content overflows at %s for %s: %s / %s" % [extent, item.id, control.get_global_rect(), reward.get_global_rect()])
					return
			if _plain(reward.effect_label.text) != _plain(item.effect_text()) or _plain(reward.name_label.text) != _plain(item.display_name):
				_fail("chest truncated a reward name or effect at %s for %s: %s / %s" % [extent, item.id, reward.effect_label.text, item.effect_text()])
				return
			if reward.get_global_rect().intersects(scrap.get_global_rect()) or reward.keep_label.text != "Behalten" or scrap.icon == null:
				_fail("keep/scrap choice lost its action or overlaps")
				return
			if capture and item.id == &"dodge_2" and extent in [Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(640, 360)]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture_path + "/chest_%dx%d.png" % [extent.x, extent.y])
		panel.buttons[0].pressed.emit()
		if panel.visible or decisions.back() != true:
			_fail("keep no longer resolves the chest")
			return
		panel.show_chest(ShopController.by_id(&"metal_crown"), 5)
		panel.buttons[1].pressed.emit()
		if panel.visible or decisions.back() != false:
			_fail("scrap no longer resolves the chest")
			return
	# These controls are reused for subsequent reward types. Chest-specific
	# hierarchy, coin icon and focus neighbours must not leak into them.
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	panel.show_upgrades([load("res://data/upgrades/bisskraft.tres"), load("res://data/upgrades/haerte.tres")])
	for frame in 4:
		await process_frame
	for card: UpgradeCard in panel.buttons:
		if card.chest_layout or card.keep_label.visible or card.icon != null or not card.focus_neighbor_top.is_empty() or not card.focus_neighbor_bottom.is_empty():
			_fail("chest layout/focus escaped into the next reward")
			return
	panel.show_chest(ShopController.by_id(&"metal_crown"), 5)
	panel.show_starters(WeaponCatalog.STARTERS)
	for frame in 4:
		await process_frame
	for card: UpgradeCard in panel.buttons:
		if card.visible and (card.chest_layout or card.icon_rect.size.x < 40.0 or not card.get_global_rect().encloses(card.effect_label.get_global_rect())):
			_fail("chest layout escaped into starter weapons")
			return
	panel.show_chest(ShopController.by_id(&"metal_crown"), 5)
	panel.show_relics([RelicCatalog.CATALOG[0], RelicCatalog.CATALOG[1], RelicCatalog.CATALOG[2]])
	for frame in 4:
		await process_frame
	for card: UpgradeCard in panel.buttons:
		if card.visible and (card.chest_layout or card.icon_rect.size.x < 40.0 or not card.get_global_rect().encloses(card.effect_label.get_global_rect())):
			_fail("chest layout escaped into boss relics")
			return
	print("Denti chest layout test passed")
	quit(0)


func _plain(text: String) -> String:
	return text.replace("\n", "").replace(" ", "")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
