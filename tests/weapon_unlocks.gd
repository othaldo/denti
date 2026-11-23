extends "res://tests/support/test_runtime.gd"
## Weapon meta unlocks through lifetime counters and class victories: rules
## without chains, progress texts, the run-side counters (wave end, death,
## resume), near goals, shop pool, banner, run-end cards and "Neu" badges.

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
	var fresh := ProgressionStore.new()
	var locked_count := 0
	for weapon in WeaponCatalog.ALL:
		var open := WeaponUnlocks.unlocked(weapon.id, fresh)
		_check(open == (weapon.id in BASE), "unexpected fresh unlock state: " + str(weapon.id))
		if not open: locked_count += 1
	_check(locked_count == WeaponUnlocks.ALL.size() and locked_count == 10, "every rule should lock exactly one standard weapon")
	for entry in WeaponUnlocks.ALL:
		_check(WeaponCatalog.by_id(entry.weapon_id) in WeaponCatalog.ALL, "invalid rule " + str(entry.weapon_id))
		# No chains: a rule names a lifetime counter or a class, never a weapon.
		var counter_rule: bool = str(entry.counter) in MetaCounters.KEYS and entry.amount > 0 and entry.class_victory == &""
		var class_rule: bool = entry.counter == &"" and ClassCatalog.by_id(entry.class_victory) != null
		_check(counter_rule != class_rule, "rule must be either a counter or a class victory: " + str(entry.weapon_id))
	for profile in ClassCatalog.profiles:
		if profile.exclusive_weapon_id != &"": continue
		var starts := 0
		for weapon in WeaponCatalog.ALL:
			if WeaponEligibility.starter(weapon, profile, profile.root_capacity) and WeaponUnlocks.unlocked(weapon.id, fresh): starts += 1
		_check(starts >= 1, "class lacks fresh starters: " + str(profile.id))
	var progress := ProgressionStore.new()
	progress.counters["kills"] = 499
	_check(not WeaponUnlocks.unlocked(&"cavity_grinder", progress), "Karies-Fräse opened before 500 kills")
	_check(WeaponUnlocks.requirement(&"cavity_grinder", progress) == "499 / 500 Kills", "progress text: " + WeaponUnlocks.requirement(&"cavity_grinder", progress))
	_check(WeaponUnlocks.requirement(&"enamel_mirror") == "2.500 Kills", "goal text: " + WeaponUnlocks.requirement(&"enamel_mirror"))
	_check(WeaponUnlocks.requirement(&"interdental_brush") == "Einmal ausfallen", "first death text")
	_check(WeaponUnlocks.requirement(&"water_turbine") == "Welle 20 gewinnen mit Spültechniker", "class victory text: " + WeaponUnlocks.requirement(&"water_turbine"))
	var after := progress.meta_snapshot()
	after.counters["kills"] = 500
	after.class_victories.append("rinser")
	_check(WeaponUnlocks.newly_unlocked(progress, after) == [&"cavity_grinder", &"water_turbine"], "unexpected new unlocks: " + str(WeaponUnlocks.newly_unlocked(progress, after)))
	_check(MetaCounters.number(12345) == "12.345" and MetaCounters.number(500) == "500", "number formatting")


