extends "res://tests/support/test_runtime.gd"
## Weapon meta unlocks: rules, retroactive seals, starter filters, shop pool,
## unlock notice state and the locked preview in the weapon selection.

const BASE: Array[StringName] = [&"magic_toothbrush", &"turbo_drill", &"floss_whip", &"water_jet",
	&"toothpick_spear", &"amalgam_slingshot", &"plaque_scaler", &"fluoride_sprayer"]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)


func _run() -> void:
	_rules()
	await _game_flow()
	await _selection_view()
	if failures.is_empty(): print("weapon unlocks ok")
	finish(1 if not failures.is_empty() else 0)


func _rules() -> void:
	var exam := WeaponMasteries.by_id(&"exam").flag
	var bronze := WeaponMasteries.by_id(&"bronze").flag
	var locked_count := 0
	for weapon in WeaponCatalog.ALL:
		var open := WeaponUnlocks.unlocked(weapon.id, {})
		_check(open == (weapon.id in BASE), "unexpected fresh unlock state: " + str(weapon.id))
		if not open: locked_count += 1
	_check(locked_count == WeaponUnlocks.ALL.size() and locked_count == 10, "every rule should lock exactly one standard weapon")
	var reachable: Array[StringName] = BASE.duplicate()
	for pass_index in WeaponUnlocks.ALL.size():
		for entry in WeaponUnlocks.ALL:
			_check(WeaponCatalog.by_id(entry.weapon_id) in WeaponCatalog.ALL and WeaponMasteries.by_id(entry.mastery_id) != null, "invalid rule " + str(entry.weapon_id))
			for source in entry.source_ids:
				_check(WeaponCatalog.by_id(source) in WeaponCatalog.ALL and source != entry.weapon_id, "invalid source for " + str(entry.weapon_id))
				if source in reachable and entry.weapon_id not in reachable: reachable.append(entry.weapon_id)
	_check(reachable.size() == WeaponCatalog.ALL.size(), "some weapons can never be unlocked")
	for profile in ClassCatalog.profiles:
		var starts := 0
		for weapon in WeaponCatalog.ALL:
			if WeaponEligibility.starter(weapon, profile, profile.root_capacity) and WeaponUnlocks.unlocked(weapon.id, {}): starts += 1
		_check(starts >= 2, "class lacks fresh starters: " + str(profile.id))
	# Chains: exam on the toothbrush opens the mirror; Bronze on the mirror opens UV.
	_check(WeaponUnlocks.unlocked(&"enamel_mirror", {"magic_toothbrush": exam}), "exam seal did not unlock the mirror")
	_check(not WeaponUnlocks.unlocked(&"uv_lamp", {"enamel_mirror": exam}), "UV opened without Bronze")
	_check(WeaponUnlocks.unlocked(&"uv_lamp", {"enamel_mirror": exam | bronze}), "Bronze on the mirror did not unlock UV")
	_check(WeaponUnlocks.unlocked(&"water_turbine", {"fluoride_sprayer": bronze}), "either source should unlock the turbine")
	# Only the chain counts; an own seal from before the unlocks does not open a weapon.
	_check(not WeaponUnlocks.unlocked(&"uv_lamp", {"uv_lamp": exam | bronze, "prophylaxis_polisher": exam}), "own seal bypassed the UV chain")
	var gained := WeaponUnlocks.newly_unlocked({}, {"turbo_drill": exam})
	_check(gained == [&"cavity_grinder", &"interdental_brush"], "unexpected new unlocks: " + str(gained))
	_check(WeaponUnlocks.newly_unlocked({"turbo_drill": exam}, {"turbo_drill": exam | bronze}).is_empty(), "repeated seals reported unlocks again")
	var text := WeaponUnlocks.requirement(&"uv_lamp")
	_check(text.contains("Bronze") and text.contains("Schmelzspiegel") and text.contains("Polierer"), "UV requirement unclear: " + text)
	_check(WeaponUnlocks.requirement(&"turbo_drill") == "", "base weapon reported a requirement")


