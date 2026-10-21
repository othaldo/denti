extends "res://tests/support/test_runtime.gd"
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func enemy() -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100, 0))
	var result: Enemy = game.get_node("Enemies").get_child(-1)
	result.set_simulation_enabled(false)
	result.data = result.data.duplicate() as EnemyData
	result.data.affix_resistances = {}
	result.health = 1000
	result.max_health = 1000
	result.damage_reduction = 0
	return result

func hit(target: Enemy, kind: String, damage: float, main: float = 0) -> void:
	var additions: Array[Dictionary] = [{"id": kind, "damage": damage}]
	target.take_damage(main, null, false, &"", additions)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_affix_dot.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	var target := enemy()
	target.data.affix_resistances = {"fire": 0.25}
	target.damage_reduction = 0.2
	var counted: float = game.telemetry.total_damage
	hit(target, "fire", 40, 100)
	assert(is_equal_approx(target.health, 920), "fire applied instant damage")
	target.affix_effects.advance(target, 0.5)
	assert(is_equal_approx(target.health, 914), "resistance or defense applied twice/missing")
	target.affix_effects.advance(target, 1.5)
	assert(is_equal_approx(target.health, 896) and not target.affix_effects.is_active())
	assert(is_equal_approx(game.telemetry.total_damage - counted, 104), "DoT telemetry inflated or missing")
	target = enemy()
	hit(target, "fire", 20)
	assert(target.health == 1000, "pure application manufactured minimum damage")
	target.affix_effects.advance(target, 1)
	hit(target, "fire", 20)
	target.affix_effects.advance(target, 2)
	assert(is_equal_approx(target.health, 960) and not target.affix_effects.is_active(), "reapplication multiplied/refreshed an existing budget")
	target = enemy()
	hit(target, "poison", 30)
	hit(target, "bleed", 12)
	target.affix_effects.advance(target, 3)
	assert(is_equal_approx(target.health, 970) and target.affix_effects.pending.has("poison") and not target.affix_effects.pending.has("bleed"))
	target.affix_effects.advance(target, 2)
	assert(is_equal_approx(target.health, 958), "simultaneous DoTs lost damage")
	target = enemy()
	for index in 10000:
		hit(target, "fire", 0.001)
	assert(target.affix_effects.pending.size() == 1 and target.affix_effects.pending.fire.size() == 4, "DoT storage grows per hit")
	target.affix_effects.advance(target, 2)
	assert(is_equal_approx(target.health, 990), "fractional ticks inflate minimum damage")
	target = enemy()
	target.data.affix_resistances = {"ice": 0.4, "electric": 0.25}
	hit(target, "ice", 10)
	hit(target, "electric", 8)
	assert(is_equal_approx(target.health, 988) and target.chill_time > 0, "direct elemental resistance failed")
	target.health = 0.2
	counted = game.telemetry.total_damage
	hit(target, "bleed", 12)
	target.affix_effects.advance(target, 0.5)
	assert(is_equal_approx(game.telemetry.total_damage - counted, 0.2), "DoT overkill inflated telemetry")
	game._create_enemy(WaveController.BOSS, game.player.position + Vector2(300, 0))
	var boss: Enemy = game.get_node("Enemies").get_child(-1)
	boss.set_simulation_enabled(false)
	boss.boss_phase_timer = 1
	boss.affix_effects.apply(&"fire", 100)
	var before := boss.health
	boss.affix_effects.advance(boss, 0.5)
	assert(boss.health == before, "DoT bypassed invulnerable phase")
	boss.boss_phase_timer = 0
	boss.boss_damage_budget = 5
	boss.affix_effects.advance(boss, 0.5)
	assert(is_equal_approx(before - boss.health, 5) and boss.boss_damage_budget == 0, "DoT bypassed boss damage budget")
	boss.affix_effects.restore({})
	boss.affix_effects.apply(&"fire", 40)
	boss.affix_effects.apply(&"poison", 100)
	boss.boss_damage_budget = 5
	var tick_parts: Dictionary = {}
	var tick_positions: Dictionary = {}
	boss.affix_damaged.connect(func(at: Vector2, amount: float, kind: StringName) -> void:
		tick_parts[str(kind)] = amount
		tick_positions[str(kind)] = at)
	boss.affix_effects.advance(boss, 0.5)
	assert(is_equal_approx(tick_parts.fire, 2.5) and is_equal_approx(tick_parts.poison, 2.5), "simultaneous effects don't share guard proportionally")
	assert(tick_positions.fire != tick_positions.poison, "simultaneous DoT numbers overlap")
	game._clear_combat()
	await process_frame
	game._create_enemy(WaveController.PLAQUE, game.player.position + Vector2(100, 0))
	target = game.get_node("Enemies").get_child(-1)
	target.set_simulation_enabled(false)
	before = target.health
	hit(target, "fire", 4)
	target.affix_effects.advance(target, 0.25)
	var state := target.affix_effects.save_data()
	var snapshot := RunSnapshot.capture(game)
	game._clear_combat()
	await process_frame
	RunSnapshot.restore(game, snapshot)
	paused = true
	target = game.get_node("Enemies").get_child(0)
	target.set_simulation_enabled(false)
	assert(target.affix_effects.save_data() == state, "resume reset duration or rerolled DoT")
	target.affix_effects.advance(target, 1.75)
	assert(is_equal_approx(before - target.health, 3), "resume applied resistance twice or lost tick")
	assert(AffixPresentation.damage_unit(&"poison").contains("5 s") and AffixPresentation.damage_unit(&"electric") == "Schaden/Treffer")
	session.clear_run()
	paused = false
	print("PASS DoT budgets, stacking, resistance, fractional ticks, guards, overkill and resume")
	finish(0)
