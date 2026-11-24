extends "res://tests/support/test_runtime.gd"
## Synergy items (docs/ITEM_SYNERGY_EXPANSION.md): catalog entries and the
## effect of every one of the 14 items, plus mint leaf loot and save/resume.

const IDS: Array[StringName] = [&"flower_pot", &"fertilizer", &"root_net", &"pocket_bed", &"floss_trap",
	&"spring_coil", &"echo_crown", &"slide_wax", &"catalyst", &"thermos", &"storm_cloud",
	&"mint_bed", &"spicy_paste", &"compost"]

var game: Node2D
var synergies: SynergyItems


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_catalog()
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://item_synergies_test.json"
	session.clear_run()
	session.pending_start_weapon_id = &"turbo_drill"
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	if game.starter_pending: choose_panel(game.choice_panel, 0)
	game.wave.set_process(false)
	game.wave.active = true
	synergies = game.synergies
	check(synergies != null and synergies.name == "Synergies", "synergy node missing")
	await _group_a()
	await _group_b()
	await _group_c()
	await _group_d()
	game.queue_free()
	await process_frame
	session.clear_run()
	if failures.is_empty(): print("item synergies ok")
	finish_checks()


func _catalog() -> void:
	for index in IDS.size():
		var id := IDS[index]
		var item := ItemCatalog.by_id(id)
		check(item != null and item in ItemCatalog.ALL, "item missing: " + str(id))
		if item == null: continue
		check(item.effect_kind != &"" and item.max_stacks > 0 and not item.description.is_empty(), "item incomplete: " + str(id))
		var icon := DentiUIIcons.item(item.icon_index) as AtlasTexture
		var cell := Vector2(index % 7, floori(index / 7.0))
		var expected := Rect2(cell * 256.0, Vector2(256, 256))
		check(icon != null and icon.atlas == DentiUIIcons.ITEM_SYNERGY and icon.region == expected, "wrong icon atlas cell: " + str(id))
		check(not item.description.contains("px"), "pixel value in text: " + str(id))


func _give(id: StringName, copies: int = 1) -> void:
	for copy in copies: game.items.acquire(ItemCatalog.by_id(id))


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
	for drop in game.get_node("Loot").get_children(): drop.queue_free()
	game.items.restore({})
	synergies.reset_wave()
	await process_frame


func _group_a() -> void:
	# Blumentopf lengthens placed things.
	var pot: float = game.items.power(&"placed_duration")
	_give(&"flower_pot", 2)
	check(is_equal_approx(game.items.power(&"placed_duration"), pot + 0.3) and is_equal_approx(synergies.placed_duration_factor(), 1.3), "Blumentopf factor wrong")
	await _clear()
	# Dünger: summon factors.
	_give(&"fertilizer")
	check(is_equal_approx(synergies.summon_damage_factor(), 1.12) and is_equal_approx(synergies.summon_health_factor(), 1.24), "Dünger factors wrong")
	await _clear()
	# Taschenbeet: a wild sprout after enough kills, which then shoots.
	_give(&"pocket_bed")
	var target := _enemy(Vector2(120, 0))
	for kill in SynergyItems.SPROUT_KILLS - SynergyItems.SPROUT_KILLS_PER_COPY:
		synergies.on_kill(game.player.global_position, WaveController.PLAQUE)
	check(synergies.sprouts.size() == 1, "no wild sprout after the kill threshold")
	synergies.sprouts[0].shot = 0.0
	synergies._process(0.05)
	check(target.health < 10000.0, "wild sprout did not shoot")
	# Wurzelnetz counts the sprout as a summon near Denti.
	_give(&"root_net")
	synergies.net_refresh = 0.0
	synergies._process(0.01)
	check(synergies.net_count >= 1 and synergies.weapon_damage_bonus() >= 3.0, "Wurzelnetz ignored a summon nearby")
	synergies.net_count = 50
	check(synergies.weapon_damage_bonus() == SynergyItems.NET_CAP, "Wurzelnetz bonus not capped")
	await _clear()
	# Zahnseidenfalle: a dash trap explodes on the first enemy.
	_give(&"floss_trap")
	synergies.on_dash_started()
	check(synergies.traps.size() == 1, "dash laid no trap")
	var victim := _enemy(Vector2(10, 0))
	synergies._process(0.01)
	check(synergies.traps.is_empty() and victim.health < 10000.0, "trap did not explode")
	await _clear()


