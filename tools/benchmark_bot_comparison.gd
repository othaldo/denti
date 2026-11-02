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

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	Engine.physics_ticks_per_second = 60
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string, "hz": 60,
		"method": "Rule-based, delayed common-viewport observations. Independent skill, combat strategy and purchase/upgrade policy. Actual player movement, contact damage, dash cost/collision and earned progression. Waves 1-5 only; no human winrates. Ordinary acid projectiles, pulse/charge warnings and current Graf cloak sectors are observed. No future spawns or hidden attack planning.", "samples": []}
	var last_wave := clampi(int(_arguments("last-wave", ["5"])[0]), 1, 5)
	for difficulty_value in _arguments("difficulties", ["normal"]):
		for build_value in _arguments("weapons", ["turbo_drill", "uv_lamp"]):
			for skill_value in _arguments("skills", ["regular"]):
				for strategy_value in _arguments("strategies", ["kite"]):
					for policy_value in _arguments("build-policies", ["simple"]):
						for seed_value in _arguments("seeds", ["13579"]):
							skill = str(skill_value)
							build_policy = str(policy_value)
							var tactic := str(strategy_value)
							if not BRAIN.PROFILES.has(skill) or tactic not in BRAIN.STRATEGIES or build_policy not in ["simple", "synergy"]:
								push_error("Invalid pilot configuration")
								finish(1)
								return
							pilot = BRAIN.new()
							pilot.configure(skill, tactic, int(seed_value))
							observation = OBSERVATION.new()
							previous_wave = -1
							var start_time := Time.get_ticks_usec()
							var result := await sample_run(str(build_value), StringName(str(difficulty_value)), tactic, int(seed_value), last_wave)
							result.skill = skill
							result.strategy = tactic
							result.build_policy = build_policy
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
		var tactics := {"aggressive": "Nahkampf", "kite": "Distanz", "collector": "Sammeln", "boss": "Bossfokus"}
		viewer.description = "%s · %s · %s" % [pilot.profile.display_name, tactics[pilot.strategy], "Synergie-Heuristik" if build_policy == "synergy" else "Feuer-Referenz"]
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
	return BUILD_POLICY.level_choice(game) if build_policy == "synergy" else super.level_choice(game)

func next_weapon_upgrade(game, state: WeaponUpgradeState) -> Dictionary:
	return BUILD_POLICY.next_upgrade(game, state) if build_policy == "synergy" else super.next_weapon_upgrade(game, state)

func shop_item_index(game) -> int:
	return BUILD_POLICY.shop_item_index(game) if build_policy == "synergy" else super.shop_item_index(game)
