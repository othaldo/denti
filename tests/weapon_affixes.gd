extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_affixes.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.set_process(false)
	game.wave.active = false
	var loadout: WeaponLoadout = game.player.loadout
	var first: WeaponInstance = loadout.equipped()[0]
	loadout.acquire(first.data)
	var second: WeaponInstance = loadout.equipped()[1]
	var fire := {"id": "fire", "rarity": 3, "damage": 8.0}
	var ice := {"id": "ice", "rarity": 2, "damage": 6.0}
	var poison := {"id": "poison", "rarity": 1, "damage": 3.0}
	if not _expect(WeaponAffixes.apply(first, fire) and first.affixes.size() == 1 and second.affixes.is_empty(), "same-type weapon instances share affixes"):
		return
	for count in 100:
		WeaponAffixes.apply(first, {"id": "fire", "rarity": 1, "damage": 1.0})
	if not _expect(first.affixes[0].damage > 14 and first.affixes[0].rarity == 4 and first.affixes[0].stacks == 101, "lower rarity failed to advance an existing affix"):
		return
	first.affixes[0].damage = 8.0
	first.affixes[0].stacks = 1
	if not _expect(not WeaponAffixes.apply(first, ice) and WeaponAffixes.apply(first, {"id": "slot", "rarity": 3}) and WeaponAffixes.apply(first, ice), "second slot did not gate the second effect"):
		return
	if not _expect(not WeaponAffixes.apply(first, poison) and WeaponAffixes.apply(first, poison, 0) and first.affixes[0].id == "poison" and first.affixes[1].id == "ice", "full slots silently replaced an effect or lost the untouched effect"):
		return
	WeaponAffixes.apply(first, fire, 0)
	WeaponAffixes.apply(second, {"id": "fire", "rarity": 1, "damage": 3.0})
	var uid := first.instance_uid
	if not _expect(loadout.merge(0) and first.instance_uid == uid and first.affixes[0].damage == 14.75 and first.affixes[1].id == "ice" and first.affix_slots == 2, "fusion lost affix investment or primary identity"):
		return
	loadout.acquire(first.data, first.tier)
	second = loadout.equipped()[1]
	WeaponAffixes.apply(second, poison)
	if not _expect(not loadout.can_merge(0) and not loadout.merge(0), "fusion silently consumed a third distinct effect"):
		return
	var saved_weapons := loadout.save_data()
	loadout.restore(saved_weapons)
	first = loadout.equipped()[0]
	second = loadout.equipped()[1]
	if not _expect(first.instance_uid == uid and first.affixes[0].damage == 14.75 and second.affixes[0].id == "poison", "weapon save/restore mixed same-type instances"):
		return
	first.affixes[0].damage = 8
	first.affixes[1].damage = 6
	for weapon in loadout.equipped():
		weapon.set_physics_process(false)
	var rng := RandomNumberGenerator.new()
	var rare_low := 0
	var rare_high := 0
	for seed_value in 120:
		rng.seed = seed_value
		var low := WeaponAffixes.roll_chest(14, 0, loadout, false, rng)
		rng.seed = seed_value
		var high := WeaponAffixes.roll_chest(14, 100, loadout, false, rng)
		var kinds: Array[String] = []
		for index in 3:
			var option: Dictionary = high.options[index]
			if not _expect(not kinds.has(str(option.id)) and not WeaponAffixes.sanitize_chest(high).is_empty(), "chest options are duplicated or invalid"):
				return
			kinds.append(str(option.id))
			rare_low += int(low.options[index].rarity >= 3)
			rare_high += int(option.rarity >= 3)
	if not _expect(rare_high > rare_low and ChestRewards.drop_chance(1000) <= ChestRewards.BASE_DROP_CHANCE * (1.0 + ChestRewards.LUCK_BONUS_CAP), "luck does not improve rarity within bounded drop odds"):
		return
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(80, 0))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.max_health = 1000
	enemy.health = 1000
	enemy.damage_reduction = 0
	enemy.data = enemy.data.duplicate() as EnemyData
	enemy.data.affix_resistances = {}
	WeaponAttackShapes.hit(enemy, first.data, 1, 20, false, game.items, Vector2.RIGHT, first.affixes)
	if not _expect(is_equal_approx(enemy.health, 974) and enemy.affix_effects.is_active(), "fire was dealt instantly instead of queued"):
		return
	enemy.affix_effects.advance(enemy, 2.0)
	if not _expect(is_equal_approx(enemy.health, 966) and enemy.chill_time > 0 and is_equal_approx(enemy.status_speed_factor(), 0.85), "affixes did not deal additional damage or apply ice slow"):
		return
	var colors: Dictionary = {}
	for number: DamageNumber in game.get_node("DamageNumbers").get_children():
		if number.render_color == WeaponAffixes.by_id(&"fire").color and number.text.is_valid_float():
			colors["fire"] = number.render_color
		if number.render_color == WeaponAffixes.by_id(&"ice").color and number.text.is_valid_float():
			colors["ice"] = number.render_color
	if not _expect(colors.get("fire") == WeaponAffixes.by_id(&"fire").color and colors.get("ice") == WeaponAffixes.by_id(&"ice").color, "additional damage is missing separate elemental colors"):
		return
	var before: float = game.telemetry.total_damage
	enemy.health = 5
	WeaponAttackShapes.hit(enemy, first.data, 1, 20, false, game.items, Vector2.RIGHT, first.affixes)
	if not _expect(is_equal_approx(game.telemetry.total_damage - before, 5), "overkill affixes inflated counted damage"):
		return
	game._clear_combat()
	await process_frame
	game._create_enemy(WaveController.BOSS, game.player.position + Vector2(500, 0))
	var boss: Enemy = game.get_node("Enemies").get_child(-1)
	boss.set_simulation_enabled(false)
	boss.boss_damage_budget = 10
	before = boss.health
	WeaponAttackShapes.hit(boss, first.data, 1, 1000, false, game.items, Vector2.RIGHT, first.affixes)
	if not _expect(is_equal_approx(before - boss.health, 10) and boss.boss_damage_budget == 0, "affixes bypassed shared boss damage budget"):
		return
	game._clear_combat()
	await process_frame
	game.wave.current_wave = 8
	game.wave.active = true
	game.rewards.chest_spawned = true
	game.rewards.treasure_spawned = true
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(700, 0), true)
	var treasure: Enemy = game.get_node("Enemies").get_child(-1)
	treasure.chill_time = 0.8
	var treasure_max := treasure.max_health
	if not _expect(treasure.treasure_carrier and treasure.sprite.modulate == ChestRewards.TREASURE_COLOR, "treasure carrier is not visibly golden"):
		return
	var pool: PlayerProjectilePool = game.get_node("Projectiles")
	var shot := pool.acquire(first.data, first.tier)
	shot.launch(Vector2(-3000, -3000), Vector2.RIGHT, 20, first.data, game.items, false, first.tier, first.affixes)
	var clean := pool.acquire(second.data, second.tier)
	clean.launch(Vector2(-3000, -3100), Vector2.RIGHT, 20, second.data, game.items, false, second.tier, second.affixes)
	if not _expect(shot.affixes[0].id == "fire" and clean.affixes[0].id == "poison", "projectiles borrowed affixes from the first weapon of their type"):
		return
	rng.seed = 4321
	var chest := WeaponAffixes.roll_chest(8, 40, loadout, true, rng)
	game._spawn_loot(game.player.position + Vector2(600, 0), &"chest", chest.scrap_coins, WeaponAffixes.CHEST_ID, chest)
	game._save_run()
	session.resume_requested = true
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game.wave.set_process(false)
	loadout = game.player.loadout
	first = loadout.equipped()[0]
	if not _expect(not paused and first.instance_uid == uid and first.affixes[0].damage == 8 and game.rewards.treasure_spawned, "combat resume lost weapon or treasure state"):
		return
	treasure = game.get_node("Enemies").get_child(0)
	if not _expect(treasure.treasure_carrier and is_equal_approx(treasure.max_health, treasure_max) and treasure.chill_time > 0, "resume lost golden durability or ice status"):
		return
	shot = game.get_node("Projectiles").get_child(0)
	if not _expect(shot.affixes[0].id == "fire" and shot.affixes.size() == 2, "combat resume lost in-flight projectile affixes"):
		return
	treasure.take_damage(99999)
	var drops: Array[Node] = game.get_node("Loot").get_children()
	var found := 0
	for drop: Loot in drops:
		if drop.reward_id == WeaponAffixes.CHEST_ID:
			found += 1
			if not _expect(drop.reward_data.golden and drop.reward_data.options.size() == 3, "ground chest lost its pre-rolled choices"):
				return
	if not _expect(found == 2, "golden kill did not guarantee a chest beyond the normal wave limit"):
		return
	var drop: Loot = drops[0]
	drop.global_position = game.player.global_position
	drop.advance_collection(0, game.player.global_position, 0)
	game._on_loot_collected(&"xp", 25)
	if not _expect(not paused and not game.weapon_chest_panel.visible and game.rewards.pending_chests.size() == 1 and game.rewards.pending_levels > 0, "combat pickup opened a reward modal"):
		return
	game.wave._process(game.wave.remaining)
	for frame in 180:
		await physics_frame
		if game.rewards.step == PostWaveRewards.Step.LEVELS:
			break
	if not _expect(game.get_node("Loot").get_child_count() == 0 and game.rewards.pending_chests.size() == 2 and not game.weapon_chest_panel.visible, "chest choices preceded loot sweep and level-ups"):
		return
	while game.rewards.pending_levels > 0:
		game.choice_panel._on_choice_pressed(0)
	if not _expect(paused and game.weapon_chest_panel.visible and not game.shop_panel.visible, "affix choices did not precede the shop"):
		return
	game.weapon_chest_panel._select_weapon(1)
	var frozen: Array = game.rewards.current_chest().options.duplicate(true)
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if not _expect(paused and game.weapon_chest_panel.visible and game.weapon_chest_panel.selected_weapon == 1 and game.rewards.current_chest().options == frozen, "resume rerolled choices or changed target weapon"):
		return
	for viewport in [Vector2i(1280, 720), Vector2i(360, 640), Vector2i(568, 320)]:
		root.content_scale_size = viewport
		root.size = viewport
		for frame in 4:
			await process_frame
		var rect: Rect2 = game.weapon_chest_panel.panel.get_global_rect()
		if not _expect(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= viewport.x + 1 and rect.end.y <= viewport.y + 1, "affix panel exceeds viewport " + str(viewport) + " " + str(rect) + " selector " + str(game.weapon_chest_panel.weapon_grid.get_combined_minimum_size())):
			return
	game.weapon_chest_panel.scrap_button.pressed.emit()
	game.weapon_chest_panel._select_weapon(0)
	var option_index := -1
	for index in 3:
		var option: Dictionary = game.rewards.current_chest().options[index]
		if WeaponAffixes.can_apply(game.player.loadout.equipped()[0], option, 0):
			option_index = index
			break
	game._on_affix_chosen(game.player.loadout.equipped()[0].instance_uid, option_index, 0)
	if not _expect(game.shop_panel.visible and not game.weapon_chest_panel.visible and game.rewards.pending_chests.is_empty(), "reward queue did not finish before shop"):
		return

	# Recycled shots must clear the previous owner's additions.
	var pool_after: PlayerProjectilePool = game.get_node("Projectiles")
	var weapon_after: WeaponInstance = game.player.loadout.equipped()[0]
	var recycled := pool_after.acquire(weapon_after.data, weapon_after.tier)
	recycled.launch(Vector2.ZERO, Vector2.RIGHT, 20, weapon_after.data, game.items, false, weapon_after.tier, weapon_after.affixes)
	recycled.retire()
	recycled = pool_after.acquire(weapon_after.data, weapon_after.tier)
	recycled.launch(Vector2.ZERO, Vector2.RIGHT, 20, weapon_after.data, game.items)
	if not _expect(recycled.affixes.is_empty() and recycled.affix_factor == 1.0, "recycled projectile leaked affixes"):
		return
	# A real evolution retains the primary identity and investment.
	game.player.loadout.restore([{"id": "turbo_drill", "tier": 4, "affix_slots": 2, "affixes": [{"id": "fire", "rarity": 3, "damage": 20}]}])
	game.items.acquire(ShopController.by_id(&"damage_1"))
	var evolving: WeaponInstance = game.player.loadout.equipped()[0]
	var evolving_uid := evolving.instance_uid
	if not _expect(game.player.loadout.evolve(0, WeaponEvolutions.by_id(&"root_breaker"), game.items), "affixed weapon could not evolve"):
		return
	evolving = game.player.loadout.equipped()[0]
	if not _expect(evolving.instance_uid == evolving_uid and evolving.affix_slots == 2 and evolving.affixes[0].damage == 20, "evolution lost affixes or identity"):
		return
	session.clear_run()
	paused = false
	print("Denti weapon affixes test passed")
	quit(0)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		paused = false
		root.get_node("GameSession").clear_run()
		push_error(message)
		quit(1)
	return condition