func _game_flow() -> void:
	var session: Node = root.get_node("GameSession")
	_check(not session.weapon_locks_enabled, "scripted runs must keep the full catalog")
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
	# Session: counters add up, report opened weapons once and mark them fresh.
	_check(session.add_meta_progress({"kills": 300}).is_empty(), "300 kills opened a weapon")
	_check(session.add_meta_progress({"kills": 200, "bosses": 3}) == ["cavity_grinder", "crown_launcher"], "counter unlocks not reported")
	_check(session.add_meta_progress({"kills": 10}).is_empty(), "an open weapon was reported again")
	_check(session.add_meta_progress({}, &"tooth_fairy") == ["uv_lamp"], "class victory did not open its weapon")
	_check(session.is_fresh("weapon:uv_lamp"), "new weapon has no Neu badge")
	session.mark_seen("weapon:uv_lamp")
	_check(not session.is_fresh("weapon:uv_lamp"), "Neu badge stayed after trying the weapon")
	var near: Array[Dictionary] = session.near_unlocks()
	_check(near.size() == 2 and near[0].id == "mouthwash_mortar" and near[1].id == "enamel_mirror" and near[1].current == 510, "near goals not sorted by progress: " + str(near))
	session.load_progression()
	_check(int(session.progression_data.counters.get("kills", 0)) == 510 and session.weapon_unlocked(&"uv_lamp"), "counters not stored in the progression file")
	# A run: kills are pending during the wave, flushed after it and on death.
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	for weapon in game.choice_panel.starter_options:
		_check(session.weapon_unlocked(weapon.id), "locked weapon offered as legacy starter: " + str(weapon.id))
	choose_panel(game.choice_panel, 0)
	game.wave.set_process(false)
	_check(game.weapon_mastery.eligible, "ranked run expected")
	for kill in 4: game.meta_progress.record_kill(WaveController.PLAQUE)
	game.meta_progress.record_kill(WaveController.BOSS)
	game.meta_progress.record_coins(7)
	_check(int(session.progression_data.counters.get("kills", 0)) == 510, "kills reached the profile before the wave ended")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	_check(not RunSaveData.normalize(snapshot).is_empty(), "save with meta progress was rejected")
	var broken := snapshot.duplicate(true)
	broken.meta_progress.pending = "lots"
	_check(RunSaveData.normalize(broken).is_empty(), "malformed meta progress reached a typed restore")
	var restored := RunMetaProgress.new()
	restored.restore(snapshot.meta_progress)
	_check(restored.pending == {"kills": 5, "bosses": 1, "coins": 7}, "pending counts lost on resume: " + str(restored.pending))
	game.meta_progress.flush(session, true)
	_check(int(session.progression_data.counters.get("kills", 0)) == 515 and game.meta_progress.pending.is_empty(), "wave flush lost kills")
	# Shop: locked weapons never appear, owned locked weapons stay for fusion.
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
	game.player.loadout.restore([{"id": "fluoride_rocket", "tier": 1}])
	var owned_offered := false
	for draw in 120:
		for offer: ShopOfferData in game.shop.offers:
			if offer != null and offer.id == &"fluoride_rocket": owned_offered = true
		game.shop.reroll(game.wave.current_wave, 0.0, game.player.loadout, game.items)
	_check(owned_offered, "owned locked weapon vanished from the shop")
	# Banner after a wave without a seal still names the new weapon.
	var unlocks: Array[String] = ["cavity_grinder"]
	var no_awards: Array[String] = []
	game.mastery_notice.present(&"magic_toothbrush", no_awards, unlocks)
	_check(game.mastery_notice.visible and game.mastery_notice.source_title == "Waffe freigeschaltet" and game.mastery_notice.source_weapon.contains("Karies-Fräse"), "unlock banner missing")
	# First death: opens the Interdental-Bürste and shows it plus near goals.
	game.shop_panel.visible = false
	game.wave.current_wave = 4
	game.player.stats.health = 0.0
	game._on_player_died()
	_check(session.weapon_unlocked(&"interdental_brush") and int(session.progression_data.counters.get("deaths", 0)) == 1, "first death did not open the brush")
	var texts := _texts(game.choice_panel.end_notices)
	_check(texts.contains("Interdental-Bürste") and texts.contains("Waffe freigeschaltet"), "run end lacks the new weapon")
	_check(texts.contains("Fast geschafft") and game.choice_panel.end_notices.find_child("GoalProgress", true, false) != null, "run end lacks near goals")
	game.queue_free()
	paused = false
	await process_frame
	session.weapon_locks_enabled = false
	session.clear_run()
	DirAccess.remove_absolute(session.progression_path)


func _selection_view() -> void:
	var session: Node = root.get_node("GameSession")
	var view := WeaponSelection.new()
	view.size = Vector2(900, 520)
	root.add_child(view)
	await process_frame
	session.progression_data.fresh_unlocks.assign(["weapon:turbo_drill"])
	var locked := {&"uv_lamp": WeaponUnlocks.requirement(&"uv_lamp")}
	var options: Array[WeaponData] = [WeaponCatalog.by_id(&"turbo_drill"), WeaponCatalog.by_id(&"uv_lamp")]
	view.show_options(options, &"uv_lamp", locked)
	_check(view.selected_id == &"" and view.shown != null and view.shown.id == &"uv_lamp", "locked draft selection became a confirmable choice")
	_check(view.roots_label.text == locked[&"uv_lamp"] and not view.stat_buttons[0].visible, "locked preview should show only its requirement")
	_check(view.icon_buttons[1].get_node("Lock").visible and not view.icon_buttons[0].has_node("Lock"), "lock markers wrong")
	_check(view.icon_buttons[0].has_node(UnlockBadge.NAME) and not view.icon_buttons[1].has_node(UnlockBadge.NAME), "Neu badge wrong")
	view.select_weapon(0)
	_check(view.selected_id == &"turbo_drill" and view.stat_buttons[0].visible, "unlocked selection did not restore the preview")
	session.progression_data.fresh_unlocks.clear()
	view.queue_free()
	await process_frame


func _texts(node: Node) -> String:
	var result := ""
	if node is Label: result += node.text + "\n"
	for child in node.get_children(): result += _texts(child)
	return result
