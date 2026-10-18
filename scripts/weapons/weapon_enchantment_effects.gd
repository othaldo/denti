class_name WeaponEnchantmentEffects
extends RefCounted

# All follow-up hits omit a weapon and cannot enter the weapon hit pipeline.
# Cooldowns are shared per player, persisted by ItemInventory, and set before damage.
static func packets(effects: ItemEffectContext, enemy: Enemy, weapon: WeaponData, affixes: Array[Dictionary], factor: float) -> Array[Dictionary]:
	var result := WeaponAffixes.packets(affixes, weapon, effects.player.stats, factor)
	for packet in result:
		if packet.id == "bleed":
			packet["duration"] = WeaponAffixes.by_id(&"bleed").dot_duration + effects.power(&"bleed_clock")
		if packet.id == "electric" and enemy.wet_time > 0:
			packet.damage *= 1.0 + minf(effects.power(&"conductive_wet"), 1.0)
	return result


static func after_hit(effects: ItemEffectContext, enemy: Enemy, weapon: WeaponData, affixes: Array[Dictionary], critical: bool, dealt: float, factor: float, was_chilled: bool) -> void:
	if dealt <= 0:
		return
	if affixes.is_empty() and not critical:
		return
	var wet := WeaponAffixes.find(affixes, &"wet")
	if wet >= 0:
		enemy.apply_wet(WeaponAffixes.utility_value(affixes[wet]) + (0.5 if effects.power(&"conductive_wet") > 0 else 0))
		effects.enchantment_support.emit(&"wet_hits", 1.0)
		if effects.power(&"water_puddle") > 0:
			effects.create_puddle(enemy.global_position)
	var bleed := WeaponAffixes.find(affixes, &"bleed")
	if bleed >= 0 and enemy.health > 0 and weapon.bleed_dps <= 0 and effects.power(&"bleed") > 0:
		# The flat item DPS uses the same bounded stacks as native cut bleeding.
		enemy.apply_bleed(effects.player.stats.scale_damage(effects.power(&"bleed")),
			WeaponAffixes.by_id(&"bleed").dot_duration + effects.power(&"bleed_clock"), 3 + roundi(effects.power(&"bleed_clock")))
	var electric := WeaponAffixes.find(affixes, &"electric")
	if electric >= 0:
		_chain(effects, enemy, WeaponAffixes.effect_damage(float(affixes[electric].damage), &"electric", weapon, effects.player.stats) * factor)
	if critical and was_chilled and enemy.affix_effects.ice_power > 0:
		var ice := WeaponAffixes.by_id(&"ice")
		if effects.ready_proc(&"enchantment_ice", ice.proc_cooldown):
			_area(effects, enemy, enemy.affix_effects.ice_power * ice.proc_factor, ice, &"affix_ice_shatter", false)
	if critical:
		_holy(effects, enemy, weapon, affixes, factor)
	var leech := WeaponAffixes.find(affixes, &"leech")
	if leech >= 0 and effects.player.stats.health > 0 and effects.player.stats.health < effects.player.stats.max_health:
		var definition := WeaponAffixes.by_id(&"leech")
		if effects.ready_proc(&"enchantment_leech", definition.proc_cooldown):
			var healed := effects.player.stats.heal(minf(WeaponAffixes.utility_value(affixes[leech]), dealt * definition.proc_factor))
			if healed > 0:
				effects.enchantment_support.emit(&"leech_healing", healed)
				effects.announce("+%s" % DentiAttributes.number(healed), effects.player.global_position, definition.color)


