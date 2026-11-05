extends "res://tools/benchmark_build_comparison.gd"
## Starts with one free weapon, carries real HP/XP/gold/gear, buys only real offers.

const EARNED_GAME = preload("res://tools/balance/earned_progression_game.gd")
const ROSTER = preload("res://tools/balance/weapon_roster_profiles.gd")
const MEASURED_STRIKE = preload("res://tools/balance/measured_strike.gd")
const BUILDS := ["turbo_drill", "floss_garrote", "uv_lamp", "water_turbine", "interdental_brush"]
const STAPLES := ["health_1", "armor_2", "damage_1", "regen_1", "tempo_2", "xp_heal_1"]
const MAX_REROLLS := 4
var failures := 0


func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string,
		"method": "One free starter, finite HP and persistent earned XP/gold/gear through waves 1-5. Real Hell/Normal stats, timed waves, loot sweep, offered level choices, earned fire upgrades, actual seeded shop offers, matching weapons plus at most one staple item and four paid rerolls per shop. No free HP/coins/items, no mastery, no dash or warning reactions. Orbit or range-aware pursuit of nearest enemy; boss pursuit at shortest weapon reach. Diagnostic policies, not human winrates.",
		"samples": []}
	for tier_value in _arguments("difficulties", ["hell"]):
		var difficulty := StringName(str(tier_value))
		for build_value in _arguments("builds", BUILDS):
			var build := str(build_value)
			for movement_value in _arguments("movements", ["orbit", "hunt"]):
				for seed_value in _arguments("seeds", PROFILES.SEEDS):
					var result := await sample_run(build, difficulty, str(movement_value), int(seed_value))
					report.samples.append(result)
					print("%s %s %s seed %d: %s wave %d, %d kills, %d gold, level %d" % [difficulty, build, movement_value, int(seed_value), result.outcome, result.wave, result.kills, result.gold_earned, result.level])
	var output := str(_arguments("output", ["res://docs/balance_earned_progression.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write progression report")
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	finish(1 if failures else 0)


func make_run(build: String, difficulty: StringName, sample_seed: int):
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://earned_progression_unused.json"
	session.resume_requested = false
	session.pending_start_weapon_id = &""
	session.selected_story_mode = false
	session.selected_difficulty_id = difficulty
	session.test_scenario_id = &""
	session.ui_sounds = false
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var game = load("res://scenes/game/game.tscn").instantiate()
	game.set_script(EARNED_GAME)
	game.probe_seed = sample_seed
	game.get_node("Player").set_script(probe_player_script())
	game.get_node("Sound").set_script(PROBE_SOUND)
	root.add_child(game)
	current_scene = game
	paused = true
	game.choice_panel.hide()
	game.starter_pending = false
	game.weapon_mastery.eligible = false
	game.wave.difficulty_id = difficulty
	game.wave.set_process(false)
	# External request plans own spawn times and placements, not combat RNG.
	game.wave.enemy_requested.disconnect(game._spawn_enemy)
	game.wave.boss_requested.disconnect(game._spawn_enemy)
	game.wave.horde_requested.disconnect(game._spawn_horde)
	game.wave.elite_requested.disconnect(game._spawn_elite)
	game.wave.loot_goblin_requested.disconnect(game._spawn_loot_goblin)
	game.player.loadout.restore([{"id": build, "tier": 1, "uid": "earned_starter"}])
	game.player.stats.dodge_rng.seed = sample_seed
	return game


func sample_run(build: String, difficulty: StringName, movement: String, sample_seed: int, last_wave: int = 5, first_wave: int = 1) -> Dictionary:
	assert(first_wave >= 1 and first_wave <= last_wave)
	var game = make_run(build, difficulty, sample_seed)
	var waves: Array[Dictionary] = []
	var aborted := false
	# Historical W1-5 probes deliberately stop at the first boss kill. Longer
	# runs follow the actual timer, loot, relic and shop flow after every boss.
	var full_flow := last_wave > 5
	var planner_state: Dictionary = {}
	for number in range(first_wave, last_wave + 1):
		game.probe_boss_killed = false
		var plan: Dictionary = PROFILES.spawn_plan(number, sample_seed + number * 7919, difficulty, planner_state)
		if full_flow:
			planner_state = plan.planner_state
			game.wave.horde_waves.assign(planner_state.horde_waves)
			game.wave.next_profile_id = StringName(plan.profile)
		seed(sample_seed + number * 104729)
		if number == first_wave: game._start_combat_wave()
		else: game._on_shop_continue()
		paused = true
		game.wave.current_profile_id = StringName(plan.profile)
		game.telemetry.current_profile_id = StringName(plan.profile)
		if movement == "orbit": game.player.position += Vector2(ORBIT_RADIUS.x, 0)
		var start := snapshot(game)
		var strike_metrics: Dictionary = {}
		for weapon: WeaponInstance in game.player.loadout.equipped():
			if not weapon.strike is MEASURED_STRIKE:
				weapon.strike = MEASURED_STRIKE.new()
			weapon.strike.metrics = strike_metrics
		var frame := 0
		var event_index := 0
		var limit := (180.0 if full_flow else 90.0) if WaveController.is_boss_wave(number) else float(plan.duration)
		while frame < roundi(limit * 60):
			if not await before_combat_step(game, frame):
				aborted = true
				break
			await physics_frame
			game.player.probe_direction = farm_direction(game, movement, float(frame) / 60)
			game.wave.remaining = maxf(float(plan.duration) - float(frame) / 60, 0)
			while event_index < plan.events.size() and int(plan.events[event_index].frame) <= frame:
				seed(sample_seed + number * 1000003 + event_index * 104729)
				var event: Dictionary = plan.events[event_index]
				match event.kind:
					"enemy": game._spawn_enemy(event.data)
					"horde": game._spawn_horde(event.data, int(event.count))
					"elite": game._spawn_elite(event.data)
					"goblin": game._spawn_loot_goblin()
				event_index += 1
			paused = false
			await process_frame
			frame += 1
			if game.probe_dead or (game.probe_boss_killed and not full_flow): break
			if game.wave.active and frame >= roundi(float(plan.duration) * 60):
				game.wave.active = false
				game.wave.remaining = 0
				seed(sample_seed + number * 100003)
				game._on_wave_finished(number)
			if game.collecting_wave_loot or game.rewards.step != PostWaveRewards.Step.COMBAT: break
		paused = true
		for weapon: WeaponInstance in game.player.loadout.equipped(): weapon.strike.flush()
		var battle: Dictionary = game.telemetry.current_wave_summary()
		var outcome := "death" if game.probe_dead else ("boss_killed" if game.probe_boss_killed else ("timeout" if WaveController.is_boss_wave(number) else "wave_complete"))
		if full_flow and not game.probe_dead:
			outcome = "wave_complete" if game.rewards.step != PostWaveRewards.Step.COMBAT else "timeout"
		if aborted: outcome = "aborted"
		if outcome == "wave_complete":
			await resolve_intermission(game)
			if run_aborted(): outcome = "aborted"
			elif game.base_victory: outcome = "victory"
		var end := snapshot(game)
		waves.append({"wave": number, "outcome": outcome, "seconds": float(frame) / 60,
			"spawn_plan": plan.digest, "start": start, "after_rewards": end,
			"combat": battle, "all_loot": game.telemetry.current_wave_summary(), "strikes": strike_metrics.duplicate()})
		if full_flow: print("W%d %s · %.1fs · %d Gold · Stufe %d" % [number, outcome, float(frame) / 60, game.coins, game.level])
		if outcome != "wave_complete" or number == last_wave: break
		await shop_policy(game, build)
		waves[-1]["after_shop"] = snapshot(game)
		if run_aborted():
			waves[-1].outcome = "aborted"
			break
	var final := snapshot(game)
	var result := {"difficulty": str(difficulty), "build": build, "movement": movement, "seed": sample_seed,
		"outcome": waves[-1].outcome, "wave": game.wave.current_wave,
		"level": game.level, "kills": game.telemetry.kills, "gold_earned": game.telemetry.coins_collected,
		"xp_earned": game.telemetry.xp_collected, "chests": game.telemetry.chests_found,
		"final": final, "waves": waves}
	_stop_audio(game)
	game.wave.active = false
	game.run_flow.enter(RunFlow.Phase.ENDED)
	game._clear_arena(false)
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.queue_free()
	await process_frame
	await process_frame
	return result


# Optional tool hooks. Defaults preserve the historical input/reward policy.
func probe_player_script() -> Script:
	return PROBE_PLAYER


func before_combat_step(_game, _frame: int) -> bool:
	return true


func before_loot_step(_game, _frame: int) -> bool:
	return true


func before_intermission_action(_game, _phase: String, _detail: String) -> bool:
	return true


func run_aborted() -> bool:
	return false


func snapshot(game) -> Dictionary:
	return {"coins": game.coins, "level": game.level, "xp": game.xp, "xp_goal": game.xp_goal,
		"stats": game.player.stats.to_save_data().duplicate(true), "equipment": game.player.loadout.save_data().duplicate(true),
		"items": game.items.save_data().duplicate(true), "relics": game.relics.save_data().duplicate(true), "upgrade_points": game.rewards.weapon_upgrades.points,
		"class_id": str(game.player.stats.class_data.id), "talents": game.talents.save_data(),
		"class_support": game.telemetry.enchantment_support.duplicate(), "dashes": game.telemetry.dashes,
		"gold_earned": game.telemetry.coins_collected, "xp_earned": game.telemetry.xp_collected,
		"chests": game.telemetry.chests_found}


func resolve_intermission(game) -> void:
	# Let the actual loot magnet finish before choosing or buying anything.
	for frame in 600:
		if not game.collecting_wave_loot: break
		if not await before_loot_step(game, frame): return
		paused = false
		await process_frame
	paused = true
	for choice in 300:
		if game.ended and game.base_victory: return
		if game.in_shop:
			await before_intermission_action(game, "Shop", "Angebote · %d Gold" % game.coins)
			return
		match game.rewards.step:
			PostWaveRewards.Step.LEVELS:
				if game.talents.enabled:
					await spend_talent_points(game)
					continue
				var upgrade := level_choice(game)
				if not await before_intermission_action(game, "Aufstieg", "Wählt " + upgrade.effect_text()): return
				game._on_upgrade_chosen(upgrade)
			PostWaveRewards.Step.WEAPONS:
				await spend_upgrade_points(game)
				if run_aborted(): return
			PostWaveRewards.Step.CHESTS:
				if not await before_intermission_action(game, "Truhe", "Kapsel verschrotten" if game.weapon_chest_panel.visible else "Item behalten"): return
				if game.weapon_chest_panel.visible: game._on_affix_scrapped()
				else: game._on_chest_resolved(true)
			PostWaveRewards.Step.RELICS:
				var relic_id := StringName(str(game.rewards.pending_relics[0]))
				await before_intermission_action(game, "Relikt", "Wählt " + RelicCatalog.by_id(relic_id).display_name)
				if run_aborted(): return
				game._on_relic_chosen(relic_id)
			_:
				push_error("Unexpected earned-run intermission step: " + str(game.rewards.step))
				failures += 1
				return
	push_error("Earned progression did not finish its actual reward queue")
	failures += 1


func level_choice(game) -> UpgradeData:
	var priority := [&"melee_damage" if game.player.loadout.equipped()[0].data.damage_stat == "melee" else &"ranged_damage", &"attack_speed", &"max_health", &"damage_bonus", &"armor", &"regen", &"crit_chance", &"speed_bonus", &"luck"]
	for stat: StringName in priority:
		var matching: Array = game.choice_panel.current_upgrades.filter(func(upgrade: UpgradeData): return upgrade.stat == stat)
		if not matching.is_empty(): return matching[0]
	return game.choice_panel.current_upgrades[0]

func spend_talent_points(game) -> void:
	for point in 100:
		if game.talents.used(game.player.stats.class_data.talent_tree) >= game.rewards.pending_levels: break
		var selected := fallback_talent_stat(game)
		if selected == &"" or not game.talents.plan_stat(selected, game.player.stats, game.UPGRADES, game.rewards.pending_levels):
			push_error("Earned progression cannot allocate a level point")
			failures += 1
			return
	game._on_talents_completed()

func fallback_talent_stat(game) -> StringName:
	var primary := &"melee_damage" if game.player.loadout.equipped()[0].data.damage_stat == "melee" else &"ranged_damage"
	for key: StringName in [primary, &"max_health", &"attack_speed", &"armor", &"regen"]:
		if game.talents.stat_choice(key, game.player.stats, game.UPGRADES) != null: return key
	return &""


func spend_upgrade_points(game) -> void:
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	await before_intermission_action(game, "Verzauberungen", "%d Punkte verfügbar" % state.remaining())
	if run_aborted(): return
	for action in weapon_upgrade_actions(game):
		var detail: String = plan_weapon_upgrade(game, action)
		if detail.is_empty():
			push_error("Cannot apply the planned bot enchantment step")
			failures += 1
			return
		await before_intermission_action(game, "Verzauberungen", detail)
		if run_aborted(): return
	await before_intermission_action(game, "Verzauberungen", "Geplante Upgrades übernehmen")
	if run_aborted(): return
	game._on_weapon_upgrades_completed()


func weapon_upgrade_actions(game) -> Array[Dictionary]:
	# Project the same deterministic policy on a private draft. The live draft
	# receives one action at a time, so the viewer never reveals future steps.
	var actual: WeaponUpgradeState = game.rewards.weapon_upgrades
	var draft := WeaponUpgradeState.new()
	draft.points = actual.points
	draft.actions.assign(actual.actions.duplicate(true))
	var actions: Array[Dictionary] = []
	for point in 100:
		var selected := next_weapon_upgrade(game, draft)
		if selected.is_empty(): break
		var weapon: WeaponInstance = selected.weapon
		if not draft.plan(game.player.loadout, weapon.instance_uid, StringName(selected.id)): break
		actions.append(draft.actions[-1].duplicate())
	return actions


func plan_weapon_upgrade(game, action: Dictionary) -> String:
	var weapon: WeaponInstance
	for equipped: WeaponInstance in game.player.loadout.equipped():
		if equipped.instance_uid == str(action.uid): weapon = equipped
	if weapon == null: return ""
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	var kind := StringName(action.id)
	if not state.plan(game.player.loadout, weapon.instance_uid, kind): return ""
	var values := state.preview(weapon)
	var rank := WeaponUpgrades.level(values[WeaponAffixes.find(values, kind)])
	var number: int = game.player.loadout.equipped().find(weapon) + 1
	return "Plant #%d · %s · %s %d/10" % [number, weapon.data.display_name, WeaponAffixes.by_id(kind).display_name, rank]


func next_weapon_upgrade(game, state: WeaponUpgradeState) -> Dictionary:
	var selected: WeaponInstance
	var lowest := 11
	for weapon: WeaponInstance in game.player.loadout.equipped():
		var values := state.preview(weapon)
		var index := WeaponAffixes.find(values, &"fire")
		var rank := WeaponUpgrades.level(values[index]) if index >= 0 else 0
		if state.remaining() >= WeaponUpgrades.cost(weapon.data) and rank < lowest and rank < 10:
			selected = weapon
			lowest = rank
	return {} if selected == null else {"weapon": selected, "id": &"fire"}


func shop_policy(game, build: String) -> void:
	var item_bought := false
	for roll in range(MAX_REROLLS + 1):
		for index in game.shop.offers.size():
			var offer: ShopOfferData = game.shop.offers[index]
			if offer != null and offer.weapon_data != null and wants_weapon(game, offer, build) and game.coins >= offer.price:
				if not await before_shop_purchase(game, offer): return
				game._on_shop_buy(index)
		if not item_bought:
			var index := shop_item_index(game)
			if index >= 0:
				if not await before_shop_purchase(game, game.shop.offers[index]): return
				game._on_shop_buy(index)
				item_bought = true
		var cheapest := EconomyRules.shop_price(WeaponCatalog.by_id(StringName(build)).price, game.wave.current_wave)
		if roll == MAX_REROLLS or game.coins < game.shop.reroll_cost + cheapest: break
		if not await before_intermission_action(game, "Shop", "Reroll · %d Gold" % game.shop.reroll_cost): return
		game._on_shop_reroll()
		if not await before_intermission_action(game, "Shop", "Neue Angebote · %d Gold" % game.coins): return
	await before_intermission_action(game, "Shop", "Fertig · %d Gold übrig" % game.coins)


func wants_weapon(_game, offer: ShopOfferData, build: String) -> bool:
	return str(offer.weapon_data.id) == build


func before_shop_purchase(game, offer: ShopOfferData) -> bool:
	if offer.weapon_data != null and not game.player.loadout.can_acquire(offer.weapon_data, offer.weapon_tier): return true
	return await before_intermission_action(game, "Shop", "Kauft %s · %d Gold" % [offer.display_name, offer.price])


func shop_item_index(game) -> int:
	for id: String in STAPLES:
		for index in game.shop.offers.size():
			var offer: ShopOfferData = game.shop.offers[index]
			if offer != null and str(offer.id) == id and game.coins >= offer.price and game.items.can_acquire(offer): return index
	return -1


func farm_direction(game, movement: String, elapsed: float) -> Vector2:
	if WaveController.is_boss_wave(game.wave.current_wave): return ROSTER.pursuit_direction(game)
	if movement == "orbit": return super.movement_direction(game, "orbit", elapsed)
	var target: Enemy
	var nearest := INF
	for enemy: Enemy in game.get_node("Enemies").get_children():
		var distance := enemy.global_position.distance_squared_to(game.player.global_position)
		if enemy.health > 0 and distance < nearest:
			target = enemy
			nearest = distance
	if target == null: return super.movement_direction(game, "orbit", elapsed)
	var reach := INF
	for weapon: WeaponInstance in game.player.loadout.equipped(): reach = minf(reach, weapon.data.range_at_tier(weapon.tier))
	var offset: Vector2 = target.global_position - game.player.global_position
	var inward := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	return (inward * clampf((offset.length() - target.data.radius - reach * 0.6) / 100, -1, 1) + inward.orthogonal() * 0.65).normalized()
