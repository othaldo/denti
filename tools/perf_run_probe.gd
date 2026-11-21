extends "res://tools/benchmark_bot_comparison.gd"
## Real-run frame-time probe: the rule-based bot plays an earned run while every
## combat/loot step is timed. Spikes keep per-system timings and spawned nodes.
## Rendered run (no --headless, VSync off) measures CPU + render submission.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/perf_run_probe.gd -- \
##     --weapons=turbo_drill --skills=expert --strategies=kite --build-policies=full_build \
##     --last-wave=20 --perf-output=res://.godot/perf_run.json

const SPIKE_MS := 16.7
const KEEP_SPIKES := 60

class FrameProfiler extends CombatDiagnostics:
	var frame_us: Dictionary[StringName, int] = {}
	var frame_calls: Dictionary[StringName, int] = {}
	var wave_us: Dictionary[StringName, int] = {}

	func should_sample(_physics: bool) -> bool:
		return true

	func record(category: StringName, started: int) -> void:
		var spent := maxi(Time.get_ticks_usec() - started, 0)
		frame_us[category] = frame_us.get(category, 0) + spent
		frame_calls[category] = frame_calls.get(category, 0) + 1
		wave_us[category] = wave_us.get(category, 0) + spent

var profiler: FrameProfiler
var perf_game: Node
var step_mark := 0
var physics_mark := 0
var physics_ticks := 0
var added_nodes := 0
var added_kinds: Dictionary = {}
var steps: Array[Dictionary] = []
var wave_steps: Dictionary = {}
var spikes: Array[Dictionary] = []
var current_phase := "combat"

func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	physics_frame.connect(_on_physics_frame)
	node_added.connect(_on_node_added)
	await super._run()

func _on_physics_frame() -> void:
	physics_ticks += 1
	if physics_mark == 0:
		physics_mark = Time.get_ticks_usec()

func _on_node_added(node: Node) -> void:
	if perf_game != null and node.name == &"Game" and node.scene_file_path.ends_with("game.tscn") and profiler == null:
		_attach_profiler(node)
	added_nodes += 1
	if added_kinds.size() < 40:
		var script: Script = node.get_script()
		var kind := node.scene_file_path if node.scene_file_path != "" else (script.resource_path.get_file() if script != null else node.get_class())
		added_kinds[kind] = added_kinds.get(kind, 0) + 1

func _attach_profiler(game_node: Node) -> void:
	# Mirrors CombatDiagnostics.configure() during the game's enter-tree pass.
	profiler = FrameProfiler.new()
	profiler.game = game_node
	profiler.scenario_id = &"perf_run"
	profiler.mode = TestArenaData.Diagnostic.FULL
	profiler.name = "CombatDiagnostics"
	CombatDiagnostics.current = profiler
	game_node.add_child(profiler)
	for entry in [["Items", "items"], ["Relics", "relics"], ["Enemies", "enemy_index"], ["Loot", "loot"], ["DamageNumbers", "numbers"]]:
		CombatDiagnostics.instrument(game_node.get_node(entry[0]), entry[1], game_node)
	profiler.reset()

func make_run(build: String, difficulty: StringName, sample_seed: int):
	profiler = null
	perf_game = root
	var session: Node = root.get_node("GameSession")
	var class_id := StringName(str(_arguments("class", [""])[0]))
	if class_id != &"":
		session.pending_start_class_id = class_id
		session.pending_talent_run = true
	var game = super.make_run(build, difficulty, sample_seed)
	if profiler == null:
		push_error("Profiler was not attached")
	else:
		# Re-equip after the profiler exists so weapon nodes carry timers.
		game.player.loadout.restore([{"id": build, "tier": 1, "uid": "earned_starter"}])
	var resolution := str(_arguments("resolution", [""])[0])
	if resolution != "":
		# Logical 1280x720 stays; canvas_items stretch renders at window pixels.
		root.size = Vector2i(int(resolution.get_slice("x", 0)), int(resolution.get_slice("x", 1)))
		root.content_scale_size = Vector2i(1280, 720)
	print("Window ", DisplayServer.window_get_size(), " root ", root.size, " class ", game.player.stats.class_data.id if game.player.stats.class_data else &"none", " talents ", game.talents.enabled)
	return game

