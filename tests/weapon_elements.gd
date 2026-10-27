extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_elements.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	var loadout: WeaponLoadout = game.player.loadout
	var data := WeaponCatalog.by_id(&"magic_toothbrush")
	var elements: Array[StringName] = []
	var supports: Array[StringName] = []
	for definition in WeaponAffixes.ALL:
		if not definition.selectable: continue
		if definition.elemental: elements.append(definition.id)
		else: supports.append(definition.id)
	_check(elements.size() == 6 and supports.size() == 6 and &"bleed" in elements and &"wet" in elements, "catalogue must contain six elements and six supports")
	for element in elements:
		var values := WeaponUpgrades.advance([], element, data, 4)
		_check(values.size() == 1, "first element rejected")
		for other in elements:
			var after := WeaponUpgrades.advance(values, other, data, 4)
			_check(not after.is_empty() if other == element else after.is_empty(), "element exclusivity or existing-rank upgrade failed")
		for support in supports:
			_check(WeaponUpgrades.advance(values, support, data, 4).size() == 2, "element blocked a meaningful support")
	_check(WeaponUpgrades.advance([], &"holy", data, 4).is_empty(), "retired holy effect is still newly selectable")
	_check(not WeaponUpgrades.fusion_fits(WeaponUpgrades.advance([], &"fire", data, 1), WeaponUpgrades.advance([], &"ice", data, 1)), "fusion bypasses element choice")
	_check(WeaponUpgrades.fusion_fits(WeaponUpgrades.advance([], &"fire", data, 1), WeaponUpgrades.advance([], &"tempo", data, 1)), "compatible fusion rejected")
	# Stale/resumed plans must release points, including a former second element.
	loadout.restore([{"id": "magic_toothbrush", "tier": 4}])
	var target := loadout.equipped()[0]
	var state := WeaponUpgradeState.new()
	state.restore({"points": 3, "actions": [{"uid": target.instance_uid, "id": "fire"}, {"uid": target.instance_uid, "id": "ice"}, {"uid": target.instance_uid, "id": "tempo"}]})
	state.validate(loadout)
	_check(state.actions.size() == 2 and state.remaining() == 1 and state.commit(loadout), "old second-element draft lost points or partially committed")
	_check(WeaponPresentation.weapon_name(target).ends_with("der Glut"), "support hides elemental weapon identity")
	# Different-element fusion also stays blocked in the actual loadout.
	loadout.restore([
		{"id": "turbo_drill", "tier": 1, "affixes": [{"id": "fire", "level": 1, "damage": 1}]},
		{"id": "turbo_drill", "tier": 1, "affixes": [{"id": "ice", "level": 1, "damage": 1}]}])
	_check(not loadout.can_merge(0) and loadout.merge_affix_conflict(0), "loadout accepts different-element fusion")
	# New supports affect only their own weapon, including zero-base knockback.
	loadout.restore([{"id": "magic_toothbrush", "tier": 4}, {"id": "magic_toothbrush", "tier": 4}])
	target = loadout.equipped()[0]
	state = WeaponUpgradeState.new()
	state.points = 30
	for id in [&"crit", &"crit_damage", &"knockback"]:
		for rank in 10: _check(state.plan(loadout, target.instance_uid, id), "support rank was rejected")
	_check(state.commit(loadout), "support draft cannot commit")
	var bonus := WeaponUpgrades.power(&"crit", 10, data, 4) / 100.0
	_check(is_equal_approx(target.data.crit_bonus, data.crit_bonus + bonus) and loadout.equipped()[1].data.crit_bonus == data.crit_bonus, "critical chance leaked between instances")
	var critical: float = game.player.stats.roll_critical_damage(10, target.data.crit_bonus, target.data.crit_multiplier, true)
	_check(is_equal_approx(critical, 10 * (data.crit_multiplier + WeaponUpgrades.power(&"crit_damage", 10, data, 4) / 100.0)), "critical multiplier does not affect actual damage rolls")
	var saved := loadout.save_data()
	for repeat in 4: target.refresh_affix_stats()
	_check(loadout.save_data() == saved, "support refresh compounds derived stats")
	loadout.restore(saved)
	_check(loadout.save_data() == saved, "support save/resume changes its values")
	target = loadout.equipped()[0]
	var pushed := _enemy({})
	pushed.data.knockback_resistance = 0.5
	var at := pushed.global_position
	WeaponAttackShapes.hit(pushed, target.data, 4, 1, false, game.items, Vector2.RIGHT, target.affixes)
	_check(is_equal_approx(pushed.global_position.x - at.x, target.data.knockback_at_tier(4) * 0.5), "Wucht ignored resistance or cannot add missing knockback")
	# Tier-specific native knockback receives the support once at every tier.
	var tiered := WeaponCatalog.by_id(&"water_jet")
	var amplified := WeaponRolls.with_affixes(tiered, WeaponUpgrades.advance([], &"knockback", tiered, 4))
	for tier in [1, 4]:
		_check(is_equal_approx(amplified.knockback_at_tier(tier) - tiered.knockback_at_tier(tier), WeaponUpgrades.power(&"knockback", 1, tiered, 4)), "native knockback tiers ignored the support")
	# Water deals direct damage. Weakness changes only that packet, once.
	var water := WeaponUpgrades.advance([], &"wet", data, 4)
	var water_damage := WeaponAffixes.packets(water, data, game.player.stats)[0].damage as float
	for resistance in [0.0, -0.25, -0.5, 0.6]:
		var enemy := _enemy({"wet": resistance})
		var before := enemy.health
		WeaponAttackShapes.hit(enemy, data, 4, 10, false, game.items, Vector2.RIGHT, water)
		_check(is_equal_approx(before - enemy.health, 10 + water_damage * (1.0 - resistance)), "water damage missing or weakness multiplied the physical hit")
		_check(enemy.wet_time > 0 and enemy.affix_effects.pending.is_empty(), "water lost wet synergy or became a DoT")
	_check(is_equal_approx(preload("res://data/enemies/sugar.tres").affix_resistance(&"wet"), -0.5) and is_equal_approx(preload("res://data/enemies/plaque.tres").affix_resistance(&"wet"), -0.25), "actual enemy resources lack water weakness")
	# Old invested mixed weapons remain loadable, with no silent deletion.
	loadout.restore([{"id": "magic_toothbrush", "tier": 4, "affixes": [{"id": "fire", "level": 2, "damage": 2}, {"id": "ice", "level": 3, "damage": 3}, {"id": "holy", "damage": 7}]}])
	_check(loadout.equipped()[0].affixes.size() == 3, "migration discarded invested old effects")
	session.clear_run()
	paused = false
	print("PASS weapon elements: exclusivity, fusion, stale drafts, six supports, actual damage/push, water weaknesses and legacy investments")
	finish(1 if failures > 0 else 0)


func _enemy(resistances: Dictionary) -> Enemy:
	game._create_enemy(preload("res://data/enemies/bacteria.tres"), Vector2(1000, 1000))
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.data = enemy.data.duplicate()
	enemy.data.affix_resistances = resistances
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.damage_reduction = 0
	enemy.set_physics_process(false)
	return enemy


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
