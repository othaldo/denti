class_name WeaponUpgradePresentation
extends RefCounted


static func equipment(state: WeaponUpgradeState, loadout: WeaponLoadout, stats: PlayerStats, items: ItemInventory, coins: int = 0, wave: int = 1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for weapon in loadout.equipped():
		var values := state.preview(weapon)
		var preview_data := state.preview_data(weapon)
		var ascension := WeaponAscension.quote(preview_data, wave)
		ascension["next"] = WeaponPresentation.tier_text(WeaponAscension.advance(preview_data), WeaponLoadout.MAX_TIER)
		ascension["blocked"] = state.ascension_blocked(weapon, coins, wave)
		var effects: Array[Dictionary] = []
		var options: Array[Dictionary] = []
		for entry in values:
			var id := StringName(entry.id)
			var next := WeaponUpgrades.next_entry(entry, id, weapon.data, weapon.tier)
			var before := number(AffixPresentation.display_value(float(entry.damage), id, weapon.data, stats, items))
			var after := number(AffixPresentation.display_value(float(next.damage), id, weapon.data, stats, items)) if not next.is_empty() else ""
			var unit := unit_text(id, items, weapon.data)
			var description := AffixPresentation.effect_description(id, weapon.data)
			effects.append({"id": id, "level": WeaponUpgrades.level(entry), "value": before + " " + unit,
				"preview": (before + " → " + after if not after.is_empty() else before) + " " + unit,
				"unit": unit, "details": description + "\n\n" + before + " " + unit})
		for definition in WeaponAffixes.ALL:
			if not definition.selectable: continue
			var entry := WeaponUpgrades.next_entry({}, definition.id, weapon.data, weapon.tier)
			var existing := WeaponAffixes.find(values, definition.id) >= 0
			options.append({"id": definition.id, "value": number(AffixPresentation.display_value(float(entry.damage), definition.id, weapon.data, stats, items)) + " " + unit_text(definition.id, items, weapon.data),
				"description": AffixPresentation.effect_description(definition.id, weapon.data), "existing": existing,
				"blocked": "Bereits auf dieser Waffe" if existing else WeaponUpgrades.blocked_reason(values, definition.id, weapon.tier)})
		var roots_info := "%s · %d/%d Plätze\n\nMk I: 1 Platz\nMk II: 2 Plätze\nMk III: 3 Plätze\nMk IV: 4 Plätze\n\nAktivieren startet bei 1/10. Jeder Schritt kostet %d Punkt(e) nach den Wurzelkosten. Eine Kapsel gibt 2 Punkte.\nSchadenseffekte teilen ihr Wurzelbudget auf die Basis-Angriffspause und die anfänglichen Projektile auf. Kontroll- und Heileffekte behalten ihre eigenen Obergrenzen." % [weapon.data.roots_text(), values.size(), WeaponUpgrades.slots(weapon.tier), WeaponUpgrades.cost(weapon.data)]
		if weapon.data.attack_mode == &"command":
			roots_info = "%s · %d/%d Plätze\n\n%s" % [weapon.data.roots_text(), values.size(), WeaponUpgrades.slots(weapon.tier), retinue_details(preview_data, weapon.tier, items)]
		result.append({"id": weapon.data.id, "uid": weapon.instance_uid, "data": preview_data, "tier": weapon.tier,
			"name": WeaponPresentation.name_for(preview_data, values), "meta": WeaponPresentation.tier_text(preview_data, weapon.tier) + " · " + weapon.data.roots_text(), "ascension": ascension,
			"cost": WeaponUpgrades.cost(weapon.data), "slot_count": WeaponUpgrades.slots(weapon.tier), "root_info": roots_info + "\n\nAb Mk IV ist Aufsteigen mit Punkten und Gold möglich. Die vier Effektplätze bleiben erhalten.\n\nEine Waffe trägt höchstens ein Element. Blutung und Wasser zählen als Elemente. Weitere Plätze können Verstärkungen tragen.", "element": WeaponAffixes.element(values), "effects": effects, "options": options})
	return result


static func retinue_details(data: WeaponData, tier: int, items: ItemInventory) -> String:
	var player := items.player if items != null else null
	var lines: PackedStringArray = []
	for row in WeaponPresentation.retinue_rows(data, player):
		lines.append("%s · %s" % [row.label, row.value])
	lines.append("Befehlsreichweite · %d" % roundi(data.range_at_tier(tier)))
	lines.append("")
	lines.append(WeaponPresentation.retinue_health_text())
	lines.append(WeaponPresentation.BITE_CONTEXT)
	var retinue := player.skill_module(ClassCatalog.NECRODENT_ID) as NecrodentSkills if player != null else null
	if retinue != null and retinue.active() and retinue.retinue_size() > 1:
		var count := retinue.retinue_size()
		lines.append("Bei %d Zähnen zeigt die Vorschau pro Biss %.0f %% der vollen Elementstärke." % [count, NecrodentSkills.enchantment_share(count) * 100.0])
	else:
		lines.append("Deine Zähne tragen das Element bei ihren Bissen auf.")
	lines.append("Jeder Rang kostet einen Punkt. Ab Mk II kommt je Stufe ein Platz dazu, bis maximal vier.")
	return "\n".join(lines)


static func unit_text(id: StringName, items: ItemInventory, weapon: WeaponData = null) -> String:
	var definition := WeaponAffixes.by_id(id)
	if definition.dot_duration > 0: return "Schaden / %.0f s" % AffixPresentation.dot_duration(id, items)
	if definition.stat_key != &"": return AffixPresentation.damage_unit(id, items)
	match definition.effect_kind:
		"wet": return "s Nässe"
		"leech": return "HP / Impuls"
		"holy": return "Schaden / Lichtstoß"
	return "Schaden / Biss" if weapon != null and weapon.attack_mode == &"command" else "Schaden / Treffer"


static func number(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".").replace(".", ",")
