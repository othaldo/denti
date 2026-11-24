extends "res://tests/support/test_runtime.gd"

const NECRO := &"necrodent"
const STAFF := &"extraction_staff"

var game: Node2D
var session: Node


func _initialize() -> void:
	call_deferred("_run")


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
	await _check_staff_scaling_and_support()
	_check_recruitment_comparison()
	game.queue_free()
	await process_frame
	session.clear_run()
	DirAccess.remove_absolute(session.progression_path)
	if failures.is_empty(): print("PASS Nekrodent: class mastery, exclusive equipment, combat, talents, shop and save/resume")
	finish_checks()


func _check_unlock() -> void:
	var view := ClassSelection.new()
	root.add_child(view)
	var necro_button: Button = view.buttons[ClassCatalog.profiles.find(ClassCatalog.by_id(NECRO))]
	var details: Array[String] = []
	view.details_requested.connect(func(title: String, body: String) -> void: details.assign([title, body]))
	necro_button.pressed.emit()
	check(necro_button.get_node("Lock").visible and view.selected_id == ClassCatalog.DEFAULT.id
		and details.size() == 2 and details[1].contains("Blutungs- oder Gift-Waffe"), "locked tile lacks status or changed selection")
	view.queue_free()
	session.record_class_victory(&"good_old_molar", &"hard", true)
	check(not session.class_unlocked(NECRO), "a class victory alone unlocked Nekrodent")
	# A wave-20 victory on Normal with a poisoned weapon opens Nekrodent (and the Assassine).
	await _start_game(ClassCatalog.DEFAULT.id)
	game.player.loadout.equipped()[0].affixes.assign([{"id": "poison", "rarity": 1, "damage": 3.0}])
	game.wave.current_wave = WaveController.MAX_WAVES
	game.wave.difficulty_id = &"hard"
	game._finish_run()
	session.load_progression()
	check(session.class_unlocked(NECRO) and session.progression_data.unlocked_classes.has("necrodent"), "a poisoned wave-20 victory did not persist the unlock")
	check(session.hell_unlocked, "class progress interfered with Hell")
	game.queue_free()
	paused = false
	await process_frame


