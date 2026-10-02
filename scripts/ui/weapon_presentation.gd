class_name WeaponPresentation
extends RefCounted


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
		hints.append("Macht Gegner %.1f s nass." % data.wet_duration)
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
