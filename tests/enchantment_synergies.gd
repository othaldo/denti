extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failed := false
var origin := Vector2(500, 400)
var brush: WeaponData

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func _enemy(offset: Vector2 = Vector2.ZERO) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, origin + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.data = enemy.data.duplicate() as EnemyData
	enemy.data.affix_resistances = {}
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.damage_reduction = 0
	return enemy

func _effects(kinds: Array[String], value: float = 7) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for kind in kinds:
		result.append({"id": kind, "rarity": 2, "damage": value})
	return result

func _hit(enemy: Enemy, kinds: Array[String], critical: bool = false, damage: float = 10) -> void:
	WeaponAttackShapes.hit(enemy, brush, 1, damage, critical, game.items, Vector2.RIGHT, _effects(kinds))

func _reset() -> void:
	game.weapon_chest_panel.hide()
	game._clear_combat()
	await process_frame
	game.items.owned.clear()
	game.items.powers.clear()
	game.items.cooldowns.clear()
	game.items.puddles.clear()
	game.relics.owned.clear()
	game.player.stats.damage_bonus = 0
	game.player.stats.health = 50
	game.player.stats.max_health = 100

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_enchantment_synergies.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	brush = WeaponCatalog.by_id(&"magic_toothbrush")
	await _electric()
	await _fire()
	await _poison()
	await _bleed()
	await _ice_and_holy()
	await _leech_and_guards()
	await _save_and_loot()
	await _automatic_attacks()
	session.clear_run()
	print("PASS enchantment roles, item bridges, bounded procs, utility, telemetry, drops and resume" if not failed else "FAIL enchantment synergies")
	finish(1 if failed else 0)

func _electric() -> void:
	await _reset()
	var source := _enemy()
	var others: Array[Enemy] = []
	for index in 4:
		others.append(_enemy(Vector2(45 * (index + 1), 0)))
	_hit(source, ["electric"])
	var damaged := 0
	for enemy in others:
		damaged += int(enemy.health < 10000)
	_check(damaged == 1, "dry electricity must hit exactly one additional target")
	var before: float = game.telemetry.proc_damage.get("affix_electric_chain", 0)
	_hit(source, ["electric"])
	_check(is_equal_approx(game.telemetry.proc_damage.get("affix_electric_chain", 0), before), "electric chain bypassed shared cooldown")
	game.items._process(0.45)
	game.items.acquire(ShopController.by_id(&"radiant_filling"))
	game.items.acquire(ShopController.by_id(&"conductive_varnish"))
	game.items.acquire(ShopController.by_id(&"rinse_valve"))
	for enemy in others:
		enemy.health = 10000
	_hit(source, ["wet", "electric"])
	damaged = 0
	for enemy in others:
		damaged += int(enemy.health < 10000)
	_check(damaged == 3 and source.wet_time > 0, "wet/chain build did not gain its bounded extra jumps")
	_check(game.items.puddles.size() == 1, "wet enchantment does not activate the puddle item")
	_check(game.telemetry.enchantment_support.get("wet_hits", 0) > 0, "wet support is absent from telemetry")
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "magic_toothbrush", "affixes": _effects(["wet"])}])
	_check(WeaponPresentation.enchantment_hint(&"electric", loadout.equipped()[0], game.items).contains("Nässe"), "build synergy hint missing")
	_check(not WeaponPresentation.enchantment_hint(&"electric", loadout.equipped()[0], game.items, 0).contains("Nässe"), "replacement hint advertises a synergy that would be removed")
	loadout.restore([{"id": "magic_toothbrush", "affixes": _effects(["holy", "leech", "bleed"]), "affix_slots": 3}])
	var tags: Array[StringName] = game.items.preferred_tags(loadout)
	_check(tags.has(&"crit") and tags.has(&"heal") and tags.has(&"bleed"), "enchantments are ignored by build-aware shop weighting")

