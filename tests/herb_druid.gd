extends "res://tests/support/test_runtime.gd"
## Kräuterzahn: planting staff rhythm, garden size and cap, sage shots through
## the projectile pipeline, skill rotation, totem aura, clove numbing (also on
## bosses), contact wear, boss trampling, Ranken, save/resume and unlock rule.

var game: Node2D
var herbs: HerbSkills


func _initialize() -> void:
	call_deferred("_run")


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
	check(game.player.stats.class_data.id == &"herb_druid" and herbs != null and herbs.active(), "Kräuterzahn did not start")
	check(herbs.staff() != null and herbs.staff().data.id == &"planting_staff", "planting staff not equipped")
	await _planting()
	await _skills()
	await _staffs()
	await _element_shots()
	await _combat()
	await _caramel_heart()
	_snapshot()
	game.queue_free()
	await process_frame
	session.clear_run()
	if failures.is_empty(): print("herb druid ok")
	finish_checks()


func _data() -> void:
	var profile := ClassCatalog.by_id(&"herb_druid")
	check(profile != null and profile.valid() and profile.exclusive_weapon_id == &"planting_staff" and profile.root_capacity == 1, "class data invalid")
	check(profile.talent_tree != null and profile.talent_tree.valid(), "talent tree invalid")
	var skills := 0
	for node in profile.talent_tree.nodes:
		if node.is_skill(): skills += 1
	check(skills == 3, "expected three branch skills")
	check(WeaponCatalog.by_id(&"planting_staff") != null and WeaponCatalog.is_starter(WeaponCatalog.by_id(&"planting_staff")), "staff not in the catalog")
	check(ClassUnlocks.requirement(&"herb_druid") == "Run ab Welle 15 mit drei Fernkampfwaffen beenden", "unlock text: " + ClassUnlocks.requirement(&"herb_druid"))
	var ranged: Array[WeaponInstance] = []
	for id in [&"amalgam_slingshot", &"water_jet", &"crown_launcher"]:
		var weapon := WeaponInstance.new()
		weapon.data = WeaponCatalog.by_id(id)
		ranged.append(weapon)
	check(ClassUnlocks.earned([], ranged, 15, false, &"normal").has("herb_druid"), "three ranged weapons at wave 15 did not open the class")
	check(not ClassUnlocks.earned([], ranged.slice(0, 2), 15, false, &"normal").has("herb_druid"), "two ranged weapons opened the class")
	check(not ClassUnlocks.earned([], ranged, 14, false, &"normal").has("herb_druid"), "wave 14 opened the class")
	for weapon in ranged: weapon.free()
	# Texts describe the effect on the herbs, not a generic weapon.
	var staff_data := WeaponCatalog.by_id(&"planting_staff")
	check(AffixPresentation.damage_unit(&"electric", null, staff_data) == "Schaden/Salbeischuss", "damage unit not about sage shots")
	check(AffixPresentation.effect_description(&"tempo", staff_data).contains("pflanzt schneller"), "tempo text does not explain the garden")
	check(AffixPresentation.effect_description(&"fire", staff_data).begins_with("Salbeischüsse"), "fire text not about sage shots")
	check(WeaponPresentation.pause_label(staff_data) == "Pflanztakt", "pause label not Pflanztakt")
	var seed_textures := {}
	for element in WeaponElementVisuals.ELEMENTS:
		var form := WeaponSkins.with_element(staff_data, element)
		check(form.element_skin == element and form.held_texture() != staff_data.held_texture(), "missing painted staff form: %s" % element)
		check(form.grip_anchor == staff_data.grip_anchor and WeaponSkins.staff_material(form) == null, "painted staff form changed its grip or got a tint: %s" % element)
		var enchantment: Array[Dictionary] = [WeaponUpgrades.next_entry({}, element, staff_data, 1)]
		var seed := ProjectileEnchantmentSkins.base_texture(staff_data, 1, enchantment)
		check(seed != ProjectileEnchantmentSkins.HERB_SEED and seed.get_size() == HerbElementArt.CELL, "missing elemental seed for %s" % element)
		check(ProjectileEnchantmentSkins.base_texture(form, 1) == seed, "staff skin and affix disagreed about the seed for %s" % element)
		seed_textures[seed] = true
		for kind in HerbSkills.Kind.size():
			var cell := HerbElementArt.plant_region(element, kind)
			check(cell.position == Vector2(kind, WeaponElementVisuals.ELEMENTS.find(element)) * HerbElementArt.CELL,
				"bad plant art cell for %s, %d" % [element, kind])
	check(seed_textures.size() == WeaponElementVisuals.ELEMENTS.size(), "different elements used the same seed")
	check(ProjectileEnchantmentSkins.base_texture(staff_data, 1) == ProjectileEnchantmentSkins.HERB_SEED and
		not HerbElementArt.plant_region(&"", HerbSkills.Kind.SAGE).has_area(), "neutral herbs lost their art")


