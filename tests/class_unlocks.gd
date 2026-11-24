extends "res://tests/support/test_runtime.gd"
## Class meta unlocks: element rules, requirement texts, recording at run end
## (death and victory), the locked class selection and the run-end notice.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_rules()
	await _flow()
	if failures.is_empty(): print("class unlocks ok")
	finish_checks()


func _weapon(id: StringName, element: String = "") -> WeaponInstance:
	var weapon := WeaponInstance.new()
	weapon.data = WeaponCatalog.by_id(id)
	if element != "": weapon.affixes.assign([{"id": element, "rarity": 1, "damage": 3.0}])
	return weapon


func _rules() -> void:
	check(ClassUnlocks.rule(ClassCatalog.DEFAULT.id) == null, "Good Old Molar must be open from the start")
	for profile in ClassCatalog.profiles:
		if profile != ClassCatalog.DEFAULT:
			check(ClassUnlocks.rule(profile.id) != null, "class has no unlock rule: " + str(profile.id))
	check(ClassUnlocks.requirement(&"rinser") == "Run ab Welle 10 mit einer Wasser-Waffe beenden", "rinser text: " + ClassUnlocks.requirement(&"rinser"))
	check(ClassUnlocks.requirement(&"tooth_fairy").contains("Elektro-Waffe"), "fairy text: " + ClassUnlocks.requirement(&"tooth_fairy"))
	check(ClassUnlocks.requirement(&"necrodent").begins_with("Welle 20 auf Normal oder höher gewinnen") and ClassUnlocks.requirement(&"necrodent").contains("Blutungs- oder Gift-Waffe"), "necrodent text: " + ClassUnlocks.requirement(&"necrodent"))
	var jet := _weapon(&"water_jet")
	var mirror := _weapon(&"enamel_mirror")
	var fiery := _weapon(&"turbo_drill", "fire")
	var plain := _weapon(&"turbo_drill")
	check(ClassUnlocks.weapon_elements(jet) == [&"water"] and ClassUnlocks.weapon_elements(mirror) == [&"light"], "damage types did not count as elements")
	check(ClassUnlocks.weapon_elements(fiery) == [&"fire"] and ClassUnlocks.weapon_elements(plain).is_empty(), "enchantments did not count as elements")
	var weapons: Array[WeaponInstance] = [plain, jet]
	check(ClassUnlocks.earned([], weapons, 10, false, &"easy") == ["rinser"], "a water weapon at wave 10 did not open the Spültechniker")
	check(ClassUnlocks.earned([], weapons, 9, false, &"normal").is_empty(), "an early death opened a class")
	check(ClassUnlocks.earned(["rinser"], weapons, 12, false, &"normal").is_empty(), "an open class was reported again")
	var poisoned: Array[WeaponInstance] = [_weapon(&"floss_whip", "poison")]
	check(ClassUnlocks.earned([], poisoned, 20, false, &"hard") == ["assassin"], "a lost wave-20 run opened Nekrodent")
	check(ClassUnlocks.earned([], poisoned, 20, true, &"easy") == ["assassin"], "an Easy victory opened Nekrodent")
	check(ClassUnlocks.earned([], poisoned, 20, true, &"normal") == ["assassin", "necrodent"], "a poisoned Normal victory did not open Nekrodent")
	for weapon in [jet, mirror, fiery, plain] + poisoned: weapon.free()


func _flow() -> void:
	var session: Node = root.get_node("GameSession")
	check(session.class_unlocked(&"ember") and not session.class_unlocked(&"necrodent"), "scripted runs must keep regular classes open and Nekrodent locked")
	session.weapon_locks_enabled = true
	session.save_path = "user://class_unlocks_test_run.json"
	session.progression_path = "user://class_unlocks_test_progression.cfg"
	session.report_dir = "user://class_unlocks_test_reports"
	DirAccess.remove_absolute(session.progression_path)
	session.load_progression()
	session.resume_requested = false
	session.clear_run()
	check(session.class_unlocked(ClassCatalog.DEFAULT.id) and not session.class_unlocked(&"ember"), "fresh profile unlock state wrong")
	var view := ClassSelection.new()
	root.add_child(view)
	await process_frame
	var details: Array[String] = []
	view.details_requested.connect(func(title: String, body: String) -> void: details.assign([title, body]))
	var ember_index := ClassCatalog.profiles.find(ClassCatalog.by_id(&"ember"))
	view.buttons[ember_index].pressed.emit()
	check(view.buttons[ember_index].get_node("Lock").visible and view.selected_id == ClassCatalog.DEFAULT.id, "locked class became selectable")
	check(details.size() == 2 and details[1].contains("Feuer-Waffe"), "locked class shows no requirement")
	check(not view.buttons[0].has_node("Lock"), "Good Old Molar shows a lock")
	view.queue_free()
	# A locked class requested for a new run falls back to Good Old Molar.
	session.pending_start_class_id = &"ember"
	session.pending_start_weapon_id = &"turbo_drill"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	check(game.player.stats.class_data == ClassCatalog.DEFAULT, "a locked class started a run")
	game.wave.set_process(false)
	game.player.loadout.equipped()[0].affixes.assign([{"id": "fire", "rarity": 1, "damage": 3.0}])
	game.wave.current_wave = 12
	game.player.stats.health = 0.0
	game._on_player_died()
	session.load_progression()
	check(session.class_unlocked(&"ember") and session.progression_data.unlocked_classes == ["ember"], "a fiery death at wave 12 did not persist the unlock")
	var notices: RunEndNotices = game.choice_panel.end_notices
	var found := false
	for card in notices.notices.get_children():
		if _texts(card).contains("Glutzahn") and _texts(card).contains("Klasse freigeschaltet"): found = true
	check(found, "run end did not announce the new class")
	game.queue_free()
	paused = false
	await process_frame
	# Testmenü: unlock everything in the local profile.
	check(session.debug_unlock_all() == OK, "unlock all failed")
	for profile in ClassCatalog.profiles: check(session.class_unlocked(profile.id), "unlock all missed " + str(profile.id))
	for weapon in WeaponCatalog.ALL: check(session.weapon_unlocked(weapon.id), "unlock all missed " + str(weapon.id))
	session.weapon_locks_enabled = false
	session.clear_run()
	DirAccess.remove_absolute(session.progression_path)


func _texts(node: Node) -> String:
	var result := ""
	if node is Label: result += node.text + "\n"
	for child in node.get_children(): result += _texts(child)
	return result
