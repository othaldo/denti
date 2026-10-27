class_name WeaponUpgrades
extends RefCounted

const MAX_LEVEL := 10
const KIND := "weapon_upgrade"


static func capsule(wave: int, golden: bool = false) -> Dictionary:
	return {"kind": KIND, "points": 1, "golden": golden, "scrap_coins": 5 + wave / 2 + (5 if golden else 0)}


static func slots(tier: int) -> int:
	return clampi(tier, 1, WeaponAffixes.MAX_SLOTS)


static func level(entry: Dictionary) -> int:
	if entry.has("level"): return clampi(int(entry.level), 1, MAX_LEVEL)
	# Historic power is preserved, including formerly unbounded legendary effects.
	var steps := WeaponAffixes.by_id(StringName(entry.id)).upgrade_steps
	for index in steps.size():
		if float(entry.damage) <= steps[index]: return index + 1
	return MAX_LEVEL


static func power(id: StringName, rank: int, data: WeaponData, tier: int) -> float:
	var definition := WeaponAffixes.by_id(id)
	var value := definition.upgrade_steps[clampi(rank, 1, MAX_LEVEL) - 1]
	var roots := float(data.hands)
	if definition.stat_key != &"" or definition.effect_kind == "leech":
		# Utility uses its existing effect-specific caps; percentages grow more gently.
		return value * sqrt(roots)
	var template := WeaponCatalog.by_id(data.id)
	var interval := template.interval if template != null else data.interval
	var count := data.projectile_count_at_tier(tier) if data.attack_mode == &"projectile" else 1
	var weight := 1.0 + 0.55 * maxi(count - 1, 0)
	# The existing damage path supplies interval^0.65. Together this is linear
	# in the base attack interval, with one shared budget across the initial fan.
	return value * roots * pow(interval / PlayerStats.BASE_ATTACK_INTERVAL, 0.35) / weight


static func next_entry(current: Dictionary, id: StringName, data: WeaponData, tier: int) -> Dictionary:
	var rank := 1 if current.is_empty() else level(current) + 1
	if rank > MAX_LEVEL: return {}
	var floor_value := float(current.get("legacy_floor", 0))
	if not current.is_empty() and not current.has("level"):
		floor_value = maxf(floor_value, float(current.damage))
	return {"id": str(id), "level": rank, "damage": maxf(power(id, rank, data, tier), floor_value),
		"legacy_floor": floor_value, "rarity": 1, "rank": 1, "progress": 0.0, "bonus": 0.0, "stacks": rank}


static func advance(values: Array[Dictionary], id: StringName, data: WeaponData, tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = values.duplicate(true)
	if not blocked_reason(values, id, tier).is_empty(): return []
	var index := WeaponAffixes.find(result, id)
	var next := next_entry(result[index] if index >= 0 else {}, id, data, tier)
	if next.is_empty(): return []
	if index < 0: result.append(next)
	else: result[index] = next
	return result


static func blocked_reason(values: Array[Dictionary], id: StringName, tier: int) -> String:
	var definition := WeaponAffixes.by_id(id)
	if definition == null: return "Unbekannter Effekt"
	var index := WeaponAffixes.find(values, id)
	if index >= 0:
		return "Bereits 10/10" if level(values[index]) >= MAX_LEVEL else ""
	if not definition.selectable: return "Nicht mehr verfügbar"
	var current := WeaponAffixes.element(values)
	if definition.elemental and current != &"":
		return "Element bereits gewählt: " + WeaponAffixes.by_id(current).display_name
	if values.size() >= slots(tier): return "Alle Plätze belegt"
	return ""


static func refresh(values: Array[Dictionary], data: WeaponData, tier: int) -> void:
	for entry in values:
		if entry.has("level"):
			entry.damage = maxf(power(StringName(entry.id), level(entry), data, tier), float(entry.get("legacy_floor", 0)))


static func fusion_fits(first: Array[Dictionary], second: Array[Dictionary]) -> bool:
	return fusion_block_reason(first, second).is_empty()


static func fusion_block_reason(first: Array[Dictionary], second: Array[Dictionary]) -> String:
	var elements: Array[StringName] = []
	for entry in first + second:
		var id := StringName(entry.id)
		if WeaponAffixes.by_id(id).elemental and not elements.has(id): elements.append(id)
	# Fusion must not bypass the element choice or throw an investment away.
	if elements.size() > 1 and (first + second).any(func(entry: Dictionary) -> bool: return entry.has("level")): return "Verschiedene Elemente"
	for left in first:
		var index := WeaponAffixes.find(second, StringName(left.id))
		if index < 0: continue
		var right := second[index]
		if (left.has("level") or right.has("level")) and level(left) + level(right) > MAX_LEVEL:
			return "Verzauberung würde 10/10 überschreiten"
	return ""
