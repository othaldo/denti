extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_amalgam_visibility.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game._open_shop()
	paused = true
	var chip: Button = game.shop_panel.amalgam_chip
	check(not chip.visible, "amalgam indicator appears without the item")
	game.player.stats.armor = 10.0
	var weapon := WeaponCatalog.by_id(&"water_jet")
	var before := WeaponPresentation.values(weapon, 1, game.player)
	check(game.items.acquire(ShopController.by_id(&"amalgam_core")), "could not acquire amalgam core")
	game._update_shop_panel()
	check(chip.visible and chip.text == "+25 %", "one core at ten armor did not display 25 percent")
	check(chip.tooltip_text.contains("10 Härte × 2.5 %") and chip.tooltip_text.contains("Waffenwerten"), "tooltip omitted calculation or already included explanation")
	var after := WeaponPresentation.values(weapon, 1, game.player)
	check(is_equal_approx(after.damage, before.damage * 1.25), "displayed armor damage differs from weapon damage")
	check(game.items.acquire(ShopController.by_id(&"amalgam_core")), "could not stack second core")
	game._update_shop_panel()
	check(chip.text == "+50 %", "second core did not update displayed contribution")
	game.player.stats.apply_upgrade(&"armor", 10)
	check(chip.text == "+60 %", "armor change did not refresh indicator or obey cap")
	game.player.stats.apply_upgrade(&"armor", -25)
	check(chip.text == "+0 %", "negative armor displayed negative bonus")
	game.player.stats.apply_upgrade(&"armor", 15)
	check(chip.text == "+50 %", "armor recovery did not restore calculated bonus")
	var found := false
	for entry in BuildPresentation.item_entries(game.items):
		if entry.name == "Amalgamkern":
			found = entry.description.contains("Aktuell: +50 % Waffenschaden")
	check(found, "owned item details omitted current contribution")
	chip.pressed.emit()
	await process_frame
	var popup := chip.get_child(chip.get_child_count() - 1) as PopupPanel
	check(popup != null and popup.visible, "amalgam click did not open explanation")
	if popup != null:
		popup.hide()
	paused = false
	session.clear_run()
	if failures.is_empty():
		print("Denti amalgam visibility test passed")
	finish_checks()
