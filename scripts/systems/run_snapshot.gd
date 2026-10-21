class_name RunSnapshot
extends RefCounted


static func capture(game) -> Dictionary:
	var enemies_data: Array[Dictionary] = []
	var enemy_indices: Dictionary = {}
	for enemy: Enemy in game.get_node("Enemies").get_children():
		enemy_indices[enemy.get_instance_id()] = enemies_data.size()
		enemies_data.append(enemy.save_state())
	var weapon_runtime: Array[Dictionary] = []
	var player_projectiles: Array[Dictionary] = []
	for projectile in game.get_node("Projectiles").get_children():
		if projectile is WeaponProjectile and not projectile.is_queued_for_deletion():
			player_projectiles.append(projectile.save_state(enemy_indices))
	for weapon: WeaponInstance in game.player.loadout.equipped():
		weapon_runtime.append({"cooldown": weapon.cooldown, "focus_hits": weapon.focus_hits,
			"focus_time": weapon.focus_time, "focus_target": enemy_indices.get(weapon.focus_target_id, -1),
			"motion": weapon.save_motion(enemy_indices)})
	var loot_data: Array[Dictionary] = []
	for drop: Loot in game.get_node("Loot").get_children():
		if drop.is_queued_for_deletion():
			continue
		loot_data.append({"position": SnapshotValues.vector_data(drop.position), "kind": str(drop.kind), "amount": drop.amount, "reward_id": str(drop.reward_id), "reward_data": drop.reward_data.duplicate(true)})
	var acid_data: Array[Dictionary] = []
	for projectile: AcidProjectile in game.get_node("EnemyProjectiles").get_children():
		if projectile.is_queued_for_deletion():
			continue
		acid_data.append({"position": SnapshotValues.vector_data(projectile.position), "direction": SnapshotValues.vector_data(projectile.direction), "speed": projectile.speed, "damage": projectile.damage, "lifetime": projectile.lifetime, "color": projectile.projectile_color.to_html(), "hit_radius": projectile.hit_radius, "visual_radius": projectile.visual_radius, "inflicted_statuses": projectile.inflicted_statuses.duplicate(true)})
	var result := {
		"base_victory": game.base_victory,
		"player": {"position": SnapshotValues.vector_data(game.player.position), "stats": game.player.stats.to_save_data(), "hurt_time": game.player.hurt_time, "dodge_time": game.player.dodge_time, "presentation": game.player.expressions.save_data(), "status_effects": game.player.status_effects.save_data()},
		"xp": game.xp, "xp_goal": game.xp_goal, "level": game.level, "coins": game.coins,
		"weapons": game.player.loadout.save_data(), "starter_pending": game.starter_pending,
		"starter_preview": str(game.choice_panel.starter_selection.selected_id) if game.starter_pending else "",
		"weapon_runtime": weapon_runtime,
		"player_projectiles": player_projectiles,
		"items": game.items.save_data(),
		"relics": game.relics.save_data(),
		"telemetry": game.telemetry.save_data(),
		"rewards": game.rewards.save_data(),
		"story": game.story.save_data(),
		"enemies": enemies_data, "loot": loot_data, "acid": acid_data,
		"shop": game.in_shop,
		"collecting_wave_loot": game.collecting_wave_loot,
		"upgrades": game.save_reward_choices(), "boss_pending": game.boss_pending,
	}
	result.merge(game.wave.save_state())
	result.player["dash"] = game.player.dash.save_data()
	result.merge(game.shop.save_state())
	return result



