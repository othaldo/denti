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
			"boss_move": enemy.boss_move, "boss_charge_next": enemy.boss_charge_next,
			"boss_dash_end": _vector_data(enemy.boss_dash_end), "boss_dash_origin": _vector_data(enemy.boss_dash_origin),
			"dying": enemy.dying, "death_elapsed": enemy.death_elapsed, "enraged": enemy.is_enraged,
			"bleed_stacks": enemy.bleed_stacks, "bleed_dps": enemy.bleed_dps,
			"bleed_time": enemy.bleed_time, "bleed_tick": enemy.bleed_tick,
			"wet_time": enemy.wet_time,
			"haste_time": enemy.haste_time, "haste_bonus": enemy.haste_bonus,
			"aura_timer": enemy.aura_timer,
			"boss_damage_budget": enemy.boss_damage_budget, "boss_phase": enemy.boss_phase,
			"elite_damage_budget": enemy.elite_damage_budget,
			"boss_phase_timer": enemy.boss_phase_timer,
			"boss_phase_burst_fired": enemy.boss_phase_burst_fired,
			"boss_phase_gap_angle": enemy.boss_phase_gap_angle,
			"boss_radial_volleys_remaining": enemy.boss_radial_volleys_remaining,
			"boss_radial_volley_timer": enemy.boss_radial_volley_timer,
			"boss_radial_volley_index": enemy.boss_radial_volley_index,
		})
	var loot_data: Array[Dictionary] = []
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.is_queued_for_deletion():
			continue
		loot_data.append({"position": _vector_data(drop.position), "kind": str(drop.kind), "amount": drop.amount, "reward_id": str(drop.reward_id)})
	var acid_data: Array[Dictionary] = []
	for projectile: AcidProjectile in game.get_node("EnemyProjectiles").get_children():
		acid_data.append({"position": _vector_data(projectile.position), "direction": _vector_data(projectile.direction), "speed": projectile.speed, "damage": projectile.damage, "lifetime": projectile.lifetime, "color": projectile.projectile_color.to_html(), "hit_radius": projectile.hit_radius, "visual_radius": projectile.visual_radius})
	var offer_data: Array[Dictionary] = []
	for offer in game.shop.offers:
		offer_data.append({"id": str(offer.id), "tier": offer.weapon_tier, "price": offer.price} if offer != null else {})
	var upgrades: Array[Dictionary] = []
	if game.choice_panel.visible and game.choice_panel.mode == &"upgrade":
		for upgrade in game.choice_panel.current_upgrades:
			upgrades.append({"stat": str(upgrade.stat), "tier": upgrade.tier})
	return {
		"wave": game.wave.current_wave, "duration": game.wave.duration, "remaining": game.wave.remaining,
		"spawn_cooldown": game.wave.spawn_cooldown, "active": game.wave.active,
		"horde_waves": game.wave.horde_waves, "horde_spawned": game.wave.horde_spawned,
		"burst_times": game.wave.burst_times, "burst_index": game.wave.burst_index,
		"elite_time": game.wave.elite_time, "elite_spawned": game.wave.elite_spawned,
		"current_profile_id": str(game.wave.current_profile_id), "next_profile_id": str(game.wave.next_profile_id),
		"player": {"position": _vector_data(game.player.position), "stats": game.player.stats.to_save_data(), "hurt_time": game.player.hurt_time},
		"xp": game.xp, "xp_goal": game.xp_goal, "level": game.level, "coins": game.coins,
		"weapons": game.player.loadout.save_data(), "starter_pending": game.starter_pending,
		"items": game.items.save_data(),
		"relics": game.relics.save_data(),
		"telemetry": game.telemetry.save_data(),
		"rewards": game.rewards.save_data(),
		"enemies": enemies_data, "loot": loot_data, "acid": acid_data,
		"shop": game.in_shop,
		"collecting_wave_loot": game.collecting_wave_loot,
		"offers": offer_data, "reroll_cost": game.shop.reroll_cost,
		"upgrades": upgrades, "boss_pending": game.boss_pending,
	}


