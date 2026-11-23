extends "res://tests/support/test_runtime.gd"

const NECRO := &"necrodent"
const STAFF := &"extraction_staff"

var game: Node2D
var session: Node
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _start_game(id: StringName, weapon: StringName = &"turbo_drill") -> void:
	session.pending_start_class_id = id
	session.pending_start_weapon_id = weapon
	session.pending_talent_run = true
	game = preload("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.wave.set_process(false)
	game.player.set_physics_process(false)


func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://necrodent_run.json"
	session.progression_path = "user://necrodent_progression.cfg"
	session.report_dir = "user://necrodent_reports"
	DirAccess.remove_absolute(session.progression_path)
	session.clear_run()
	session.load_progression()
	await _check_unlock()
	await _check_local_unlock()
	await _check_combat()
	await _check_target_coordination()
	await _check_branches()
	await _check_tooth_health()
	await _check_shop()
	await _check_enchantment_details()
	_check_recruitment_comparison()
	game.queue_free()
	await process_frame
	session.clear_run()
	DirAccess.remove_absolute(session.progression_path)
	if failures == 0: print("PASS Nekrodent: class mastery, exclusive equipment, combat, talents, shop and save/resume")
	finish(0 if failures == 0 else 1)


func _check_unlock() -> void:
	var view := ClassSelection.new()
	root.add_child(view)
	var necro_button: Button = view.buttons[ClassCatalog.profiles.find(ClassCatalog.by_id(NECRO))]
	var details: Array[String] = []
	view.details_requested.connect(func(title: String, body: String) -> void: details.assign([title, body]))
	necro_button.pressed.emit()
	_check(necro_button.get_node("Lock").visible and view.selected_id == ClassCatalog.DEFAULT.id
		and details.size() == 2 and details[1].contains("Blutungs- oder Gift-Waffe"), "locked tile lacks status or changed selection")
	view.queue_free()
	session.record_class_victory(&"good_old_molar", &"hard", true)
	_check(not session.class_unlocked(NECRO), "a class victory alone unlocked Nekrodent")
	# A wave-20 victory on Normal with a poisoned weapon opens Nekrodent (and the Assassine).
	await _start_game(ClassCatalog.DEFAULT.id)
	game.player.loadout.equipped()[0].affixes.assign([{"id": "poison", "rarity": 1, "damage": 3.0}])
	game.wave.current_wave = WaveController.MAX_WAVES
	game.wave.difficulty_id = &"hard"
	game._finish_run()
	session.load_progression()
	_check(session.class_unlocked(NECRO) and session.progression_data.unlocked_classes.has("necrodent"), "a poisoned wave-20 victory did not persist the unlock")
	_check(session.hell_unlocked, "class progress interfered with Hell")
	game.queue_free()
	paused = false
	await process_frame


func _check_local_unlock() -> void:
	var regular_profile: String = session.progression_path
	session.progression_path = "user://necrodent_debug_progression.cfg"
	DirAccess.remove_absolute(session.progression_path)
	session.load_progression()
	_check(not session.class_unlocked(NECRO), "debug unlock leaked into a fresh profile")
	_check(not session.record_class_victory(&"ember", &"hard", true), "one regular win unlocked Nekrodent")
	await _start_game(ClassCatalog.DEFAULT.id)
	var menu: DebugCheatMenu = game.get_node("DebugCheatMenu")
	menu.open_menu()
	_check(not menu.necrodent_unlock_button.disabled, "local unlock button is unavailable")
	menu.necrodent_unlock_button.pressed.emit()
	_check(menu.necrodent_unlock_button.disabled and menu.necrodent_unlock_button.text == "Nekrodent freigeschaltet",
		"debug menu did not reflect the unlock")
	_check(game.weapon_mastery.eligible and game.player.stats.class_data == ClassCatalog.DEFAULT,
		"local profile unlock modified the current run")
	session.load_progression()
	_check(session.class_unlocked(NECRO) and session.progression_data.class_wins == ["ember"],
		"local unlock did not persist independently of earned wins")
	var view := ClassSelection.new()
	root.add_child(view)
	view.buttons[ClassCatalog.profiles.find(ClassCatalog.by_id(NECRO))].pressed.emit()
	_check(view.selected_id == NECRO, "locally unlocked class is unavailable in regular selection")
	_check(view.style_box.get_child_count() == 4 and view.style_box.get_child(2).text.contains(WeaponPresentation.tooth_base_values(NecrodentSkills.Kind.MOLAR)),
		"class selection hid the tooth comparison")
	_check(not session.record_class_victory(&"assassin", &"hard", true)
		and session.progression_data.class_wins.has("assassin"), "local unlock prevented a real win or repeated the unlock notice")
	view.queue_free()
	menu.close_menu()
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(session.progression_path)
	session.progression_path = regular_profile
	session.load_progression()
	_check(session.class_unlocked(NECRO) and not session.progression_data.necrodent_debug_unlocked,
		"regular unlock changed after switching profiles")


func _enemy(offset: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 10000.0
	enemy.damage_reduction = 0.0
	return enemy


func _check_combat() -> void:
	await _start_game(NECRO)
	var player: Player = game.player
	var module: NecrodentSkills = player.skill_module(NECRO)
	var staff: WeaponInstance = player.loadout.equipped()[0]
	_check(player.stats.class_data.id == NECRO and staff.data.id == STAFF and module.teeth.size() == 1, "incorrect Nekrodent starting kit")
	_check(not player.loadout.can_acquire(WeaponCatalog.by_id(&"turbo_drill"))
		and not WeaponEligibility.allowed(staff.data, ClassCatalog.DEFAULT), "class weapon restrictions failed")
	_check(player.loadout.sell(0) == 0 and is_instance_valid(staff), "permanent staff was sold")
	var near := _enemy(Vector2(70, 0))
	var target := _enemy(Vector2(-170, 0))
	_check(not staff.force_attack(1.0) and target.health == 10000.0, "staff independently attacks")
	module.on_dash_ended(player.global_position, target.global_position)
	_check(module.marked == target, "dash did not target from its endpoint")
	for tick in 110: module.advance(1.0 / 60.0)
	_check(target.health < 10000.0 and near.health == 10000.0 and module.teeth.size() == 1, "retinue missed its command or grew mid-wave")
	module.teeth[0].recovery = 0.9
	game._save_run()
	var saved: Dictionary = session.load_run()
	_check(not saved.is_empty(), "run snapshot with teeth was rejected")
	game.queue_free()
	await process_frame
	session.resume_requested = true
	await _start_game(NECRO, &"")
	player = game.player
	module = player.skill_module(NECRO)
	_check(module.teeth.size() == 1 and absf(module.teeth[0].recovery - 0.9) < 0.05, "continue lost the resting tooth")
	_check(is_instance_valid(module.marked) and module.marked.global_position.x < player.global_position.x, "continue lost the marked target")
	module.advance(1.0)
	_check(module.teeth.size() == 1 and module.teeth[0].recovery == 0.0, "revival changed the retinue")
	module.marked.queue_free()
	await process_frame
	module.advance(0.2)
	_check(module.marked == null, "unavailable command target was retained")
	game.level = 4
	game.talents.prepare(3, 2, 0.0)
	for point in 3:
		_check(game.talents.plan_talent(&"necro_swarm_recruit", player.stats, game.UPGRADES, 3),
			"early tooth %d is unavailable" % (point + 2))
	_check(game.talents.commit(player.stats, game.UPGRADES, 3), "could not spend regular level points on teeth")
	game._sync_talents()
	_check(module.teeth.size() == 1, "new tooth spawned before the next wave")
	game._start_combat_wave()
	_check(module.teeth.size() == 4, "recruited teeth did not join on the next wave")


func _check_target_coordination() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	await process_frame
	var player: Player = game.player
	var module: NecrodentSkills = player.skill_module(NECRO)
	var near := _enemy(Vector2(60, 0))
	var far := _enemy(Vector2(144, 0))
	near.health = 8.0
	far.health = 8.0
	player.class_combat.powers = {"necro_teeth": 3.0}
	module.reset_wave()
	module.on_dash_ended(player.global_position, near.global_position)
	module.advance(0.01)
	_check(_attackers(module, near) == 1 and _attackers(module, far) == 1,
		"weak enemies should each draw one tooth even after a command")

	var replacement := _enemy(Vector2(184, 20))
	replacement.health = 8.0
	near.take_damage(20.0)
	module.advance(0.01)
	_check(_attackers(module, near) == 0 and _attackers(module, replacement) == 1,
		"teeth should reassign their targets immediately after a death")

	player.class_combat.powers = {"necro_teeth": 3.0, "necro_focus": 1.0}
	far.health = 1000.0
	module.reset_wave()
	module.on_dash_ended(player.global_position, far.global_position)
	module.advance(0.01)
	_check(_attackers(module, far) == 4, "a healthy priority target should draw the brigade")


func _attackers(module: NecrodentSkills, enemy: Enemy) -> int:
	var total := 0
	for tooth in module.teeth:
		if tooth.target == enemy: total += 1
	return total


func _check_branches() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	await process_frame
	var player: Player = game.player
	var module: NecrodentSkills = player.skill_module(NECRO)
	for node in player.stats.class_data.talent_tree.nodes:
		if node.is_attribute(): continue
		var icon := DentiUIIcons.talent(node.icon_index) as AtlasTexture
		_check(icon != null and icon.atlas == DentiUIIcons.NECRO_TALENT_ATLAS,
			"Nekrodent talent needs its own painted icon: " + str(node.id))
	var close := _enemy(Vector2(62, 0))
	var far := _enemy(Vector2(-150, 0))
	player.class_combat.powers = {"necro_teeth": 1.0, "necro_swarm": 1.0}
	module.reset_wave()
	module.advance(0.01)
	_check(module.teeth[0].target != null and module.teeth[1].target != null
		and module.teeth[0].target != module.teeth[1].target, "swarm failed to spread out")
	player.class_combat.powers = {"necro_guard": 1.0}
	module.reset_wave()
	module.on_dash_ended(player.global_position, far.global_position)
	module.advance(0.01)
	_check(module.marked == far and module.teeth[0].target == close, "escort did not keep a tooth near Denti")
	_check(module.pursuit_destination(close, player.global_position) == module.teeth[0].at
		and module.pursuit_destination(far, player.global_position) == player.global_position, "escort lured the wrong enemies")


func _check_tooth_health() -> void:
	var player: Player = game.player
	var module := player.skill_module(NECRO) as NecrodentSkills
	player.class_combat.powers = {"necro_teeth": 2.0, "necro_molar_teeth": 1.0, "necro_guard_teeth": 1.0}
	module.reset_wave()
	var tooth := module.teeth[0]
	var staff := player.loadout.equipped()[0]
	staff.update_visual()
	var resting_tip := staff.muzzle_position()
	_check(module.cast_left > 0.0 and tooth.emerge_left < module.teeth[1].emerge_left
		and module.teeth[1].emerge_left < module.teeth[2].emerge_left, "wave start did not stagger the summon")
	module.advance(0.2)
	staff.update_visual()
	_check(staff.muzzle_position().y < resting_tip.y - 15.0 and tooth.emerge_left < NecrodentSummon.RISE_SECONDS,
		"staff did not rise as the tooth emerged")
	_check(module.roster_counts() == PackedInt32Array([1, 1, 1])
		and module.teeth[2].health > module.teeth[1].health
		and module.bite_damage_before_target_bonuses(NecrodentSkills.Kind.MOLAR) > module.bite_damage_before_target_bonuses(),
		"tooth roles did not differentiate health and damage")
	var enemy := _enemy(tooth.at - player.global_position)
	for repeat in 10: module._bite(tooth, enemy, player.loadout.equipped()[0])
	_check(tooth.recovery == 0.0 and is_equal_approx(tooth.health, module.tooth_max_health(tooth.kind)), "biting exhausted a healthy tooth")
	enemy.simulation_enabled = true
	enemy.contact_damage = 11.0
	module.advance(NecrodentSkills.CONTACT_SCAN_INTERVAL)
	var expected := module.tooth_max_health(tooth.kind) - 11.0
	_check(is_equal_approx(tooth.health, expected), "contact did not hurt the tooth")
	module.restore_with_enemies(module.save_with_enemies({}), [])
	tooth = module.teeth[0]
	_check(is_equal_approx(tooth.health, expected), "resume lost the tooth's current health")
	_check(module.cast_left == 0.0 and tooth.emerge_left == 0.0, "resume replayed the wave opening summon")
	enemy.contact_damage = 1000.0
	module.advance(1.0)
	_check(tooth.health == 0.0 and tooth.recovery > 0.0, "a fatal contact did not knock the tooth down")
	module.advance(NecrodentSkills.RECOVERY_SECONDS - 0.05)
	_check(tooth.recovery > 0.0, "tooth returned before its recovery time")
	module.advance(0.1)
	_check(tooth.recovery == 0.0 and is_equal_approx(tooth.health, module.tooth_max_health(tooth.kind)), "revived tooth did not recover health")
	_check(module.cast_left > 0.0 and tooth.emerge_left > 0.0 and module.teeth.size() == 3, "revival did not summon the existing tooth")
	enemy.queue_free()
	await process_frame


func _check_shop() -> void:
	game.wave.active = false
	game.wave.current_wave = 2
	game.coins = 100
	game._open_shop()
	var offer_index := -1
	for index in game.shop.offers.size():
		var offer: ShopOfferData = game.shop.offers[index]
		if offer == null or offer.weapon_data == null: continue
		_check(offer.id == STAFF and offer.weapon_tier == 1, "shop offered an unusable weapon")
		offer_index = index
	_check(offer_index >= 0, "shop did not supply a staff for fusion")
	if offer_index >= 0:
		game._on_shop_buy(offer_index)
		var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
		_check(weapons.size() == 1 and weapons[0].tier == 2
			and weapons[0].data.range_at_tier(2) > weapons[0].data.range_at_tier(1), "staff fusion failed")


func _check_enchantment_details() -> void:
	var player: Player = game.player
	var staff := player.loadout.equipped()[0]
	var retinue := player.skill_module(NECRO) as NecrodentSkills
	player.class_combat.powers = {"necro_teeth": 3.0}
	retinue.reset_wave()
	var before := retinue.bite_interval(staff.data)
	staff.affixes = [
		WeaponUpgrades.next_entry({}, &"fire", staff.data, staff.tier),
		WeaponUpgrades.next_entry({}, &"tempo", staff.data, staff.tier),
	]
	staff.refresh_affix_stats()
	_check(retinue.bite_interval(staff.data) < before, "staff tempo did not speed up bites")
	_check(staff.data.element_skin == &"fire" and staff.sprite.material != null, "equipped element did not color the staff")
	var preview_material := WeaponSkins.staff_material(WeaponSkins.with_element(staff.data, &"bleed"))
	_check(preview_material.get_shader_parameter("element_color") == WeaponAffixes.by_id(&"bleed").color
		and staff.data.element_skin == &"fire", "preview did not color the staff independently of equipment")
	var no_affixes: Array[Dictionary] = []
	_check(WeaponSkins.staff_material(WeaponRolls.with_affixes(staff.data, no_affixes)) == null, "cleared staff retained an elemental tint")
	var enemy := _enemy(Vector2(96, 10))
	var packets := WeaponEnchantmentEffects.packets(player.items.effect_context, enemy, staff.data, staff.affixes,
		NecrodentSkills.enchantment_share(retinue.retinue_size()))
	var preview := AffixPresentation.display_value(float(staff.affixes[0].damage), &"fire", staff.data, player.stats, player.items)
	_check(packets.size() == 1 and is_equal_approx(float(packets[0].damage), preview),
		"staff preview did not show the elemental power per bite")
	retinue._bite(retinue.teeth[0], enemy, staff)
	_check(enemy.affix_effects.fire_budget > 0.0 and is_equal_approx(retinue.teeth[0].cooldown, retinue.bite_interval(staff.data)),
		"the actual bite did not use staff fire and cadence")
	var upgrade_model := WeaponUpgradePresentation.equipment(
		WeaponUpgradeState.new(), player.loadout, player.stats, player.items)[0]
	_check(str(upgrade_model.root_info).contains("Bisspause") and str(upgrade_model.root_info).contains("36 %"),
		"staff details omitted bite cadence or the elemental share")
	var reach: Dictionary = upgrade_model.options.filter(func(option: Dictionary) -> bool: return option.id == &"range")[0]
	_check(str(reach.description).contains("markieren"), "staff range preview describes a weapon hit")
	var menu: GameMenu = game.game_menu
	menu.open_pause()
	menu._show_stats()
	await process_frame
	var link := menu.rows.find_child("RetinueDetails", true, false) as LinkButton
	_check(link != null, "stats does not link to the retinue")
	if link != null:
		link.pressed.emit()
		_check(menu.item_details.values_grid.get_child_count() == 10
			and menu.item_details.heading.text.begins_with("Extraktionsstab"), "retinue details omitted live bite values")
	menu.close_pause()


func _check_recruitment_comparison() -> void:
	var points := TalentProgression.new()
	points.prepare(1, 2, 0.0)
	var panel: TalentPanel = game.talent_panel
	panel.present(points, game.player.stats, game.UPGRADES, 1)
	for extent in [Vector2(296, 470), Vector2(1184, 560)]:
		panel.view.layout_in(extent)
		for kind in NecrodentSkills.TOOTH_NAMES.size():
			var note := panel.view.note_labels[kind]
			_check(note.visible and note.text.replace("\n", " · ") == WeaponPresentation.tooth_base_values(kind)
				and note.get_rect().end.x <= extent.x, "first point omitted a tooth comparison")
	panel.hide()