func _game_flow() -> void:
	var session: Node = root.get_node("GameSession")
	_check(not session.weapon_locks_enabled, "scripted runs must keep the full catalog")
	_check(session.weapon_unlocked(&"uv_lamp"), "disabled locks still filtered UV")
	session.weapon_locks_enabled = true
	session.save_path = "user://weapon_unlocks_test_run.json"
	session.progression_path = "user://weapon_unlocks_test_progression.cfg"
	session.report_dir = "user://weapon_unlocks_test_reports"
	DirAccess.remove_absolute(session.progression_path)
	session.load_progression()
	session.resume_requested = false
	session.selected_story_mode = false
	session.clear_run()
	_check(not session.weapon_unlocked(&"uv_lamp") and session.weapon_unlocked(&"magic_toothbrush"), "fresh profile unlock state wrong")
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	for weapon in game.choice_panel.starter_options:
		_check(weapon.id in BASE, "locked weapon offered as legacy starter: " + str(weapon.id))
	_check(not game.choice_panel.starter_options.is_empty(), "no starters offered")
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.coins = 1000000
	game.wave.current_wave = 6
	game._open_shop()
	var seen_weapon := false
	for draw in 60:
		for offer: ShopOfferData in game.shop.offers:
			if offer == null or offer.weapon_data == null: continue
			seen_weapon = true
			_check(session.weapon_unlocked(offer.id), "shop offered locked weapon: " + str(offer.id))
		game.shop.reroll(game.wave.current_wave, 0.0, game.player.loadout, game.items)
	_check(seen_weapon, "shop never rolled a weapon")
	# A locked weapon already owned (e.g. older save) stays offered for fusion.
	game.player.loadout.restore([{"id": "uv_lamp", "tier": 1}])
	var owned_offered := false
	for draw in 120:
		for offer: ShopOfferData in game.shop.offers:
			if offer != null and offer.id == &"uv_lamp": owned_offered = true
		game.shop.reroll(game.wave.current_wave, 0.0, game.player.loadout, game.items)
	_check(owned_offered, "owned locked weapon vanished from the shop")
	# Seals earned in a run report the weapons they unlock, once, and survive saves.
	var mastery := RunWeaponMastery.new()
	mastery.begin(&"magic_toothbrush", true)
	mastery.record(session, &"boss", &"normal", 5)
	_check(mastery.unlocks == ["enamel_mirror"] and mastery.pending_unlocks == ["enamel_mirror"], "exam unlock not queued: " + str(mastery.unlocks))
	_check(session.weapon_unlocked(&"enamel_mirror"), "unlock not persisted in the session")
	mastery.record(session, &"boss", &"normal", 5)
	_check(mastery.unlocks.size() == 1, "repeated boss duplicated the unlock")
	game.weapon_mastery = mastery
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	_check(not RunSaveData.normalize(snapshot).is_empty(), "save with unlock state was rejected")
	var broken := snapshot.duplicate(true)
	broken.weapon_mastery.pending_unlocks = "uv_lamp"
	_check(RunSaveData.normalize(broken).is_empty(), "malformed unlock state reached a typed restore")
	var restored := RunWeaponMastery.new()
	restored.restore(mastery.save_data())
	_check(restored.unlocks == ["enamel_mirror"] and restored.take_pending_unlocks() == ["enamel_mirror"] and restored.pending_unlocks.is_empty(), "unlock state lost on resume")
	session.load_progression()
	_check(session.weapon_unlocked(&"enamel_mirror") and not session.weapon_unlocked(&"uv_lamp"), "unlock not stored in the progression file")
	var awards: Array[String] = ["exam"]
	var unlocks: Array[String] = ["enamel_mirror"]
	game.mastery_notice.present(&"magic_toothbrush", awards, unlocks)
	_check(game.mastery_notice.visible and game.mastery_notice.source_weapon.contains("Schmelzspiegel"), "notice does not name the unlocked weapon")
	game.queue_free()
	await process_frame
	session.weapon_locks_enabled = false
	session.clear_run()
	DirAccess.remove_absolute(session.progression_path)


func _selection_view() -> void:
	var view := WeaponSelection.new()
	view.size = Vector2(900, 520)
	root.add_child(view)
	await process_frame
	var locked := {&"uv_lamp": WeaponUnlocks.requirement(&"uv_lamp")}
	var options: Array[WeaponData] = [WeaponCatalog.by_id(&"turbo_drill"), WeaponCatalog.by_id(&"uv_lamp")]
	view.show_options(options, &"uv_lamp", locked)
	_check(view.selected_id == &"" and view.shown != null and view.shown.id == &"uv_lamp", "locked draft selection became a confirmable choice")
	_check(view.roots_label.text == locked[&"uv_lamp"] and not view.stat_buttons[0].visible, "locked preview should show only its requirement")
	_check(view.icon_buttons[1].get_node("Lock").visible and not view.icon_buttons[0].has_node("Lock"), "lock markers wrong")
	_check(view.selected_weapon() == null, "locked weapon returned as selected")
	view.select_weapon(0)
	_check(view.selected_id == &"turbo_drill" and view.stat_buttons[0].visible and view.art.modulate == Color.WHITE, "unlocked selection did not restore the preview")
	view.select_weapon(1)
	_check(view.selected_id == &"" and view.icon_buttons[1].selected and not view.icon_buttons[0].selected, "locked inspection lost its highlight")
	view.queue_free()
	await process_frame
