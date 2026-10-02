extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _seed_for(stats: PlayerStats, evade: bool) -> void:
	var probe := RandomNumberGenerator.new()
	for value in 1000:
		probe.seed = value
		if (probe.randf() < stats.effective_dodge_chance()) == evade:
			stats.dodge_rng.seed = value
			return

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_player_status_effects.json"
	session.report_dir = "user://test_status_reports"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	paused = true
	var player: Player = game.player
	var effects: PlayerStatusEffects = player.status_effects
	var stats: PlayerStats = player.stats
	var poison: Array[Dictionary] = [{"kind": DentiStatus.Type.POISON, "damage": 2.0, "duration": 4.0}]
	var bleed: Array[Dictionary] = [{"kind": DentiStatus.Type.BLEED, "damage": 2.0, "duration": 3.0}]
	stats.dodge_chance = 0.6
	stats.shield_charges = 1
	_seed_for(stats, true)
	player.take_hit(10.0, poison)
	_check(effects.active.is_empty() and stats.shield_charges == 1, "dodged hit inflicted a status")
	player.dodge_time = 0.0
	_seed_for(stats, false)
	player.take_hit(10.0, poison)
	_check(effects.active.is_empty() and stats.shield_charges == 0, "shield block inflicted a status")
	player.hurt_time = 0.2
	_seed_for(stats, false)
	var before_rng := stats.dodge_rng.state
	player.take_hit(10.0, poison)
	_check(effects.active.is_empty() and stats.dodge_rng.state == before_rng, "invulnerable hit inflicted status")
	player.hurt_time = 0.0
	_seed_for(stats, false)
	player.take_hit(10.0, poison)
	_check(effects.active.has(DentiStatus.Type.POISON) and stats.health == 90.0, "landed hit did not apply poison")
	player.expressions.reaction_remaining = 0.0
	player.expressions._refresh_face()
	_check(player.expressions.current_face == DentiExpressions.Face.POISON, "poison gameplay did not control Denti face")
	var paused_state := effects.save_data()
	for frame in 3:
		await process_frame
	_check(effects.save_data() == paused_state and stats.health == 90.0, "paused game advanced status clocks")
	stats.armor = 15.0
	stats.shield_charges = 2
	effects.advance(0.75)
	effects.apply_attacks(poison)
	_check(is_equal_approx(effects.active[DentiStatus.Type.POISON]["tick"], 0.25), "refresh delayed next tick")
	effects.apply_attacks(bleed)
	player.expressions._refresh_face()
	_check(player.expressions.current_face == DentiExpressions.Face.POISON_BLEED, "combined effects did not select combined face")
	effects.advance(0.25)
	_check(stats.health == 88.0 and stats.shield_charges == 2, "poison used armor, dodge, or shield")
	effects.advance(0.75)
	_check(stats.health == 87.0, "bleed did not use armor or fractional tick damage")
	_check(float(game.telemetry.status_damage.get("poison", 0.0)) == 2.0 and float(game.telemetry.status_damage.get("bleed", 0.0)) == 1.0, "status damage was not attributed separately")
	game._refresh_hud()
	_check(game.hud.ailments_label.visible and game.hud.ailments_label.text.contains("Vergiftet") and game.hud.ailments_label.text.contains("Blutung"), "HUD omitted active statuses/durations")
	var state := effects.save_data()
	game._save_run()
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	player = game.player
	effects = player.status_effects
	stats = player.stats
	_check(effects.save_data() == state and stats.health == 87.0, "resume lost status potency, duration or next tick")
	_check(player.expressions.current_face == DentiExpressions.Face.POISON_BLEED, "resume lost combined gameplay status face")
	effects.advance(1.0)
	_check(stats.health == 84.0 and stats.shield_charges == 2, "resume changed status tick schedule")
	effects.clear()
	stats.health = 100.0
	effects.apply_attacks(poison)
	effects.advance(4.0)
	_check(stats.health == 92.0 and effects.active.is_empty() and not player.expressions.has_status(DentiExpressions.Status.POISON), "large delta added post-expiry ticks or omitted terminal tick")
	effects.apply_attacks(poison)
	effects.apply_attacks([{"kind": DentiStatus.Type.POISON, "damage": 1.0, "duration": 2.0}])
	_check(effects.active.size() == 1 and effects.active[DentiStatus.Type.POISON]["damage"] == 2.0, "same status stacked or weaker hit replaced stronger potency")
	# Exercise normal Godot physics, not just explicit time advancement.
	effects.clear()
	stats.health = 100.0
	effects.apply_attacks(poison)
	paused = false
	for frame in 65:
		await physics_frame
	paused = true
	_check(stats.health == 98.0 and effects.active[DentiStatus.Type.POISON]["remaining"] < 3.0, "live physics did not run poison ticks and duration")
	game._begin_loot_collection()
	_check(effects.active.is_empty() and not game.hud.ailments_label.visible, "post-wave loot/rewards retained damaging ailments")
	var before_hp := stats.health
	effects.advance(10.0)
	_check(stats.health == before_hp, "post-wave rewards suffered status damage")
	# Old saves acquire no gameplay ailments from mere presentation fields.
	effects.restore({})
	_check(effects.active.is_empty(), "legacy save gained ailments")
	effects.apply_attacks([{"kind": 99, "damage": 4.0, "duration": 5.0}])
	_check(effects.active.is_empty(), "invalid kind created an effect")
	# Fatal status damage records its attribution before the death/report signal.
	game.ended = false
	stats.health = 1.0
	effects.apply_attacks(poison)
	var old_damage := float(game.telemetry.status_damage.get("poison", 0.0))
	effects.advance(6.0)
	_check(game.ended and paused and stats.health == 0.0 and effects.active.is_empty(), "fatal tick failed death cleanup or kept ticking")
	_check(float(game.telemetry.status_damage.get("poison", 0.0)) == old_damage + 1.0, "fatal status damage was lost or overkill counted")
	_check(player.expressions.current_face == DentiExpressions.Face.DEAD, "status death did not show dead face")
	game.free()
	paused = false
	session.clear_run()
	if failures == 0:
		print("PASS player_status_effects")
	quit(0 if failures == 0 else 1)
