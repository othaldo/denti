class_name RunSnapshot
extends RefCounted

const ACID_PROJECTILE: PackedScene = preload("res://scenes/enemies/acid_projectile.tscn")


static func capture(game) -> Dictionary:
	var enemies_data: Array[Dictionary] = []
	for enemy: Enemy in game.get_node("Enemies").get_children():
		enemies_data.append({
			"type": enemy.data.resource_path, "position": _vector_data(enemy.position),
			"health": enemy.health, "phase": enemy.special_phase,
			"timer": enemy.special_timer, "direction": _vector_data(enemy.special_direction),
		})
	var loot_data: Array[Dictionary] = []
	for drop: Loot in game.get_node("Loot").get_children():
		loot_data.append({"position": _vector_data(drop.position), "kind": str(drop.kind), "amount": drop.amount})
	var acid_data: Array[Dictionary] = []
	for projectile: AcidProjectile in game.get_node("EnemyProjectiles").get_children():
		acid_data.append({"position": _vector_data(projectile.position), "direction": _vector_data(projectile.direction), "speed": projectile.speed, "damage": projectile.damage, "lifetime": projectile.lifetime})
	var offer_data: Array[Dictionary] = []
	for offer in game.shop.offers:
		offer_data.append({"id": str(offer.id), "tier": offer.weapon_tier, "price": offer.price} if offer != null else {})
	var upgrades: Array[Dictionary] = []
	if game.choice_panel.visible and game.choice_panel.mode == &"upgrade":
		for upgrade in game.choice_panel.current_upgrades:
			upgrades.append({"stat": str(upgrade.stat), "tier": upgrade.tier})
	return {
		"wave": game.wave.current_wave, "remaining": game.wave.remaining,
		"spawn_cooldown": game.wave.spawn_cooldown, "active": game.wave.active,
		"horde_waves": game.wave.horde_waves, "horde_spawned": game.wave.horde_spawned,
		"player": {"position": _vector_data(game.player.position), "stats": game.player.stats.to_save_data(), "hurt_time": game.player.hurt_time},
		"xp": game.xp, "xp_goal": game.xp_goal, "level": game.level, "coins": game.coins,
		"weapons": game.player.loadout.save_data(), "starter_pending": game.starter_pending,
		"enemies": enemies_data, "loot": loot_data, "acid": acid_data,
		"shop": game.in_shop, "intermission_pending": game.intermission_pending,
		"offers": offer_data, "reroll_cost": game.shop.reroll_cost,
		"upgrades": upgrades, "boss_pending": game.boss_pending,
	}