func _check_local_unlock() -> void:
	var regular_profile: String = session.progression_path
	session.progression_path = "user://necrodent_debug_progression.cfg"
	DirAccess.remove_absolute(session.progression_path)
	session.load_progression()
	check(not session.class_unlocked(NECRO), "debug unlock leaked into a fresh profile")
	check(not session.record_class_victory(&"ember", &"hard", true), "one regular win unlocked Nekrodent")
	await _start_game(ClassCatalog.DEFAULT.id)
	var menu: DebugCheatMenu = game.get_node("DebugCheatMenu")
	menu.open_menu()
	check(not menu.necrodent_unlock_button.disabled, "local unlock button is unavailable")
	menu.necrodent_unlock_button.pressed.emit()
	check(menu.necrodent_unlock_button.disabled and menu.necrodent_unlock_button.text == "Nekrodent freigeschaltet",
		"debug menu did not reflect the unlock")
	check(game.weapon_mastery.eligible and game.player.stats.class_data == ClassCatalog.DEFAULT,
		"local profile unlock modified the current run")
	session.load_progression()
	check(session.class_unlocked(NECRO) and session.progression_data.class_wins == ["ember"],
		"local unlock did not persist independently of earned wins")
	var view := ClassSelection.new()
	root.add_child(view)
	view.buttons[ClassCatalog.profiles.find(ClassCatalog.by_id(NECRO))].pressed.emit()
	check(view.selected_id == NECRO, "locally unlocked class is unavailable in regular selection")
	check(view.style_box.get_child_count() == 4 and view.style_box.get_child(2).text.contains(WeaponPresentation.tooth_base_values(NecrodentSkills.Kind.MOLAR)),
		"class selection hid the tooth comparison")
	check(not session.record_class_victory(&"assassin", &"hard", true)
		and session.progression_data.class_wins.has("assassin"), "local unlock prevented a real win or repeated the unlock notice")
	view.queue_free()
	menu.close_menu()
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(session.progression_path)
	session.progression_path = regular_profile
	session.load_progression()
	check(session.class_unlocked(NECRO) and not session.progression_data.necrodent_debug_unlocked,
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
	check(player.stats.class_data.id == NECRO and staff.data.id == STAFF and module.teeth.size() == 1, "incorrect Nekrodent starting kit")
	check(not player.loadout.can_acquire(WeaponCatalog.by_id(&"turbo_drill"))
		and not WeaponEligibility.allowed(staff.data, ClassCatalog.DEFAULT), "class weapon restrictions failed")
	check(player.loadout.sell(0) == 0 and is_instance_valid(staff), "permanent staff was sold")
	var near := _enemy(Vector2(70, 0))
	var target := _enemy(Vector2(-170, 0))
	check(not staff.force_attack(1.0) and target.health == 10000.0, "staff independently attacks")
	module.on_dash_ended(player.global_position, target.global_position)
	check(module.marked == target, "dash did not target from its endpoint")
	for tick in 110: module.advance(1.0 / 60.0)
	check(target.health < 10000.0 and near.health == 10000.0 and module.teeth.size() == 1, "retinue missed its command or grew mid-wave")
	module.teeth[0].recovery = 0.9
	game._save_run()
	var saved: Dictionary = session.load_run()
	check(not saved.is_empty(), "run snapshot with teeth was rejected")
	game.queue_free()
	await process_frame
	session.resume_requested = true
	await _start_game(NECRO, &"")
	player = game.player
	module = player.skill_module(NECRO)
	check(module.teeth.size() == 1 and absf(module.teeth[0].recovery - 0.9) < 0.05, "continue lost the resting tooth")
	check(is_instance_valid(module.marked) and module.marked.global_position.x < player.global_position.x, "continue lost the marked target")
	module.advance(1.0)
	check(module.teeth.size() == 1 and module.teeth[0].recovery == 0.0, "revival changed the retinue")
	module.marked.queue_free()
	await process_frame
	module.advance(0.2)
	check(module.marked == null, "unavailable command target was retained")
	game.level = 4
	game.talents.prepare(3, 2, 0.0)
	for point in 3:
		check(game.talents.plan_talent(&"necro_swarm_recruit", player.stats, game.UPGRADES, 3),
			"early tooth %d is unavailable" % (point + 2))
	check(game.talents.commit(player.stats, game.UPGRADES, 3), "could not spend regular level points on teeth")
	game._sync_talents()
	check(module.teeth.size() == 1, "new tooth spawned before the next wave")
	game._start_combat_wave()
	check(module.teeth.size() == 4, "recruited teeth did not join on the next wave")


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
	check(_attackers(module, near) == 1 and _attackers(module, far) == 1,
		"weak enemies should each draw one tooth even after a command")

	var replacement := _enemy(Vector2(184, 20))
	replacement.health = 8.0
	near.take_damage(20.0)
	module.advance(0.01)
	check(_attackers(module, near) == 0 and _attackers(module, replacement) == 1,
		"teeth should reassign their targets immediately after a death")

	player.class_combat.powers = {"necro_teeth": 3.0, "necro_focus": 1.0}
	far.health = 1000.0
	module.reset_wave()
	module.on_dash_ended(player.global_position, far.global_position)
	module.advance(0.01)
	check(_attackers(module, far) == 4, "a healthy priority target should draw the brigade")


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
		check(icon != null and icon.atlas == DentiUIIcons.NECRO_TALENT_ATLAS,
			"Nekrodent talent needs its own painted icon: " + str(node.id))
	var close := _enemy(Vector2(62, 0))
	var far := _enemy(Vector2(-150, 0))
	player.class_combat.powers = {"necro_teeth": 1.0, "necro_swarm": 1.0}
	module.reset_wave()
	module.advance(0.01)
	check(module.teeth[0].target != null and module.teeth[1].target != null
		and module.teeth[0].target != module.teeth[1].target, "swarm failed to spread out")
	player.class_combat.powers = {"necro_guard": 1.0}
	module.reset_wave()
	module.on_dash_ended(player.global_position, far.global_position)
	module.advance(0.01)
	check(module.marked == far and module.teeth[0].target == close, "escort did not keep a tooth near Denti")
	check(module.pursuit_destination(close, player.global_position) == module.teeth[0].at
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
	check(module.cast_left > 0.0 and tooth.emerge_left < module.teeth[1].emerge_left
		and module.teeth[1].emerge_left < module.teeth[2].emerge_left, "wave start did not stagger the summon")
	module.advance(0.2)
	staff.update_visual()
	check(staff.muzzle_position().y < resting_tip.y - 15.0 and tooth.emerge_left < NecrodentSummon.RISE_SECONDS,
		"staff did not rise as the tooth emerged")
	check(module.roster_counts() == PackedInt32Array([1, 1, 1])
		and module.teeth[2].health > module.teeth[1].health
		and module.bite_damage_before_target_bonuses(NecrodentSkills.Kind.MOLAR) > module.bite_damage_before_target_bonuses(),
		"tooth roles did not differentiate health and damage")
	var enemy := _enemy(tooth.at - player.global_position)
	for repeat in 10: module._bite(tooth, enemy, player.loadout.equipped()[0])
	check(tooth.recovery == 0.0 and is_equal_approx(tooth.health, module.tooth_max_health(tooth.kind)), "biting exhausted a healthy tooth")
	enemy.simulation_enabled = true
	enemy.contact_damage = 11.0
	module.advance(NecrodentSkills.CONTACT_SCAN_INTERVAL)
	var expected := module.tooth_max_health(tooth.kind) - 11.0
	check(is_equal_approx(tooth.health, expected), "contact did not hurt the tooth")
	module.restore_with_enemies(module.save_with_enemies({}), [])
	tooth = module.teeth[0]
	check(is_equal_approx(tooth.health, expected), "resume lost the tooth's current health")
	check(module.cast_left == 0.0 and tooth.emerge_left == 0.0, "resume replayed the wave opening summon")
	enemy.contact_damage = 1000.0
	module.advance(1.0)
	check(tooth.health == 0.0 and tooth.recovery > 0.0, "a fatal contact did not knock the tooth down")
	module.advance(NecrodentSkills.RECOVERY_SECONDS - 0.05)
	check(tooth.recovery > 0.0, "tooth returned before its recovery time")
	module.advance(0.1)
	check(tooth.recovery == 0.0 and is_equal_approx(tooth.health, module.tooth_max_health(tooth.kind)), "revived tooth did not recover health")
	check(module.cast_left > 0.0 and tooth.emerge_left > 0.0 and module.teeth.size() == 3, "revival did not summon the existing tooth")
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
		check(offer.id == STAFF and offer.weapon_tier == 1, "shop offered an unusable weapon")
		offer_index = index
	check(offer_index >= 0, "shop did not supply a staff for fusion")
	# Class items: summon items fit the Nekrodent, placed-object items do not.
	var items: ItemInventory = game.player.items
	var pot := ItemCatalog.by_id(&"flower_pot")
	check(items.fits_build(ItemCatalog.by_id(&"fertilizer")) and items.fits_build(ItemCatalog.by_id(&"root_net"))
		and not items.fits_build(pot) and items.fits_build(ItemCatalog.by_id(&"pocket_bed")), "class item filter misjudged the Nekrodent")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var offered_pot := false
	for roll in 300:
		if ChestRewards.roll_item(12, 200.0, items, rng).get("item_id", "") == "flower_pot": offered_pot = true
	check(not offered_pot, "chest offered an item for other classes")
	items.owned["rinse_valve"] = 1
	check(items.fits_build(pot), "an enabling item did not open the class item")
	items.owned.erase("rinse_valve")
	if offer_index >= 0:
		game._on_shop_buy(offer_index)
		var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
		check(weapons.size() == 1 and weapons[0].tier == 2
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
	check(retinue.bite_interval(staff.data) < before, "staff tempo did not speed up bites")
	check(staff.data.element_skin == &"fire" and staff.sprite.material != null, "equipped element did not color the staff")
	var preview_material := WeaponSkins.staff_material(WeaponSkins.with_element(staff.data, &"bleed"))
	check(preview_material.get_shader_parameter("element_color") == WeaponAffixes.by_id(&"bleed").color
		and staff.data.element_skin == &"fire", "preview did not color the staff independently of equipment")
	var no_affixes: Array[Dictionary] = []
	check(WeaponSkins.staff_material(WeaponRolls.with_affixes(staff.data, no_affixes)) == null, "cleared staff retained an elemental tint")
	var enemy := _enemy(Vector2(96, 10))
	var packets := WeaponEnchantmentEffects.packets(player.items.effect_context, enemy, staff.data, staff.affixes,
		retinue.current_enchantment_share())
	var preview := AffixPresentation.display_value(float(staff.affixes[0].damage), &"fire", staff.data, player.stats, player.items)
	check(packets.size() == 1 and is_equal_approx(float(packets[0].damage), preview),
		"staff preview did not show the elemental power per bite")
	retinue._bite(retinue.teeth[0], enemy, staff)
	check(enemy.affix_effects.fire_budget > 0.0 and is_equal_approx(retinue.teeth[0].cooldown, retinue.bite_interval(staff.data)),
		"the actual bite did not use staff fire and cadence")
	var upgrade_model := WeaponUpgradePresentation.equipment(
		WeaponUpgradeState.new(), player.loadout, player.stats, player.items)[0]
	check(str(upgrade_model.root_info).contains("Bisspause") and str(upgrade_model.root_info).contains("%.0f %%" % (NecrodentSkills.enchantment_share(retinue.retinue_size(), staff.tier) * 100.0)),
		"staff details omitted bite cadence or the elemental share")
	var reach: Dictionary = upgrade_model.options.filter(func(option: Dictionary) -> bool: return option.id == &"range")[0]
	check(str(reach.description).contains("markieren"), "staff range preview describes a weapon hit")
	var menu: GameMenu = game.game_menu
	menu.open_pause()
	menu._show_stats()
	await process_frame
	var link := menu.rows.find_child("RetinueDetails", true, false) as LinkButton
	check(link != null, "stats does not link to the retinue")
	if link != null:
		link.pressed.emit()
		check(menu.item_details.values_grid.get_child_count() == 10
			and menu.item_details.heading.text.begins_with("Extraktionsstab"), "retinue details omitted live bite values")
	menu.close_pause()


func _check_staff_scaling_and_support() -> void:
	var player: Player = game.player
	var staff := player.loadout.equipped()[0]
	var module := player.skill_module(NECRO) as NecrodentSkills
	# Mk strengthens bites; the element share grows toward 1/sqrt(n).
	var tier := staff.tier
	player.class_combat.powers = {"necro_teeth": 5.0, "necro_molar_teeth": 2.0, "necro_guard_teeth": 2.0}
	module.reset_wave()
	staff.tier = 1
	var mk_one := module.bite_damage_before_target_bonuses()
	staff.tier = 4
	check(is_equal_approx(module.bite_damage_before_target_bonuses(), mk_one * 1.9), "staff Mk IV did not strengthen bites")
	check(is_equal_approx(NecrodentSkills.enchantment_share(6, 1), 1.0 / 4.2)
		and is_equal_approx(NecrodentSkills.enchantment_share(6, 4), 1.0 / sqrt(6.0))
		and NecrodentSkills.enchantment_share(12, 4) * 12 > NecrodentSkills.enchantment_share(6, 4) * 6,
		"Mk did not let a larger retinue add elemental damage")
	check(is_equal_approx(module.current_enchantment_share(), NecrodentSkills.enchantment_share(6, 4)), "current share ignored the staff Mk")
	staff.tier = tier
	# The extraction staff enchants to 15/15, ordinary weapons stop at 10/10.
	check(WeaponUpgrades.max_level(staff.data) == 15 and WeaponUpgrades.max_level(WeaponCatalog.by_id(&"turbo_drill")) == 10,
		"enchantment caps differ from the design")
	var values: Array[Dictionary] = []
	for rank in 16:
		var next := WeaponUpgrades.advance(values, &"fire", staff.data, 4)
		if next.is_empty(): break
		values = next
	check(WeaponUpgrades.level(values[0]) == 15 and WeaponUpgrades.power(&"fire", 15, staff.data, 4) > WeaponUpgrades.power(&"fire", 10, staff.data, 4),
		"extraction staff did not enchant past 10")
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	var drill_values: Array[Dictionary] = []
	for rank in 12:
		var next := WeaponUpgrades.advance(drill_values, &"fire", drill, 4)
		if next.is_empty(): break
		drill_values = next
	check(WeaponUpgrades.level(drill_values[0]) == 10, "ordinary weapon enchanted past 10")
	check(WeaponUpgrades.advance(values, &"ice", staff.data, 4).is_empty(), "staff accepted a second element")
	# Blutsauger: molar bites heal Denti, capped per bite; milk teeth do not.
	player.class_combat.powers = {"necro_teeth": 2.0, "necro_molar_teeth": 1.0, "necro_molar_leech": 1.0}
	module.reset_wave()
	var enemy := _enemy(Vector2(40, 0))
	enemy.max_health = 100000.0
	enemy.health = enemy.max_health
	player.stats.health = player.stats.max_health - 20.0
	var before := player.stats.health
	var milk: NecrodentSkills.Tooth = module.teeth.filter(func(t: NecrodentSkills.Tooth) -> bool: return t.kind == NecrodentSkills.Kind.MILK)[0]
	var molar: NecrodentSkills.Tooth = module.teeth.filter(func(t: NecrodentSkills.Tooth) -> bool: return t.kind == NecrodentSkills.Kind.MOLAR)[0]
	module._bite(milk, enemy, staff)
	check(is_equal_approx(player.stats.health, before), "a milk tooth leeched")
	module._bite(molar, enemy, staff)
	var gained := player.stats.health - before
	check(gained > 0.0 and gained <= NecrodentSkills.MOLAR_LEECH_CAP + 0.001, "molar leech did not heal within its cap")
	# Staff Lebensraub: the interval shrinks with sqrt(teeth), floored at 0.2 s.
	check(is_equal_approx(NecrodentSkills.leech_interval(1), 0.6) and is_equal_approx(NecrodentSkills.leech_interval(4), 0.3)
		and is_equal_approx(NecrodentSkills.leech_interval(19), NecrodentSkills.LEECH_MIN_INTERVAL), "leech interval ignored the retinue")
	staff.affixes = [WeaponUpgrades.next_entry({}, &"leech", staff.data, staff.tier)]
	player.class_combat.powers = {"necro_teeth": 3.0}
	module.reset_wave()
	player.items.effect_context.cooldowns.clear()
	player.stats.health = player.stats.max_health - 20.0
	before = player.stats.health
	module._bite(module.teeth[0], enemy, staff)
	check(player.stats.health > before, "staff leech did not heal on a bite")
	var key := "enchantment_leech:" + staff.instance_uid
	check(is_equal_approx(float(player.items.effect_context.cooldowns.get(key, 0.0)), 0.3), "staff leech did not use the retinue interval")
	staff.affixes = []
	# Zahnschild: a standing guard grants one shield charge per interval.
	player.class_combat.powers = {"necro_teeth": 1.0, "necro_guard_teeth": 1.0, "necro_guard_shield": 1.0}
	module.reset_wave()
	player.stats.shield_charges = 0
	module.advance(NecrodentSkills.GUARD_SHIELD_SECONDS - 0.1)
	check(player.stats.shield_charges == 0, "guard shield came too early")
	module.advance(0.2)
	check(player.stats.shield_charges == 1, "standing guard did not grant a shield")
	module.advance(3.0)
	module.restore_with_enemies(module.save_with_enemies({}), [])
	check(is_equal_approx(module.shield_left, NecrodentSkills.GUARD_SHIELD_SECONDS - 3.0), "resume lost the guard shield clock")
	player.stats.shield_charges = 0
	enemy.queue_free()
	await process_frame


func _check_recruitment_comparison() -> void:
	var points := TalentProgression.new()
	points.prepare(1, 2, 0.0)
	var panel: TalentPanel = game.talent_panel
	panel.present(points, game.player.stats, game.UPGRADES, 1)
	for extent in [Vector2(296, 470), Vector2(1184, 560)]:
		panel.view.layout_in(extent)
		for kind in NecrodentSkills.TOOTH_NAMES.size():
			var note := panel.view.note_labels[kind]
			check(note.visible and note.text.replace("\n", " · ") == WeaponPresentation.tooth_base_values(kind)
				and note.get_rect().end.x <= extent.x, "first point omitted a tooth comparison")
	panel.hide()
