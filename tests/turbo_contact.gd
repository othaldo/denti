extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0


func _initialize() -> void: call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_turbo_contact.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	game.player.stats.crit_chance = 0
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		_replacement(direction)
		_forward_pair(direction)
	_living_target()
	_affixes()
	_resume()
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		_scaler_pair(direction)
	_close_control()
	_polisher_cycle()
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		_polisher_pair(direction)
	_polisher_affixes()
	_polisher_resume()
	session.clear_run()
	print("PASS contact balance: visible bounded drill/scaler contacts, scaled affixes/shared healing, resisted push, persistent polishing cycle and JSON resume")
	finish(1 if failures else 0)


func _equip_actual(id: StringName) -> WeaponInstance:
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	game.player.loadout.restore([{"id": str(id), "tier": 1}])
	game.items.cooldowns.clear()
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	weapon.data = weapon.data.duplicate(true)
	return weapon


func _equip(extras: int = 0) -> WeaponInstance:
	var weapon := _equip_actual(&"turbo_drill")
	weapon.data.contact_retarget = true
	weapon.data.contact_extra_targets = extras
	weapon.data.contact_extra_damage = 0.5
	return weapon


func _enemy(offset: Vector2, health: float = 10000) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = health
	enemy.max_health = 10000
	enemy.damage_reduction = 0
	return enemy


func _replacement(direction: Vector2) -> void:
	var weapon := _equip()
	var original := _enemy(direction * 80)
	var replacement := _enemy(direction * 110)
	var third := _enemy(direction * 140)
	var side := _enemy(direction * 95 + direction.orthogonal() * 70)
	var behind := _enemy(direction * -60)
	weapon._begin_attack([original])
	var aim := weapon.aim
	original.free()
	weapon._physics_process(weapon.attack_duration * 0.21)
	_check(replacement.health == 10000, "replacement contact bypassed the windup")
	weapon._physics_process(weapon.attack_time)
	_check(replacement.health < 10000 and weapon.aim == aim, "dead target was not replaced on the original blade")
	_check(third.health == 10000 and side.health == 10000 and behind.health == 10000, "single replacement hit extra/off-axis/back targets")
	_check(weapon.strike.contact_hits == 1, "replacement spent an incorrect contact count")
	weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
	_check(weapon.strike.contact_hits == 1, "finished replacement attack repeated")


func _living_target() -> void:
	var weapon := _equip()
	var original := _enemy(Vector2(80, 0))
	var other := _enemy(Vector2(110, 0))
	weapon._begin_attack([original])
	original.global_position += Vector2(0, 100)
	weapon._physics_process(weapon.attack_time)
	_check(original.health == 10000 and other.health == 10000, "replacement stole an attack from a living target")


func _forward_pair(direction: Vector2) -> void:
	var weapon := _equip(1)
	var first := _enemy(direction * 80)
	var second := _enemy(direction * 125)
	var third := _enemy(direction * 150)
	var near := _enemy(direction * 45)
	var side := _enemy(direction * 115 + direction.orthogonal() * 70)
	weapon._begin_attack([first])
	weapon._physics_process(weapon.attack_time)
	var damage := 10000 - first.health
	_check(is_equal_approx(damage, weapon.data.raw_damage_with_stats(weapon.tier, game.player.stats)), "primary normal-target damage changed")
	_check(damage > 0 and is_equal_approx(10000 - second.health, damage * 0.5), "forward follow-up did not deal exactly half damage")
	_check(third.health == 10000 and near.health == 10000 and side.health == 10000, "bounded follow-up hit a third/front/off-axis target")
	_check(weapon.strike.contact_hits == 2, "follow-up did not consume exactly two contacts")
	weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
	_check(is_equal_approx(10000 - first.health, damage) and third.health == 10000, "contact budget reset within a strike")
	weapon = _equip(1)
	var boss := _enemy(direction * 90)
	boss.data = boss.data.duplicate(true)
	boss.data.is_boss = true
	weapon._begin_attack([boss])
	weapon._physics_process(weapon.attack_time)
	_check(weapon.strike.contact_hits == 1, "single boss was counted as two targets")
	_check(is_equal_approx(10000 - boss.health, weapon.data.damage_against(boss, weapon.data.raw_damage_with_stats(weapon.tier, game.player.stats), weapon.tier)), "primary boss damage changed")