func _fire() -> void:
	await _reset()
	var source := _enemy()
	var others: Array[Enemy] = []
	for index in 4:
		others.append(_enemy(Vector2(20 * (index + 1), 0)))
	source.health = 1
	var before: float = game.telemetry.enchantment_support.get("fire_spreads", 0)
	_hit(source, ["fire"])
	var ignited := 0
	for enemy in others:
		ignited += int(enemy.affix_effects.pending.has("fire"))
	_check(ignited == 3, "fire kill must spread to at most three nearby targets, including a one-shot")
	game.items.cooldowns.clear()
	others[0].health = 0.01
	others[0].affix_effects.advance(others[0], 0.5)
	_check(game.telemetry.enchantment_support.get("fire_spreads", 0) == before + 1, "transferred fire recursively spread again")
	_check(not others[3].affix_effects.pending.has("fire"), "fire escaped its target/generation cap")
	var immune := _enemy(Vector2(0, 50))
	immune.data.affix_resistances = {"fire": 1.0}
	immune.health = 1
	_hit(immune, ["fire"])
	_check(is_equal_approx(immune.affix_effects.fire_budget, 1.82), "fire spread budget ignored the existing 60 percent resistance cap")

func _poison() -> void:
	await _reset()
	var source := _enemy()
	var addition: Array[Dictionary] = [{"id": "poison", "damage": 10}]
	source.take_damage(0, null, false, &"", addition)
	_check(source.affix_effects.poison_stacks == 1 and is_equal_approx(source.affix_effects.budget(&"poison"), 10), "initial poison budget changed")
	source.affix_effects.advance(source, 0.6)
	var before := source.affix_effects.budget(&"poison")
	source.take_damage(0, null, false, &"", addition)
	_check(is_equal_approx(source.affix_effects.budget(&"poison") - before, 11.5), "sustained poison did not gain its buildup bonus")
	for index in 100:
		source.take_damage(0, null, false, &"", addition)
	_check(source.affix_effects.poison_stacks == 2, "same-frame poison instantly filled buildup")
	for index in 10:
		source.affix_effects.advance(source, 0.6)
		source.take_damage(0, null, false, &"", addition)
	_check(source.affix_effects.poison_stacks == 5 and source.affix_effects.pending.poison.size() == 10, "poison exceeds buildup or storage cap")
	var saved := source.affix_effects.save_data()
	source.affix_effects.restore(saved)
	_check(source.affix_effects.save_data() == saved, "poison resume reset buildup or recalculated budgets")
	source.affix_effects.advance(source, 5.1)
	_check(source.affix_effects.poison_stacks == 0, "poison buildup does not expire")

func _bleed() -> void:
	await _reset()
	game.items.acquire(ShopController.by_id(&"floss_reel"))
	game.items.acquire(ShopController.by_id(&"bleeding_hourglass"))
	game.items.acquire(ShopController.by_id(&"scalpel_wax"))
	game.items.acquire(ShopController.by_id(&"contagious_floss"))
	var source := _enemy()
	var other := _enemy(Vector2(60, 0))
	_hit(source, ["bleed"])
	_check(source.has_bleeding() and source.bleed_stacks == 1 and source.bleed_dps > 0, "floss item does not strengthen enchanted bleeding on a non-cut weapon")
	_check(source.affix_effects.pending.bleed.size() == 8, "hourglass did not extend enchanted bleeding")
	_check(AffixPresentation.damage_unit(&"bleed", game.items).contains("4 s"), "preview ignores hourglass duration")
	var normal := _enemy(Vector2(0, 300))
	_check(game.items.modify_damage(source, brush, 10) > game.items.modify_damage(normal, brush, 10), "scalpel wax ignores enchanted bleeding")
	source.take_damage(20000)
	_check(other.has_bleeding() and other.affix_effects.budget(&"bleed") > 0, "bleed spread misses kills outside the direct weapon callback")
	game.relics.acquire(&"blood_moon_tooth")
	var witness := _enemy(Vector2(140, 0))
	witness.health = 1
	var tail := _enemy(Vector2(230, 0))
	var before: float = game.telemetry.proc_damage.get("blood_moon_tooth", 0)
	other.take_damage(20000)
	_check(game.telemetry.proc_damage.get("blood_moon_tooth", 0) > before, "blood moon ignores enchanted bleeding")
	_check(tail.health == 10000, "blood moon recursively detonated a secondary kill")