static func restore(game, saved: Dictionary) -> void:
	var wave: WaveController = game.wave
	var player: Player = game.player
	var shop: ShopController = game.shop
	wave.current_wave = clampi(int(saved.get("wave", 1)), 1, WaveController.MAX_WAVES)
	wave.remaining = clampf(float(saved.get("remaining", WaveController.DURATION)), 0.0, WaveController.DURATION)
	wave.spawn_cooldown = maxf(float(saved.get("spawn_cooldown", 0.0)), 0.0)
	wave.active = bool(saved.get("active", true))
	wave.horde_waves.clear()
	for value in saved.get("horde_waves", []):
		wave.horde_waves.append(int(value))
	if wave.horde_waves.is_empty():
		wave.plan_hordes()
	wave.horde_spawned = bool(saved.get("horde_spawned", false))
	var player_data: Dictionary = saved.get("player", {})
	player.position = _read_vector(player_data.get("position", [640.0, 360.0]))
	player.stats.load_save_data(player_data.get("stats", {}))
	player.hurt_time = maxf(float(player_data.get("hurt_time", 0.0)), 0.0)
	game.xp = maxi(int(saved.get("xp", 0)), 0)
	game.xp_goal = maxi(int(saved.get("xp_goal", 5)), 1)
	game.level = maxi(int(saved.get("level", 1)), 1)
	game.coins = maxi(int(saved.get("coins", 0)), 0)
	if saved.has("weapons"):
		player.loadout.restore(saved.get("weapons", []))
	else:
		player.loadout.acquire(WeaponCatalog.by_id(&"magic_toothbrush"))
		for id_value in saved.get("owned_weapons", []):
			var old_id := StringName(str(id_value))
			var mapped_id := &"floss_whip" if old_id == &"floss" else (&"turbo_drill" if old_id == &"drill" else old_id)
			var old_weapon := WeaponCatalog.by_id(mapped_id)
			if old_weapon != null:
				player.loadout.acquire(old_weapon)
	for entry in saved.get("enemies", []):
		var enemy_data := _enemy_from_path(str(entry.get("type", "")))
		if enemy_data == null:
			continue
		game._create_enemy(enemy_data, _read_vector(entry.get("position", [0.0, 0.0])))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = clampf(float(entry.get("health", enemy.max_health)), 1.0, enemy.max_health)
		enemy.special_phase = clampi(int(entry.get("phase", 0)), 0, 2) as Enemy.SpecialPhase
		enemy.special_timer = maxf(float(entry.get("timer", 0.0)), 0.0)
		enemy.special_direction = _read_vector(entry.get("direction", [0.0, 0.0]))
	for entry in saved.get("loot", []):
		var kind := StringName(str(entry.get("kind", "xp")))
		if kind == &"xp" or kind == &"coin":
			game._spawn_loot(_read_vector(entry.get("position", [0.0, 0.0])), kind, maxi(int(entry.get("amount", 1)), 1))
	for entry in saved.get("acid", []):
		var projectile: AcidProjectile = ACID_PROJECTILE.instantiate()
		game.get_node("EnemyProjectiles").add_child(projectile)
		projectile.launch(_read_vector(entry.get("position", [0.0, 0.0])), _read_vector(entry.get("direction", [1.0, 0.0])), float(entry.get("speed", 290.0)), float(entry.get("damage", 8.0)), player)
		projectile.lifetime = float(entry.get("lifetime", 2.2))
	shop.reroll_cost = maxi(int(saved.get("reroll_cost", 2)), 2)
	shop.offers.clear()
	for value in saved.get("offers", []):
		var offer_id := str(value.get("id", "")) if value is Dictionary else str(value)
		if offer_id == "floss":
			offer_id = "floss_whip"
		elif offer_id == "drill":
			offer_id = "turbo_drill"
		var template := ShopController.by_id(StringName(offer_id))
		var found: ShopOfferData = null
		if template != null:
			if template.weapon_data != null and value is Dictionary:
				found = ShopController.weapon_offer(template, int(value.get("tier", 1)))
			else:
				found = template.duplicate() as ShopOfferData
			if value is Dictionary:
				found.price = maxi(int(value.get("price", found.price)), 1)
		shop.offers.append(found)
	game.in_shop = bool(saved.get("shop", false))
	game.intermission_pending = bool(saved.get("intermission_pending", false))
	game.boss_pending = bool(saved.get("boss_pending", false))
	game.starter_pending = bool(saved.get("starter_pending", false))
	if game.starter_pending:
		game.choice_panel.show_starters(WeaponCatalog.STARTERS)
		game.get_tree().paused = true
		game._refresh_hud()
		return
	var upgrade_data: Array = saved.get("upgrades", [])
	if upgrade_data.size() == 3:
		var options: Array[UpgradeData] = []
		for value in upgrade_data:
			for upgrade in game.UPGRADES:
				if value is Dictionary and str(upgrade.stat) == str(value.get("stat", "")):
					options.append(upgrade.with_tier(int(value.get("tier", 1))))
					break
				if value is String and upgrade.resource_path == value:
					options.append(upgrade.with_tier(1))
					break
		if options.size() == 3:
			game.choice_panel.show_upgrades(options)
			game.get_tree().paused = true
	elif game.in_shop:
		if shop.offers.size() != 3:
			shop.open_shop(wave.current_wave, player.stats.luck, player.loadout)
		game._update_shop_panel()
		game.get_tree().paused = true
	game._refresh_hud()


static func _enemy_from_path(path: String) -> EnemyData:
	for candidate in [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.BOSS, WaveController.FINAL_BOSS]:
		if candidate.resource_path == path:
			return candidate
	return null


static func _vector_data(value: Vector2) -> Array[float]:
	return [value.x, value.y]


static func _read_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
