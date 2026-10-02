extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	_check(DentiAttributes.name_for(DentiAttributes.Type.ARMOR) == "Härte", "armor lost its canonical name")
	_check(DentiAttributes.name_for(DentiAttributes.Type.MAX_HEALTH) == "Schmelz", "max HP is confused with armor")
	_check(DentiAttributes.meaning_for(DentiAttributes.Type.MAX_HEALTH).contains("HP"), "max HP lacks an explanation")
	_check(DentiAttributes.resolve_text("+1 Rüstung, +12 Leben, -4 % Angriffstempo. +2 % Krit, +10 Glück.") == "+1 Härte, +12 Schmelz (HP), -4 % Putzeifer. +2 % Glanz, +10 Zahnglück.", "legacy item terminology was not normalized")
	_check(DentiAttributes.resolve_text("+1 Regeneration, -3 % Schaden. Alle 8 normalen Kills: +1 Leben.") == "+1 Speichel, -3 % Bisskraft. Alle 8 normalen Kills: +1 Leben.", "healing became max HP or flat damage kept an alias")
	_check(DentiAttributes.resolve_text("XP heilt 0,35 Leben je Punkt. -8 maximales Leben.").ends_with("-8 Schmelz."), "HP penalty or healing prose was damaged")
	_check(DentiAttributes.bonus_text(DentiAttributes.Type.CRIT_CHANCE, 0.03) == "+3 % Glanz", "fractional crit displayed in the wrong unit")
	_check(DentiAttributes.ACTIVE.has(DentiAttributes.Type.DODGE), "Zahnflutsch is absent from the live stat pool")
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_attribute_presentation.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.coins = 10000
	game._open_shop()
	_check(paused, "purchase regression must exercise the paused shop")
	for upgrade: UpgradeData in game.UPGRADES:
		var type := DentiAttributes.from_key(upgrade.stat)
		_check(type >= 0 and DentiAttributes.key_for(type) == upgrade.stat, "attribute enum does not round-trip an upgrade key")
		var copy := upgrade.duplicate() as UpgradeData
		copy.display_name = "Outdated resource label"
		var card := UpgradeCard.new()
		game.choice_panel.add_child(card)
		card.show_upgrade(copy)
		_check(card.name_label.text == DentiAttributes.name_for(type).to_upper() and card.effect_label.text.contains(DentiAttributes.name_for(type)), "level-up presentation bypasses central names")
		_check(card.tooltip_text.contains(DentiAttributes.meaning_for(type)), "level-up lacks attribute meaning")
		card.free()
	var ui: ShopPanel = game.shop_panel
	# Buy through the actual UI; every stat delta must appear without reopening.
	for id in [&"health_1", &"metal_crown", &"mouthwash", &"lucky_molar", &"mythic_regen", &"mythic_bite", &"dodge_1"]:
		var offer := ShopController.by_id(id).duplicate() as ShopOfferData
		game.shop.offers[0] = offer
		game._update_shop_panel()
		var before: Dictionary = game.player.stats.to_save_data()
		var previous_coins: int = game.coins
		ui.offer_buttons[0].buy_button.pressed.emit()
		_check(game.coins == previous_coins - offer.price and game.shop.offers[0] == null, "UI purchase was not completed: " + str(id))
		for key: StringName in offer.stat_changes:
			var type := DentiAttributes.from_key(key)
			_check(is_equal_approx(float(game.player.stats.get(key)), float(before[str(key)]) + float(offer.stat_changes[key])), "purchased stat delta differs from its data")
			_check(ui.stats_label.text.contains("%s %s" % [DentiAttributes.name_for(type), DentiAttributes.value_text(game.player.stats, type)]), "shop retained stale purchased stats: " + str(key))
	_check(ui.luck_label.text == "20 Zahnglück", "shop header luck did not refresh after buying")
	# A stat change outside show_shop must refresh the existing view as well.
	game.player.stats.apply_upgrade(&"attack_speed", 7.0)
	_check(ui.stats_label.text.contains("Putzeifer +17 %"), "paused shop ignored the stats.changed signal")
	var weapon: WeaponData = game.player.loadout.equipped()[0].data
	_check(weapon.damage_type == "Schmelz" and weapon.damage_type_label() == "Schmelzbruch", "damage type compatibility or HP distinction was lost")
	ui._select("equipment", 0)
	_check(ui.details.subtitle.text.contains("Schmelzbruch"), "weapon details still confuse damage type with max HP")
	game._save_run()
	var expected := ui.stats_label.text
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_check(game.in_shop and game.shop_panel.stats_label.text == expected, "resumed shop lost stat names or values")
	game.player.stats.apply_upgrade(&"armor", 1.0)
	_check(game.shop_panel.stats_label.text.contains("Härte " + game.player.stats.armor_text()), "resumed shop did not reconnect live stats")
	# Rebinding context must disconnect the old stats source.
	var previous_player: Player = game.player
	game.shop_panel.set_build_context(null)
	_check(not previous_player.stats.changed.is_connected(game.shop_panel._refresh_stats), "shop left a stale stats connection")
	game.shop_panel.set_build_context(previous_player)
	_check(previous_player.stats.changed.is_connected(game.shop_panel._refresh_stats), "shop failed to reconnect current stats")
	game.free()
	paused = false
	session.clear_run()
	if failures == 0:
		print("PASS attribute_presentation")
	quit(0 if failures == 0 else 1)