func _affixes() -> void:
	var weapon := _equip(1)
	weapon.tier = 2
	for kind in [&"fire", &"leech"]:
		for rank in 3: weapon.affixes = WeaponUpgrades.advance(weapon.affixes, kind, weapon.data, 2)
	weapon.refresh_affix_stats()
	var first := _enemy(Vector2(80, 0))
	var second := _enemy(Vector2(125, 0))
	game.player.stats.health = 50
	weapon._begin_attack([first])
	weapon._physics_process(weapon.attack_time)
	_check(is_equal_approx(10000 - second.health, (10000 - first.health) * 0.5), "secondary elemental packet used full power")
	var leech: Dictionary = weapon.affixes[WeaponAffixes.find(weapon.affixes, &"leech")]
	_check(game.player.stats.health > 50 and game.player.stats.health <= 50 + WeaponAffixes.utility_value(leech) + 0.001, "follow-up bypassed the per-weapon healing clock")


func _resume() -> void:
	var weapon := _equip(1)
	var first := _enemy(Vector2(80, 0), 1)
	var second := _enemy(Vector2(125, 0))
	var third := _enemy(Vector2(150, 0))
	weapon._begin_attack([first])
	for frame in 60:
		weapon._physics_process(weapon.attack_duration / 60)
		if weapon.strike.contact_hits > 0: break
	_check(weapon.strike.contact_hits == 1 and second.health == 10000, "resume fixture skipped its first contact boundary")
	if is_instance_valid(first): first.free()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(weapon.save_motion({second.get_instance_id(): 0, third.get_instance_id(): 1})))
	_check(saved.hits.is_empty() and saved.contact_hits == 1, "dead primary was not represented by an independent spent budget")
	weapon.restore_motion(saved, [second, third])
	weapon._physics_process(weapon.attack_time)
	_check(is_equal_approx(10000 - second.health, weapon.strike.damage * 0.5) and third.health == 10000, "JSON resume repeated full damage or skipped the forward follow-up")
	saved = JSON.parse_string(JSON.stringify(weapon.save_motion({third.get_instance_id(): 0})))
	second.free()
	weapon.restore_motion(saved, [third])
	weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
	_check(third.health == 10000, "lost target references restored a consumed hit budget")
	# Historic mid-strike saves cannot acquire an extra contact on update.
	saved.erase("contact_hits")
	saved.erase("contact_limit")
	saved.erase("primary_contact")
	saved.remaining = 0.1
	weapon.restore_motion(saved, [third])
	weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
	_check(third.health == 10000 and weapon.strike.contact_limit == 1, "legacy saved attack acquired new targets")


func _scaler_pair(direction: Vector2) -> void:
	var weapon := _equip_actual(&"plaque_scaler")
	var first := _enemy(direction * 70)
	var second := _enemy(direction.rotated(deg_to_rad(20)) * 95)
	var third := _enemy(direction.rotated(deg_to_rad(28)) * 100)
	var side := _enemy(direction * 70 + direction.orthogonal() * 90)
	var behind := _enemy(direction * -70)
	weapon._begin_attack([first])
	weapon._physics_process(weapon.attack_duration * 0.21)
	_check(first.health == 10000 and second.health == 10000, "scaler bypassed the visible windup")
	weapon._physics_process(weapon.attack_time)
	var first_damage := 10000 - first.health
	_check(first_damage > 0 and is_equal_approx(10000 - second.health, first_damage * 0.5), "scaler's swept blade lost its bounded half-damage follow-up")
	_check(third.health == 10000 and side.health == 10000 and behind.health == 10000 and weapon.strike.contact_hits == 2, "scaler became an unlimited or circular attack")
	# A dead target must not consume the whole slash if another body is touched.
	weapon = _equip_actual(&"plaque_scaler")
	first = _enemy(direction * 70)
	second = _enemy(direction * 90)
	weapon._begin_attack([first])
	var aim := weapon.aim
	first.free()
	weapon._physics_process(weapon.attack_time)
	_check(second.health < 10000 and weapon.aim == aim and weapon.strike.contact_hits == 1, "scaler's dead-target replacement changed aim or lost contact")