func _ice_and_holy() -> void:
	await _reset()
	var source := _enemy()
	var other := _enemy(Vector2(50, 0))
	_hit(source, ["ice"])
	var before := other.health
	_hit(source, [], true)
	_check(other.health < before and game.telemetry.proc_damage.get("affix_ice_shatter", 0) > 0, "critical hit with another weapon did not shatter a chilled target")
	before = other.health
	_hit(source, [], true)
	_check(other.health == before, "ice shatter bypasses shared cooldown")
	_hit(source, ["holy"], true)
	_hit(source, ["holy"], true)
	_check(source.affix_effects.holy_marks == 2, "holy marks do not accumulate")
	before = other.health
	_hit(source, [], true)
	_check(other.health < before and source.affix_effects.holy_marks == 0, "third crit did not detonate the holy mark")
	_check(game.telemetry.proc_damage.get("affix_holy", 0) > 0, "holy damage missing from telemetry")
	_hit(source, ["holy"], true)
	source.affix_effects.advance(source, 4.1)
	_check(source.affix_effects.holy_marks == 0 and source.affix_effects.holy_power == 0, "holy marks do not expire")

func _leech_and_guards() -> void:
	await _reset()
	var source := _enemy()
	var before: float = game.player.stats.health
	_hit(source, ["leech"])
	var healed: float = game.player.stats.health - before
	_check(healed > 0 and healed <= 0.5, "leech must heal no more than five percent of a ten-damage hit")
	for index in 100:
		_hit(source, ["leech"])
	_check(is_equal_approx(game.player.stats.health, before + healed), "rapid hits bypass shared leech interval")
	_check(is_equal_approx(game.telemetry.enchantment_support.get("leech_healing", 0), healed), "healing telemetry counts requested rather than actual healing")
	game.items._process(0.75)
	game._create_enemy(WaveController.BOSS, origin + Vector2(300, 0))
	var boss: Enemy = game.get_node("Enemies").get_child(-1)
	boss.set_simulation_enabled(false)
	boss.boss_phase_timer = 1.0
	before = game.player.stats.health
	_hit(boss, ["leech", "wet", "holy", "poison"], true)
	_check(game.player.stats.health == before and boss.wet_time == 0 and boss.affix_effects.holy_marks == 0 and boss.affix_effects.poison_stacks == 0, "guarded hit activated utility or buildup")
	game.items.cooldowns.clear()
	var other := _enemy(Vector2(350, 0))
	_hit(other, ["electric", "holy", "ice", "fire"], true)
	_check(boss.boss_phase_timer > 0 and boss.health == boss.max_health, "follow-up damage bypassed boss invulnerability")

func _save_and_loot() -> void:
	await _reset()
	var loadout: WeaponLoadout = game.player.loadout
	loadout.restore([{"id": "magic_toothbrush", "tier": 4, "affix_slots": 4, "affixes": _effects(["wet", "holy", "leech", "poison"])}])
	var saved := loadout.save_data()
	loadout.restore(saved)
	_check(loadout.save_data() == saved and loadout.equipped()[0].affixes.size() == 4, "new enchantments were lost on weapon resume")
	var source := _enemy()
	source.data = WaveController.PLAQUE
	_hit(source, ["holy", "poison", "wet", "leech"], true)
	_hit(source, ["holy"], true)
	for index in 9:
		source.apply_bleed(1, 4, Enemy.MAX_BLEED_STACKS)
	var effects := source.affix_effects.save_data()
	var cooldowns: Dictionary = game.items.cooldowns.duplicate()
	var support: Dictionary = game.telemetry.enchantment_support.duplicate()
	var snapshot := RunSnapshot.capture(game)
	game._clear_combat()
	await process_frame
	RunSnapshot.restore(game, snapshot)
	paused = true
	var restored: Enemy = game.get_node("Enemies").get_child(0)
	_check(restored.affix_effects.save_data() == effects and restored.wet_time > 0, "combat resume lost marks, buildup or wet duration")
	_check(restored.bleed_stacks == Enemy.MAX_BLEED_STACKS, "resume truncated valid item-enhanced bleed stacks")
	_check(game.items.cooldowns == cooldowns and game.telemetry.enchantment_support == support, "resume reset shared cooldowns or support telemetry")
	var seen := {}
	var rng := RandomNumberGenerator.new()
	var empty := WeaponLoadout.new()
	for seed_value in 200:
		rng.seed = seed_value
		var reward := WeaponAffixes.roll_chest(10, 20, empty, false, rng)
		_check(not WeaponAffixes.sanitize_chest(reward).is_empty(), "expanded loot failed save sanitization")
		for option in reward.options:
			seen[str(option.id)] = true
	for kind in ["wet", "holy", "leech"]:
		_check(seen.has(kind), "new enchantment missing from random loot: " + kind)
	var chest := {"kind": "affix", "options": _effects(["wet", "holy", "leech"]), "scrap_coins": 5}
	game.weapon_chest_panel.show_chest(chest, game.player.loadout, game.player.stats, 5, game.items)
	for card in game.weapon_chest_panel.buttons:
		_check(not card.effect_label.text.contains("Basisschaden"), "utility card is advertised as flat damage")
		for text in [card.effect_label.text, card.tooltip_text]:
			for index in text.length():
				_check(text.unicode_at(index) <= 32 or DentiUIStyle.FONT.has_char(text.unicode_at(index)), "new enchantment text uses an unsupported glyph")
	empty.free()

