extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failed := false
const RULES: PoisonBuildData = preload("res://data/synergies/poison_build.tres")

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func _near(a: float, b: float, message: String) -> void:
	_check(is_equal_approx(a, b), message + " (%s != %s)" % [a, b])

func _enemy(offset: Vector2 = Vector2(100, 0), data: EnemyData = WaveController.PLAQUE) -> Enemy:
	game._create_enemy(data, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.data = enemy.data.duplicate() as EnemyData
	enemy.data.affix_resistances = {}
	enemy.max_health = 10000
	enemy.health = 10000
	enemy.damage_reduction = 0
	return enemy

func _hit(enemy: Enemy, poison: float = 0, weapon: StringName = &"turbo_drill") -> void:
	var affixes: Array[Dictionary] = []
	if poison > 0: affixes.append({"id": "poison", "rarity": 1, "damage": poison})
	WeaponAttackShapes.hit(enemy, WeaponCatalog.by_id(weapon), 1, 1, false, game.items, Vector2.RIGHT, affixes, 1, false, "poison_test")

func _clock(seconds: float) -> void:
	game.items._process(seconds)
	for enemy: Enemy in game.get_node("Enemies").get_children():
		if not enemy.is_queued_for_deletion(): enemy.affix_effects.advance(enemy, seconds)

func _reset() -> void:
	game._clear_combat()
	await process_frame
	game.items.restore({})
	game.relics.restore({})
	game.player.stats.damage_bonus = 0
	game.player.stats.attack_speed = 0
	game.telemetry.enchantment_support.clear()
	game.telemetry.proc_damage.clear()

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_poison_build.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	await _depots()
	await _playstyle_comparison()
	await _nerve_and_guards()
	await _switch_budget()
	await _resume()
	await _selection_and_access()
	await _death_and_automatic_attacks()
	session.clear_run()
	print("PASS poison depot limits, control, switch conservation, automatic melee/ranged, telemetry, rewards and resume" if not failed else "FAIL poison build")
	finish(1 if failed else 0)

func _depots() -> void:
	await _reset()
	var source := _enemy()
	_hit(source)
	_check(source.affix_effects.depot.ticks.is_empty(), "baseline Denti gained a free depot")
	_check(game.items.acquire(ItemCatalog.by_id(&"poison_depot")), "common depot item is unavailable")
	_check(not game.items.acquire(ItemCatalog.by_id(&"poison_depot")), "depot stack limit bypassed")
	_near(game.player.stats.attack_speed, -3, "depot downside was not applied once")
	_hit(source)
	_near(source.affix_effects.depot.budget(), 35, "unenchanted Mk I drill cannot start poison build")
	for hit in 100: _hit(source)
	_near(source.affix_effects.depot.budget(), 35, "rapid hits multiplied/refreshed depot budget")
	var other := _enemy(Vector2(130, 0))
	_hit(other)
	_check(other.affix_effects.depot.ticks.is_empty(), "same-frame spray bypassed global depot interval")
	_clock(0.6)
	_hit(other, 10, &"magic_toothbrush")
	_check(other.affix_effects.depot.budget() > 18 and other.affix_effects.depot.budget() <= 36, "existing poison did not strengthen a ranged depot within cap")
	_clock(0.6)
	var third := _enemy(Vector2(160, 0))
	_hit(third)
	_clock(0.6)
	var fourth := _enemy(Vector2(190, 0))
	_hit(fourth)
	_check(fourth.affix_effects.depot.ticks.is_empty(), "more than three simultaneous depot targets")
	_near(game.telemetry.enchantment_support.get("poison_depots", 0), 3, "ticks created free depot applications")
	_clock(4.2)
	_hit(source)
	_check(source.affix_effects.depot.ticks.is_empty() and source.affix_effects.depot.target_lock > 0, "depot expiration reset target lock")
	_clock(2.01)
	_hit(source)
	_near(source.affix_effects.depot.budget(), 35, "expired target never becomes eligible again")
	# Pay resistance at application and normal defense at each tick, exactly once.
	await _reset()
	game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
	source = _enemy()
	source.data.affix_resistances = {"poison": 0.5}
	source.damage_reduction = 0.2
	_hit(source)
	var before := source.health
	_clock(6)
	_near(before - source.health, 14, "depot resistance/defense counted twice or ignored")
	_near(game.telemetry.proc_damage.get("poison_depot", 0), 14, "depot telemetry does not count actual damage")
	_check(paused, "combat helper changed pause state")
	await _reset()
	game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
	source = _enemy()
	game.player.stats.melee_damage = 20
	game.player.stats.damage_bonus = 50
	WeaponAttackShapes.hit(source, WeaponCatalog.by_id(&"turbo_drill"), 4, 1000, true, game.items, Vector2.RIGHT, [], 1, false)
	var expected := (WeaponCatalog.by_id(&"turbo_drill").damage_at_tier(4) + 20) * 1.25 * 1.5
	_near(source.affix_effects.depot.budget(), expected, "depot ignores weapon tier/stats or inherits critical hit damage")
	game.player.stats.melee_damage = 0

func _nerve_and_guards() -> void:
	await _reset()
	game.items.acquire(ItemCatalog.by_id(&"nerve_probe"))
	var source := _enemy()
	_hit(source)
	_near(source.status_speed_factor(), 1, "nerve probe slows without poison")
	_hit(source, 10)
	_near(source.status_speed_factor(), 0.75, "poisoned real hit does not slow")
	_clock(1)
	_hit(source)
	_near(source.affix_effects.depot.nerve_time, 0.4, "rapid hits refresh nerve slow")
	_clock(0.41)
	_near(source.status_speed_factor(), 1, "nerve slow did not expire")
	_clock(1.6)
	_hit(source)
	_near(source.status_speed_factor(), 0.75, "nerve slow does not recover after target interval")
	var boss := _enemy(Vector2(180, 0), WaveController.BOSS)
	_hit(boss, 10)
	_near(boss.status_speed_factor(), 0.9375, "boss control is not reduced to quarter strength")
	game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
	game.items._process(0.61)
	_hit(boss, 10)
	var boss_budget := boss.affix_effects.depot.budget()
	var boss_health := boss.health
	boss.affix_effects.advance(boss, 0.5)
	_check(boss_budget > 0 and boss.health < boss_health, "isolated boss without kills receives no depot benefit")
	boss = _enemy(Vector2(230, 0), WaveController.BOSS)
	boss.boss_phase_timer = 1
	boss.affix_effects.depot.nerve_time = 0
	_hit(boss, 10)
	_check(boss.affix_effects.depot.ticks.is_empty() and boss.affix_effects.depot.nerve_time == 0, "guarded boss accepted depot/slow")

func _playstyle_comparison() -> void:
	var report := {}
	for style: String in ["focus", "switch"]:
		await _reset()
		game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
		var enemies: Array[Enemy] = [_enemy(), _enemy(Vector2(150, 0)), _enemy(Vector2(200, 0))]
		# Identical shot count and time budget; only the contacted enemy differs.
		for shot in 6:
			_hit(enemies[shot % 3] if style == "switch" else enemies[0])
			_clock(0.61)
		_clock(6)
		report[style] = {"depots": game.telemetry.enchantment_support.get("poison_depots", 0), "damage": game.telemetry.proc_damage.get("poison_depot", 0)}
	_near(report.focus.damage, 35, "focus acquired multiple depots inside target lock")
	_near(report.switch.damage, 105, "six spread hits do not reward switching over focus")
	print("Poison controlled playstyle comparison: " + JSON.stringify(report))

func _switch_budget() -> void:
	await _reset()
	game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
	game.relics.acquire(&"venom_fang")
	var source := _enemy()
	var other := _enemy(Vector2(180, 0))
	_hit(source, 30)
	var budget := source.affix_effects.budget(&"poison") + source.affix_effects.depot.budget()
	var before := source.health
	_hit(source)
	_near(source.health, before - 1, "same target triggered switch")
	before = source.health
	_hit(other, 10)
	var advanced := minf(budget * 0.25, 30)
	_near(before - source.health, advanced, "target switch did not advance expected budget")
	_near(source.affix_effects.budget(&"poison") + source.affix_effects.depot.budget(), budget - advanced, "switch copied instead of consuming poison")
	_near(game.telemetry.proc_damage.get("poison_switch", 0), advanced, "switch actual damage is absent")
	var support: float = game.telemetry.enchantment_support.get("poison_switches", 0)
	_hit(source)
	_near(game.telemetry.enchantment_support.get("poison_switches", 0), support, "alternating hits bypass relic cooldown")
	var poison_damage: float = game.telemetry.proc_damage.get("affix_poison", 0)
	var depot_damage: float = game.telemetry.proc_damage.get("poison_depot", 0)
	source.affix_effects.advance(source, 6)
	var delivered: float = game.telemetry.proc_damage.get("affix_poison", 0) - poison_damage + game.telemetry.proc_damage.get("poison_depot", 0) - depot_damage
	_near(delivered + advanced, budget, "switch changed total finite damage budget")
	_clock(2.1)
	_hit(other, 20)
	var distant := _enemy(Vector2(600, 0))
	_hit(distant, 20)
	_near(game.telemetry.enchantment_support.get("poison_switches", 0), support, "relic searched across the arena")

func _resume() -> void:
	await _reset()
	game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
	game.items.acquire(ItemCatalog.by_id(&"nerve_probe"))
	game.relics.acquire(&"venom_fang")
	for offset in [100, 150, 200]:
		_hit(_enemy(Vector2(offset, 0)), 10)
		_clock(0.6)
	for enemy: Enemy in game.get_node("Enemies").get_children(): enemy.data = WaveController.PLAQUE
	game.rewards.earn_level()
	game.rewards.step = PostWaveRewards.Step.LEVELS
	var snapshot := RunSnapshot.capture(game)
	var poison: Dictionary = snapshot.poison_build.duplicate(true)
	var invalid := snapshot.duplicate(true)
	invalid.poison_build.depots = ["enemy"]
	_check(RunSaveData.normalize(invalid).is_empty(), "malformed depot identity reached typed restore")
	invalid = snapshot.duplicate(true)
	invalid.enemies[0].affix_effects.depot.ticks = {}
	_check(RunSaveData.normalize(invalid).is_empty(), "malformed depot schedule reached typed restore")
	var states: Array = snapshot.enemies.map(func(entry: Dictionary) -> Dictionary: return entry.affix_effects.depot)
	game._save_run()
	var session: Node = root.get_node("GameSession")
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	game.wave.active = false
	game.wave.set_process(false)
	game.choice_panel.hide()
	var restored := RunSnapshot.capture(game)
	_check(JSON.stringify(restored.poison_build) == JSON.stringify(poison), "resume lost target identities/window/capacity")
	for index in states.size():
		_check(JSON.stringify(restored.enemies[index].affix_effects.depot) == JSON.stringify(states[index]), "resume changed depot installments/target locks")
	var fourth := _enemy(Vector2(250, 0))
	_hit(fourth)
	_check(fourth.affix_effects.depot.ticks.is_empty(), "resume reset simultaneous depot capacity")
	var empty: Array[Node] = []
	game.items.effect_context.poison_build.restore({}, empty)
	_check(game.items.effect_context.poison_build.depots.is_empty(), "legacy save gained new runtime state")

func _selection_and_access() -> void:
	await _reset()
	var tags: Array[StringName] = [&"poison"]
	for sample in 80:
		seed(sample)
		var choices := RelicCatalog.choices([], tags)
		_check(choices.size() == 3 and choices.has("venom_fang"), "poison build has no relevant milestone option")
		_check(choices[0] != choices[1] and choices[0] != choices[2] and choices[1] != choices[2], "duplicate relic in choice")
	_check(not RelicCatalog.choices(["venom_fang"], tags).has("venom_fang"), "owned relic reappeared")
	var all_owned: Array[String] = []
	for relic in RelicCatalog.CATALOG: all_owned.append(str(relic.id))
	_check(RelicCatalog.choices(all_owned, tags).is_empty(), "exhausted relic pool manufactured a choice")
	game.items.acquire(ItemCatalog.by_id(&"divine_seal"))
	_check(game.items.preferred_tags(game.player.loadout).has(&"shield"), "shield source does not guide relic relevance")
	game.player.loadout.restore([{"id": "turbo_drill", "tier": 1, "affix_slots": 1, "affixes": [{"id": "poison", "rarity": 1, "damage": 5}]}])
	_check(game.items.preferred_tags(game.player.loadout).has(&"poison"), "melee poison build has no exact shop tag")
	var found := false
	for sample in 80:
		game.shop.rng.seed = sample
		game.shop.open_shop(1, 0, game.player.loadout, game.items)
		for offer: ShopOfferData in game.shop.offers:
			if offer != null and offer.id == &"poison_depot": found = true
	_check(found and ItemCatalog.by_id(&"poison_depot").rarity_tier == 1, "depot unavailable in early shop pool")
	for index in [103, 104]:
		var icon := DentiUIIcons.item(index) as AtlasTexture
		_check(icon != null and icon.filter_clip and icon.atlas == DentiUIIcons.POISON_ATLAS, "new painted icon is not wired")
	_check((DentiUIIcons.relic(5) as AtlasTexture).atlas == DentiUIIcons.POISON_ATLAS, "poison relic lacks its new art")

func _death_and_automatic_attacks() -> void:
	await _reset()
	game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
	var source := _enemy()
	_hit(source)
	source.health = 1
	source.global_position = game.player.global_position + Vector2(800, 0)
	source.affix_effects.advance(source, 0.5)
	_near(game.telemetry.enchantment_support.get("poison_depot_kills_outside_range", 0), 1, "delayed distance kill not measured")
	for id: String in ["turbo_drill", "magic_toothbrush"]:
		await _reset()
		game.items.acquire(ItemCatalog.by_id(&"poison_depot"))
		game.items.acquire(ItemCatalog.by_id(&"nerve_probe"))
		game.player.loadout.restore([{"id": id, "tier": 1}])
		source = _enemy(Vector2(60, 0))
		paused = false
		for frame in 180:
			await physics_frame
			source.affix_effects.advance(source, 1.0 / 60)
		paused = true
		_check(game.telemetry.proc_damage.get("poison_depot", 0) > 0, "automatic weapon cannot sustain depot: " + id)
		_check(game.telemetry.enchantment_support.get("poison_nerve_applications", 0) > 0, "automatic weapon does not use nerve probe: " + id)