func _close_control() -> void:
	for id in [&"turbo_drill", &"cavity_grinder", &"plaque_scaler", &"prophylaxis_polisher"]:
		for resistance in [0.0, 1.0]:
			var weapon := _equip_actual(id)
			var target := _enemy(Vector2(100, 0))
			target.data = target.data.duplicate(true)
			target.data.knockback_resistance = resistance
			var at := target.global_position
			weapon._begin_attack([target])
			weapon._physics_process(weapon.attack_time)
			_check(target.health < 10000, "contact control fixture did not connect: " + str(id))
			_check(is_equal_approx(target.global_position.x - at.x, weapon.data.knockback_at_tier(1) * (1.0 - resistance)) and is_equal_approx(target.global_position.y, at.y), "contact push ignored its direction or resistance: " + str(id))
			_check(resistance > 0 or target.global_position.x > at.x, "short weapon failed to create any space: " + str(id))


func _polisher_pair(direction: Vector2) -> void:
	var weapon := _equip_actual(&"prophylaxis_polisher")
	weapon.data.crit_bonus = 0
	var first := _enemy(direction * 80)
	var second := _enemy(direction * 110)
	var third := _enemy(direction * 119)
	var near := _enemy(direction * 40)
	var side := _enemy(direction * 100 + direction.orthogonal() * 65)
	weapon._begin_attack([first])
	weapon._physics_process(weapon.attack_duration * 0.21)
	_check(first.health == 10000 and second.health == 10000, "polisher pair skipped its windup")
	weapon._physics_process(weapon.attack_time)
	var damage := 10000 - first.health
	_check(is_equal_approx(damage, weapon.data.raw_damage_with_stats(1, game.player.stats)), "polisher changed primary hit damage")
	_check(is_equal_approx(10000 - second.health, damage * 0.4), "polisher follow-up was not 40 percent")
	_check(third.health == 10000 and near.health == 10000 and side.health == 10000, "polisher exceeded its forward pair or hit off-axis")
	weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
	_check(weapon.strike.contact_hits == 2 and is_equal_approx(10000 - second.health, damage * 0.4), "polisher repeated its follow-up")
	weapon = _equip_actual(&"prophylaxis_polisher")
	weapon.data.crit_bonus = 0
	weapon.crit_cycle_progress = 2
	first = _enemy(direction * 80)
	second = _enemy(direction * 110)
	weapon._begin_attack([first])
	weapon._physics_process(weapon.attack_time)
	_check(weapon.strike.critical and weapon.crit_cycle_progress == 0, "polisher pair advanced the crit cycle more than once")
	_check(is_equal_approx(10000 - second.health, (10000 - first.health) * 0.4), "polisher critical follow-up ignored its damage share")
	weapon = _equip_actual(&"prophylaxis_polisher")
	weapon.data.crit_bonus = 0
	var boss := _enemy(direction * 120)
	boss.data = boss.data.duplicate(true)
	boss.data.is_boss = true
	weapon._begin_attack([boss])
	weapon._physics_process(weapon.attack_time)
	_check(weapon.strike.contact_hits == 1 and is_equal_approx(10000 - boss.health, weapon.strike.damage), "single boss received a second polisher hit")


func _polisher_affixes() -> void:
	var weapon := _equip_actual(&"prophylaxis_polisher")
	weapon.tier = 2
	weapon.data.crit_bonus = 0
	for kind in [&"fire", &"leech"]:
		for rank in 3: weapon.affixes = WeaponUpgrades.advance(weapon.affixes, kind, weapon.data, 2)
	weapon.refresh_affix_stats()
	var first := _enemy(Vector2(80, 0))
	var second := _enemy(Vector2(110, 0))
	game.player.stats.health = 50
	weapon._begin_attack([first])
	weapon._physics_process(weapon.attack_time)
	_check(is_equal_approx(10000 - second.health, (10000 - first.health) * 0.4), "polisher elemental follow-up used full power")
	var leech: Dictionary = weapon.affixes[WeaponAffixes.find(weapon.affixes, &"leech")]
	_check(game.player.stats.health > 50 and game.player.stats.health <= 50 + WeaponAffixes.utility_value(leech) + 0.001, "polisher pair bypassed the shared healing clock")


