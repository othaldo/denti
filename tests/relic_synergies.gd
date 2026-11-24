extends "res://tests/support/test_runtime.gd"

## Synergy relics: open to every class, four choices after a milestone boss,
## and the effect of each of the twelve relics on its general mechanic.

var game: Node2D
var relics: RelicInventory

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_catalog()
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://relic_synergies_test.json"
	session.clear_run()
	session.pending_start_weapon_id = &"turbo_drill"
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	game.wave.set_process(false)
	game.wave.active = true
	relics = game.relics
	await _weapons()
	await _poison()
	await _loot()
	await _elements()
	await _control()
	_snapshot()
	game.queue_free()
	await process_frame
	session.clear_run()
	if failures.is_empty(): print("relic synergies ok")
	finish_checks()

func _catalog() -> void:
	check(RelicCatalog.OFFER_COUNT == 4 and RelicCatalog.CATALOG.size() == 18, "expected 18 relics and four choices")
	var names := {}
	for relic in RelicCatalog.CATALOG:
		check(not relic.display_name.is_empty() and not relic.description.is_empty() and DentiUIIcons.relic_icon(relic) != null, "relic presentation incomplete: " + str(relic.id))
		check(not names.has(relic.display_name), "duplicate relic name: " + relic.display_name)
		names[relic.display_name] = true
		for profile in ClassCatalog.profiles:
			check(not relic.display_name.contains(profile.display_name), "relic named after a class: " + relic.display_name)
	for sample in 40:
		seed(sample)
		var tags: Array[StringName] = [&"fire"]
		var choices := RelicCatalog.choices([], tags)
		check(choices.size() == RelicCatalog.OFFER_COUNT and choices.has("tinder_tooth"), "fire build missed its matching relic")
	var owned: Array[String] = []
	for relic in RelicCatalog.CATALOG: owned.append(str(relic.id))
	check(RelicCatalog.choices(owned).is_empty(), "exhausted pool offered a relic")

