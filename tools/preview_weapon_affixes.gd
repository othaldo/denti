extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://affix_preview.json"
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.current_wave = 12
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 2, "affix_slots": 2, "affixes": [{"id": "fire", "rarity": 1, "rank": 3, "damage": 5, "stacks": 3}]},
		{"id": "turbo_drill", "tier": 3, "affix_slots": 2, "affixes": [{"id": "poison", "rarity": 2, "damage": 6}, {"id": "bleed", "rarity": 1, "damage": 4}]},
		{"id": "enamel_mirror", "tier": 2, "affixes": [{"id": "electric", "rarity": 3, "damage": 12}]},
	])
	for weapon in game.player.loadout.equipped():
		weapon.set_physics_process(false)
	var reward := {"kind": "affix", "golden": false, "scrap_coins": 11, "options": [
		{"id": "fire", "rarity": 1, "damage": 3.0},
		{"id": "electric", "rarity": 3, "damage": 14.0},
		{"id": "ice", "rarity": 4, "damage": 25.0},
	]}
	game.rewards.queue_affix_chest(reward)
	game.rewards.step = PostWaveRewards.Step.CHESTS
	game._advance_post_wave_rewards()
	for extent in [Vector2i(1280, 720), Vector2i(360, 640)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 8:
			await process_frame
		await _capture("affix_chest_%dx%d" % [extent.x, extent.y])
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	game.weapon_chest_panel.hide()
	paused = false
	var first: WeaponInstance = game.player.loadout.equipped()[0]
	WeaponAffixes.apply(first, {"id": "ice", "rarity": 3, "damage": 8})
	var positions: Array[Vector2] = [Vector2(-110, -35), Vector2(120, 40), Vector2(75, -110)]
	var enemies: Array[Enemy] = []
	for index in 3:
		game._create_enemy(WaveController.SUGAR, game.player.position + positions[index])
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.max_health = 10000
		enemy.health = 10000
		enemy.set_simulation_enabled(false)
		enemies.append(enemy)
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(-160, 80), true)
	game.get_node("Enemies").get_child(-1).set_simulation_enabled(false)
	for frame in 8:
		await process_frame
	for index in 3:
		var weapon: WeaponInstance = game.player.loadout.equipped()[index]
		WeaponAttackShapes.hit(enemies[index], weapon.data, weapon.tier, 25, false, game.items, Vector2.RIGHT, weapon.affixes)
		enemies[index].affix_effects.advance(enemies[index], 0.5)
	await process_frame
	await _capture("affix_damage_1280x720")
	game._clear_combat()
	game.coins = 250
	game._open_shop()
	var rolls: Array[Dictionary] = [
		{"quality": 1, "damage": 0.65, "interval": 1.30, "range": 0.85, "crit": 0.01},
		{"quality": 4, "damage": 1.65, "interval": 0.75, "range": 1.23, "crit": 0.09},
		{"quality": 2, "damage": 1.1, "interval": 1.02, "range": 1.02, "crit": 0.04},
		{"quality": 3, "damage": 1.4, "interval": 0.9, "range": 1.12, "crit": 0.07}]
	for index in 4:
		var id: String = ["magic_toothbrush", "magic_toothbrush", "turbo_drill", "enamel_mirror"][index]
		var offer := ShopController.weapon_offer(ShopController.by_id(StringName(id)), [1, 1, 2, 3][index])
		offer.weapon_data = WeaponRolls.resolve(offer.weapon_data, rolls[index])
		game.shop.offers[index] = offer
	game._update_shop_panel()
	for frame in 8:
		await process_frame
	await _capture("weapon_rolls_shop_1280x720")
	game.shop_panel.hide()
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 4, "affix_slots": 3, "affixes": [{"id": "fire", "rarity": 4, "rank": 3, "damage": 35.5, "progress": 0.25}, {"id": "tempo", "rarity": 2, "damage": 7}]},
		{"id": "uv_lamp", "tier": 4, "affix_slots": 4, "affixes": [{"id": "poison", "rarity": 4, "rank": 2, "damage": 30}, {"id": "range", "rarity": 3, "damage": 14}, {"id": "tempo", "rarity": 2, "damage": 7}, {"id": "bleed", "rarity": 3, "damage": 14}]},
		{"id": "mouthwash_mortar", "tier": 4, "affix_slots": 3, "affixes": [{"id": "poison", "rarity": 4, "rank": 3, "damage": 35}]}
	])
	var expanded := {"kind": "affix", "options": [{"id": "range", "rarity": 2, "damage": 7}, {"id": "mk", "rarity": 4, "damage": 0}, {"id": "slot", "rarity": 3, "damage": 0}], "scrap_coins": 11}
	game.weapon_chest_panel.show_chest(expanded, game.player.loadout, game.player.stats, 11)
	for extent in [Vector2i(1280, 720), Vector2i(360, 640)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 8:
			await process_frame
		await _capture("weapon_chest_expansion_%dx%d" % [extent.x, extent.y])
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	game.weapon_chest_panel._select_weapon(1)
	for frame in 8:
		await process_frame
	await _capture("weapon_chest_expansion_progress")
	session.clear_run()
	quit(0)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")