func _polisher_resume() -> void:
	var weapon := _equip_actual(&"prophylaxis_polisher")
	weapon.data.crit_bonus = 0
	var first := _enemy(Vector2(50, 0), 1)
	var second := _enemy(Vector2(120, 0))
	var third := _enemy(Vector2(125, 0))
	weapon._begin_attack([first])
	for frame in 60:
		weapon._physics_process(weapon.attack_duration / 60)
		if weapon.strike.contact_hits > 0: break
	_check(weapon.strike.contact_hits == 1 and second.health == 10000, "polisher resume fixture skipped its first contact")
	if is_instance_valid(first): first.free()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(weapon.save_motion({second.get_instance_id(): 0, third.get_instance_id(): 1})))
	weapon.restore_motion(saved, [second, third])
	weapon._physics_process(weapon.attack_time)
	_check(is_equal_approx(10000 - second.health, weapon.strike.damage * 0.4) and third.health == 10000, "polisher resume repeated full damage or exceeded its pair")
	# A pre-buff saved attack still owns its original one-contact budget.
	var legacy := saved.duplicate(true)
	legacy.contact_limit = 1
	second.health = 10000
	weapon.restore_motion(legacy, [second, third])
	weapon.strike.tick(weapon, WeaponMotion.ACTIVE_START, WeaponMotion.ACTIVE_END)
	_check(second.health == 10000 and weapon.strike.contact_hits == 1, "polisher enlarged an already spent legacy attack")
	weapon._begin_attack([second])
	_check(weapon.strike.contact_limit == 2, "new polisher attack did not receive the new pair budget")


func _polisher_cycle() -> void:
	var weapon := _equip_actual(&"prophylaxis_polisher")
	weapon.data.crit_bonus = 0
	var target := _enemy(Vector2(108, 0))
	weapon._begin_attack([target])
	weapon._physics_process(weapon.attack_time)
	_check(target.health < 10000 and not weapon.strike.critical and weapon.crit_cycle_progress == 1, "polisher lost its extended reach or first cycle step")
	target.free()
	weapon._physics_process(1.0)
	_check(weapon.crit_cycle_progress == 1, "an idle gap erased the polishing cycle")
	# This is explicitly an attack cycle: even a whiff advances it.
	target = _enemy(Vector2(108, 0))
	weapon._begin_attack([target])
	target.free()
	weapon._physics_process(weapon.attack_time)
	_check(weapon.crit_cycle_progress == 2 and not weapon.strike.critical and weapon.strike.contact_hits == 0, "target switching or a missed attack corrupted the polishing cycle")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	_check(snapshot.weapon_runtime[0].crit_cycle_progress == 2 and snapshot.weapon_runtime[0].focus_target == -1, "cycle save still depends on a surviving target")
	RunSnapshot.restore(game, snapshot)
	weapon = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	weapon.data = weapon.data.duplicate(true)
	weapon.data.crit_bonus = 0
	target = _enemy(Vector2(108, 0))
	weapon._begin_attack([target])
	weapon._physics_process(weapon.attack_time)
	_check(weapon.strike.critical and weapon.crit_cycle_progress == 0 and target.health < 10000, "resumed third attack did not critically hit a new target")
	target.free()
	target = _enemy(Vector2(108, 0))
	weapon._begin_attack([target])
	_check(not weapon.strike.critical and weapon.crit_cycle_progress == 1, "polisher repeated its guaranteed crit on the fourth attack")
	# An old save without this optional field starts a fresh cycle.
	snapshot.weapon_runtime[0].erase("crit_cycle_progress")
	RunSnapshot.restore(game, snapshot)
	_check(game.player.loadout.equipped()[0].crit_cycle_progress == 0, "legacy resume fabricated polishing progress")
