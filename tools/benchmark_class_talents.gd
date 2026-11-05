extends "res://tools/benchmark_earned_progression.gd"
## Shared earned-run engine; only class, talent policy and approach differ.
var path := "flexible"

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var report := {"schema_version": 1, "hz": 60, "method": "One free drill; actual HP, drops, XP points, shared stat/talent budget, paid shops and finite dash charge. Normal W1-5, deterministic hunt without hazard reading. Diagnostic policies, not winrates.", "samples": []}
	for policy: String in ["flexible", "poison", "pursuit"]:
		path = policy
		for sample_seed in [13579, 24680]:
			var sample: Dictionary = await sample_run("turbo_drill", &"normal", "hunt", sample_seed)
			sample["talent_policy"] = path
			report.samples.append(sample)
			print("earned class: %s seed %d: %s wave %d, L%d, talents %s, support %s" % [path, sample_seed, sample.outcome, sample.wave, sample.level, JSON.stringify(sample.final.talents.ranks), JSON.stringify(sample.final.class_support)])
	var output := str(_arguments("output", ["res://.godot/class_talent_earned.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	finish(1 if failures else 0)

func make_run(build: String, difficulty: StringName, sample_seed: int):
	var session: Node = root.get_node("GameSession")
	session.pending_start_class_id = &"good_old_molar" if path == "flexible" else &"assassin"
	session.pending_talent_run = true
	return super.make_run(build, difficulty, sample_seed)

func spend_talent_points(game) -> void:
	var order: Array[StringName] = [&"versatile", &"molar_opener", &"molar_stride"]
	if path == "poison": order = [&"venom_opener", &"venom_stride", &"venom_switch"]
	elif path == "pursuit": order = [&"pressure", &"pursuit_health", &"pursuit_finish"]
	for point in 100:
		if game.talents.used(game.player.stats.class_data.talent_tree) >= game.rewards.pending_levels: break
		var planned := false
		for id in order:
			if game.talents.plan_talent(id, game.player.stats, game.UPGRADES, game.rewards.pending_levels):
				planned = true
				break
		if not planned:
			var key := fallback_talent_stat(game)
			planned = key != &"" and game.talents.plan_stat(key, game.player.stats, game.UPGRADES, game.rewards.pending_levels)
		if not planned:
			push_error("Class policy cannot allocate an earned level point")
			failures += 1
			return
	game._on_talents_completed()

func before_combat_step(game, _frame: int) -> bool:
	# Real request gates and resource consumption; no charge/HP reset.
	if game.player.dash.ready_to_dash(): game.player.try_dash()
	return true

func farm_direction(game, movement: String, elapsed: float) -> Vector2:
	if path == "flexible" or WaveController.is_boss_wave(game.wave.current_wave): return super.farm_direction(game, movement, elapsed)
	var target: Enemy = game.player.class_combat.focus.get_ref() as Enemy if path == "pursuit" and game.player.class_combat.focus != null else null
	if not is_instance_valid(target) or not target.is_targetable():
		var best := INF
		for enemy: Enemy in game.get_node("Enemies").get_children():
			if not enemy.is_targetable(): continue
			var distance: float = enemy.global_position.distance_squared_to(game.player.global_position)
			# Select a new approach, never override automatic weapon targeting.
			if path == "poison" and enemy.affix_effects.depot.target_lock > 0: distance *= 4
			if distance < best:
				best = distance
				target = enemy
	if target == null: return super.farm_direction(game, movement, elapsed)
	var offset: Vector2 = target.global_position - game.player.global_position
	var inward := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	return (inward * clampf((offset.length() - target.data.radius - 95) / 100, -1, 1) + inward.orthogonal() * 0.65).normalized()