static func restore(game, saved: Dictionary) -> void:
	var wave: WaveController = game.wave
	var player: Player = game.player
	var shop: ShopController = game.shop
	wave.current_wave = clampi(int(saved.get("wave", 1)), 1, WaveController.MAX_WAVES)
	wave.duration = clampf(float(saved.get("duration", WaveController.DURATION)), 1.0, 120.0)
	wave.remaining = clampf(float(saved.get("remaining", wave.duration)), 0.0, wave.duration)
	wave.spawn_cooldown = maxf(float(saved.get("spawn_cooldown", 0.0)), 0.0)
	wave.active = bool(saved.get("active", true))
	wave.horde_waves.clear()
	for value in saved.get("horde_waves", []):
		wave.horde_waves.append(int(value))
	if wave.horde_waves.is_empty():
		wave.plan_hordes()
	wave.horde_spawned = bool(saved.get("horde_spawned", false))
	if saved.has("burst_times"):
		wave.burst_times.clear()
		for value in saved.get("burst_times", []):
			wave.burst_times.append(float(value))
		wave.burst_index = clampi(int(saved.get("burst_index", 0)), 0, wave.burst_times.size())
	else:
		wave.plan_bursts()
		while wave.burst_index < wave.burst_times.size() and wave.burst_times[wave.burst_index] <= wave.duration - wave.remaining:
			wave.burst_index += 1
	wave.elite_time = clampf(float(saved.get("elite_time", -1.0)), -1.0, wave.duration)
	wave.elite_spawned = bool(saved.get("elite_spawned", false))
	wave.current_profile_id = StringName(str(saved.get("current_profile_id", "")))
	wave.next_profile_id = StringName(str(saved.get("next_profile_id", "")))
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
	game.items.restore(saved.get("items", {}))
	game.relics.restore(saved.get("relics", {}))
	game.rewards.restore(saved.get("rewards", {}))
	for entry in saved.get("enemies", []):
		var enemy_data := _enemy_from_path(str(entry.get("type", "")))
		if enemy_data == null:
			continue
		game._create_enemy(enemy_data, _read_vector(entry.get("position", [0.0, 0.0])))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.dying = bool(entry.get("dying", false))
		enemy.health = 0.0 if enemy.dying else clampf(float(entry.get("health", enemy.max_health)), 1.0, enemy.max_health)
		enemy.special_phase = clampi(int(entry.get("phase", 0)), 0, 2) as Enemy.SpecialPhase
		enemy.special_timer = maxf(float(entry.get("timer", 0.0)), 0.0)
		enemy.special_direction = _read_vector(entry.get("direction", [0.0, 0.0]))
		enemy.boss_move = clampi(int(entry.get("boss_move", Enemy.BossMove.PULSE)), 0, 1) as Enemy.BossMove
		enemy.boss_charge_next = bool(entry.get("boss_charge_next", true))
		enemy.boss_dash_end = _read_vector(entry.get("boss_dash_end", [0.0, 0.0]))
		enemy.boss_dash_origin = _read_vector(entry.get("boss_dash_origin", [0.0, 0.0]))
		enemy.death_elapsed = clampf(float(entry.get("death_elapsed", 0.0)), 0.0, Enemy.BOSS_DEATH_DURATION)
		enemy.is_enraged = bool(entry.get("enraged", enemy.health <= enemy.max_health * 0.5 and enemy.data.is_boss))
		if enemy.dying:
			enemy.remove_from_group("enemies")
		enemy.bleed_stacks = clampi(int(entry.get("bleed_stacks", 0)), 0, 5)
		enemy.bleed_dps = maxf(float(entry.get("bleed_dps", 0.0)), 0.0)
		enemy.bleed_time = maxf(float(entry.get("bleed_time", 0.0)), 0.0)
		enemy.bleed_tick = clampf(float(entry.get("bleed_tick", 1.0)), 0.0, 1.0)
		enemy.wet_time = maxf(float(entry.get("wet_time", 0.0)), 0.0)
		enemy.haste_time = clampf(float(entry.get("haste_time", 0.0)), 0.0, Enemy.AURA_HASTE_DURATION)
		enemy.haste_bonus = clampf(float(entry.get("haste_bonus", 0.0)), 0.0, 1.0)
		enemy.aura_timer = clampf(float(entry.get("aura_timer", 0.0)), 0.0, Enemy.AURA_PULSE_INTERVAL)
		if enemy.data.is_elite:
			enemy.elite_damage_budget = clampf(float(entry.get("elite_damage_budget", enemy.elite_damage_budget)), 0.0, enemy.max_health * enemy.data.elite_guard_fraction)
		if enemy.data.is_boss:
			enemy.boss_phase = clampi(int(entry.get("boss_phase", 2 if enemy.health <= enemy.max_health / 3.0 else (1 if enemy.health <= enemy.max_health * 2.0 / 3.0 else 0))), 0, 2)
			enemy.boss_damage_budget = clampf(float(entry.get("boss_damage_budget", enemy.boss_damage_budget)), 0.0, enemy.max_health * enemy.data.boss_guard_burst_fraction)
			enemy.boss_phase_timer = clampf(float(entry.get("boss_phase_timer", 0.0)), 0.0, enemy.data.boss_phase_duration)
			enemy.boss_phase_burst_fired = bool(entry.get("boss_phase_burst_fired", false))
			enemy.boss_phase_gap_angle = float(entry.get("boss_phase_gap_angle", 0.0))
			enemy.boss_radial_volleys_remaining = clampi(int(entry.get("boss_radial_volleys_remaining", 0)), 0, enemy.data.boss_radial_volley_count)
			enemy.boss_radial_volley_timer = clampf(float(entry.get("boss_radial_volley_timer", 0.0)), 0.0, enemy.data.boss_radial_volley_interval)
			enemy.boss_radial_volley_index = clampi(int(entry.get("boss_radial_volley_index", 0)), 0, enemy.data.boss_radial_volley_count)
		enemy.queue_redraw()
	for entry in saved.get("loot", []):
		var kind := StringName(str(entry.get("kind", "xp")))
		if kind == &"xp" or kind == &"coin" or kind == &"chest" and ShopController.by_id(StringName(str(entry.get("reward_id", "")))) != null:
			game._spawn_loot(_read_vector(entry.get("position", [0.0, 0.0])), kind, maxi(int(entry.get("amount", 1)), 1), StringName(str(entry.get("reward_id", ""))))
	for entry in saved.get("acid", []):
		var projectile: AcidProjectile = ACID_PROJECTILE.instantiate()
		game.get_node("EnemyProjectiles").add_child(projectile)
		projectile.launch(_read_vector(entry.get("position", [0.0, 0.0])), _read_vector(entry.get("direction", [1.0, 0.0])), float(entry.get("speed", 290.0)), float(entry.get("damage", 8.0)), player, Color(str(entry.get("color", "87e021"))), float(entry.get("hit_radius", 21.0)), float(entry.get("visual_radius", 9.0)))
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
	game.boss_pending = bool(saved.get("boss_pending", false))
	game.starter_pending = bool(saved.get("starter_pending", false))
	game.telemetry.restore(saved.get("telemetry", {}), wave.current_wave)
	if game.telemetry.current_profile_id == &"":
		game.telemetry.current_profile_id = wave.current_profile_id
	var upgrade_data: Array = saved.get("upgrades", [])
	if not saved.has("rewards"):
		if game.in_shop:
			game.rewards.step = PostWaveRewards.Step.SHOP
		elif upgrade_data.size() == 3:
			game.rewards.pending_levels = 1
			game.rewards.step = PostWaveRewards.Step.COMBAT if wave.active or game.boss_pending else PostWaveRewards.Step.LEVELS
		elif bool(saved.get("intermission_pending", false)):
			game.rewards.step = PostWaveRewards.Step.SHOP
	if bool(saved.get("collecting_wave_loot", false)):
		game._begin_loot_collection()
		return
	if game.starter_pending:
		game.choice_panel.show_starters(WeaponCatalog.STARTERS)
		game.get_tree().paused = true
		game._refresh_hud()
		return
	if game.rewards.step == PostWaveRewards.Step.LEVELS and upgrade_data.size() == 3:
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
		else:
			game._advance_post_wave_rewards()
	elif game.rewards.step == PostWaveRewards.Step.CHESTS or game.rewards.step == PostWaveRewards.Step.RELICS:
		game._advance_post_wave_rewards()
	elif game.rewards.step == PostWaveRewards.Step.LEVELS:
		game._advance_post_wave_rewards()
	elif game.in_shop or game.rewards.step == PostWaveRewards.Step.SHOP:
		if shop.offers.size() != 3:
			shop.open_shop(wave.current_wave, player.stats.luck, player.loadout, game.items)
		game.in_shop = true
		game._update_shop_panel()
		game.get_tree().paused = true
	game._refresh_hud()


static func _enemy_from_path(path: String) -> EnemyData:
	for candidate in [
		WaveController.PLAQUE,
		WaveController.BACTERIA,
		WaveController.SUGAR,
		WaveController.ACID_SPITTER,
		WaveController.ACID_CROWN,
		WaveController.HUNT_GERM,
		WaveController.CAVITY_COUNT,
		WaveController.CAVITY_PRINCE,
		WaveController.CAVITY_KING,
		WaveController.CAVITY_EMPEROR,
	]:
		if candidate.resource_path == path:
			return candidate
	return null


static func _vector_data(value: Vector2) -> Array[float]:
	return [value.x, value.y]


static func _read_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
