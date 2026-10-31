extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://test_sustain_balance.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	paused = true
	game.player.stats.max_health = 1000
	game.player.stats.crit_chance = 0
	_salvos_and_resume()
	_splash_and_contact()
	_legacy_and_full_health()
	_fairy_items()
	session.clear_run()
	paused = false
	print("PASS sustain: per-instance clocks, shared salvo/splash limits, real projectile owners, JSON resume, pooled reuse, contact/beam healing, legacy clock, full health and reduced fairy XP healing")
	finish(1 if failures else 0)

func _reset() -> void:
	for shot in game.get_node("Projectiles").get_children(): shot.free()
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	game.player.loadout.restore([])
	game.items.cooldowns.clear()
	game.element_impacts.clear()
	game.player.stats.health = 50

func _equip(ids: Array[String]) -> Array[WeaponInstance]:
	var entries: Array[Dictionary] = []
	for id in ids:
		var data := WeaponCatalog.by_id(StringName(id))
		var affixes: Array[Dictionary] = []
		for rank in 10: affixes = WeaponUpgrades.advance(affixes, &"leech", data, 4)
		entries.append({"id": id, "tier": 4, "affixes": affixes})
	game.player.loadout.restore(entries)
	var equipped: Array[WeaponInstance] = game.player.loadout.equipped()
	for weapon in equipped: weapon.set_physics_process(false)
	return equipped

func _enemy(offset := Vector2(140, 0)) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 1000000
	enemy.max_health = 1000000
	enemy.damage_reduction = 0
	return enemy

func _fire(weapon: WeaponInstance, enemy: Enemy) -> Array[Node]:
	var pool: Node = game.get_node("Projectiles")
	var previous := pool.get_child_count()
	weapon._begin_attack([enemy])
	var shots: Array[Node] = pool.get_children().slice(previous)
	for shot in shots: shot.set_physics_process(false)
	return shots

func _contact(shot: WeaponProjectile, enemy: Enemy) -> void:
	shot.impact_time = 0
	shot.traveled = 0
	shot.hit_ids.clear()
	shot.global_position = enemy.global_position - shot.direction * 6
	shot._physics_process(0.025)

func _salvos_and_resume() -> void:
	_reset()
	var weapons := _equip(["magic_toothbrush", "magic_toothbrush"])
	var uids := [weapons[0].instance_uid, weapons[1].instance_uid]
	_check(uids[0] != uids[1], "equal weapon types share their instance identity")
	var enemy := _enemy()
	var first := _fire(weapons[0], enemy)
	var second := _fire(weapons[1], enemy)
	_check(first.size() == 3 and second.size() == 3, "salvo fixture has no three-projectile attacks")
	var before: float = game.player.stats.health
	_contact(first[0], enemy)
	var healed: float = game.player.stats.health - before
	_check(healed > 0 and healed <= WeaponAffixes.by_id(&"leech").utility_cap, "first owner did not heal within its cap")
	for shot: WeaponProjectile in first:
		_check(shot.source_uid == uids[0], "salvo projectile lost its owner")
		_contact(shot, enemy)
	_check(is_equal_approx(game.player.stats.health, before + healed), "salvo healed separately for each pellet")
	for shot: WeaponProjectile in second:
		_check(shot.source_uid == uids[1], "second weapon inherited the first owner's identity")
		_contact(shot, enemy)
	_check(is_equal_approx(game.player.stats.health, before + healed * 2), "identical weapon instances still share a healing clock")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	RunSnapshot.restore(game, saved)
	weapons = game.player.loadout.equipped()
	for weapon in weapons: weapon.set_physics_process(false)
	_check(weapons[0].instance_uid == uids[0] and weapons[1].instance_uid == uids[1], "resume changed weapon identities")
	var shots := game.get_node("Projectiles").get_children()
	enemy = game.get_node("Enemies").get_child(0)
	for shot: WeaponProjectile in shots:
		shot.set_physics_process(false)
		_check(uids.has(shot.source_uid), "JSON projectile resume lost its owner")
		_contact(shot, enemy)
	_check(is_equal_approx(game.player.stats.health, before + healed * 2), "resume reset active healing clocks")
	var interval := WeaponAffixes.by_id(&"leech").proc_cooldown
	game.items._process(interval - 0.01)
	_contact(shots[0], enemy)
	_check(is_equal_approx(game.player.stats.health, before + healed * 2), "owner cooldown ended early")
	game.items._process(0.01001)
	_contact(shots[0], enemy)
	_check(is_equal_approx(game.player.stats.health, before + healed * 3), "owner did not recover after its interval")
	# An idle pooled body must take the newly launching weapon's identity.
	var pool: PlayerProjectilePool = game.get_node("Projectiles")
	var reused: WeaponProjectile = shots[0]
	var data := reused.data
	pool.recycle(reused)
	var next := pool.acquire(data, 4)
	_check(next == reused, "pool reuse fixture did not reuse its projectile")
	next.launch(enemy.global_position - Vector2(6, 0), Vector2.RIGHT, 100, data, game.items, false, 4, weapons[0].affixes, 1.0, "new_owner")
	var prior: float = game.player.stats.health
	_contact(next, enemy)
	_check(next.source_uid == "new_owner" and game.player.stats.health > prior, "pooled projectile retained a previous owner's blocked clock")

