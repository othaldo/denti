class_name ElementReactions
extends RefCounted

const ALL: Array[ElementReactionData] = [
	preload("res://data/reactions/steam.tres"),
	preload("res://data/reactions/toxic_flare.tres"),
	preload("res://data/reactions/frost.tres"),
]


static func after_hit(effects: ItemEffectContext, source: Enemy, weapon: WeaponData, affixes: Array[Dictionary]) -> void:
	if source.health <= 0:
		return
	for reaction in ALL:
		if float(effects.cooldowns.get(str(reaction.id), 0)) > 0:
			continue
		var triggered := false
		var prepared := true
		for kind in reaction.elements:
			triggered = triggered or WeaponAffixes.find(affixes, kind) >= 0 or (kind == &"wet" and weapon.wet_duration > 0)
			prepared = prepared and _active(source, kind)
		if not triggered or not prepared:
			continue
		# Use one accepted elemental hit, never accumulated DoT installments.
		var power := source.affix_effects.ice_power if reaction.power_element == &"ice" else source.affix_effects.fire_budget
		if power <= 0:
			continue
		var excluded: Array[Enemy] = []
		if not reaction.include_source:
			excluded.append(source)
		var candidates := WeaponEnchantmentEffects.nearby(effects, source.global_position, reaction.radius, excluded)
		if candidates.is_empty() or not effects.ready_proc(reaction.id, reaction.cooldown):
			continue
		var color := WeaponAffixes.by_id(reaction.damage_element).color
		for other in candidates.slice(0, reaction.targets):
			# Instant elemental damage still passes resistance, defense and boss
			# guards. No weapon means no on-hit procs or recursive reactions.
			var additions: Array[Dictionary] = [{"id": str(reaction.damage_element), "damage": power * reaction.damage_factor,
				"instant": true, "proc_id": str(reaction.id)}]
			other.take_damage(0, null, false, &"", additions)
			ElementImpactBatch.emit_from(other, reaction.damage_element, other.global_position, Vector2.UP, 24)
		effects.ring(source.global_position, reaction.radius, color)
		effects.enchantment_support.emit(reaction.id, 1.0)


static func _active(enemy: Enemy, kind: StringName) -> bool:
	match kind:
		&"wet": return enemy.wet_time > 0
		&"ice": return enemy.chill_time > 0
		&"fire": return enemy.affix_effects.fire_budget > 0 and (enemy.affix_effects.fire_time > 0 or enemy.affix_effects.pending.has("fire"))
		&"poison": return enemy.affix_effects.budget(&"poison") + enemy.affix_effects.depot.budget() > 0
	return false


static func hints(kind: StringName, build: Array[StringName]) -> PackedStringArray:
	var result: PackedStringArray = []
	for reaction in ALL:
		if not reaction.elements.has(kind):
			continue
		if reaction.elements.all(func(element: StringName) -> bool: return element == kind or build.has(element)):
			result.append(reaction.display_name)
	return result


static func mechanics_text(kind: StringName) -> String:
	var lines: PackedStringArray = []
	for reaction in ALL:
		if not reaction.elements.has(kind):
			continue
		var names: PackedStringArray = []
		for element in reaction.elements:
			names.append(WeaponAffixes.by_id(element).display_name)
		lines.append("%s + %s: %.0f %% eines %s-Treffers an bis zu %d %sZiele (%.1f s)." % [
			" + ".join(names), reaction.display_name, reaction.damage_factor * 100,
			WeaponAffixes.by_id(reaction.power_element).display_name, reaction.targets,
			"andere " if not reaction.include_source else "", reaction.cooldown])
	return "\n".join(lines)
