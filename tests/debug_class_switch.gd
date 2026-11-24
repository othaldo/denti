extends "res://tests/support/test_runtime.gd"
## Cheat-menu class switch: class offsets swap cleanly, earned stats, weapons
## and items stay, skills/talents follow the new class and the run still saves
## and resumes.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_debug_class_switch.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	var menu: DebugCheatMenu = game.get_node("DebugCheatMenu")
	var cheats: DebugRunControls = menu.controls
	var stats: PlayerStats = game.player.stats
	var molar := ClassCatalog.DEFAULT
	var ember := ClassCatalog.by_id(&"ember")
	var assassin := ClassCatalog.by_id(&"assassin")
	check(stats.class_data == molar, "Runs start as Good Old Molar here")

	# Earned stats survive; only the class offsets change.
	stats.load_save_data(stats.to_save_data(), stats.class_save_data())
	cheats.set_stats({"armor": 7.0})
	var armor_before := stats.raw_stat(&"armor")
	var melee_before := stats.raw_stat(&"melee_damage")
	var health_before := stats.raw_stat(&"max_health")
	var roots_before: int = stats.root_capacity
	var weapons_before: int = game.player.loadout.equipped().size()
	game.items.acquire(ItemCatalog.ALL.filter(func(item: ShopOfferData) -> bool: return item.weapon_data == null)[0])
	var items_before: Dictionary = game.items.owned.duplicate()
	check(cheats.set_class(&"ember") == "", "Switching to Ember must work")
	check(stats.class_data == ember, "Class must be Ember")
	check(is_equal_approx(stats.raw_stat(&"armor"), armor_before), "Earned armor must stay")
	check(is_equal_approx(stats.raw_stat(&"melee_damage"), melee_before + float(ember.starting_stats.get("melee_damage", 0.0))), "Ember melee offset must apply")
	check(is_equal_approx(stats.raw_stat(&"max_health"), health_before + float(ember.starting_stats.get("max_health", 0.0))), "Ember health offset must apply")
	check(stats.root_capacity == roots_before + ember.root_capacity - molar.root_capacity, "Roots must follow the class difference")
	check(game.player.loadout.equipped().size() == weapons_before and game.items.owned == items_before, "Weapons and items must stay")
	check(game.player.dash.config == ember.dash_config(), "Dash must use the new class")
	check(game.player.class_combat.profile == ember, "Class combat must follow the switch")
	check(game.talents.enabled == (ember.talent_tree != null), "Class talents must be available")
	var ember_module: ClassSkillModule = null
	for module in game.player.skill_modules:
		if module.class_id() == &"ember": ember_module = module
	check(ember_module != null and ember_module.active(), "Ember skills must become active")

	# Switching back restores the original offsets exactly.
	check(cheats.set_class(&"good_old_molar") == "", "Switching back must work")
	check(is_equal_approx(stats.raw_stat(&"melee_damage"), melee_before) and is_equal_approx(stats.raw_stat(&"max_health"), health_before), "Offsets must undo exactly")
	check(stats.root_capacity == roots_before, "Roots must return")
	check(cheats.set_class(&"good_old_molar") == "Bereits aktiv", "Same class must be reported")
	check(cheats.set_class(&"nope") != "", "Unknown classes must be rejected")

	# Old talent ranks would invalidate the save for the new tree.
	# The assassin only wields contact weapons: others leave, the run stays saveable.
	cheats.add_weapon(&"water_jet", 1)
	cheats.add_weapon(&"turbo_drill", 1)
	check(cheats.set_class(&"assassin") == "", "Switching to Assassin must work")
	for weapon: WeaponInstance in game.player.loadout.equipped():
		check(WeaponEligibility.allowed(weapon.data, assassin), "Remaining weapons must fit the class: " + str(weapon.data.id))
	check(not cheats.removed_weapons.is_empty(), "Removed weapons must be reported")
	check(game.player.loadout.equipped().any(func(weapon: WeaponInstance) -> bool: return weapon.data.id == &"turbo_drill"), "Fitting weapons must stay")
	game._save_run()
	check(not session.load_run().is_empty(), "An assassin run with contact weapons must save")
	var first := assassin.talent_tree.nodes[0]
	game.talents.ranks[str(first.id)] = 1
	game.talents.spent = maxi(game.talents.spent, first.cost)
	game.level = maxi(game.level, game.talents.spent + 1)  # earned points need levels
	check(cheats.set_class(&"frost_warden") == "", "Switching with talent ranks must work")
	check(game.talents.ranks.is_empty(), "Ranks of the old tree must be dropped")
	game._save_run()
	var saved: Dictionary = session.load_run()
	check(not saved.is_empty(), "The switched run must save and validate")
	check(TalentProgression.valid(saved.get("talents", {}), ClassCatalog.by_id(&"frost_warden")), "Saved talents must be valid for the new class")

	# Blocked during an open level-up.
	game.rewards.step = PostWaveRewards.Step.LEVELS
	check(cheats.set_class(&"ember") == "Erst Aufstieg abschließen", "Level-up step must block switching")
	game.rewards.step = PostWaveRewards.Step.COMBAT

	game.starter_pending = true
	check(cheats.set_class(&"ember") == "Erst Startwaffe wählen", "Starter selection must block switching")
	game.starter_pending = false

	# Menu control.
	menu.open_menu()
	await process_frame
	var target := ClassCatalog.profiles.find(ember)
	menu.class_select.select(target)
	menu._set_class()
	check(stats.class_data == ember and menu.status.text.contains(ember.display_name), "Menu must switch the class")
	check(menu.class_select.selected == target, "Menu must show the active class")
	# Relikte tab: grant and remove any relic.
	check(menu.relic_buttons.size() == RelicCatalog.CATALOG.size(), "Every relic needs a row in the Relikte tab")
	menu._toggle_relic(&"heat_stone")
	check(game.relics.has_relic(&"heat_stone") and menu.relic_buttons[&"heat_stone"].text == "Entfernen", "Menu must grant a relic")
	check(session.load_run().get("relics", {}).get("owned", []).has("heat_stone"), "Granted relic must reach the save")
	menu._toggle_relic(&"heat_stone")
	check(game.relics.owned.is_empty() and menu.relic_buttons[&"heat_stone"].text == "+", "Menu must remove relics again")
	menu.close_menu()

	session.clear_run()
	finish_checks()
