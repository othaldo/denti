extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_affix_progression.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
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
	var rarity_colors: Array[Color] = []
	for index in 3:
		var rarity := int(chest.options[index].rarity)
		var rarity_label: Label = panel.buttons[index].rarity_label
		var color := rarity_label.get_theme_color("font_color")
		assert(rarity_label.text.to_lower().contains(DentiRarity.name_for(rarity).to_lower()) and not rarity_colors.has(color), "capsule choices lost their distinct named rarity")
		rarity_colors.append(color)
	var label: Label = panel.replacement_buttons[0].get_meta("rarity_label")
	assert(label.get_theme_color("font_color") == DentiUIStyle.rarity_text_color(4) and label.text == "Legendär III+", "replacement rarity/progress missing")
	var equipment: Array[Dictionary] = []
	game.shop_panel.details.show_weapon(weapon.data, weapon.tier, game.player, true, equipment)
	game.shop_panel.details.show_affixes(weapon, game.player.stats)
	var rows: VBoxContainer = game.shop_panel.details.affix_rows
	var rarity_label := rows.get_child(-1) as Label
	assert(rarity_label.text == "Legendär III+" and rarity_label.get_theme_color("font_color") == DentiUIStyle.rarity_text_color(4), "weapon details use wrong rarity color")
	assert(AffixPresentation.comparison(weapon, chest.options[0], game.player.stats, -1).contains("Legendär III+"))
	var offer := {"id": "ice", "rarity": 2, "damage": 7.0}
	var original_offer := offer.duplicate(true)
	var brush_text := AffixPresentation.comparison(weapon, offer, game.player.stats, -1)
	loadout.acquire(WeaponCatalog.by_id(&"uv_lamp"))
	var lamp: WeaponInstance = loadout.equipped()[-1]
	var lamp_text := AffixPresentation.comparison(lamp, offer, game.player.stats, -1)
	assert(brush_text.get_slice("\n", 0) == "Fundwert: +7.0 Basisschaden" and brush_text.get_slice("\n", 0) == lamp_text.get_slice("\n", 0), "weapon selection changes advertised fund value")
	assert(brush_text.get_slice("\n", 1) != lamp_text.get_slice("\n", 1) and lamp_text.contains("Auf dieser Waffe:"), "weapon-specific damage is not identified separately")
	assert(offer == original_offer, "preview changed the drop")
	var upgrade_text := AffixPresentation.comparison(weapon, chest.options[0], game.player.stats, -1)
	assert(upgrade_text.begins_with("Fundwert: +25.0 Basisschaden") and upgrade_text.get_slice("\n", 1).contains("->"), "upgrade preview lost fixed fund or before/after damage")
	# Check the bundled font itself: system fallback can hide missing glyphs on desktop.
	var glyph_chest := {"kind": "affix", "options": [chest.options[0], {"id": "slot", "rarity": 3}, {"id": "mk", "rarity": 4}], "scrap_coins": 5}
	panel.show_chest(glyph_chest, loadout, game.player.stats, 5)
	assert(not panel.replacement.visible, "upgrades with no new effects waste space on a replacement selector")
	for card in panel.buttons:
		for text in [card.effect_label.text, card.tooltip_text]:
			for index in text.length():
				var code: int = text.unicode_at(index)
				if code > 32 and not DentiUIStyle.FONT.has_char(code):
					push_error("Affix card uses an unsupported glyph: U+%04X" % code)
					finish(1)
					return
	# Names belong to individual weapons, and use development rather than raw
	# values (a legacy damage roll must not beat a higher-tier tempo effect).
	var base_name := WeaponCatalog.by_id(&"magic_toothbrush").display_name
	loadout.restore([
		{"id": "magic_toothbrush", "tier": 2, "affix_slots": 4, "affixes": [
			{"id": "fire", "rarity": 1, "damage": 999}, {"id": "ice", "rarity": 2, "damage": 7},
			{"id": "tempo", "rarity": 3, "damage": 14}, {"id": "poison", "rarity": 1, "damage": 3}]},
		{"id": "magic_toothbrush", "tier": 2}])
	weapon = loadout.equipped()[0]
	assert(WeaponPresentation.weapon_name(weapon) == base_name + " der Eile")
	assert(WeaponPresentation.weapon_name(loadout.equipped()[1]) == base_name and weapon.data.display_name == base_name, "instance name contaminated shared weapon data")
	assert(WeaponPresentation.enchantment_list(weapon).contains("Feuer I") and WeaponPresentation.enchantment_list(weapon).contains("Angriffstempo I"))
	assert(WeaponAffixes.apply(weapon, {"id": "ice", "rarity": 4, "damage": 25}))
	assert(WeaponPresentation.weapon_name(weapon) == base_name + " des Frosts", "stronger enchantment did not update the name")
	loadout.restore(loadout.save_data())
	weapon = loadout.equipped()[0]
	assert(WeaponPresentation.weapon_name(weapon) == base_name + " des Frosts", "resume changed the enchanted name")
	assert(WeaponAffixes.apply(weapon, {"id": "bleed", "rarity": 1, "damage": 3}, 1))
	assert(WeaponPresentation.weapon_name(weapon) == base_name + " der Eile", "replacing the dominant enchantment left a stale name")
	assert(loadout.merge(0) and WeaponPresentation.weapon_name(loadout.equipped()[0]) == base_name + " der Eile", "fusion lost the enchanted name")
	for data in WeaponAffixes.ALL:
		assert(not data.name_suffix.is_empty())
		var option := {"id": str(data.id), "rarity": 2, "damage": 7}
		var compact := AffixPresentation.comparison(weapon, option, game.player.stats, -1, true)
		assert(compact.begins_with(AffixPresentation.effect_description(data.id)) and not compact.contains("Fundwert:"))
		assert(AffixPresentation.comparison(weapon, option, game.player.stats, -1).contains("Fundwert: +7.0" if data.effect_kind == "damage" else "Fundstärke: 7.0"))
	assert(AffixPresentation.effect_description(&"tempo").contains("schneller"))
	game.shop_panel.details.show_weapon(weapon.data, weapon.tier, game.player, true, equipment)
	game.shop_panel.details.show_affixes(weapon, game.player.stats)
	assert(game.shop_panel.details.heading.text.begins_with(WeaponPresentation.weapon_name(weapon)))
	session.clear_run()
	paused = false
	print("PASS ranked affixes, upgrades, matching rewards, migration and Mk colors")
	finish(0)
