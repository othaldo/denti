class_name WeaponPresentation
extends RefCounted

const EVOLUTION_COLOR := Color("ff3038")


static func weapon_name(weapon: WeaponInstance) -> String:
	if weapon.affixes.is_empty():
		return weapon.data.display_name
	# Compare development, not incomparable damage and percentage values.
	# Equal effects keep their slot order, so names are stable across save/resume.
	var strongest: Dictionary = weapon.affixes[0]
	for affix in weapon.affixes:
		if WeaponAffixes.nominal(affix) > WeaponAffixes.nominal(strongest):
			strongest = affix
	var suffix := WeaponAffixes.by_id(StringName(strongest.id)).name_suffix
	return weapon.data.display_name + (" " + suffix if not suffix.is_empty() else "")


static func enchantment_list(weapon: WeaponInstance) -> String:
	var parts: PackedStringArray = []
	for affix in weapon.affixes:
		parts.append("%s %s" % [WeaponAffixes.by_id(StringName(affix.id)).display_name,
			["I", "II", "III"][clampi(int(affix.get("rank", 1)), 1, WeaponAffixes.MAX_RANK) - 1] + ("+" if float(affix.get("bonus", 0)) > 0 else "")])
	return " · ".join(parts) if not parts.is_empty() else "Noch keine Verzauberung"


static func enchantment_hint(kind: StringName, weapon: WeaponInstance, items: ItemInventory = null, replace: int = -1) -> String:
	var parts: PackedStringArray = []
	var selected_affixes := weapon.affixes
	if replace >= 0 and replace < selected_affixes.size() and WeaponAffixes.find(selected_affixes, kind) < 0:
		selected_affixes = selected_affixes.duplicate()
		selected_affixes.remove_at(replace)
	var wet_build := weapon.data.wet_duration > 0 or WeaponAffixes.find(selected_affixes, &"wet") >= 0
	var electric_build := WeaponAffixes.find(selected_affixes, &"electric") >= 0
	if items != null:
		for other in items.player.loadout.equipped():
			if other == weapon:
				continue
			wet_build = wet_build or other.data.wet_duration > 0 or WeaponAffixes.find(other.affixes, &"wet") >= 0
			electric_build = electric_build or WeaponAffixes.find(other.affixes, &"electric") >= 0
	match kind:
		&"fire":
			if weapon.data.attack_mode in [&"area", &"sweep", &"cone"] or weapon.data.splash_radius > 0:
				parts.append("Flächenwaffe")
		&"ice", &"holy":
			if items != null and (items.player.stats.crit_chance + weapon.data.crit_bonus >= 0.10 or items._power(&"crit_burst") > 0 or items._power(&"crit_beam") > 0):
				parts.append("Krit-Build")
			if kind == &"holy" and WeaponAffixes.find(selected_affixes, &"ice") >= 0:
				parts.append("Eis")
		&"poison":
			if weapon.data.interval <= 0.5 or WeaponAffixes.find(selected_affixes, &"tempo") >= 0:
				parts.append("schnelle Treffer")
		&"bleed":
			if weapon.data.bleed_dps > 0:
				parts.append("Schnitt-Blutung")
			if items != null and (items._power(&"bleed") > 0 or items._power(&"bleed_clock") > 0 or items._power(&"bleed_bonus") > 0 or items._power(&"bleed_spread") > 0):
				parts.append("Blutungsitems")
		&"electric":
			if wet_build:
				parts.append("Nässe im Build")
			if items != null and items._power(&"chain") > 0:
				parts.append("Kettenitems")
		&"wet":
			if electric_build:
				parts.append("Elektro im Build")
			if items != null and (items._power(&"conductive_wet") > 0 or items._power(&"water_puddle") > 0):
				parts.append("Wasseritems")
		&"leech":
			if items != null and items._power(&"overheal_shield") > 0:
				parts.append("Speichelkelch")
	return "Passt zu: " + ", ".join(parts) if not parts.is_empty() else ""


