extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D
var player: Player

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _reset() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	for shot in game.get_node("EnemyProjectiles").get_children(): shot.free()
	game.get_node("Enemies").set_physics_process(false)
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.wave.active = true
	game.wave.set_process(false)
	player.set_physics_process(false)
	player.global_position = Vector2(500, 300)
	player.stats.max_health = 10000
	player.stats.health = 10000
	player.stats.armor = 0
	player.stats.dodge_chance = 0
	player.stats.dash_recovery_bonus = 0
	player.stats.shield_charges = 0
	player.hurt_time = 0
	player.dodge_time = 0
	player.status_effects.clear()
	player.dash.reset_wave()
	player.dash.last_direction = Vector2.DOWN
	paused = false

func _enemy(at: Vector2) -> Enemy:
	game._create_enemy(EnemyCatalog.PLAQUE, at)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.contact_damage = 10
	enemy.move_speed = 0
	game.get_node("Enemies").set_physics_process(false)
	return enemy

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://player_dash_test.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	player = game.player
	player.loadout.restore([])
	game.set_process(false)
	_reset()
	for phase in [RunFlow.Phase.STARTER, RunFlow.Phase.COLLECTING, RunFlow.Phase.REWARDS, RunFlow.Phase.SHOP, RunFlow.Phase.STORY, RunFlow.Phase.ENDED]:
		game.run_flow.enter(phase)
		_check(not player.try_dash() and player.dash.charge == 100, "dash started outside active combat")
	game.run_flow.enter(RunFlow.Phase.BOSS_OVERTIME)
	game.wave.active = false
	game.boss_pending = true
	_check(player.try_dash(), "boss overtime rejected dash")
	game.boss_pending = false
	for direction in [Vector2.RIGHT, Vector2(1, 1), Vector2.DOWN]:
		_reset()
		player.stats.speed_bonus = 500
		_check(player.dash.request(direction, true), "full dash was rejected")
		player._physics_process(0.16)
		_check(player.global_position.distance_to(Vector2(500, 300) + direction.normalized() * 150) < 0.02, "dash distance depends on diagonal or move speed")
		_check(not player.dash.active and player.dash.charge == 0 and player.hurt_time == 0 and player.dodge_time == 0, "dash gives protection or skips its recovery")
	player.stats.speed_bonus = 0
	for sample in [[0.0, 4.51], [100.0, 2.51], [400.0, 1.5]]:
		_reset()
		player.stats.dash_recovery_bonus = sample[0]
		player.dash.request(Vector2.RIGHT, true)
		player._physics_process(sample[1] - 0.01)
		_check(not player.dash.ready_to_dash(), "dash became ready before both gates elapsed")
		player._physics_process(0.01001)
		_check(player.dash.ready_to_dash(), "dash did not recharge at its expected time")
	_reset()
	player.stats.dash_recovery_bonus = 400
	player.dash.request(Vector2.RIGHT, true)
	player._physics_process(1.31)
	_check(player.dash.charge > 99.99 and player.dash.cooldown > 0 and not player.try_dash(), "full charge bypassed cooldown")
	_reset()
	player.dash.charge = 99
	_check(not player.try_dash() and player.dash.charge == 99, "partial charge is usable or invalid input spends it")
	player.dash.reset_wave()
	_check(player.try_dash() and player.dash.direction == Vector2.DOWN, "first stationary dash does not point down")
	_reset()
	Input.action_press("move_left")
	_check(player.try_dash() and player.dash.direction == Vector2.LEFT, "current movement direction was ignored")
	Input.action_release("move_left")
	player._physics_process(5)
	_check(player.try_dash() and player.dash.direction == Vector2.LEFT, "stationary dash forgot last movement")
	_reset()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_SHIFT
	press.keycode = KEY_SHIFT
	press.pressed = true
	root.push_input(press, true)
	_check(player.dash.active, "physical Shift did not trigger dash")
	player._physics_process(5)
	press.echo = true
	root.push_input(press, true)
	_check(not player.dash.active, "held Shift repeated dash")
	press.echo = false
	press.pressed = false
	root.push_input(press, true)
	press.pressed = true
	root.push_input(press, true)
	_check(player.dash.active, "released Shift could not dash again")
	press.pressed = false
	root.push_input(press, true)
	for protection in ["none", "shield", "dodge", "roll", "hurt"]:
		_reset()
		var obstacle := _enemy(player.global_position + Vector2(75, 0))
		if protection == "shield": player.stats.shield_charges = 2
		if protection == "hurt": player.hurt_time = 0.4
		if protection == "dodge": player.dodge_time = 0.15
		if protection == "roll":
			player.stats.dodge_chance = 0.6
			player.stats.shield_charges = 1
			for seed in 100:
				player.stats.dodge_rng.seed = seed
				if player.stats.dodge_rng.randf() < 0.6:
					player.stats.dodge_rng.seed = seed
					break
		var before := player.stats.health
		player.dash.request(Vector2.RIGHT, true)
		player._physics_process(0.16)
		_check(player.global_position.x < obstacle.global_position.x and not player.dash.active and player.dash.charge < 1, "protection allowed crossing an enemy: " + protection)
		obstacle.try_contact_hit()
		_check(player.stats.health == before - (10 if protection == "none" else 0), "contact damage was duplicated or ignored")
		if protection == "shield": _check(player.stats.shield_charges == 1, "same contact consumed two shields")
		if protection == "roll": _check(player.stats.shield_charges == 1, "passive dodge consumed a shield during dash")
	_reset()
	_enemy(player.global_position)
	player.dash.request(Vector2.RIGHT, true)
	player._physics_process(1.0)
	_check(player.global_position == Vector2(500, 300), "dash escaped an overlapping horde")
	_reset()
	var charger := _enemy(player.global_position + Vector2(75, 100))
	charger.data = charger.data.duplicate()
	charger.data.attack_speed = 1000
	charger.attack_damage = 10
	charger.active_special_attack = EnemyData.SpecialAttack.DASH
	charger.special_phase = Enemy.SpecialPhase.ACTIVE
	charger.special_direction = Vector2.UP
	player.dash.request(Vector2.RIGHT, true)
	player._physics_process(0.16)
	_check(not player.dash.active and player.global_position.x < 600 and player.stats.health < 10000, "crossing enemy charge tunneled through dash")
	_reset()
	player.global_position.x = player.arena.arena_size.x - DentiArena.PLAYER_MARGIN - 10
	player.dash.request(Vector2.RIGHT, true)
	player._physics_process(0.16)
	_check(player.global_position.x <= player.arena.arena_size.x - DentiArena.PLAYER_MARGIN and not player.dash.active and player.dash.charge < 1, "arena boundary did not stop/spend dash")
	_reset()
	var wall := StaticBody2D.new()
	wall.position = Vector2(580, 300)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 100)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	await physics_frame
	await physics_frame
	player.dash.request(Vector2.RIGHT, true)
	player._physics_process(0.16)
	_check(player.global_position.x < 570 and not player.dash.active, "dash crossed a physical wall")
	wall.free()
	for long_frame in [0.16, 1.0]:
		_reset()
		var shot := EnemyProjectilePatterns.acquire(game.get_node("EnemyProjectiles"))
		shot.launch(player.global_position + Vector2(75, -100), Vector2.DOWN, 1250, 20, player, Color.GREEN, 5)
		player.dash.request(Vector2.RIGHT, true)
		player._physics_process(long_frame)
		shot._physics_process(long_frame)
		_check(player.stats.health == 9980 and not shot.is_inside_tree(), "dash tunneled through a moving projectile on a long frame")
	_reset()
	var pulse := _enemy(player.global_position + Vector2(75, 40))
	pulse.data = pulse.data.duplicate()
	pulse.data.radius = 5
	pulse.data.attack_radius = 50
	pulse.attack_damage = 20
	pulse.active_special_attack = EnemyData.SpecialAttack.PULSE
	pulse.special_phase = Enemy.SpecialPhase.WARNING
	pulse.special_timer = 0.08
	player.dash.request(Vector2.RIGHT, true)
	player._physics_process(0.16)
	pulse._process_special(0.16, Vector2.ZERO)
	_check(player.stats.health == 9980, "dash tunneled through an activating damage area")
	player.hurt_time = 0
	player.stats.health = 10000
	pulse.special_phase = Enemy.SpecialPhase.WARNING
	pulse.special_timer = 0.16
	pulse._process_special(0.16, Vector2.ZERO)
	_check(player.stats.health == 10000, "a warning dealt damage retroactively after dash escaped it")
	_reset()
	player.dash.request(Vector2.RIGHT, true)
	player._physics_process(0.06)
	var saved: Dictionary = game.RUN_SNAPSHOT.capture(game)
	var remainder := player.dash.remaining
	var cooldown := player.dash.cooldown
	paused = true
	for frame in 3: await process_frame
	_check(player.dash.remaining == remainder and player.dash.cooldown == cooldown and not player.try_dash(), "pause advanced or refilled dash")
	_check(session.save_run(saved) == OK, "dash save failed")
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	player = game.player
	_check(is_equal_approx(player.dash.remaining, remainder) and is_equal_approx(player.dash.cooldown, cooldown) and player.dash.charge == 0, "resume refilled or lost active dash")
	paused = false
	game.wave.set_process(false)
	player.set_physics_process(false)
	_enemy(player.global_position + Vector2(50, 0))
	player._physics_process(remainder)
	_check(not player.dash.active and player.global_position.x < 620, "resumed movement skipped new collision checks")
	saved.player.erase("dash")
	saved.player.stats.erase("dash_recovery_bonus")
	_check(not RunSaveData.normalize(saved).is_empty(), "legacy dash-less save was rejected")
	player.dash.restore({})
	player.stats.load_save_data(saved.player.stats)
	_check(player.dash.ready_to_dash() and player.stats.dash_recovery_bonus == 0, "old save lacks full base charge")
	var corrupt: Dictionary = saved.duplicate(true)
	corrupt.player.dash = {"direction": ["bad", 1]}
	_check(RunSaveData.normalize(corrupt).is_empty(), "malformed dash vector was accepted")
	_check(game.telemetry.dashes > 0, "dash telemetry did not survive restore")
	player.stats.dash_recovery_bonus = 400
	game._show_level_choice()
	for choice: UpgradeData in game.choice_panel.current_upgrades:
		_check(choice.stat != &"dash_recovery_bonus", "capped recovery was offered again")
	_check(DentiAttributes.Type.DODGE == 10 and DentiAttributes.Type.DASH_RECOVERY == 11, "dash changed existing attribute IDs")
	player.stats.dash_recovery_bonus = 390
	var upgrade: UpgradeData = load("res://data/upgrades/wurzelkraft.tres").with_tier(4).with_stat_context(player.stats)
	_check(upgrade.amount == 10 and upgrade.effect_text().contains("0.80 s"), "upgrade cap or resulting refill time is wrong")
	player.dash.charge = 41
	player.dash.remaining = 0
	player.dash.cooldown = 0.5
	player.dash.recovery = 0.1
	var restored := PlayerDash.new()
	restored.restore(JSON.parse_string(JSON.stringify(player.dash.save_data())))
	_check(restored.charge == 41 and restored.cooldown == 0.5 and restored.recovery == 0.1 and not restored.active, "partly recharging cooldown save changed phase")
	player.stats.dash_recovery_bonus = 0
	game.items.acquire(ItemCatalog.by_id(&"mint_essence"))
	game.items.acquire(ItemCatalog.by_id(&"sugar_2"))
	_check(player.stats.dash_recovery_bonus == 25, "shop items do not modify authoritative dash recovery")
	session.clear_run()
	game.free()
	paused = false
	if failures.is_empty(): print("Dash movement, gates, collision, hazards, input, pause and save compatibility passed")
	finish(0 if failures.is_empty() else 1)
