class_name PoisonBuildEffects
extends RefCounted

const RULES: PoisonBuildData = preload("res://data/synergies/poison_build.tres")
var depots: Array[WeakRef] = []
var previous: WeakRef
var window := 0.0

func advance(delta: float) -> void:
	window = maxf(window - delta, 0)
	if window <= 0: previous = null

func clear() -> void:
	depots.clear()
	previous = null
	window = 0

func _prune() -> void:
	for index in range(depots.size() - 1, -1, -1):
		var enemy := depots[index].get_ref() as Enemy
		if not is_instance_valid(enemy) or enemy.health <= 0 or enemy.affix_effects.depot.ticks.is_empty():
			depots.remove_at(index)

func after_hit(effects: ItemEffectContext, enemy: Enemy, weapon: WeaponData, tier: int) -> void:
	var relic_active := is_instance_valid(effects.relics) and effects.relics.has_relic(&"venom_fang")
	if effects.power(&"poison_depot") <= 0 and effects.power(&"poison_nerve") <= 0 and not relic_active: return
	if not enemy.is_targetable() or enemy.data.is_boss and enemy.boss_phase_timer > 0: return
	var state := enemy.affix_effects
	var depot := state.depot
	if effects.power(&"poison_depot") > 0:
		apply_depot(effects, enemy, weapon, tier, effects.power(&"poison_depot"))
	if state.budget(&"poison") + depot.budget() <= 0: return
	if effects.power(&"poison_nerve") > 0 and depot.nerve_lock <= 0:
		depot.nerve_time = RULES.nerve_duration
		depot.nerve_lock = RULES.nerve_target_lock
		effects.enchantment_support.emit(&"poison_nerve_applications", 1)
		enemy.queue_redraw()
	if not relic_active: return
	var other := previous.get_ref() as Enemy if previous != null else null
	# Only a real hit may advance the switch. No global target search, kill or
	# secondary hit is required; consumed poison is removed before dealing it.
	if is_instance_valid(other) and other != enemy and other.is_targetable() and not (other.data.is_boss and other.boss_phase_timer > 0) and other.global_position.distance_squared_to(enemy.global_position) <= RULES.switch_radius * RULES.switch_radius:
		var available := other.affix_effects.budget(&"poison") + other.affix_effects.depot.budget()
		if available > 0 and effects.ready_proc(&"poison_switch", RULES.switch_interval):
			var requested := minf(available * RULES.switch_fraction, RULES.switch_budget_cap)
			var spent := other.affix_effects.consume_poison(requested)
			var additions: Array[Dictionary] = [{"id": "poison", "damage": spent, "dot_tick": true, "proc_id": "poison_switch"}]
			other.take_damage(0, null, false, &"", additions)
			effects.enchantment_support.emit(&"poison_switches", 1)
			effects.enchantment_support.emit(&"poison_budget_advanced", spent)
			effects.line(enemy.global_position, other.global_position, WeaponAffixes.by_id(&"poison").color)
	previous = weakref(enemy)
	window = RULES.switch_window

func apply_depot(effects: ItemEffectContext, enemy: Enemy, weapon: WeaponData, tier: int, strength: float) -> bool:
	if strength <= 0 or not enemy.is_targetable() or enemy.data.is_boss and enemy.boss_phase_timer > 0: return false
	_prune()
	var state := enemy.affix_effects
	var depot := state.depot
	if depot.target_lock > 0 or not depot.ticks.is_empty() or depots.size() >= RULES.depot_targets: return false
	var root_hit := weapon.raw_damage_with_stats(tier, effects.player.stats) / maxi(weapon.hands, 1)
	var base := effects.player.stats.scale_damage(maxf(RULES.depot_damage, root_hit * RULES.depot_weapon_factor) * strength)
	var resisted := base * (1.0 - enemy.data.affix_resistance(&"poison"))
	var amount := resisted + minf(state.budget(&"poison") * RULES.poison_budget_bonus, resisted)
	if amount <= 0 or not effects.ready_proc(&"poison_depot", RULES.depot_interval): return false
	depot.open(amount, weapon.range_at_tier(tier))
	depots.append(weakref(enemy))
	effects.enchantment_support.emit(&"poison_depots", 1)
	enemy.queue_redraw()
	return true

func on_enemy_died(effects: ItemEffectContext, enemy: Enemy) -> void:
	var depot := enemy.affix_effects.depot
	if depot.ticking and enemy.global_position.distance_to(effects.player.global_position) > depot.origin_range + enemy.data.radius:
		effects.enchantment_support.emit(&"poison_depot_kills_outside_range", 1)

func save_data(indices: Dictionary) -> Dictionary:
	_prune()
	var active: Array[int] = []
	for reference in depots:
		var enemy := reference.get_ref() as Enemy
		if indices.has(enemy.get_instance_id()): active.append(indices[enemy.get_instance_id()])
	var last := previous.get_ref() as Enemy if previous != null else null
	return {"depots": active, "previous": indices.get(last.get_instance_id(), -1) if is_instance_valid(last) else -1, "window": window}

func restore(saved: Dictionary, enemies: Array[Node]) -> void:
	clear()
	for value in saved.get("depots", []):
		var index := int(value)
		if index >= 0 and index < enemies.size() and depots.size() < RULES.depot_targets:
			var enemy := enemies[index] as Enemy
			if not enemy.affix_effects.depot.ticks.is_empty() and not depots.any(func(ref: WeakRef) -> bool: return ref.get_ref() == enemy):
				depots.append(weakref(enemy))
	var index := int(saved.get("previous", -1))
	window = clampf(float(saved.get("window", 0)), 0, RULES.switch_window)
	if index >= 0 and index < enemies.size() and window > 0: previous = weakref(enemies[index])