func _enemy(offset: Vector2, health: float = 10000.0, data: EnemyData = WaveController.PLAQUE) -> Enemy:
	game._create_enemy(data, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = health
	enemy.max_health = maxf(health, 10000.0)
	enemy.damage_reduction = 0
	return enemy

func _clear() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	for drop in game.get_node("Loot").get_children(): drop.queue_free()
	relics.owned.clear()
	relics.on_wave_start()
	await process_frame

func _weapons() -> void:
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	var scaler := WeaponCatalog.by_id(&"plaque_scaler")
	var target := _enemy(Vector2(60, 0))
	relics.acquire(&"dental_brace")
	relics.on_weapon_hit(target, 100.0, drill, false)
	relics.on_weapon_hit(target, 100.0, drill, false)
	check(target.health == 10000.0, "the same weapon twice triggered the brace")
	relics.synergies.advance(0.2)
	relics.on_weapon_hit(target, 100.0, scaler, false)
	check(is_equal_approx(target.health, 10000.0 - 40.0), "two weapons did not add a 40 %% strike: %s" % target.health)
	relics.acquire(&"bell_crown")
	relics.on_shield_blocked()
	check(relics.synergies.bell_cooldown > 0.0, "a blocked hit did not make the weapons attack")
	var cooldown := relics.synergies.bell_cooldown
	relics.on_shield_blocked()
	check(relics.synergies.bell_cooldown == cooldown, "Glockenkrone ignored its cooldown")
	relics.acquire(&"heat_stone")
	for index in 3: _enemy(Vector2(40 + index * 20, 30))
	relics.synergies.heat_refresh = 0.0
	relics.synergies.advance(0.0)
	check(relics.weapon_damage_bonus(target) == 4 * RelicSynergies.HEAT_PER_ENEMY, "Hitzestein did not count the crowd: %s" % relics.weapon_damage_bonus(target))
	await _clear()

func _poison() -> void:
	var target := _enemy(Vector2(60, 0))
	var neighbour := _enemy(Vector2(100, 20))
	var poison: Array[Dictionary] = [{"id": "poison", "damage": 40.0}]
	target.take_damage(0, null, false, &"", poison)
	relics.acquire(&"shadow_floss")
	relics.on_weapon_hit(target, 10.0, WeaponCatalog.by_id(&"turbo_drill"), false)
	check(neighbour.affix_effects.budget(&"poison") == 0.0, "Schattenseide spread poison without a dash")
	relics.on_dash_started()
	relics.on_weapon_hit(target, 10.0, WeaponCatalog.by_id(&"turbo_drill"), false)
	var spread := neighbour.affix_effects.budget(&"poison")
	check(spread > 0.0, "the first hit after a dash did not spread poison")
	relics.on_weapon_hit(target, 10.0, WeaponCatalog.by_id(&"turbo_drill"), false)
	check(neighbour.affix_effects.budget(&"poison") == spread, "a second hit after one dash spread again")
	relics.acquire(&"belladonna")
	check(relics.weapon_damage_bonus(target) == RelicSynergies.BELLADONNA_BONUS, "poisoned enemy near Denti took no bonus")
	var far := _enemy(Vector2(600, 0))
	far.take_damage(0, null, false, &"", poison)
	check(relics.weapon_damage_bonus(far) == 0.0, "Tollkirsche reached a distant enemy")
	await _clear()

func _loot() -> void:
	game._spawn_loot(game.player.global_position + Vector2(260, 0), &"coin", 1)
	var drop: Loot = game.get_node("Loot").get_child(-1)
	game.player.dash.remaining = 0.2
	relics.synergies.advance(0.0)
	check(not drop.wave_collecting, "loot flew without the tin")
	relics.acquire(&"milk_tooth_tin")
	relics.synergies.advance(0.0)
	check(drop.wave_collecting, "dashing did not draw loot with the tin")
	game.player.dash.remaining = 0.0
	var target := _enemy(Vector2(120, 0))
	relics.acquire(&"lucky_penny")
	game.player.stats.luck = 10000.0
	seed(7)
	# The chance is capped below certainty; a handful of coins must fire.
	for coin in 8: relics.on_loot_collected(&"coin")
	check(target.health < 10000.0, "lucky coins fired no shard")
	var health := target.health
	relics.on_loot_collected(&"xp")
	check(target.health == health, "experience fired a coin shard")
	game.player.stats.luck = 0.0
	await _clear()

func _elements() -> void:
	var burning := _enemy(Vector2(60, 0))
	var neighbour := _enemy(Vector2(90, 20))
	var fire: Array[Dictionary] = [{"id": "fire", "damage": 30.0}]
	burning.take_damage(0, null, false, &"", fire)
	relics.acquire(&"tinder_tooth")
	relics.on_enemy_died(burning, 0.0)
	check(neighbour.affix_effects.budget(&"fire") > 0.0, "a burning death set no neighbour alight")
	var wet := _enemy(Vector2(300, 0))
	var other := _enemy(Vector2(340, 30))
	wet.apply_wet(3.0)
	relics.acquire(&"copper_crown")
	relics.on_weapon_hit(wet, 100.0, WeaponCatalog.by_id(&"water_jet"), false)
	check(other.health == 10000.0, "the current jumped to a dry enemy")
	other.apply_wet(3.0)
	relics.synergies.copper_cooldown = 0.0
	relics.on_weapon_hit(wet, 100.0, WeaponCatalog.by_id(&"water_jet"), false)
	check(other.health < 10000.0, "the current did not jump between wet enemies")
	await _clear()

func _control() -> void:
	var drifter := _enemy(Vector2(200, 0))
	relics.acquire(&"rinse_whirl")
	relics.on_dash_started()
	check(drifter.global_position.distance_to(game.player.global_position) < 200.0 - 30.0, "the dash whirl did not draw enemies in")
	var slowed := _enemy(Vector2(-100, 0))
	var near := _enemy(Vector2(-140, 20))
	slowed.chill_time = 1.0
	relics.acquire(&"ice_flower")
	relics.on_enemy_died(slowed, 0.0)
	check(near.chill_time > 0.0, "Eisblume did not slow the neighbour")
	var boss := _enemy(Vector2(0, 200), 10000.0, WaveController.BOSS)
	boss.set_simulation_enabled(false)
	relics.acquire(&"glacier_heart")
	check(relics.weapon_damage_bonus(boss) == 0.0, "Gletscherherz acted on an unslowed boss")
	boss.chill_time = 1.0
	check(relics.weapon_damage_bonus(boss) == RelicSynergies.GLACIER_BONUS, "slowed boss took no bonus")
	near.chill_time = 1.0
	check(relics.weapon_damage_bonus(near) == 0.0, "Gletscherherz affected an ordinary enemy")
	await _clear()

func _snapshot() -> void:
	relics.acquire(&"glacier_heart")
	relics.acquire(&"sun_mark")
	var restored := RelicInventory.new()
	restored.restore(relics.save_data())
	check(restored.owned == relics.owned, "relics lost on resume")
	var legacy := relics.save_data()
	legacy.owned.append("frost_ice_flower")
	restored.restore(legacy)
	check(not restored.owned.has("frost_ice_flower"), "removed class relic survived a resume")
	restored.free()