func _splash_and_contact() -> void:
	_reset()
	var weapons := _equip(["mouthwash_mortar", "mouthwash_mortar"])
	var enemy := _enemy()
	_enemy(Vector2(160, 20))
	var cap := WeaponAffixes.utility_value(weapons[0].affixes[0], weapons[0].data.hands)
	for weapon in weapons:
		var shot: WeaponProjectile = _fire(weapon, enemy)[0]
		shot.global_position = enemy.global_position
		var before: float = game.player.stats.health
		shot._explode()
		_check(is_equal_approx(game.player.stats.health - before, cap), "splash healed per target or a different mortar was blocked")
	_reset()
	weapons = _equip(["floss_whip", "enamel_mirror"])
	enemy = _enemy(Vector2(100, 0))
	for weapon in weapons:
		var before: float = game.player.stats.health
		weapon._begin_attack([enemy])
		if WeaponMotion.is_contact(weapon.data): weapon._physics_process(weapon.attack_duration)
		_check(game.player.stats.health > before, "contact/beam attack omitted its own lifesteal identity")

func _legacy_and_full_health() -> void:
	_reset()
	var weapon := _equip(["enamel_mirror"])[0]
	var enemy := _enemy()
	game.items.cooldowns["enchantment_leech"] = 0.2
	var before: float = game.player.stats.health
	weapon._begin_attack([enemy])
	_check(game.player.stats.health == before, "old shared clock was silently cleared on load")
	game.items._process(0.2001)
	weapon._begin_attack([enemy])
	_check(game.player.stats.health > before, "old shared clock never yielded to the per-weapon clock")
	game.items._process(1.0)
	_check(not game.items.cooldowns.has("enchantment_leech:" + weapon.instance_uid), "expired owner clocks accumulate forever")
	game.player.stats.health = game.player.stats.max_health
	weapon._begin_attack([enemy])
	_check(not game.items.cooldowns.has("enchantment_leech:" + weapon.instance_uid), "full-health hit consumed a healing impulse")
	game.player.stats.health -= 10
	before = game.player.stats.health
	weapon._begin_attack([enemy])
	_check(game.player.stats.health > before, "full-health attack prevented the next useful heal")

func _fairy_items() -> void:
	_reset()
	for row in [["xp_heal_1", 0.10], ["tooth_fairy_pact", 0.25], ["xp_heal_3", 0.35], ["xp_heal_4", 0.45]]:
		game.items.restore({"owned": {}})
		var item := ItemCatalog.by_id(StringName(row[0]))
		_check(game.items.acquire(item), "fairy item could not be acquired")
		game.player.stats.health = 50
		game.items.on_pickup(&"xp", 10)
		_check(is_equal_approx(game.player.stats.health, 50 + float(row[1]) * 10), "fairy item XP heal does not use its reduced coefficient")
		var before: float = game.player.stats.health
		game.items.on_pickup(&"coin", 10)
		_check(game.player.stats.health == before, "fairy contract healed from coins")
	game.items.restore({"owned": {"xp_heal_1": 2, "tooth_fairy_pact": 1, "xp_heal_3": 1, "xp_heal_4": 1}})
	game.player.stats.health = 50
	game.items.on_pickup(&"xp", 10)
	_check(is_equal_approx(game.player.stats.health, 62.5), "mixed fairy rarities do not stack at the new values")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(RunSnapshot.capture(game)))
	RunSnapshot.restore(game, saved)
	_check(is_equal_approx(game.items.power(&"xp_heal"), 1.25), "resumed fairy items retained old healing strength")
