class_name WeaponUpgrades
extends RefCounted

## Default rank cap. Single weapons may raise theirs up to LEVEL_LIMIT.
const MAX_LEVEL := 10
const LEVEL_LIMIT := 15
const KIND := "weapon_upgrade"
const POINTS_PER_CAPSULE := 2
const ECONOMY_VERSION := 2


static func cost(data: WeaponData) -> int:
	return maxi(data.hands, 1)


static func capsule(wave: int, golden: bool = false) -> Dictionary:
	return {"kind": KIND, "points": POINTS_PER_CAPSULE, "golden": golden, "scrap_coins": 5 + wave / 2 + (5 if golden else 0)}


static func slots(tier: int) -> int:
	return clampi(tier, 1, WeaponAffixes.MAX_SLOTS)


static func max_level(data: WeaponData = null) -> int:
	return clampi(data.enchantment_max_level, 1, LEVEL_LIMIT) if data != null else MAX_LEVEL


## Ranks past the authored table continue with its last step.
static func step(definition: WeaponAffixData, rank: int) -> float:
	var steps := definition.upgrade_steps
	var count := steps.size()
	if rank <= count: return steps[maxi(rank, 1) - 1]
	var increment := steps[count - 1] - steps[count - 2] if count > 1 else steps[count - 1]
	return steps[count - 1] + increment * (rank - count)


static func level(entry: Dictionary) -> int:
	if entry.has("level"): return clampi(int(entry.level), 1, LEVEL_LIMIT)
	# Historic power is preserved, including formerly unbounded legendary effects.
	var steps := WeaponAffixes.by_id(StringName(entry.id)).upgrade_steps
	for index in steps.size():
		if float(entry.damage) <= steps[index]: return index + 1
	return MAX_LEVEL


static func power(id: StringName, rank: int, data: WeaponData, tier: int) -> float:
	var definition := WeaponAffixes.by_id(id)
	var value := step(definition, clampi(rank, 1, max_level(data)))
	var roots := float(data.hands)
	if definition.stat_key != &"" or definition.effect_kind == "leech":
		# Percentages already apply to the whole weapon. Healing is weighted once,
		# including its flat base and cap, in utility_value instead.
		return value
	var template := WeaponCatalog.by_id(data.id)
	var interval := template.interval if template != null else data.interval
	var count := data.projectile_count_at_tier(tier) if data.attack_mode == &"projectile" else 1
	var weight := 1.0 + 0.55 * maxi(count - 1, 0)
	# The existing damage path supplies interval^0.65. Together this is linear
	# in the base attack interval, with one shared budget across the initial fan.
	return value * roots * pow(interval / PlayerStats.BASE_ATTACK_INTERVAL, 0.35) / weight


static func next_entry(current: Dictionary, id: StringName, data: WeaponData, tier: int) -> Dictionary:
	var rank := 1 if current.is_empty() else level(current) + 1
	if rank > max_level(data): return {}
	var floor_value := float(current.get("legacy_floor", 0))
	if not current.is_empty() and not current.has("level"):
		floor_value = maxf(floor_value, float(current.damage))
	return {"id": str(id), "level": rank, "damage": maxf(power(id, rank, data, tier), floor_value),
		"legacy_floor": floor_value, "rarity": 1, "rank": 1, "progress": 0.0, "bonus": 0.0, "stacks": rank}


static func advance(values: Array[Dictionary], id: StringName, data: WeaponData, tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = values.duplicate(true)
	if not blocked_reason(values, id, tier, data).is_empty(): return []
	var index := WeaponAffixes.find(result, id)
	var next := next_entry(result[index] if index >= 0 else {}, id, data, tier)
	if next.is_empty(): return []
	if index < 0: result.append(next)
	else: result[index] = next
	return result


static func blocked_reason(values: Array[Dictionary], id: StringName, tier: int, data: WeaponData = null) -> String:
	var definition := WeaponAffixes.by_id(id)
	if definition == null: return "Unbekannter Effekt"
	var index := WeaponAffixes.find(values, id)
	if index >= 0:
		var cap := max_level(data)
		return "Bereits %d/%d" % [cap, cap] if level(values[index]) >= cap else ""
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


static func fusion_fits(first: Array[Dictionary], second: Array[Dictionary], data: WeaponData = null) -> bool:
	return fusion_block_reason(first, second, data).is_empty()


static func fusion_block_reason(first: Array[Dictionary], second: Array[Dictionary], data: WeaponData = null) -> String:
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
		var cap := max_level(data)
		if (left.has("level") or right.has("level")) and level(left) + level(right) > cap:
			return "Verzauberung würde %d/%d überschreiten" % [cap, cap]
	return ""