func _enemy(offset: Vector2, data: EnemyData = WaveController.PLAQUE) -> Enemy:
	game._create_enemy(data, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 10000.0
	enemy.max_health = 10000.0
	enemy.damage_reduction = 0
	return enemy


## Staffs plant on their own during a wave; tests drive them explicitly.
func _hold_staffs() -> void:
	for weapon in herbs.staffs():
		weapon.set_physics_process(false)
		weapon.attack_time = 0.0


func _clear() -> void:
	_hold_staffs()
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	for projectile in game.get_node("Projectiles").get_children():
		if projectile is WeaponProjectile: projectile.visible = false
	herbs.reset_wave()
	game.player.class_combat.powers = {}
	await process_frame


func _planting() -> void:
	_hold_staffs()
	herbs.reset_wave()
	var staff := herbs.staff()
	# Outside combat nothing is planted; during a wave the staff plants even
	# without enemies near, so the garden can be prepared.
	game.wave.active = false
	staff.cooldown = 0.0
	staff._physics_process(0.0)
	check(herbs.plants.is_empty(), "planted outside combat")
	game.wave.active = true
	check(game.player.combat_active(), "test not in combat: paused %s, phase %s, health %s" % [paused, game.run_flow.phase, game.player.stats.health])
	# Entering combat first waits for the staff's root phase, then plants.
	staff.cooldown = 0.0
	staff._physics_process(0.0)
	if herbs.plants.is_empty():
		staff.cooldown = 0.0
		staff.attack_time = 0.0
		staff._physics_process(0.0)
	check(herbs.plants.size() == 1 and staff.cooldown > 0.0, "staff did not plant in its rhythm")
	var interval := staff.attack_interval()
	check(staff.cooldown >= interval * (1.0 - WeaponInstance.PLANT_JITTER) - 0.001 and staff.cooldown <= interval * (1.0 + WeaponInstance.PLANT_JITTER) + 0.001, "planting interval jitter out of range")
	# New herbs land around Denti, not on one spot.
	var spot: Vector2 = herbs.plants[0].at
	var distance := spot.distance_to(game.player.global_position)
	check(distance >= HerbSkills.SPREAD_MIN - 0.01 and distance <= HerbSkills.SPREAD_MAX + 0.01, "herb not planted in the ring around Denti: %.1f" % distance)
	var start: Vector2 = game.player.global_position
	var corner := Vector2.ONE * DentiArena.PLAYER_MARGIN
	game.player.global_position = corner
	for sample in 12:
		spot = herbs.planting_spot()
		check(spot.x >= corner.x and spot.y >= corner.y, "planting point left the arena at a corner")
		check(spot.distance_to(corner) >= HerbSkills.SPREAD_MIN - 0.01, "planting point collapsed onto Denti at a corner")
	game.player.global_position = start
	var target := _enemy(Vector2(120, 0))
	check(not staff.force_attack(0.0), "skills forced a planting staff attack")
	# Planting animation: the staff jabs and the seed starts at its head.
	check(herbs.cast_left(staff.instance_uid) > 0.0 and herbs.plants[0].tip.is_finite(), "planting started no animation")
	herbs.advance(0.1)
	check(HerbPlanting.plunge(herbs.cast_left(staff.instance_uid)) > 0.0, "staff did not jab while planting")
	herbs.advance(HerbPlanting.CAST_SECONDS)
	check(herbs.cast_left(staff.instance_uid) == 0.0, "planting animation did not end")
	# No gameplay cap: only the performance guard limits a staff's garden, and
	# beyond it the oldest herb makes room.
	for index in HerbSkills.SAFETY_CAP: herbs.plant(game.player.global_position + Vector2(index + 1, 0))
	check(herbs.plants.size() == HerbSkills.SAFETY_CAP, "garden ignored its safety guard: %d" % herbs.plants.size())
	# Natural garden size: lifetime / planting interval, about five herbs on Mk I.
	check(absf(herbs.expected_garden(staff) - HerbSkills.LIFETIME / staff.attack_interval()) < 0.01 and herbs.expected_garden(staff) > 4.0 and herbs.expected_garden(staff) < 6.0, "start garden size off: %.2f" % herbs.expected_garden(staff))
	var first: Dictionary = herbs.plants[0]
	check(first.at.x > game.player.global_position.x, "full garden did not replace the oldest herb")
	await _clear()
	# Sage shots go through the weapon projectile pipeline.
	target = _enemy(Vector2(150, 0))
	herbs.plant()
	for tick in 90: herbs.advance(1.0 / 60.0)
	var flying := 0
	for projectile in game.get_node("Projectiles").get_children():
		if projectile is WeaponProjectile and projectile.visible:
			flying += 1
			check(projectile.body_sprite.texture == ProjectileEnchantmentSkins.HERB_SEED, "sage shot did not use its seed sprite")
	check(flying > 0 or target.health < 10000.0, "a grown sage sprout did not shoot")
	herbs.plants[0].life = 0.01
	herbs.advance(0.02)
	check(herbs.plants.is_empty(), "a herb outlived its lifetime")
	await _clear()


func _skills() -> void:
	game.player.class_combat.powers = {"skill_totem": 1.0, "skill_clove": 1.0, "skill_shrub": 1.0}
	var kinds: Array[int] = []
	for index in 8:
		kinds.append(herbs.next_kind())
		herbs.plant(game.player.global_position + Vector2(-200 + index * 50, 200))
	check(kinds.count(HerbSkills.Kind.TOTEM) == 2 and kinds.count(HerbSkills.Kind.CLOVE) == 2, "rotation wrong: %s" % [kinds])
	check(kinds.count(HerbSkills.Kind.SHRUB) == 0 or kinds.count(HerbSkills.Kind.SHRUB) == 1, "shrub frequency wrong: %s" % [kinds])
	await _clear()
	game.player.class_combat.powers = {"herb_monoculture": 1.0, "skill_totem": 1.0}
	check(herbs.next_kind() == HerbSkills.Kind.SAGE and is_equal_approx(herbs.lifetime(HerbSkills.Kind.SAGE), HerbSkills.LIFETIME * HerbSkills.MONOCULTURE_LIFE), "Monokultur did not keep only sage with longer lives")
	await _clear()
	# Totem aura: haste for Denti while grown and near.
	game.player.class_combat.powers = {"skill_totem": 1.0}
	herbs.plantings = 1
	herbs.plant()
	check(herbs.plants[0].kind == HerbSkills.Kind.TOTEM, "second planting was not a totem")
	check(herbs.attack_speed_bonus() == 0.0, "an unripe totem gave haste")
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	check(herbs.attack_speed_bonus() == HerbSkills.TOTEM_HASTE, "totem aura gave no haste")
	check(herbs.heal_pulse_left == 0.0, "totem showed healing at full health")
	var stats: PlayerStats = game.player.stats
	stats.health = stats.max_health - 10.0
	var before := stats.health
	herbs.advance(0.2)
	check(is_equal_approx(stats.health, before + 0.2) and herbs.heal_pulse_left > 0.0 and herbs.heal_origin.is_finite(), "totem did not heal and show a pulse from its position")
	herbs.advance(0.51)
	check(herbs.heal_pending == 0.0, "totem healing feedback was not flushed")
	stats.health = stats.max_health
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
	check(game.player.module_damage_bonus(boss, herbs.staff().data) == HerbSkills.CLOVE_BONUS, "clove did not expose the boss")
	check(game.player.module_damage_bonus(far, herbs.staff().data) == 0.0, "clove reached a distant enemy")
	await _clear()


func _staffs() -> void:
	var loadout: WeaponLoadout = game.player.loadout
	var staff_data := WeaponCatalog.by_id(&"planting_staff")
	# Talents open roots: extra_roots goes through the talent sync into the loadout.
	game.player.class_combat.powers = {"extra_roots": 2.0}
	game.player.stats.talent_roots = 2
	check(loadout.capacity == 3, "talent roots did not widen the loadout: %d" % loadout.capacity)
	check(loadout.acquire(staff_data, 1) and loadout.acquire(staff_data, 1), "second and third staff could not be equipped")
	_hold_staffs()
	herbs.reset_wave()
	var all := herbs.staffs()
	check(all.size() == 3, "expected three staffs, got %d" % all.size())
	# Staffs entering a wave keep their root phase, so they never jab in unison.
	var phases := {}
	for weapon in all:
		weapon.engagement_pending = true
		weapon.cooldown = 0.0
		weapon._physics_process(0.0)
		phases[snappedf(weapon.cooldown, 0.001)] = true
	check(phases.size() >= 2, "staffs started in unison")
	herbs.reset_wave()
	# The shop offers no further staff without a free root, only a fusion.
	game.shop.reroll(8, 0.0, loadout, game.items)
	for offer: ShopOfferData in game.shop.offers:
		if offer != null and offer.weapon_data != null:
			check(offer.id == &"planting_staff" and loadout.can_acquire(offer.weapon_data, offer.weapon_tier), "shop offered an unusable weapon: %s" % offer.id)
	# Every staff keeps its own garden and cap.
	all[1].affixes.assign([{"id": "fire", "rarity": 1, "damage": 3.0}])
	all[2].tier = 3
	for index in 4:
		for weapon in all: herbs.plant(game.player.global_position + Vector2(index * 4, 0), weapon)
	herbs.plant(game.player.global_position, all[2])
	check(herbs.garden_size(all[0]) == 4 and herbs.garden_size(all[2]) == 5, "per-staff gardens mixed: %d / %d" % [herbs.garden_size(all[0]), herbs.garden_size(all[2])])
	check(herbs.lifetime(HerbSkills.Kind.SAGE, all[2]) > herbs.lifetime(HerbSkills.Kind.SAGE, all[0]), "Mk tier did not lengthen herb lives")
	check(herbs.element_color(all[1]).a > 0.0 and herbs.element_color(all[0]).a == 0.0, "staff elements mixed up")
	var fiery := herbs.plants.filter(func(entry: Dictionary) -> bool: return entry.staff == all[1].instance_uid)
	check(herbs.staff_of(fiery[0]) == all[1], "herb lost its staff")
	var before := all[0].attack_interval()
	game.player.class_combat.powers = {"herb_rate": 2.0}
	check(is_equal_approx(all[0].attack_interval(), before / 1.2), "Dichtes Beet did not speed up planting")
	game.player.class_combat.powers = {}
	# Resume keeps the owner of every herb.
	var states: Dictionary = JSON.parse_string(JSON.stringify(game.player.save_skill_modules()))
	check(ClassSkillModule.valid_state(states), "multi-staff garden fails validation")
	herbs.reset_wave()
	game.player.restore_skill_modules(states)
	check(herbs.garden_size(all[1]) == 4 and herbs.garden_size(all[2]) == 5, "garden owners lost on resume")
	# Removing staffs hands their herbs to the first.
	loadout.restore([{"id": "planting_staff", "tier": 1, "uid": all[0].instance_uid}], false)
	game.player.stats.talent_roots = 0
	check(herbs.staff_of(fiery[0]) == herbs.staff(), "orphaned herb kept a missing staff")
	await _clear()


func _element_shots() -> void:
	var staff := herbs.staff()
	var old_affixes := staff.affixes.duplicate(true)
	var pool := game.get_node("Projectiles") as PlayerProjectilePool
	_enemy(Vector2(150, 0))
	for element in WeaponElementVisuals.ELEMENTS:
		staff.affixes.assign([WeaponUpgrades.next_entry({}, element, staff.data, 1)])
		var kind := HerbSkills.Kind.SHRUB if element == &"ice" else HerbSkills.Kind.SAGE
		herbs._add_plant(kind, game.player.global_position, staff)
		herbs.plants[0].shot = 0.0
		herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
		var expected := pool.skins.frames(HerbElementArt.seed(element), ProjectileEnchantmentSkins.mask(staff.affixes),
			ProjectileEnchantmentSkins.visual_radius(staff.data, staff.tier))
		var fired := 0
		for node in pool.get_children():
			var shot := node as WeaponProjectile
			if shot == null or not shot.visible: continue
			check(shot.source_uid == staff.instance_uid and shot.visual_element == element and expected.has(shot.body_sprite.texture),
				"garden shot did not use the planting staff's elemental seed for %s" % element)
			fired += 1
			shot.retire()
		check(fired == (HerbSkills.SHRUB_SHOTS if kind == HerbSkills.Kind.SHRUB else 1), "wrong elemental shot count for %s" % element)
		herbs.reset_wave()
	staff.affixes.assign(old_affixes)
	await _clear()


func _combat() -> void:
	# Ranken: a dash leaves a sprout at its start.
	game.player.class_combat.powers = {"herb_tendril": 1.0}
	herbs.on_dash_started()
	check(herbs.plants.size() == 1, "Ranken did not plant on dash")
	await _clear()
	# Enemies wear herbs down; bosses trample them.
	var biter := _enemy(Vector2(0, 0))
	biter.contact_damage = 1000.0
	herbs.plant(game.player.global_position)
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	herbs.advance(0.02)
	check(herbs.plants.is_empty(), "contact did not wear the herb down")
	await _clear()
	var boss := _enemy(Vector2(0, 0), WaveController.BOSS)
	# Bosses trample with tripled contact damage: one hit that a normal enemy
	# survives finishes the herb.
	boss.contact_damage = herbs.plant_health() / HerbSkills.BOSS_TRAMPLE + 1.0
	herbs.plant(game.player.global_position)
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	herbs.advance(0.02)
	check(herbs.plants.is_empty(), "a boss did not trample the herb")
	await _clear()


func _caramel_heart() -> void:
	var boss := _enemy(Vector2(300, 0), EnemyCatalog.CAVITY_PRINCE)
	boss.boss_phase = 2
	boss.boss_phase_timer = 0.0
	var ritual := boss.caramel_encounter.overload
	ritual.begin()
	var heart := ritual.live_pylons()[0]
	var start: Vector2 = game.player.global_position
	game.player.global_position = heart.global_position + Vector2.RIGHT * (ritual.opening_distance + 100.0)
	var spot := heart.global_position + Vector2.DOWN * ritual.opening_distance * 0.5
	herbs.plant(spot)
	var sage := herbs.plants[0]
	boss.caramel_encounter.advance(ritual.profile.warning_seconds)
	check(ritual.state == CaramelOverload.State.ACTIVE and not heart.is_targetable(), "a sprout opened a heart while Denti was away")
	sage.shot = 0.0
	herbs.advance(HerbSkills.GROW_SECONDS + 0.01)
	check(heart.is_targetable(), "grown sage did not open a nearby heart while Denti was away")
	var before := heart.health
	for projectile in game.get_node("Projectiles").get_children():
		if projectile is WeaponProjectile and projectile.visible: projectile._physics_process(0.25)
	check(heart.health < before, "sage projectile did not hit the open heart from the garden")
	sage.life = 0.01
	herbs.advance(0.02)
	check(not heart.is_targetable(), "heart stayed open after the nearby sage wilted")
	game.player.global_position = start
	await _clear()


func _snapshot() -> void:
	game.player.class_combat.powers = {"skill_totem": 1.0}
	for index in 3: herbs.plant(game.player.global_position + Vector2(index * 40, 0))
	herbs.advance(0.2)
	var states: Dictionary = JSON.parse_string(JSON.stringify(game.player.save_skill_modules()))
	check(ClassSkillModule.valid_state(states), "herb state fails validation")
	var saved_plants: Array = herbs.plants.duplicate(true)
	herbs.reset_wave()
	game.player.restore_skill_modules(states)
	check(herbs.plants.size() == saved_plants.size() and herbs.plantings == 3, "garden lost on resume")
	check(herbs.plants[1].kind == saved_plants[1].kind and herbs.plants[1].at.is_equal_approx(saved_plants[1].at), "herb kind or place changed on resume")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	check(not RunSaveData.normalize(snapshot).is_empty(), "run save with a garden was rejected")
