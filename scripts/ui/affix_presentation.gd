class_name AffixPresentation
extends RefCounted


static func progress_text(value: Dictionary) -> String:
	var text := "%s %s%s" % [DentiRarity.name_for(value.rarity), ["I", "II", "III"][clampi(int(value.get("rank", 1)), 1, WeaponAffixes.MAX_RANK) - 1], "+" if float(value.get("bonus", 0)) > 0 else ""]
	return text + (" · %.1f %%" % (float(value.get("progress", 0)) * 100.0) if float(value.get("progress", 0)) > 0 else "")


static func display_value(value: float, kind: StringName, weapon: WeaponData, stats: PlayerStats = null, items: ItemInventory = null) -> float:
	var data := WeaponAffixes.by_id(kind)
	if data.effect_kind in ["wet", "leech"]:
		return WeaponAffixes.utility_value({"id": str(kind), "damage": value}) + (0.5 if kind == &"wet" and items != null and items.power(&"conductive_wet") > 0 else 0.0)
	if data.stat_key != &"":
		return value
	return WeaponAffixes.effect_damage(value, kind, weapon, stats) * (data.proc_factor if data.effect_kind == "holy" else 1.0)


static func value_text(value: float, kind: StringName, weapon: WeaponData, stats: PlayerStats = null, items: ItemInventory = null) -> String:
	return ("%.2f" if WeaponAffixes.by_id(kind).effect_kind in ["wet", "leech"] else "%.1f") % display_value(value, kind, weapon, stats, items)


static func summary(weapon: WeaponInstance, stats: PlayerStats = null, items: ItemInventory = null) -> String:
	var lines: PackedStringArray = []
	for affix in weapon.affixes:
		var data := WeaponAffixes.by_id(StringName(affix.id))
		lines.append("%s +%s %s · %s" % [data.display_name, value_text(float(affix.damage), data.id, weapon.data, stats, items), damage_unit(data.id, items), progress_text(affix)])
	return "Verzauberungen · %d/%d Plätze" % [weapon.affixes.size(), weapon.affix_slots] + ("\n" + "\n".join(lines) if not lines.is_empty() else "")


static func dot_duration(kind: StringName, items: ItemInventory = null) -> float:
	return minf(WeaponAffixes.by_id(kind).dot_duration + (items.power(&"bleed_clock") if items != null and kind == &"bleed" else 0.0), EnemyAffixEffects.MAX_DOT_DURATION)


static func damage_unit(kind: StringName, items: ItemInventory = null) -> String:
	var data := WeaponAffixes.by_id(kind)
	if data.effect_kind == "wet":
		return "s Nässe"
	if data.effect_kind == "leech":
		return "HP / Heilimpuls"
	if data.effect_kind == "holy":
		return "Schaden / Lichtstoß"
	if data.stat_key != &"":
		return "% " + data.display_name
	return "Gesamtschaden über %.0f s" % dot_duration(kind, items) if data.dot_duration > 0 else "Schaden/Treffer"


static func effect_description(kind: StringName) -> String:
	var data := WeaponAffixes.by_id(kind)
	if not data.description.is_empty():
		return data.description
	if data.stat_key == &"range":
		return "Diese Waffe trifft weiter entfernte Gegner."
	if data.stat_key == &"tempo":
		return "Diese Waffe greift schneller an."
	if data.dot_duration > 0:
		return "Jeder Treffer: %s über %.0f s." % [data.display_name, data.dot_duration]
	if data.slow_fraction > 0:
		return "Treffer verursachen Eisschaden und verlangsamen."
	return "Jeder Treffer verursacht zusätzlichen Elektroschaden."


