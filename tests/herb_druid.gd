extends "res://tests/support/test_runtime.gd"
## Kräuterzahn: planting staff rhythm, garden size and cap, sage shots through
## the projectile pipeline, skill rotation, totem aura, clove numbing (also on
## bosses), contact wear, boss trampling, Ranken, save/resume and unlock rule.

var game: Node2D
var herbs: HerbSkills
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)


func _run() -> void:
	_data()
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://herb_druid_test.json"
	session.clear_run()
	session.pending_start_class_id = &"herb_druid"
	session.pending_start_weapon_id = &"planting_staff"
	session.pending_talent_run = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	if game.starter_pending: choose_panel(game.choice_panel, 0)
	game.wave.set_process(false)
	game.wave.active = true
	game.player.set_physics_process(false)
	herbs = HerbSkills.for_player(game.player)
	_check(game.player.stats.class_data.id == &"herb_druid" and herbs != null and herbs.active(), "Kräuterzahn did not start")
	_check(herbs.staff() != null and herbs.staff().data.id == &"planting_staff", "planting staff not equipped")
	await _planting()
	await _skills()
	await _combat()
	_snapshot()
	game.queue_free()
	await process_frame
	session.clear_run()
	if failures.is_empty(): print("herb druid ok")
	finish(1 if not failures.is_empty() else 0)


func _data() -> void:
	var profile := ClassCatalog.by_id(&"herb_druid")
	_check(profile != null and profile.valid() and profile.exclusive_weapon_id == &"planting_staff" and profile.root_capacity == 1, "class data invalid")
	_check(profile.talent_tree != null and profile.talent_tree.valid(), "talent tree invalid")
	var skills := 0
	for node in profile.talent_tree.nodes:
		if node.is_skill(): skills += 1
	_check(skills == 3, "expected three branch skills")
	_check(WeaponCatalog.by_id(&"planting_staff") != null and WeaponCatalog.is_starter(WeaponCatalog.by_id(&"planting_staff")), "staff not in the catalog")
	_check(ClassUnlocks.requirement(&"herb_druid") == "Run ab Welle 15 mit drei Fernkampfwaffen beenden", "unlock text: " + ClassUnlocks.requirement(&"herb_druid"))
	var ranged: Array[WeaponInstance] = []
	for id in [&"amalgam_slingshot", &"water_jet", &"crown_launcher"]:
		var weapon := WeaponInstance.new()
		weapon.data = WeaponCatalog.by_id(id)
		ranged.append(weapon)
	_check(ClassUnlocks.earned([], ranged, 15, false, &"normal").has("herb_druid"), "three ranged weapons at wave 15 did not open the class")
	_check(not ClassUnlocks.earned([], ranged.slice(0, 2), 15, false, &"normal").has("herb_druid"), "two ranged weapons opened the class")
	_check(not ClassUnlocks.earned([], ranged, 14, false, &"normal").has("herb_druid"), "wave 14 opened the class")
	for weapon in ranged: weapon.free()
	# Texts describe the effect on the herbs, not a generic weapon.
	var staff_data := WeaponCatalog.by_id(&"planting_staff")
	_check(AffixPresentation.damage_unit(&"electric", null, staff_data) == "Schaden/Salbeischuss", "damage unit not about sage shots")
	_check(AffixPresentation.effect_description(&"tempo", staff_data).contains("pflanzt schneller"), "tempo text does not explain the garden")
	_check(AffixPresentation.effect_description(&"fire", staff_data).begins_with("Salbeischüsse"), "fire text not about sage shots")
	_check(WeaponPresentation.pause_label(staff_data) == "Pflanztakt", "pause label not Pflanztakt")
	# Until painted forms exist the staff head is tinted in the element color.
	var fiery := WeaponSkins.with_element(staff_data, &"fire")
	_check(fiery.element_skin == &"fire" and WeaponSkins.staff_material(fiery) != null, "enchanted staff shows no element")
	_check(WeaponSkins.staff_material(staff_data) == null, "plain staff got an element tint")