# Evolutions keep tier IV internally for combat values and legacy saves.
static func tier_text(data: WeaponData, tier: int) -> String:
	var level := tier + int(data.chest_upgrades.get("mk", 0)) if data != null else tier
	var roman := ""
	for entry in [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while level >= int(entry[0]):
			roman += str(entry[1])
			level -= int(entry[0])
	return "Mk " + roman


static func tier_color(data: WeaponData, tier: int) -> Color:
	return DentiRarity.color_for(mini(tier + int(data.chest_upgrades.get("mk", 0)), 5)) if data != null else DentiRarity.color_for(tier)


static func special_color(data: WeaponData) -> Color:
	return tier_color(data, 4) if data != null and (data.evolution_kind != &"" or int(data.chest_upgrades.get("mk", 0)) > 0) else Color.TRANSPARENT


static func role(data: WeaponData) -> String:
	if not data.role.is_empty():
		return data.role
	return {"projectile": "Treffer aus der Distanz", "melee": "Gezielter Nahkampf", "area": "Rundum gegen Gruppen", "beam": "Präziser Soforttreffer"}.get(str(data.attack_mode), "Automatischer Angriff")


static func values(data: WeaponData, tier: int, player: Player) -> Dictionary:
	var damage := data.damage_at_tier(tier)
	var pause := data.interval_at_tier(tier)
	var crit := 0.05
	if player != null:
		damage = data.damage_with_stats(tier, player.stats, player.items.base_weapon_damage_bonus())
		pause = data.cooldown_at_tier(tier, player.stats.attack_interval, player.items.attack_interval_factor())
		crit = player.stats.crit_chance
	return {"damage": damage, "pause": pause, "range": data.range_at_tier(tier),
		"crit": clampf(crit + data.crit_bonus, 0.0, 1.0), "multiplier": data.crit_multiplier}


static func quick_text(data: WeaponData, tier: int, player: Player) -> String:
	var current := values(data, tier, player)
	return "%s\n%.1f Treffer · %.2f s · %d Reichweite" % [role(data), current.damage, current.pause, roundi(current.range)]


static func card_effect(data: WeaponData, tier: int) -> String:
	var hints: PackedStringArray = []
	if data.boss_bonus_tiers.size() > 0:
		hints.append("+%d %% Schaden gegen Bosse." % roundi(data.boss_bonus_tiers[clampi(tier, 1, 4) - 1] * 100))
	if data.crit_cycle > 0:
		hints.append("Jeder %d. Treffer auf dasselbe Ziel ist kritisch." % data.crit_cycle)
	if data.attack_mode in [&"beam_line", &"thrust"]:
		hints.append("Trifft alle Gegner entlang der Linie.")
	if data.wet_duration > 0:
		hints.append("Nass %.1f s: %s." % [data.wet_duration, WeaponData.WET_STATUS.short_text()])
	if data.bleed_dps > 0:
		hints.append("Blutung: %.1f Schaden/s für %.1f s." % [data.bleed_dps, data.bleed_duration])
	if data.enamel_exposure > 0:
		hints.append("+%d %% Schmelzbruch für %.1f s." % [roundi(data.enamel_exposure * 100), data.exposure_duration])
	if data.focus_cap > 0:
		hints.append("Ziel-Fokus bis +%d %% Schaden." % roundi(data.focus_cap * 100))
	if data.splash_at_tier(tier) > 0:
		hints.append("Explodiert im Radius %d." % roundi(data.splash_at_tier(tier)))
	if data.projectile_count_at_tier(tier) > 1:
		hints.append("%d Geschosse pro Angriff." % data.projectile_count_at_tier(tier))
	return "\n".join(hints.slice(0, 2)) if not hints.is_empty() else role(data) + "."


static func comparison(data: WeaponData, tier: int, other: WeaponData, other_tier: int, player: Player) -> String:
	var before := values(other, other_tier, player)
	var after := values(data, tier, player)
	return "Treffer %.1f -> %.1f · Pause %.2f -> %.2f s\nReichweite %d -> %d · Wurzeln %d -> %d" % [
		before.damage, after.damage, before.pause, after.pause,
		roundi(before.range), roundi(after.range), other.hands, data.hands]


static func synergy(data: WeaponData, equipment: Array[Dictionary], player: Player) -> String:
	var hints: PackedStringArray = []
	for entry in equipment:
		var other: WeaponData = entry.get("data")
		if other == null or other == data:
			continue
		if data.damage_type == "Schmelz" and other.enamel_exposure > 0.0:
			hints.append("%s: Bonus für Schmelzbruch-Treffer." % other.display_name)
			break
		if data.enamel_exposure > 0.0 and other.damage_type == "Schmelz":
			hints.append("Verstärkt %s." % other.display_name)
			break
		if data.damage_type == "Licht" and other.wet_duration > 0.0 and player != null and player.items.count(&"conductive_varnish") > 0:
			hints.append("%s + Leitlack: Lichtbonus auf nasse Ziele." % other.display_name)
			break
	if player != null:
		if data.damage_type == "Wasser" and player.items.count(&"conductive_varnish") > 0:
			hints.append("Leitlack: Bonus auf nasse Ziele.")
		if data.damage_type == "Schnitt" and player.items.count(&"floss_reel") > 0:
			hints.append("Zahnseide-Spule: stärkere Blutung.")
		if (data.crit_bonus > 0.0 or data.crit_cycle > 0) and player.items.count(&"polish_paste") > 0:
			hints.append("Polierpaste: Blitze bei Crit.")
	return "\n".join(hints)
