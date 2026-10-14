extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_affix_progression.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	var common := {"id": "fire", "rarity": 1, "damage": 3.0}
	for damage in [3, 4, 5, 7]:
		assert(WeaponAffixes.apply(weapon, common))
		assert(weapon.affixes[0].damage == damage, "common progression wrong")
	assert(weapon.affixes[0].rarity == 2 and weapon.affixes[0].rank == 1)
	var before: Array = weapon.affixes.duplicate(true)
	assert(WeaponAffixes.apply(weapon, common) and weapon.affixes[0].progress == 0.5 and weapon.affixes[0].damage == 8, "lower rarity failed to add partial progress")
	assert(WeaponAffixes.apply(weapon, {"id": "fire", "rarity": 3, "damage": 14}))
	assert(weapon.affixes[0].rank == 1 and weapon.affixes[0].damage == 14)
	for damage in [17, 20, 25]:
		assert(WeaponAffixes.apply(weapon, {"id": "fire", "rarity": 3, "damage": 14}))
		assert(weapon.affixes[0].damage == damage)
	for damage in [30, 35, 37, 39]:
		assert(WeaponAffixes.apply(weapon, {"id": "fire", "rarity": 4, "damage": 25}))
		assert(weapon.affixes[0].damage == damage, "legendary growth stopped")
	var loadout: WeaponLoadout = game.player.loadout
	var uid := weapon.instance_uid
	loadout.restore(loadout.save_data())
	weapon = loadout.equipped()[0]
	assert(weapon.instance_uid == uid and weapon.affixes[0].rank == 3 and weapon.affixes[0].bonus == 4 and weapon.affixes[0].damage == 39, "resume changed progress")
	var joined := WeaponAffixes.sanitize([
		{"id": "ice", "rarity": 1, "rank": 2, "damage": 4, "stacks": 2},
		{"id": "ice", "rarity": 1, "rank": 1, "damage": 3, "stacks": 1}])
	assert(joined.size() == 1 and joined[0].rank == 3 and joined[0].damage == 5, "fusion failed to carry ranked contributions")
	var legacy := WeaponAffixes.sanitize([{"id": "fire", "rarity": 1, "damage": 120, "stacks": 90}])
	assert(legacy[0].damage == 120 and legacy[0].rank == 1, "migration removed invested damage")
	var rng := RandomNumberGenerator.new()
	for seed_value in 150:
		rng.seed = seed_value
		var chest := WeaponAffixes.roll_chest(2, 0, loadout, false, rng)
		var useful := false
		for option in chest.options:
			useful = useful or option.id == "fire" and int(option.rarity) == 4
		assert(useful, "chest lacks promised useful existing effect")
		assert(WeaponAffixes.sanitize_chest(chest).options == chest.options, "saving rerolled chest")
	var panel: WeaponChestPanel = game.weapon_chest_panel
	var chest := {"kind": "affix", "options": [{"id": "fire", "rarity": 4, "damage": 25}, {"id": "ice", "rarity": 2, "damage": 7}, {"id": "poison", "rarity": 3, "damage": 14}], "scrap_coins": 5}
	panel.show_chest(chest, loadout, game.player.stats, 5)
	for index in 3:
		assert(panel.buttons[index].rarity_label.get_theme_color("font_color") == DentiRarity.color_for(int(chest.options[index].rarity)), "chest rarity differs from Mk color")
	var label: Label = panel.replacement_buttons[0].get_meta("rarity_label")
	assert(label.get_theme_color("font_color") == DentiRarity.color_for(4) and label.text == "Legendär III+", "replacement rarity/progress missing")
	var equipment: Array[Dictionary] = []
	game.shop_panel.details.show_weapon(weapon.data, weapon.tier, game.player, true, equipment)
	game.shop_panel.details.show_affixes(weapon, game.player.stats)
	var rows: VBoxContainer = game.shop_panel.details.affix_rows
	var rarity_label := rows.get_child(-1) as Label
	assert(rarity_label.text == "Legendär III+" and rarity_label.get_theme_color("font_color") == DentiRarity.color_for(4), "weapon details use wrong rarity color")
	assert(WeaponAffixes.comparison(weapon, chest.options[0], game.player.stats, -1).contains("Legendär III+"))
	var offer := {"id": "ice", "rarity": 2, "damage": 7.0}
	var original_offer := offer.duplicate(true)
	var brush_text := WeaponAffixes.comparison(weapon, offer, game.player.stats, -1)
	loadout.acquire(WeaponCatalog.by_id(&"uv_lamp"))
	var lamp: WeaponInstance = loadout.equipped()[-1]
	var lamp_text := WeaponAffixes.comparison(lamp, offer, game.player.stats, -1)
	assert(brush_text.get_slice("\n", 0) == "Fundwert: +7.0 Basisschaden" and brush_text.get_slice("\n", 0) == lamp_text.get_slice("\n", 0), "weapon selection changes advertised fund value")
	assert(brush_text.get_slice("\n", 1) != lamp_text.get_slice("\n", 1) and lamp_text.contains("Auf dieser Waffe:"), "weapon-specific damage is not identified separately")
	assert(offer == original_offer, "preview changed the drop")
	var upgrade_text := WeaponAffixes.comparison(weapon, chest.options[0], game.player.stats, -1)
	assert(upgrade_text.begins_with("Fundwert: +25.0 Basisschaden") and upgrade_text.get_slice("\n", 1).contains("→"), "upgrade preview lost fixed fund or before/after damage")
	session.clear_run()
	paused = false
	print("PASS ranked affixes, upgrades, matching rewards, migration and Mk colors")
	quit(0)
