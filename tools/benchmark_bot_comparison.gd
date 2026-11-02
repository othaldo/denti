extends "res://tools/benchmark_earned_progression.gd"

const BRAIN = preload("res://tools/balance/bots/pilot_brain.gd")
const OBSERVATION = preload("res://tools/balance/bots/pilot_observation.gd")
const PILOT_PLAYER = preload("res://tools/balance/bots/pilot_player.gd")
const BUILD_POLICY = preload("res://tools/balance/bots/build_policy.gd")
const VIEWER = preload("res://tools/balance/bots/run_viewer.gd")
var pilot: BRAIN
var observation: OBSERVATION
var viewer: VIEWER
var skill := "regular"
var build_policy := "simple"
var previous_wave := -1
var loadout_plan := "single"
var build_rng := RandomNumberGenerator.new()

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	Engine.physics_ticks_per_second = 60
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string, "hz": 60,
		"method": "Rule-based, delayed common-viewport observations; diagnostic, not human winrates. Independent movement and build policies, actual movement/dash and earned progression. Probes ending by W5 retain the historical early boss-kill stop. Longer runs follow complete timed boss waves, loot, offered relics and shops through W20. One free starter; all subsequent gear and ranks are earned. No future spawns or hidden attack planning.", "samples": []}
	var last_wave := clampi(int(_arguments("last-wave", ["5"])[0]), 1, 20)
	loadout_plan = str(_arguments("loadout-plan", ["single"])[0])
	for difficulty_value in _arguments("difficulties", ["normal"]):
		for build_value in _arguments("weapons", ["turbo_drill", "uv_lamp"]):
			for skill_value in _arguments("skills", ["regular"]):
				for strategy_value in _arguments("strategies", ["kite"]):
					for policy_value in _arguments("build-policies", ["simple"]):
						for seed_value in _arguments("seeds", ["13579"]):
							skill = str(skill_value)
							build_policy = str(policy_value)
							var tactic := str(strategy_value)
							if not BRAIN.PROFILES.has(skill) or tactic not in BRAIN.STRATEGIES or build_policy not in ["simple", "synergy", "element_leech", "full_build", "random", "no_shop"] or loadout_plan not in ["single", "uv_floss"] or (loadout_plan == "uv_floss" and str(build_value) != "uv_lamp"):
								push_error("Invalid pilot configuration")
								finish(1)
								return
							pilot = BRAIN.new()
							pilot.configure(skill, tactic, int(seed_value))
							build_rng.seed = int(seed_value) + 32452843
							observation = OBSERVATION.new()
							previous_wave = -1
							var start_time := Time.get_ticks_usec()
							var result := await sample_run(str(build_value), StringName(str(difficulty_value)), tactic, int(seed_value), last_wave)
							result.skill = skill
							result.strategy = tactic
							result.build_policy = build_policy
							result.loadout_plan = loadout_plan
							result.pilot = pilot.metrics()
							result.wall_seconds = (Time.get_ticks_usec() - start_time) / 1000000.0
							result.physics_hz = Engine.physics_ticks_per_second
							result.time_scale = Engine.time_scale
							if is_instance_valid(viewer): result.viewer = {"speed": viewer.speed, "events": viewer.events.duplicate(true)}
							report.samples.append(result)
							print("%s %s %s %s %s seed %s: %s W%d" % [difficulty_value, build_value, skill, tactic, build_policy, seed_value, result.outcome, result.wave])
							if run_aborted(): break
	var output := str(_arguments("output", ["res://.godot/bot_comparison.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write bot report")
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	finish(1 if failures else 0)

func probe_player_script() -> Script:
	return PILOT_PLAYER

func make_run(build: String, difficulty: StringName, sample_seed: int):
	var game = super.make_run(build, difficulty, sample_seed)
	if "--visible" in OS.get_cmdline_user_args():
		viewer = VIEWER.new()
		var tactics := {"aggressive": "Nahkampf", "kite": "Distanz", "collector": "Sammeln", "boss": "Bossfokus", "orbit": "Starrer Kreis"}
		var policies := {"simple": "Feuer-Referenz", "synergy": "Synergie-Heuristik", "element_leech": "Element + Lebensraub", "full_build": "Voller Ausbau (Heuristik)", "random": "Zufallsentscheidungen", "no_shop": "Ohne Shop"}
		viewer.description = "%s · %s · %s" % [pilot.profile.display_name, tactics[pilot.strategy], policies[build_policy]]
		viewer.game = game
		viewer.speed = float(_arguments("speed", ["4"])[0])
		viewer.capture_path = str(_arguments("capture", [""])[0])
		root.add_child(viewer)
	return game

func before_combat_step(_game, _frame: int) -> bool:
	if not is_instance_valid(viewer): return true
	viewer.phase = "Kampf"
	return await viewer.before_step()

func before_loot_step(_game, _frame: int) -> bool:
	if not is_instance_valid(viewer): return true
	viewer.phase = "Beute"
	return await viewer.before_step()

func before_intermission_action(game, phase_name: String, detail: String) -> bool:
	if not is_instance_valid(viewer): return true
	if phase_name == "Verzauberungen": game.weapon_enchantment_panel.refresh()
	return await viewer.present_decision(phase_name, detail)

func run_aborted() -> bool:
	return is_instance_valid(viewer) and viewer.cancelled

func farm_direction(game, _movement: String, elapsed: float) -> Vector2:
	if previous_wave != game.wave.current_wave:
		previous_wave = game.wave.current_wave
		pilot.begin_wave()
		observation.reset()
	var frame := roundi(elapsed * 60)
	var world: Dictionary = observation.capture(game, frame) if frame % pilot.profile.decision_ticks == 0 else {}
	var direction := pilot.step(frame, world)
	game.player.probe_dash = pilot.dash
	return direction

func level_choice(game) -> UpgradeData:
	if build_policy == "random": return game.choice_panel.current_upgrades[build_rng.randi_range(0, game.choice_panel.current_upgrades.size() - 1)]
	return BUILD_POLICY.level_choice(game) if build_policy in ["synergy", "full_build"] else super.level_choice(game)

func next_weapon_upgrade(game, state: WeaponUpgradeState) -> Dictionary:
	if build_policy in ["element_leech", "full_build", "random"]:
		var choices: Array[Dictionary] = []
		var best := INF
		for weapon: WeaponInstance in game.player.loadout.equipped():
			if state.remaining() < WeaponUpgrades.cost(weapon.data): continue
			var values := state.preview(weapon)
			var kinds: Array[StringName] = [&"fire", &"leech"]
			if build_policy == "random":
				kinds.clear()
				for affix: WeaponAffixData in WeaponAffixes.ALL: kinds.append(affix.id)
			for index in kinds.size():
				var kind := kinds[index]
				if WeaponUpgrades.advance(values, kind, weapon.data, weapon.tier).is_empty(): continue
				var found := WeaponAffixes.find(values, kind)
				var rank := WeaponUpgrades.level(values[found]) if found >= 0 else 0
				var score := rank + index * 2
				if build_policy == "random" or score <= best:
					if build_policy != "random" and score < best: choices.clear()
					best = score
					choices.append({"weapon": weapon, "id": kind})
		return {} if choices.is_empty() else choices[build_rng.randi_range(0, choices.size() - 1) if build_policy == "random" else 0]
	return BUILD_POLICY.next_upgrade(game, state) if build_policy == "synergy" else super.next_weapon_upgrade(game, state)

func shop_item_index(game) -> int:
	if build_policy == "random":
		var candidates: Array[int] = []
		for index in game.shop.offers.size():
			var offer: ShopOfferData = game.shop.offers[index]
			if offer != null and offer.weapon_data == null and offer.price <= game.coins and game.items.can_acquire(offer): candidates.append(index)
		return -1 if candidates.is_empty() else candidates[build_rng.randi_range(0, candidates.size() - 1)]
	return BUILD_POLICY.shop_item_index(game) if build_policy in ["synergy", "full_build"] else super.shop_item_index(game)

func shop_policy(game, build: String) -> void:
	if build_policy == "no_shop":
		await before_intermission_action(game, "Shop", "Überspringt alle Käufe und Rerolls")
		return
	if build_policy == "full_build":
		for roll in range(MAX_REROLLS + 1):
			for index in game.shop.offers.size():
				var offer: ShopOfferData = game.shop.offers[index]
				if offer == null or offer.weapon_data == null or offer.price > game.coins or not wants_weapon(game, offer, build) or not game.player.loadout.can_acquire(offer.weapon_data, offer.weapon_tier): continue
				await before_shop_purchase(game, offer)
				if run_aborted(): return
				game._on_shop_buy(index)
			# Each purchase removes one offer. The heuristic must be positive and
			# affordable; real prices and stack limits still gate every transaction.
			for purchase in game.shop.offers.size():
				var index := shop_item_index(game)
				if index < 0: break
				await before_shop_purchase(game, game.shop.offers[index])
				if run_aborted(): return
				game._on_shop_buy(index)
			var reserve := EconomyRules.shop_price(WeaponCatalog.by_id(StringName(build)).price, game.wave.current_wave)
			if roll == MAX_REROLLS or game.coins < game.shop.reroll_cost + reserve: break
			await before_intermission_action(game, "Shop", "Reroll · %d Gold" % game.shop.reroll_cost)
			if run_aborted(): return
			game._on_shop_reroll()
			await before_intermission_action(game, "Shop", "Neue Angebote · %d Gold" % game.coins)
			if run_aborted(): return
		await before_intermission_action(game, "Shop", "Fertig · %d Gold übrig" % game.coins)
		return
	await super.shop_policy(game, build)

func wants_weapon(game, offer: ShopOfferData, build: String) -> bool:
	if loadout_plan != "uv_floss": return super.wants_weapon(game, offer, build)
	var weapon := offer.weapon_data
	# Reserve four roots for two UV lamps and two for one floss cutter. Once
	# a slot is occupied, only fusion-compatible offers may upgrade it.
	if weapon.id not in [&"uv_lamp", &"floss_garrote"]: return false
	var count := 0
	for equipped: WeaponInstance in game.player.loadout.equipped():
		if equipped.data.id == weapon.id: count += 1
	var target := 2 if weapon.id == &"uv_lamp" else 1
	if count < target: return true
	# acquire() fills free roots before fusing. Do not consume the roots reserved
	# for the other family with a temporary third lamp / second cutter.
	if game.player.loadout.used_slots() + weapon.hands <= game.player.loadout.capacity: return false
	for equipped: WeaponInstance in game.player.loadout.equipped():
		if equipped.data.id == weapon.id and equipped.tier == offer.weapon_tier and equipped.tier < WeaponLoadout.MAX_TIER: return true
	return false
