class_name WeaponAffixes
extends RefCounted

const MAX_SLOTS := 4
const SLOT_CHANCE := 0.20
const MAX_RANK := 3
const LEGENDARY_BONUS := 2.0
const MK_CHANCE := 0.025
const CHEST_ID := &"weapon_affix"
const ALL: Array[WeaponAffixData] = [
	preload("res://data/affixes/fire.tres"), preload("res://data/affixes/ice.tres"),
	preload("res://data/affixes/poison.tres"), preload("res://data/affixes/bleed.tres"),
	preload("res://data/affixes/electric.tres"),
	preload("res://data/affixes/range.tres"), preload("res://data/affixes/tempo.tres"),
	preload("res://data/affixes/wet.tres"), preload("res://data/affixes/holy.tres"), preload("res://data/affixes/leech.tres"),
]


static func by_id(id: StringName) -> WeaponAffixData:
	for affix in ALL:
		if affix.id == id:
			return affix
	return null


static func sanitize(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if not value is Dictionary or by_id(StringName(str(value.get("id", "")))) == null:
			continue
		var damage := float(value.get("damage", 0.0))
		if not is_finite(damage) or damage <= 0.0:
			continue
		var entry := {"id": str(value.id), "damage": damage, "rarity": clampi(int(value.get("rarity", 1)), 1, 4), "stacks": maxi(int(value.get("stacks", 1)), 1), "rank": clampi(int(value.get("rank", 1)), 1, MAX_RANK), "bonus": maxf(float(value.get("bonus", 0)), 0), "progress": clampf(float(value.get("progress", 0)), 0, 0.999999)}
		var index := find(result, StringName(entry.id))
		if index >= 0:
			result[index] = merge_entries(result[index], entry)
		elif result.size() < MAX_SLOTS:
			result.append(entry)
	return result


static func find(values: Array[Dictionary], id: StringName) -> int:
	for index in values.size():
		if StringName(values[index].id) == id:
			return index
	return -1


static func rank_damage(id: StringName, rarity: int, rank: int = 1) -> float:
	return by_id(id).damage_steps[(clampi(rarity, 1, 4) - 1) * MAX_RANK + clampi(rank, 1, MAX_RANK) - 1]


static func progress_text(value: Dictionary) -> String:
	var text := "%s %s%s" % [DentiRarity.name_for(value.rarity), ["I", "II", "III"][clampi(int(value.get("rank", 1)), 1, MAX_RANK) - 1], "+" if float(value.get("bonus", 0)) > 0 else ""]
	return text + (" · %.1f %%" % (float(value.get("progress", 0)) * 100.0) if float(value.get("progress", 0)) > 0 else "")


static func progress_weight(current: Dictionary, option: Dictionary) -> float:
	return pow(0.5, maxi(int(current.rarity) - int(option.rarity), 0))


static func nominal(value: Dictionary) -> float:
	var rarity := int(value.rarity)
	var rank := int(value.get("rank", 1))
	var base := rank_damage(StringName(value.id), rarity, rank) + float(value.get("bonus", 0))
	var next := rank_damage(StringName(value.id), rarity, rank + 1) if rank < MAX_RANK else (rank_damage(StringName(value.id), rarity + 1) if rarity < 4 else base + LEGENDARY_BONUS)
	return lerpf(base, next, float(value.get("progress", 0)))


static func upgraded(current: Dictionary, option: Dictionary) -> Dictionary:
	var result := current.duplicate(true)
	var before := nominal(current)
	if int(option.rarity) > int(current.rarity):
		result.rarity = int(option.rarity)
		result["rank"] = 1
		result["progress"] = 0.0
	else:
		result["progress"] = float(result.get("progress", 0)) + progress_weight(current, option) * float(option.get("weight", 1))
		while float(result.progress) >= 1.0:
			result.progress -= 1.0
			if int(result.get("rank", 1)) < MAX_RANK:
				result["rank"] = int(result.get("rank", 1)) + 1
			elif int(result.rarity) < 4:
				result.rarity += 1
				result["rank"] = 1
			else:
				result["bonus"] = float(result.get("bonus", 0)) + LEGENDARY_BONUS
	result.stacks = int(result.get("stacks", 1)) + 1
	result.damage = float(current.damage) + maxf(nominal(result) - before, 0.0)
	return result


static func merge_entries(first: Dictionary, second: Dictionary) -> Dictionary:
	var primary := first if int(first.rarity) >= int(second.rarity) else second
	var other := second if primary == first else first
	var result := primary.duplicate(true)
	for contribution in int(other.get("rank", 1)):
		result = upgraded(result, other)
	if float(other.get("progress", 0)) > 0:
		var partial := other.duplicate(true)
		partial["weight"] = float(other.progress)
		result = upgraded(result, partial)
	result["bonus"] = float(result.get("bonus", 0)) + float(other.get("bonus", 0))
	result.damage += float(other.get("bonus", 0))
	result.damage = maxf(float(result.damage), maxf(float(first.damage), float(second.damage)))
	result.stacks = int(first.get("stacks", 1)) + int(second.get("stacks", 1))
	return result


static func roll_chest(wave: int, luck: float, loadout: WeaponLoadout, golden: bool = false, rng: RandomNumberGenerator = null) -> Dictionary:
	var random := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		random.randomize()
	var pool: Array[StringName] = []
	for affix in ALL:
		pool.append(affix.id)
	var options: Array[Dictionary] = []
	# Reserve one useful matching effect before choosing the other two types.
	var matches: Array[Dictionary] = []
	for weapon in loadout.equipped():
		for affix in weapon.affixes:
			matches.append(affix)
	var matching: Dictionary = matches[random.randi_range(0, matches.size() - 1)] if not matches.is_empty() else {}
	for index in 3:
		var tier := maxi(DentiRarity.roll(wave + (4 if golden else 0), luck, random), 2 if golden else 1)
		var kind := StringName(matching.id) if index == 0 and not matching.is_empty() else pool[random.randi_range(0, pool.size() - 1)]
		if index == 0 and not matching.is_empty():
			tier = maxi(tier, int(matching.rarity))
		pool.erase(kind)
		options.append({"id": str(kind), "rarity": tier, "damage": rank_damage(kind, tier)})
	var can_upgrade := false
	for weapon in loadout.equipped():
		can_upgrade = can_upgrade or weapon.tier >= 4
	var can_unlock := false
	for weapon in loadout.equipped():
		can_unlock = can_unlock or weapon.affix_slots < MAX_SLOTS
	if can_unlock and wave >= 2 and random.randf() < SLOT_CHANCE:
		options[2] = {"id": "slot", "rarity": 3, "damage": 0.0}
	if wave >= 8 and can_upgrade and random.randf() < MK_CHANCE * (1.0 + minf(maxf(luck, 0) / 100.0, 0.6)):
		options[2] = {"id": "mk", "rarity": 4, "damage": 0.0}
	return {"kind": "affix", "options": options, "golden": golden, "scrap_coins": 5 + wave / 2 + (5 if golden else 0)}


static func sanitize_chest(value: Dictionary) -> Dictionary:
	if value.get("kind", "") != "affix":
		return {}
	var options: Array[Dictionary] = []
	var seen: Array[String] = []
	for option in value.get("options", []):
		if not option is Dictionary:
			continue
		var id := str(option.get("id", ""))
		var damage := float(option.get("damage", 0.0))
		if id in seen or (id not in ["slot", "mk"] and (by_id(StringName(id)) == null or not is_finite(damage) or damage <= 0.0)):
			continue
		seen.append(id)
		options.append({"id": id, "rarity": clampi(int(option.get("rarity", 1)), 1, 4), "damage": 0.0 if id in ["slot", "mk"] else damage})
	if options.size() != 3:
		return {}
	return {"kind": "affix", "options": options, "golden": bool(value.get("golden", false)), "scrap_coins": maxi(int(value.get("scrap_coins", 1)), 1),
		"target_uid": str(value.get("target_uid", "")), "replace": int(value.get("replace", -1))}


static func can_apply(weapon: WeaponInstance, option: Dictionary, replace: int = -1) -> bool:
	if option.get("id", "") == "slot":
		return weapon.affix_slots < MAX_SLOTS
	if option.get("id", "") == "mk":
		return weapon.tier >= 4
	if by_id(StringName(str(option.get("id", "")))) == null or float(option.get("damage", 0.0)) <= 0.0:
		return false
	var index := find(weapon.affixes, StringName(option.id))
	if index >= 0:
		return true
	return weapon.affixes.size() < weapon.affix_slots or replace >= 0 and replace < weapon.affixes.size()


static func apply(weapon: WeaponInstance, option: Dictionary, replace: int = -1) -> bool:
	if not can_apply(weapon, option, replace):
		return false
	if option.id == "slot":
		weapon.affix_slots += 1
		return true
	if option.id == "mk":
		var upgrades := weapon.data.chest_upgrades.duplicate(true)
		upgrades["mk"] = int(upgrades.get("mk", 0)) + 1
		weapon.data = WeaponRolls.resolve(weapon.data, weapon.data.rolls, upgrades)
		return true
	var index := find(weapon.affixes, StringName(option.id))
	if index >= 0:
		weapon.affixes[index] = upgraded(weapon.affixes[index], option)
	else:
		var entry := {"id": str(option.id), "damage": rank_damage(StringName(option.id), int(option.rarity)), "rarity": int(option.rarity), "rank": 1, "bonus": 0.0, "stacks": 1}
		if weapon.affixes.size() < weapon.affix_slots:
			weapon.affixes.append(entry)
		else:
			weapon.affixes[replace] = entry
	weapon.refresh_affix_stats()
	if weapon.get_parent() is WeaponLoadout:
		weapon.get_parent().prepare_projectile_visuals()
	return true


static func damage_for(value: float, data: WeaponData, stats: PlayerStats = null) -> float:
	# Slow heavy weapons receive larger additions; Mk and crit do not multiply affixes.
	var template := WeaponCatalog.by_id(data.id)
	var interval := template.interval if template != null else data.interval
	var raw := value * pow(interval / PlayerStats.BASE_ATTACK_INTERVAL, 0.65)
	return stats.scale_damage(raw) if stats != null else raw


static func packets(values: Array[Dictionary], data: WeaponData, stats: PlayerStats, factor: float = 1.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for affix in values:
		if by_id(StringName(affix.id)).stat_key != &"" or by_id(StringName(affix.id)).effect_kind != "damage":
			continue
		result.append({"id": str(affix.id), "damage": effect_damage(float(affix.damage), StringName(affix.id), data, stats) * factor})
	return result


static func effect_damage(value: float, kind: StringName, data: WeaponData, stats: PlayerStats = null) -> float:
	return damage_for(value, data, stats) * by_id(kind).damage_factor


static func utility_value(affix: Dictionary) -> float:
	var data := by_id(StringName(affix.id))
	return minf(data.utility_base + float(affix.damage) * data.utility_scale, data.utility_cap)


static func display_value(value: float, kind: StringName, weapon: WeaponData, stats: PlayerStats = null, items: ItemInventory = null) -> float:
	var data := by_id(kind)
	if data.effect_kind in ["wet", "leech"]:
		return utility_value({"id": str(kind), "damage": value}) + (0.5 if kind == &"wet" and items != null and items._power(&"conductive_wet") > 0 else 0.0)
	if data.stat_key != &"":
		return value
	return effect_damage(value, kind, weapon, stats) * (data.proc_factor if data.effect_kind == "holy" else 1.0)


static func value_text(value: float, kind: StringName, weapon: WeaponData, stats: PlayerStats = null, items: ItemInventory = null) -> String:
	return ("%.2f" if by_id(kind).effect_kind in ["wet", "leech"] else "%.1f") % display_value(value, kind, weapon, stats, items)


static func summary(weapon: WeaponInstance, stats: PlayerStats = null, items: ItemInventory = null) -> String:
	var lines: PackedStringArray = []
	for affix in weapon.affixes:
		var data := by_id(StringName(affix.id))
		lines.append("%s +%s %s · %s" % [data.display_name, value_text(float(affix.damage), data.id, weapon.data, stats, items), damage_unit(data.id, items), progress_text(affix)])
	return "Verzauberungen · %d/%d Plätze" % [weapon.affixes.size(), weapon.affix_slots] + ("\n" + "\n".join(lines) if not lines.is_empty() else "")


static func dot_duration(kind: StringName, items: ItemInventory = null) -> float:
	return minf(by_id(kind).dot_duration + (items._power(&"bleed_clock") if items != null and kind == &"bleed" else 0.0), EnemyAffixEffects.MAX_DOT_DURATION)


static func damage_unit(kind: StringName, items: ItemInventory = null) -> String:
	var data := by_id(kind)
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
	var data := by_id(kind)
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
		if weapon.affix_slots >= MAX_SLOTS:
			return "Alle 4 Plätze sind bereits offen.\nWähle eine andere Waffe."
		return "Plätze %d -> %d\nFür eine weitere Verzauberung." % [weapon.affix_slots, mini(weapon.affix_slots + 1, MAX_SLOTS)]
	if option.id == "mk":
		if weapon.tier < 4:
			return "Benötigt Mk IV.\nVerbessere diese Waffe zuerst im Shop."
		var upgrades := weapon.data.chest_upgrades.duplicate(true)
		upgrades["mk"] = int(upgrades.get("mk", 0)) + 1
		var next := WeaponRolls.resolve(weapon.data, weapon.data.rolls, upgrades)
		return "%s -> %s\n+10 %% Basisschaden\n+3 %% Tempo und Reichweite\nBenötigt mindestens Mk IV" % [WeaponPresentation.tier_text(weapon.data, weapon.tier), WeaponPresentation.tier_text(next, weapon.tier)]
	var data := by_id(StringName(option.id))
	var index := find(weapon.affixes, data.id)
	var before := float(weapon.affixes[index].damage) if index >= 0 else 0.0
	var after := float(upgraded(weapon.affixes[index], option).damage) if index >= 0 else rank_damage(data.id, int(option.rarity))
	var result := ("Fundstärke: %.1f" if data.effect_kind != "damage" else "Fundwert: +%.1f " + ("%% " + data.display_name if data.stat_key != &"" else "Basisschaden")) % rank_damage(data.id, int(option.rarity))
	var value_before := value_text(before, data.id, weapon.data, stats, items)
	var value_after := value_text(after, data.id, weapon.data, stats, items)
	if compact:
		var unit := "Schaden / %.0f s" % dot_duration(data.id, items) if data.dot_duration > 0 else damage_unit(data.id, items)
		result = effect_description(data.id) + "\n" + ("+%s -> +%s" % [value_before, value_after] if index >= 0 else "+%s" % value_after) + " " + unit
		if index >= 0:
			result += "\n%s -> %s" % [progress_text(weapon.affixes[index]), progress_text(upgraded(weapon.affixes[index], option))]
		elif weapon.affixes.size() >= weapon.affix_slots:
			result += "\nErsetzt: " + (by_id(StringName(weapon.affixes[replace].id)).display_name if replace >= 0 and replace < weapon.affixes.size() else "Bitte Ersatz wählen")
		if data.slow_fraction > 0:
			result += "\nBis zu %.0f %% langsamer für %.1f s" % [data.slow_fraction * 100, data.slow_duration]
		return result
	if index >= 0:
		result += "\nAuf dieser Waffe: +%s -> +%s %s" % [value_before, value_after, damage_unit(data.id, items)]
	else:
		result += "\nAuf dieser Waffe: +%s %s" % [value_after, damage_unit(data.id, items)]
	if index >= 0:
		result += "\n%s -> %s" % [progress_text(weapon.affixes[index]), progress_text(upgraded(weapon.affixes[index], option))]
		result += "\nFortschritt: +%.1f %% · danach %.1f %%" % [progress_weight(weapon.affixes[index], option) * 100, float(upgraded(weapon.affixes[index], option).get("progress", 0)) * 100]
	elif weapon.affixes.size() >= weapon.affix_slots:
		result += "\nErsetzt: " + (by_id(StringName(weapon.affixes[replace].id)).display_name if replace >= 0 and replace < weapon.affixes.size() else "Bitte Effekt wählen")
	else:
		result += "\nBelegt einen freien Platz für Verzauberungen"
	if data.slow_fraction > 0:
		result += "\nVerlangsamt für %.1f s" % data.slow_duration
	return result + "\n" + effect_description(data.id) + "\n" + mechanics_text(data.id)


static func mechanics_text(kind: StringName) -> String:
	var data := by_id(kind)
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