func _enemy(offset: Vector2, data: EnemyData = WaveController.PLAQUE) -> Enemy:
	game._create_enemy(data, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 10000.0
	enemy.max_health = 10000.0
	enemy.damage_reduction = 0
	return enemy


func _clear() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	for projectile in game.get_node("Projectiles").get_children():
		if projectile is WeaponProjectile: projectile.visible = false
	herbs.reset_wave()
	game.player.class_combat.powers = {}
	await process_frame


func _planting() -> void:
	var staff := herbs.staff()
	staff._physics_process(0.0)
	_check(herbs.plants.is_empty(), "planted without enemies near")
	var target := _enemy(Vector2(120, 0))
	staff.cooldown = 0.0
	staff._physics_process(0.0)
	_check(herbs.plants.size() == 1 and staff.cooldown > 0.0, "staff did not plant in its rhythm")
	_check(not staff.force_attack(0.0), "skills forced a planting staff attack")
	# Garden size: lifetime / interval, capped; a full garden replaces its oldest herb.
	for index in 30: herbs.plant(game.player.global_position + Vector2(index * 3, 0))
	_check(herbs.plants.size() == herbs.capacity() and herbs.capacity() == HerbSkills.CAPS[0], "garden ignored its cap: %d" % herbs.plants.size())
	var first: Dictionary = herbs.plants[0]
	_check(first.at.x > game.player.global_position.x, "full garden did not replace the oldest herb")
	await _clear()
	# Sage shots go through the weapon projectile pipeline.
	target = _enemy(Vector2(150, 0))
	herbs.plant()
	for tick in 90: herbs.advance(1.0 / 60.0)
	var flying := 0
	for projectile in game.get_node("Projectiles").get_children():
		if projectile is WeaponProjectile and projectile.visible: flying += 1
	_check(flying > 0 or target.health < 10000.0, "a grown sage sprout did not shoot")
	herbs.plants[0].life = 0.01
	herbs.advance(0.02)
	_check(herbs.plants.is_empty(), "a herb outlived its lifetime")
	await _clear()


func _skills() -> void:
	game.player.class_combat.powers = {"skill_totem": 1.0, "skill_clove": 1.0, "skill_shrub": 1.0}
	var kinds: Array[int] = []
	for index in 8:
		kinds.append(herbs.next_kind())
		herbs.plant(game.player.global_position + Vector2(-200 + index * 50, 200))
	_check(kinds.count(HerbSkills.Kind.TOTEM) == 2 and kinds.count(HerbSkills.Kind.CLOVE) == 2, "rotation wrong: %s" % [kinds])
	_check(kinds.count(HerbSkills.Kind.SHRUB) == 0 or kinds.count(HerbSkills.Kind.SHRUB) == 1, "shrub frequency wrong: %s" % [kinds])
	await _clear()
	game.player.class_combat.powers = {"herb_monoculture": 1.0, "skill_totem": 1.0}
	_check(herbs.next_kind() == HerbSkills.Kind.SAGE and herbs.capacity() == roundi(HerbSkills.CAPS[0] * HerbSkills.MONOCULTURE_CAP), "Monokultur did not keep only sage")
	await _clear()
	# Totem aura: haste for Denti while grown and near.
	game.player.class_combat.powers = {"skill_totem": 1.0}
	herbs.plantings = 1
	herbs.plant()
	_check(herbs.plants[0].kind == HerbSkills.Kind.TOTEM, "second planting was not a totem")
	_check(herbs.attack_speed_bonus() == 0.0, "an unripe totem gave haste")
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	_check(herbs.attack_speed_bonus() == HerbSkills.TOTEM_HASTE, "totem aura gave no haste")
	await _clear()
	# Clove: numbs enemies and bosses, weapon damage bonus through the module.
	game.player.class_combat.powers = {"skill_clove": 1.0}
	var boss := _enemy(Vector2(40, 0), WaveController.BOSS)
	var far := _enemy(Vector2(400, 0))
	herbs.plantings = 3
	herbs.plant(game.player.global_position + Vector2(-30, 0))
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	herbs.clove_tick = 0.0
	herbs.advance(0.01)
	_check(game.player.module_damage_bonus(boss, herbs.staff().data) == HerbSkills.CLOVE_BONUS, "clove did not expose the boss")
	_check(game.player.module_damage_bonus(far, herbs.staff().data) == 0.0, "clove reached a distant enemy")
	await _clear()


func _combat() -> void:
	# Ranken: a dash leaves a sprout at its start.
	game.player.class_combat.powers = {"herb_tendril": 1.0}
	herbs.on_dash_started()
	_check(herbs.plants.size() == 1, "Ranken did not plant on dash")
	await _clear()
	# Enemies wear herbs down; bosses trample them.
	var biter := _enemy(Vector2(0, 0))
	biter.contact_damage = 1000.0
	herbs.plant()
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	herbs.advance(0.02)
	_check(herbs.plants.is_empty(), "contact did not wear the herb down")
	await _clear()
	var boss := _enemy(Vector2(0, 0), WaveController.BOSS)
	boss.contact_damage = 0.0
	herbs.plant()
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	herbs.advance(0.02)
	_check(herbs.plants.is_empty(), "a boss did not trample the herb")
	await _clear()


func _snapshot() -> void:
	game.player.class_combat.powers = {"skill_totem": 1.0}
	for index in 3: herbs.plant(game.player.global_position + Vector2(index * 40, 0))
	herbs.advance(0.2)
	var states: Dictionary = JSON.parse_string(JSON.stringify(game.player.save_skill_modules()))
	_check(ClassSkillModule.valid_state(states), "herb state fails validation")
	var saved_plants: Array = herbs.plants.duplicate(true)
	herbs.reset_wave()
	game.player.restore_skill_modules(states)
	_check(herbs.plants.size() == saved_plants.size() and herbs.plantings == 3, "garden lost on resume")
	_check(herbs.plants[1].kind == saved_plants[1].kind and herbs.plants[1].at.is_equal_approx(saved_plants[1].at), "herb kind or place changed on resume")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	_check(not RunSaveData.normalize(snapshot).is_empty(), "run save with a garden was rejected")