static func restore(game, saved: Dictionary) -> void:
	saved = RunSaveData.normalize(saved)
	if saved.is_empty():
		return
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	var wave: WaveController = game.wave
	var player: Player = game.player
	var shop: ShopController = game.shop
	game.story.restore(saved.get("story", {}))
	game.session.selected_story_mode = game.story.enabled
	game.arena.set_story_chapter(StoryCatalog.chapter(game.story.chapter_index) if game.story.enabled else null)
	wave.restore_state(saved, game.story.enabled)
	game.base_victory = bool(saved.get("base_victory", wave.endless_enabled))
	var player_data: Dictionary = saved.get("player", {})
	player.position = SnapshotValues.read_vector(player_data.get("position", [640.0, 360.0]))
	player.stats.load_save_data(player_data.get("stats", {}))
	player.hurt_time = maxf(float(player_data.get("hurt_time", 0.0)), 0.0)
	player.dodge_time = clampf(float(player_data.get("dodge_time", 0.0)), 0.0, Player.DODGE_IFRAMES)
	player.expressions.restore(player_data.get("presentation", {}))
	player.status_effects.restore(player_data.get("status_effects", {}))
	player.dash.restore(player_data.get("dash", {}))
	game.xp = maxi(int(saved.get("xp", 0)), 0)
	game.xp_goal = maxi(int(saved.get("xp_goal", 5)), 1)
	game.level = maxi(int(saved.get("level", 1)), 1)
	game.coins = maxi(int(saved.get("coins", 0)), 0)
	if saved.has("weapons"):
		# A lowered class/challenge limit never silently deletes owned equipment.
		player.loadout.restore(saved.get("weapons", []), false)
		# Existing saves with a successfully fused weapon also earn its encyclopedia entry.
		for weapon in player.loadout.equipped():
			for recipe in WeaponEvolutions.ALL:
				if weapon.data.id == recipe.result.id:
					game.get_node("/root/GameSession").discover_fusion(recipe.id)
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
		game._create_enemy(enemy_data, SnapshotValues.read_vector(entry.get("position", [0.0, 0.0])), bool(entry.get("treasure_carrier", false)))
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.restore_state(entry, bool(saved.get("boss_pending", false)))
	var runtime: Array = saved.get("weapon_runtime", [])
	var weapons := player.loadout.equipped()
	var restored_enemies: Array[Node] = game.get_node("Enemies").get_children()
	var projectiles := game.get_node("Projectiles") as PlayerProjectilePool
	for entry in saved.get("player_projectiles", []):
		if not entry is Dictionary:
			continue
		var data := WeaponCatalog.by_id(StringName(entry.get("id", "")))
		if data != null:
			data = WeaponRolls.resolve(data, entry.get("rolls", {}), entry.get("upgrades", {}))
			var projectile := projectiles.acquire(data, clampi(entry.get("tier", 1), 1, 4))
			projectile.restore_state(entry, game.items, restored_enemies, data)
	# Historic in-flight combinations can differ from the current equipment.
	# Restore those first, then keep the equipped styles ready before unpausing.
	projectiles.prepare_skins(weapons)
	for index in mini(runtime.size(), weapons.size()):
		if not runtime[index] is Dictionary:
			continue
		var entry: Dictionary = runtime[index]
		var weapon := weapons[index]
		weapon.cooldown = clampf(float(entry.get("cooldown", 0.0)), 0.0, 30.0)
		weapon.restore_motion(entry.get("motion", {}), restored_enemies)
		var target_index := int(entry.get("focus_target", -1))
		if target_index >= 0 and target_index < restored_enemies.size():
			weapon.focus_target_id = restored_enemies[target_index].get_instance_id()
			weapon.focus_hits = clampi(int(entry.get("focus_hits", 0)), 0, 1000)
			weapon.focus_time = clampf(float(entry.get("focus_time", 0.0)), 0.0, 30.0)
	for entry in saved.get("loot", []):
		var kind := StringName(str(entry.get("kind", "xp")))
		if kind == &"xp" or kind == &"coin" or kind == &"chest" and (ShopController.by_id(StringName(str(entry.get("reward_id", "")))) != null or not WeaponAffixes.sanitize_chest(entry.get("reward_data", {})).is_empty()):
			game._spawn_loot(SnapshotValues.read_vector(entry.get("position", [0.0, 0.0])), kind, maxi(int(entry.get("amount", 1)), 1), StringName(str(entry.get("reward_id", ""))), entry.get("reward_data", {}))
	for entry in saved.get("acid", []):
		var projectile := EnemyProjectilePatterns.acquire(game.get_node("EnemyProjectiles"))
		projectile.launch(SnapshotValues.read_vector(entry.get("position", [0.0, 0.0])), SnapshotValues.read_vector(entry.get("direction", [1.0, 0.0])), float(entry.get("speed", 290.0)), float(entry.get("damage", 8.0)), player, Color(str(entry.get("color", "87e021"))), float(entry.get("hit_radius", 21.0)), float(entry.get("visual_radius", 9.0)), DentiStatus.sanitize_attacks(entry.get("inflicted_statuses", [])))
		projectile.lifetime = float(entry.get("lifetime", 2.2))
	shop.restore_state(saved, wave.current_wave)
	game.in_shop = bool(saved.get("shop", false))
	game.boss_pending = bool(saved.get("boss_pending", false))
	game.starter_pending = bool(saved.get("starter_pending", false))
	game.telemetry.restore(saved.get("telemetry", {}), wave.current_wave)
	if game.telemetry.current_profile_id == &"":
		game.telemetry.current_profile_id = wave.current_profile_id
	game.restore_intermission(saved)


static func _enemy_from_path(path: String) -> EnemyData:
	return EnemyCatalog.by_path(path)