func before_combat_step(game, frame: int) -> bool:
	_close_step(game, "combat")
	# Dash-bound class skills only fire on dashes; keep them busy like a human.
	if "--dash-often" in OS.get_cmdline_user_args() and game.player.dash.ready_to_dash():
		game.player.try_dash()
	return await super.before_combat_step(game, frame)

func before_loot_step(game, frame: int) -> bool:
	_close_step(game, "loot")
	return await super.before_loot_step(game, frame)

func before_intermission_action(game, phase_name: String, detail: String) -> bool:
	step_mark = 0
	return await super.before_intermission_action(game, phase_name, detail)

func _close_step(game, phase: String) -> void:
	var now := Time.get_ticks_usec()
	if step_mark != 0 and profiler != null and phase == current_phase:
		var total := float(now - step_mark) / 1000.0
		var physics_part := float(now - physics_mark) / 1000.0 if physics_mark != 0 else 0.0
		var wave_number: int = game.wave.current_wave
		var key := "%02d_%s" % [wave_number, phase]
		if not wave_steps.has(key):
			wave_steps[key] = {"wave": wave_number, "phase": phase, "ms": PackedFloat32Array(), "enemies_max": 0, "enemy_shots_max": 0, "nodes_max": 0, "categories_us": {}}
		var bucket: Dictionary = wave_steps[key]
		bucket.ms.append(total)
		var enemies: int = game.get_node("Enemies").get_child_count()
		var shots: int = game.get_node("EnemyProjectiles").get_child_count()
		bucket.enemies_max = maxi(bucket.enemies_max, enemies)
		bucket.enemy_shots_max = maxi(bucket.enemy_shots_max, shots)
		bucket.nodes_max = maxi(bucket.nodes_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		for category in profiler.frame_us:
			bucket.categories_us[str(category)] = int(bucket.categories_us.get(str(category), 0)) + profiler.frame_us[category]
		var grown := _cache_growth()
		var split := _engine_split()
		for category in split:
			bucket.categories_us["engine_" + category] = int(bucket.categories_us.get("engine_" + category, 0)) + int(split[category] * 1000.0)
		if total >= SPIKE_MS:
			var parts := {}
			for category in profiler.frame_us:
				parts[str(category)] = snappedf(profiler.frame_us[category] / 1000.0, 0.01)
			var spike := {"wave": wave_number, "phase": phase, "ms": snappedf(total, 0.01),
				"physics_part_ms": snappedf(physics_part, 0.01), "process_render_ms": snappedf(total - physics_part, 0.01),
				"physics_ticks": physics_ticks, "enemies": enemies, "enemy_shots": shots,
				"player_shots": game.get_node("Projectiles").get_child_count(),
				"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"added_nodes": added_nodes, "added_kinds": added_kinds.duplicate(),
				"save_ms": profiler.save_ms, "categories_ms": parts, "calls": profiler.frame_calls.duplicate()}
			spike.merge(_engine_split())
			spike["cache_growth"] = grown
			spike["wave_frame"] = bucket.ms.size()
			spikes.append(spike)
	current_phase = phase
	profiler_reset_frame()
	step_mark = Time.get_ticks_usec()
	physics_mark = 0
	physics_ticks = 0
	added_nodes = 0
	added_kinds.clear()

const CACHES := [["res://scripts/systems/projectile_paint.gd", "source_images"], ["res://scripts/systems/combat_sprite_textures.gd", "textures"],
	["res://scripts/enemies/projectile_visuals.gd", "textures"], ["res://scripts/systems/combat_draw_cache.gd", "arcs"],
	["res://scripts/systems/combat_glyphs.gd", "regions"], ["res://scripts/systems/combat_glyphs.gd", "warning_rings"], ["res://scripts/systems/combat_glyphs.gd", "marks"],
	["res://scripts/systems/attack_effects.gd", "cones"], ["res://scripts/weapons/weapon_element_visuals.gd", "cone_uvs"],
	["res://scripts/ui/hud_status_icons.gd", "_frames"], ["res://scripts/ui/weapon_mastery_icons.gd", "cache"], ["res://scripts/player/player.gd", "used_rects"],
	["res://scripts/systems/prepared_combat_textures.gd", "textures"], ["res://scripts/systems/prepared_weapon_element_effects.gd", "textures"],
	["res://scripts/enemies/prepared_projectile_textures.gd", "textures"], ["res://scripts/ui/run_setup_presentation.gd", "_icons"],
	["res://scripts/enemies/acid_king_visuals.gd", "contours"]]
var cache_sizes: Dictionary = {}

func _cache_growth() -> Dictionary:
	var grown := {}
	for entry in CACHES:
		var script: Script = load(entry[0])
		var value = script.get(entry[1])
		var size: int = value.size() if value != null else -1
		var key: String = entry[0].get_file().get_basename() + "." + entry[1]
		if cache_sizes.has(key) and size > int(cache_sizes[key]):
			grown[key] = size - int(cache_sizes[key])
		cache_sizes[key] = size
	return grown

func _engine_split() -> Dictionary:
	# Values describe the frame that was just processed/rendered.
	var viewport := root.get_viewport_rid()
	return {"process_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01),
		"render_setup_cpu_ms": snappedf(RenderingServer.get_frame_setup_time_cpu(), 0.01),
		"render_cpu_ms": snappedf(RenderingServer.viewport_get_measured_render_time_cpu(viewport), 0.01),
		"render_gpu_ms": snappedf(RenderingServer.viewport_get_measured_render_time_gpu(viewport), 0.01)}

func profiler_reset_frame() -> void:
	if profiler == null:
		return
	profiler.frame_us.clear()
	profiler.frame_calls.clear()
	profiler.save_ms = -1.0

func finish(exit_code: int = 0) -> void:
	_write_perf_report()
	super.finish(exit_code)

func _percentile(sorted: PackedFloat32Array, fraction: float) -> float:
	if sorted.is_empty():
		return 0.0
	return sorted[clampi(int(ceil(fraction * sorted.size())) - 1, 0, sorted.size() - 1)]

func _write_perf_report() -> void:
	var waves: Array[Dictionary] = []
	var keys := wave_steps.keys()
	keys.sort()
	for key in keys:
		var bucket: Dictionary = wave_steps[key]
		var values: PackedFloat32Array = bucket.ms
		var sorted := values.duplicate()
		sorted.sort()
		var total := 0.0
		var over_16 := 0
		var over_33 := 0
		for value in values:
			total += value
			over_16 += int(value >= 16.7)
			over_33 += int(value >= 33.3)
		var categories := {}
		for category in bucket.categories_us:
			categories[category] = snappedf(float(bucket.categories_us[category]) / 1000.0 / maxi(values.size(), 1), 0.001)
		waves.append({"wave": bucket.wave, "phase": bucket.phase, "steps": values.size(),
			"mean_ms": snappedf(total / maxi(values.size(), 1), 0.01), "p50_ms": snappedf(_percentile(sorted, 0.5), 0.01),
			"p95_ms": snappedf(_percentile(sorted, 0.95), 0.01), "p99_ms": snappedf(_percentile(sorted, 0.99), 0.01),
			"max_ms": snappedf(sorted[-1] if not sorted.is_empty() else 0.0, 0.01),
			"frames_over_16_7": over_16, "frames_over_33_3": over_33,
			"enemies_max": bucket.enemies_max, "enemy_shots_max": bucket.enemy_shots_max, "nodes_max": bucket.nodes_max,
			"mean_category_ms_per_step": categories})
	spikes.sort_custom(func(a, b): return a.ms > b.ms)
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_driver_name(),
		"display": DisplayServer.get_name(), "spike_threshold_ms": SPIKE_MS, "spike_count": spikes.size(),
		"note": "Step = one bot step (>=1 physics tick + one rendered frame). Category times are inclusive and overlap (hits are inside weapons/projectiles). Bot brain/observation time lands in the physics part.",
		"waves": waves, "top_spikes": spikes.slice(0, KEEP_SPIKES)}
	var output := str(_arguments("perf-output", ["res://.godot/perf_run.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write perf report " + output)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("Perf report: ", ProjectSettings.globalize_path(output), " spikes: ", spikes.size())