static func _chain(effects: ItemEffectContext, source: Enemy, power: float) -> void:
	if float(effects.cooldowns.get("enchantment_electric", 0)) > 0:
		return
	var data := WeaponAffixes.by_id(&"electric")
	var wet := source.wet_time > 0
	var chain_power := effects.power(&"chain")
	var targets := mini(data.proc_targets + int(wet) + int(chain_power > 0), data.proc_target_cap)
	var radius := data.proc_radius + (85.0 if wet else 0.0)
	var candidates := _nearby(effects, source.global_position, radius, [source])
	if candidates.is_empty() or not effects.ready_proc(&"enchantment_electric", data.proc_cooldown):
		return
	var visited: Array[Enemy] = [source]
	var previous := source
	for index in targets:
		if candidates.is_empty():
			break
		var next := candidates[0]
		visited.append(next)
		var from := previous.global_position
		_damage(next, power * (data.proc_factor + minf(chain_power, 0.6)), &"electric", &"affix_electric_chain")
		effects.line(from, next.global_position, data.color)
		previous = next
		candidates = _nearby(effects, next.global_position, radius, visited)


static func _holy(effects: ItemEffectContext, enemy: Enemy, weapon: WeaponData, affixes: Array[Dictionary], factor: float) -> void:
	var index := WeaponAffixes.find(affixes, &"holy")
	var state := enemy.affix_effects
	var data := WeaponAffixes.by_id(&"holy")
	if index >= 0:
		state.holy_power = maxf(state.holy_power, WeaponAffixes.effect_damage(float(affixes[index].damage), &"holy", weapon, effects.player.stats) * factor)
	elif state.holy_time <= 0:
		return
	state.holy_time = data.mark_duration
	state.holy_marks = mini(state.holy_marks + 1, data.mark_threshold)
	enemy.queue_redraw()
	if state.holy_marks < data.mark_threshold or not effects.ready_proc(&"enchantment_holy", data.proc_cooldown):
		return
	state.holy_marks = 0
	_area(effects, enemy, state.holy_power * data.proc_factor, data, &"affix_holy", true)


static func on_enemy_died(effects: ItemEffectContext, enemy: Enemy) -> void:
	var state := enemy.affix_effects
	var data := WeaponAffixes.by_id(&"fire")
	if state.fire_budget <= 0 or not state.fire_can_spread:
		return
	if float(effects.cooldowns.get("enchantment_fire", 0)) > 0:
		return
	var candidates := _nearby(effects, enemy.global_position, data.proc_radius, [enemy])
	if candidates.is_empty() or not effects.ready_proc(&"enchantment_fire", data.proc_cooldown):
		return
	# Share a bounded single-hit budget, never the sum of all pending DoTs.
	for other in candidates.slice(0, data.proc_targets):
		var additions: Array[Dictionary] = [{"id": "fire", "damage": state.fire_budget * data.proc_factor, "can_spread": false}]
		other.take_damage(0, null, false, &"", additions)
		effects.line(enemy.global_position, other.global_position, data.color)
	effects.enchantment_support.emit(&"fire_spreads", 1.0)


static func _area(effects: ItemEffectContext, source: Enemy, amount: float, data: WeaponAffixData, proc_id: StringName, include_source: bool) -> void:
	var excluded: Array[Enemy] = []
	if not include_source:
		excluded.append(source)
	var candidates := _nearby(effects, source.global_position, data.proc_radius, excluded)
	for other in candidates.slice(0, data.proc_targets):
		_damage(other, amount, data.id, proc_id)
	effects.ring(source.global_position, data.proc_radius, data.color)


static func _damage(enemy: Enemy, amount: float, kind: StringName, proc_id: StringName) -> void:
	var additions: Array[Dictionary] = [{"id": str(kind), "damage": amount, "proc_id": str(proc_id)}]
	enemy.take_damage(0, null, false, &"", additions)


static func _nearby(effects: ItemEffectContext, at: Vector2, radius: float, excluded: Array[Enemy]) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for other in effects.player.nearby_enemies(at, radius, false):
		if other.health > 0 and not excluded.has(other) and at.distance_squared_to(other.global_position) <= radius * radius:
			result.append(other)
	result.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		var da := at.distance_squared_to(a.global_position)
		var db := at.distance_squared_to(b.global_position)
		return a.spatial_order < b.spatial_order if is_equal_approx(da, db) else da < db)
	return result
