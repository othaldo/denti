extends "res://tools/benchmark_bot_comparison.gd"
## Paired movement-only control: both pilots receive the same recorded W5 build.

var checkpoint: Dictionary = {}
var controller: RefCounted
var sensor: RefCounted
var hit_events: Array[Dictionary] = []
var combat_frame := 0

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var input_path := str(_arguments("input", [""])[0])
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(input_path))
	var reference_brain: Script = load(str(_arguments("reference-brain", [""])[0]))
	var reference_sensor: Script = load(str(_arguments("reference-sensor", [""])[0]))
	var samples: Array[Dictionary] = []
	for entry: Dictionary in original.samples:
		var arrivals: Array = entry.waves.filter(func(wave: Dictionary): return int(wave.wave) == 5)
		if arrivals.is_empty() or entry.skill != "expert": continue
		checkpoint = arrivals[0].start.duplicate(true)
		for revision in ["reference", "revised"]:
			hit_events.clear()
			controller = reference_brain.new() if revision == "reference" else BRAIN.new()
			sensor = reference_sensor.new() if revision == "reference" else OBSERVATION.new()
			controller.configure("expert", str(entry.strategy), int(entry.seed))
			previous_wave = -1
			var result := await sample_run(str(entry.build), StringName(entry.difficulty), str(entry.strategy), int(entry.seed), 5, 5)
			var start: Dictionary = result.waves[0].start
			for key in ["stats", "equipment", "items", "coins", "level", "xp", "xp_goal"]:
				# JSON report numbers are floats; normalize in-memory integer fields
				# before deep comparison without dropping any equipment/item values.
				if JSON.parse_string(JSON.stringify(start[key])) != checkpoint[key]:
					push_error("Boss control changed the starting checkpoint: " + str(key))
					failures += 1
			result.policy_revision = revision
			result.strategy = entry.strategy
			result.pilot = controller.metrics()
			result.hits = hit_events.duplicate(true)
			samples.append(result)
			print("%s %s %s seed %d: %s (%.2fs)" % [revision, entry.build, entry.strategy, int(entry.seed), result.outcome, result.waves[0].seconds])
	var report := {"engine": Engine.get_version_info().string, "hz": Engine.physics_ticks_per_second,
		"time_scale": Engine.time_scale,
		"method": "Paired W5 reconstruction from the same earned arrival. Identical HP, stats, equipment, items, wallet and spawn plan. Fresh weapon runtime, status state and pilot RNG in BOTH arms; not a bit-exact full-run replay. Expert only. No purchases or player/enemy balance changes.", "samples": samples}
	var file := FileAccess.open(str(_arguments("output", ["res://.godot/boss_pilot_replay.json"])[0]), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	finish(1 if failures else 0)

func make_run(build: String, difficulty: StringName, sample_seed: int):
	var game = super.make_run(build, difficulty, sample_seed)
	game.player.stats.load_save_data(checkpoint.stats)
	game.player.loadout.restore(checkpoint.equipment)
	game.items.restore(checkpoint.items)
	game.coins = int(checkpoint.coins)
	game.level = int(checkpoint.level)
	game.xp = int(checkpoint.xp)
	game.xp_goal = int(checkpoint.xp_goal)
	game.wave.current_wave = 4
	game.player.damaged.connect(_record_hit)
	return game

func before_combat_step(_game, frame: int) -> bool:
	combat_frame = frame
	return true

func _record_hit(_at: Vector2, amount: float) -> void:
	var game = current_scene
	var boss: Enemy = game.boss
	var kind := "other"
	for entry in get_stack():
		if str(entry.function) == "try_contact_hit": kind = "contact"
		elif str(entry.source).ends_with("cloak_encounter.gd"): kind = "cloak"
	var event := {"time": combat_frame / 60.0, "damage": amount, "kind": kind,
		"at": SnapshotValues.vector_data(game.player.global_position)}
	if is_instance_valid(boss) and boss.cloak_encounter != null:
		event.distance = boss.global_position.distance_to(game.player.global_position)
		event.cloak_state = int(boss.cloak_encounter.state)
		event.remaining = boss.cloak_encounter.remaining
		event.variant = int(boss.cloak_encounter.variant)
	hit_events.append(event)

func farm_direction(game, _movement: String, elapsed: float) -> Vector2:
	if previous_wave != game.wave.current_wave:
		previous_wave = game.wave.current_wave
		controller.begin_wave()
		sensor.reset()
	var frame := roundi(elapsed * 60)
	var world: Dictionary = sensor.capture(game, frame) if frame % controller.profile.decision_ticks == 0 else {}
	var direction: Vector2 = controller.step(frame, world)
	game.player.probe_dash = controller.dash
	return direction