func _group_b() -> void:
	# Sprungfeder: one more dash charge.
	var before: float = game.player.stats.max_stamina()
	_give(&"spring_coil")
	check(is_equal_approx(game.player.stats.max_stamina(), before + game.player.stats.class_data.dash_config().cost), "Sprungfeder gave no dash charge")
	await _clear()
	check(is_equal_approx(game.player.stats.max_stamina(), before), "dash charge survived losing the item")
	# Nachhall-Krone: weapons attack at dash end, then a cooldown.
	_give(&"echo_crown")
	_enemy(Vector2(40, 0))
	for weapon in game.player.loadout.equipped():
		weapon.attack_time = 0.0
		weapon.cooldown = 0.0
	synergies.on_dash_ended()
	check(synergies.volley_cooldown > 0.0, "Nachhall-Krone did not fire")
	var cooldown: float = synergies.volley_cooldown
	synergies.on_dash_ended()
	check(synergies.volley_cooldown == cooldown, "Nachhall-Krone ignored its cooldown")
	await _clear()
	# Rutschwachs: a short damage window after a dash.
	_give(&"slide_wax")
	check(synergies.weapon_damage_bonus() == 0.0, "Rutschwachs active without a dash")
	synergies.on_dash_ended()
	check(is_equal_approx(synergies.weapon_damage_bonus(), 30.0), "Rutschwachs window missing")
	synergies._process(SynergyItems.SLIDE_SECONDS + 0.01)
	check(synergies.weapon_damage_bonus() == 0.0, "Rutschwachs window did not end")
	await _clear()


func _group_c() -> void:
	# Gewitterwolke: electric enchantment hits leave the target wet.
	_give(&"storm_cloud")
	var target := _enemy(Vector2(60, 0))
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	var shock: Array[Dictionary] = [{"id": "electric", "rarity": 2, "damage": 6.0}]
	WeaponEnchantmentEffects.after_hit(game.items.effect_context, target, drill, shock, false, 10.0, 1.0, false)
	check(target.wet_time > 0.0, "Gewitterwolke did not wet the target")
	await _clear()
	# Thermoskanne: fire on a chilled target hits enemies nearby.
	_give(&"thermos")
	target = _enemy(Vector2(60, 0))
	var neighbour := _enemy(Vector2(90, 10))
	var fire: Array[Dictionary] = [{"id": "fire", "rarity": 2, "damage": 6.0}]
	WeaponEnchantmentEffects.after_hit(game.items.effect_context, target, drill, fire, false, 10.0, 1.0, true)
	check(neighbour.health < 10000.0 or target.health < 10000.0, "Thermoskanne did not burst")
	await _clear()
	# Katalysator raises the reaction multiplier read in ElementReactions.
	_give(&"catalyst", 2)
	check(is_equal_approx(game.items.power(&"reaction_damage"), 0.8), "Katalysator power wrong")
	await _clear()


func _group_d() -> void:
	# Minzbeet: elites and every n-th kill drop a mint leaf.
	_give(&"mint_bed")
	var loot: Node = game.get_node("Loot")
	var elite := WaveController.PLAQUE.duplicate() as EnemyData
	elite.is_elite = true
	synergies.on_kill(game.player.global_position + Vector2(200, 0), elite)
	await process_frame
	var mints := loot.get_children().filter(func(drop: Node) -> bool: return drop is Loot and drop.kind == &"mint")
	check(mints.size() == 1, "elite dropped no mint leaf")
	if mints.size() == 1:
		var mint := mints[0] as Loot
		check(mint.sprite.texture == CombatSpriteTextures.MINT_LEAF, "mint pickup did not use its painted sprite")
	# Mint leaves heal, Scharfe Zahnpasta bursts around Denti.
	_give(&"spicy_paste")
	var stats: PlayerStats = game.player.stats
	stats.health = stats.max_health - 20.0
	var near := _enemy(Vector2(40, 0))
	game._on_loot_collected(&"mint", SynergyItems.MINT_HEAL)
	check(is_equal_approx(stats.health, stats.max_health - 20.0 + SynergyItems.MINT_HEAL), "mint leaf did not heal")
	check(near.health < 10000.0, "Scharfe Zahnpasta did not burst")
	stats.health = stats.max_health
	# Saves keep mint loot.
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	check(not RunSaveData.normalize(snapshot).is_empty(), "save with mint loot rejected")
	var saved_mints := 0
	for entry in snapshot.get("loot", []):
		if str(entry.get("kind", "")) == "mint": saved_mints += 1
	check(saved_mints >= 1, "mint loot missing from the save")
	await _clear()
	# Kompost: a lost summon may drop a mint leaf (certain with enough chance).
	game.items.acquire(ItemCatalog.by_id(&"compost"))
	game.items.effect_context.extra_powers = {"summon_mint": 1.0}
	synergies.on_summon_lost(game.player.global_position + Vector2(150, 0))
	await process_frame
	var dropped := loot.get_children().filter(func(drop: Node) -> bool: return drop is Loot and drop.kind == &"mint")
	check(dropped.size() == 1, "Kompost dropped no mint leaf")
	game.items.effect_context.extra_powers = {}
	await _clear()