static func comparison(weapon: WeaponInstance, option: Dictionary, stats: PlayerStats, replace: int, compact: bool = false, items: ItemInventory = null) -> String:
	if option.id == "slot":
		if weapon.affix_slots >= WeaponAffixes.MAX_SLOTS:
			return "Alle 4 Plätze sind bereits offen.\nWähle eine andere Waffe."
		return "Plätze %d -> %d\nFür eine weitere Verzauberung." % [weapon.affix_slots, mini(weapon.affix_slots + 1, WeaponAffixes.MAX_SLOTS)]
	if option.id == "mk":
		if weapon.tier < 4:
			return "Benötigt Mk IV.\nVerbessere diese Waffe zuerst im Shop."
		var upgrades := weapon.data.chest_upgrades.duplicate(true)
		upgrades["mk"] = int(upgrades.get("mk", 0)) + 1
		var next := WeaponRolls.resolve(weapon.data, weapon.data.rolls, upgrades)
		return "%s -> %s\n+10 %% Basisschaden\n+3 %% Tempo und Reichweite\nBenötigt mindestens Mk IV" % [WeaponPresentation.tier_text(weapon.data, weapon.tier), WeaponPresentation.tier_text(next, weapon.tier)]
	var data := WeaponAffixes.by_id(StringName(option.id))
	var index := WeaponAffixes.find(weapon.affixes, data.id)
	var before := float(weapon.affixes[index].damage) if index >= 0 else 0.0
	var after := float(WeaponAffixes.upgraded(weapon.affixes[index], option).damage) if index >= 0 else WeaponAffixes.rank_damage(data.id, int(option.rarity))
	var result := ("Fundstärke: %.1f" if data.effect_kind != "damage" else "Fundwert: +%.1f " + ("%% " + data.display_name if data.stat_key != &"" else "Basisschaden")) % WeaponAffixes.rank_damage(data.id, int(option.rarity))
	var value_before := value_text(before, data.id, weapon.data, stats, items)
	var value_after := value_text(after, data.id, weapon.data, stats, items)
	if compact:
		var unit := "Schaden / %.0f s" % dot_duration(data.id, items) if data.dot_duration > 0 else damage_unit(data.id, items)
		result = effect_description(data.id) + "\n" + ("+%s -> +%s" % [value_before, value_after] if index >= 0 else "+%s" % value_after) + " " + unit
		if index >= 0:
			result += "\n%s -> %s" % [progress_text(weapon.affixes[index]), progress_text(WeaponAffixes.upgraded(weapon.affixes[index], option))]
		elif weapon.affixes.size() >= weapon.affix_slots:
			result += "\nErsetzt: " + (WeaponAffixes.by_id(StringName(weapon.affixes[replace].id)).display_name if replace >= 0 and replace < weapon.affixes.size() else "Bitte Ersatz wählen")
		if data.slow_fraction > 0:
			result += "\nBis zu %.0f %% langsamer für %.1f s" % [data.slow_fraction * 100, data.slow_duration]
		return result
	if index >= 0:
		result += "\nAuf dieser Waffe: +%s -> +%s %s" % [value_before, value_after, damage_unit(data.id, items)]
	else:
		result += "\nAuf dieser Waffe: +%s %s" % [value_after, damage_unit(data.id, items)]
	if index >= 0:
		result += "\n%s -> %s" % [progress_text(weapon.affixes[index]), progress_text(WeaponAffixes.upgraded(weapon.affixes[index], option))]
		result += "\nFortschritt: +%.1f %% · danach %.1f %%" % [WeaponAffixes.progress_weight(weapon.affixes[index], option) * 100, float(WeaponAffixes.upgraded(weapon.affixes[index], option).get("progress", 0)) * 100]
	elif weapon.affixes.size() >= weapon.affix_slots:
		result += "\nErsetzt: " + (WeaponAffixes.by_id(StringName(weapon.affixes[replace].id)).display_name if replace >= 0 and replace < weapon.affixes.size() else "Bitte Effekt wählen")
	else:
		result += "\nBelegt einen freien Platz für Verzauberungen"
	if data.slow_fraction > 0:
		result += "\nVerlangsamt für %.1f s" % data.slow_duration
	return result + "\n" + effect_description(data.id) + "\n" + mechanics_text(data.id)


static func mechanics_text(kind: StringName) -> String:
	var data := WeaponAffixes.by_id(kind)
	match kind:
		&"fire":
			return "Glut: %.0f %% eines Trefferbudgets an bis zu %d Ziele im Radius %.0f. Intervall %.2f s; übertragene Glut verbreitet sich nicht erneut." % [data.proc_factor * 100, data.proc_targets, data.proc_radius, data.proc_cooldown]
		&"ice":
			return "Krits auf gekühlte Ziele: Eissplitter mit %.0f %% Eisschaden an bis zu %d andere Ziele. Gemeinsames Intervall %.1f s." % [data.proc_factor * 100, data.proc_targets, data.proc_cooldown]
		&"poison":
			return "Bis zu %d Giftstufen, höchstens eine je %.1f s. Jede weitere Stufe: +%.0f %% Schaden neuer Giftanwendungen. Verfällt ohne Gift nach %.0f s." % [data.buildup_limit, data.buildup_interval, data.buildup_bonus * 100, data.dot_duration]
		&"bleed":
			return "Zahnseide ergänzt begrenzte Blutungsstapel. Sanduhr verlängert den Effekt; Skalpellwachs, Ansteckende Zahnseide und Blutmond erkennen diese Blutung."
		&"electric":
			return "Ein Sprung, +1 bei nassem Startziel, +1 mit Kettenitem; maximal %d. Sprungschaden %.0f %% des Elektrotreffers, Kettenitems verstärken ihn. Intervall %.2f s. Leitlack verstärkt Elektro auf nassen Zielen." % [data.proc_target_cap, data.proc_factor * 100, data.proc_cooldown]
		&"wet":
			return "Kein Zusatzschaden. Nassdauer maximal %.1f s; aktiviert Elektro, Leitlack und Spülpfützen. Nass verlangsamt nach den normalen Gegnerregeln." % data.utility_cap
		&"holy":
			return "%d Krits; Markierungen halten jeweils %.0f s. Weitere Waffen können markierte Ziele auslösen. Lichtstoß trifft bis zu %d Ziele, Intervall %.1f s." % [data.mark_threshold, data.mark_duration, data.proc_targets, data.proc_cooldown]
		&"leech":
			return "Kein Zusatzschaden. Heilt bis zu %.0f %% des tatsächlich verursachten Trefferschadens, höchstens %.1f HP je Impuls. Gemeinsames Intervall %.2f s für alle Waffen; DoTs und Folgeeffekte heilen nicht." % [data.proc_factor * 100, data.utility_cap, data.proc_cooldown]
	return ""