func _automatic_attacks() -> void:
	await _reset()
	game.player.stats.crit_chance = 1.0
	game.player.stats.health = 40
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 4, "affix_slots": 4, "affixes": _effects(["wet", "electric", "holy", "leech"])},
		{"id": "turbo_drill", "tier": 4, "affix_slots": 4, "affixes": _effects(["fire", "ice", "poison", "bleed"])}])
	var previous_origin := origin
	origin = game.player.global_position + Vector2(75, 0)
	for index in 8:
		_enemy(Vector2((index % 4) * 18, (index / 4) * 30))
	var before: Dictionary = game.telemetry.proc_damage.duplicate()
	var support: Dictionary = game.telemetry.enchantment_support.duplicate()
	paused = false
	for frame in 300:
		await physics_frame
		# The fixture freezes enemy movement; advance their status component at
		# the ordinary fixed step so this probe includes real deferred damage.
		for enemy: Enemy in game.get_node("Enemies").get_children():
			enemy.affix_effects.advance(enemy, 1.0 / 60.0)
			enemy.chill_time = maxf(enemy.chill_time - 1.0 / 60.0, 0)
	paused = true
	_check(game.telemetry.proc_damage.get("affix_electric_chain", 0) > before.get("affix_electric_chain", 0), "automatic projectiles did not trigger electric chains")
	_check(game.telemetry.proc_damage.get("affix_holy", 0) > before.get("affix_holy", 0), "automatic critical attacks did not trigger holy marks")
	_check(game.telemetry.proc_damage.get("affix_ice_shatter", 0) > before.get("affix_ice_shatter", 0), "automatic melee did not trigger ice shatter")
	_check(game.telemetry.enchantment_support.get("leech_healing", 0) > support.get("leech_healing", 0), "automatic attacks did not heal")
	for kind in ["affix_fire", "affix_poison", "affix_bleed"]:
		_check(game.telemetry.proc_damage.get(kind, 0) > before.get(kind, 0), "automatic melee did not apply its deferred damage: " + kind)
	var report := {"frames": 300, "proc_damage": {}, "support": {}}
	for kind in ["affix_fire", "affix_ice_shatter", "affix_poison", "affix_bleed", "affix_electric_chain", "affix_holy"]:
		report.proc_damage[kind] = float(game.telemetry.proc_damage.get(kind, 0)) - float(before.get(kind, 0))
	for kind in ["wet_hits", "leech_healing"]:
		report.support[kind] = float(game.telemetry.enchantment_support.get(kind, 0)) - float(support.get(kind, 0))
	print("Automatic enchantment probe: " + JSON.stringify(report))
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/enchantment_combat.png")
		var file := FileAccess.open("res://.godot/enchantment_combat.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	origin = previous_origin
