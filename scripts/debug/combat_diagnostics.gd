class_name CombatDiagnostics
extends Node

const SAMPLE_INTERVAL := 10
static var current: CombatDiagnostics
var game: Node2D
var scenario_id: StringName
var mode: TestArenaData.Diagnostic
var sampled_us: Dictionary[StringName, int] = {}
var calls: Dictionary[StringName, int] = {}
var first_frame := 0
var save_ms := 0.0

static func configure(game_node: Node2D, data: TestArenaData) -> void:
	var profiler := CombatDiagnostics.new()
	profiler.game = game_node
	profiler.scenario_id = data.id
	profiler.mode = data.diagnostic
	profiler.name = "CombatDiagnostics"
	current = profiler
	game_node.add_child(profiler)
	for entry in [["Items", "items"], ["Relics", "relics"], ["Enemies", "enemy_index"], ["Loot", "loot"], ["DamageNumbers", "numbers"]]:
		instrument(game_node.get_node(entry[0]), entry[1], game_node)
	profiler.reset()

static func instrument(node: Node, kind: String, context: Node) -> void:
	# Creation-time hook only. Ordinary actors keep their original scripts.
	if not is_instance_valid(current) or not is_instance_valid(current.game):
		return
	if context != current.game and not current.game.is_ancestor_of(context):
		return
	node.set_script(load("res://scripts/debug/profiled_%s.gd" % kind))
	node.set("diagnostics", current)

func reset() -> void:
	sampled_us.clear()
	calls.clear()
	first_frame = Engine.get_process_frames()
	save_ms = 0.0

func should_sample(physics: bool) -> bool:
	return (Engine.get_physics_frames() if physics else Engine.get_process_frames()) % SAMPLE_INTERVAL == 0

func record(category: StringName, started: int) -> void:
	sampled_us[category] = sampled_us.get(category, 0) + maxi(Time.get_ticks_usec() - started, 0)
	calls[category] = calls.get(category, 0) + 1

func milliseconds(category: StringName) -> float:
	# Extrapolate sampled callbacks across all rendered frames, including frames
	# with zero hits and multiple physics steps. Inclusive times may overlap.
	return float(sampled_us.get(category, 0)) * SAMPLE_INTERVAL / 1000.0 / maxi(Engine.get_process_frames() - first_frame, 1)

func snapshot() -> Dictionary:
	var result := {}
	for category in sampled_us:
		result[str(category)] = milliseconds(category)
	return result

func hide_effects() -> bool:
	return mode == TestArenaData.Diagnostic.NO_EFFECTS

func no_hits() -> bool:
	return mode == TestArenaData.Diagnostic.NO_HITS

func _exit_tree() -> void:
	if current == self:
		current = null
