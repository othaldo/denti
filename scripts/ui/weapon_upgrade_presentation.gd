class_name WeaponUpgradePresentation
extends RefCounted


static func equipment(state: WeaponUpgradeState, loadout: WeaponLoadout, stats: PlayerStats, items: ItemInventory) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for weapon in loadout.equipped():
		var values := state.preview(weapon)
		var preview_data := WeaponRolls.with_affixes(weapon.data, values)
		var effects: Array[Dictionary] = []
		var options: Array[Dictionary] = []
		for entry in values:
			var id := StringName(entry.id)
			var next := WeaponUpgrades.next_entry(entry, id, weapon.data, weapon.tier)
			var before := number(AffixPresentation.display_value(float(entry.damage), id, weapon.data, stats, items))
			var after := number(AffixPresentation.display_value(float(next.damage), id, weapon.data, stats, items)) if not next.is_empty() else ""
			var unit := unit_text(id, items)
			effects.append({"id": id, "level": WeaponUpgrades.level(entry), "value": before + " " + unit,
				"preview": (before + " -> " + after if not after.is_empty() else before) + " " + unit,
				"unit": unit, "details": AffixPresentation.effect_description(id) + "\n\n" + before + " " + unit})
		for definition in WeaponAffixes.ALL:
			if not definition.selectable: continue
			var entry := WeaponUpgrades.next_entry({}, definition.id, weapon.data, weapon.tier)
			var existing := WeaponAffixes.find(values, definition.id) >= 0
			options.append({"id": definition.id, "value": number(AffixPresentation.display_value(float(entry.damage), definition.id, weapon.data, stats, items)) + " " + unit_text(definition.id, items),
				"description": AffixPresentation.effect_description(definition.id), "existing": existing,
				"blocked": "Bereits auf dieser Waffe" if existing else WeaponUpgrades.blocked_reason(values, definition.id, weapon.tier)})
		var roots_info := "%s · %d/%d Plätze\n\nMk I: 1 Platz\nMk II: 2 Plätze\nMk III: 3 Plätze\nMk IV: 4 Plätze\n\nAktivieren startet bei 1/10. Jeder Schritt kostet %d Punkt(e) nach den Wurzelkosten. Eine Kapsel gibt 2 Punkte.\nSchadenseffekte teilen ihr Wurzelbudget auf die Basis-Angriffspause und die anfänglichen Projektile auf. Kontroll- und Heileffekte behalten ihre eigenen Obergrenzen." % [weapon.data.roots_text(), values.size(), WeaponUpgrades.slots(weapon.tier), WeaponUpgrades.cost(weapon.data)]
		result.append({"id": weapon.data.id, "uid": weapon.instance_uid, "data": preview_data, "tier": weapon.tier,
			"name": WeaponPresentation.name_for(weapon.data, values), "meta": WeaponPresentation.tier_text(weapon.data, weapon.tier) + " · " + weapon.data.roots_text(),
			"cost": WeaponUpgrades.cost(weapon.data), "slot_count": WeaponUpgrades.slots(weapon.tier), "root_info": roots_info + "\n\nEine Waffe trägt höchstens ein Element. Blutung und Wasser zählen als Elemente. Weitere Plätze können Verstärkungen tragen.", "element": WeaponAffixes.element(values), "effects": effects, "options": options})
	return result


static func unit_text(id: StringName, items: ItemInventory) -> String:
	var definition := WeaponAffixes.by_id(id)
	if definition.dot_duration > 0: return "Schaden / %.0f s" % AffixPresentation.dot_duration(id, items)
	if definition.stat_key != &"": return AffixPresentation.damage_unit(id, items)
	match definition.effect_kind:
		"wet": return "s Nässe"
		"leech": return "HP / Impuls"
		"holy": return "Schaden / Lichtstoß"
	return "Schaden / Treffer"


static func number(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".").replace(".", ",")
