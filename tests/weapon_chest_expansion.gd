extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_chest_expansion.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	var hud_icon: TextureRect = game.hud.find_child("ChestIcon", true, false)
	assert(hud_icon != null and hud_icon.texture == CombatSpriteTextures.UPGRADE_CAPSULE, "HUD lost upgrade capsule")
	var drop := Loot.new()
	drop.configure(&"chest", 1, game.player)
	assert(drop.sprite.texture == hud_icon.texture and (drop.sprite.texture.get_size() * drop.sprite.scale).is_equal_approx(Vector2(32, 32)), "drop artwork or world size differs")
	drop.free()
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "magic_toothbrush", "tier": 4}])
	var weapon := loadout.equipped()[0]
	var template := weapon.data
	for number in 3:
		assert(WeaponAffixes.apply(weapon, {"id": "slot"}))
	assert(weapon.affix_slots == 4 and not WeaponAffixes.can_apply(weapon, {"id": "slot"}))
	assert(WeaponAffixes.apply(weapon, {"id": "range", "rarity": 3, "damage": 14}))
	assert(WeaponAffixes.apply(weapon, {"id": "tempo", "rarity": 2, "damage": 7}))
	assert(is_equal_approx(weapon.data.range_at_tier(4), template.range_at_tier(4) * 1.14))
	assert(is_equal_approx(weapon.data.interval_at_tier(4), template.interval_at_tier(4) / 1.07))
	assert(WeaponAffixes.packets(weapon.affixes, weapon.data, game.player.stats).is_empty(), "stat affixes cause elemental damage")
	for number in 2:
		assert(WeaponAffixes.apply(weapon, {"id": "mk"}))
	assert(WeaponPresentation.tier_text(weapon.data, 4) == "Mk VI")
	assert(is_equal_approx(weapon.data.base_damage, template.base_damage * 1.2))
	assert(is_equal_approx(weapon.data.range_at_tier(4), template.range_at_tier(4) * 1.20))
	var saved := loadout.save_data()
	loadout.restore(saved)
	weapon = loadout.equipped()[0]
	assert(weapon.affix_slots == 4 and WeaponPresentation.tier_text(weapon.data, 4) == "Mk VI")
	assert(is_equal_approx(weapon.data.base_damage, template.base_damage * 1.2), "resume compounds Mk bonuses")
	assert(WeaponAffixes.apply(weapon, {"id": "fire", "rarity": 4, "damage": 25}))
	var current := weapon.affixes[-1].duplicate(true)
	for number in 4:
		assert(WeaponAffixes.apply(weapon, {"id": "fire", "rarity": 2, "damage": 7}))
	assert(weapon.affixes[-1].rank == 2 and weapon.affixes[-1].damage == 30, "weaker funds stop progress")
	assert(WeaponAffixes.apply(weapon, {"id": "electric", "rarity": 1, "damage": 3}))
	assert(weapon.affixes.size() == 4)
	var pool: PlayerProjectilePool = game.get_node("Projectiles")
	var shot := pool.acquire(weapon.data, 4)
	shot.launch(Vector2.ZERO, Vector2.RIGHT, 10, weapon.data, game.items)
	var shot_saved := shot.save_state({})
	var restored := pool.acquire(template, 4)
	restored.restore_state(shot_saved, game.items, [])
	assert(WeaponPresentation.tier_text(restored.data, 4) == "Mk VI" and is_equal_approx(restored.data.range_at_tier(4), weapon.data.range_at_tier(4)), "in-flight projectile lost upgrades")
	var rng := RandomNumberGenerator.new()
	var mk_count := 0
	var stat_count := 0
	for number in 1000:
		rng.seed = number
		var chest := WeaponAffixes.roll_chest(12, 0, loadout, false, rng)
		assert(not WeaponAffixes.sanitize_chest(chest).is_empty())
		for option in chest.options:
			mk_count += int(option.id == "mk")
			stat_count += int(option.id in ["range", "tempo"])
	assert(mk_count >= 10 and mk_count < 50 and stat_count > 100, "rare Mk/stat rewards missing or too common")
	game._on_loot_collected(&"chest", 7, &"polish_paste")
	game._on_loot_collected(&"chest", 7, &"polish_paste")
	game._refresh_hud()
	assert(game.hud.chests_label.text == "2")
	var telemetry: Dictionary = game.telemetry.save_data()
	game.telemetry.begin_wave(2)
	game._refresh_hud()
	assert(game.hud.chests_label.text == "0")
	game.telemetry.restore(telemetry, 1)
	game._refresh_hud()
	assert(game.hud.chests_label.text == "2", "resume loses wave chest count")
	for template_offer in ShopController.CATALOG:
		if template_offer.weapon_data != null:
			assert(template_offer.weapon_tier <= 4)
	loadout.restore([{"id": "magic_toothbrush", "tier": 3}])
	assert(not WeaponAffixes.apply(loadout.equipped()[0], {"id": "mk"}))
	session.clear_run()
	paused = false
	print("PASS expanded slots, stat effects, weak progress, rare Mk, snapshots and wave counter")
	quit(0)
