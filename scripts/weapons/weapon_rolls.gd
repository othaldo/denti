class_name WeaponRolls
extends RefCounted

# Instance quality is independent of Mk. Fusion preserves each better attribute.
const NAMES: Array[String] = ["Schrott", "Solide", "Meisterwerk", "Göttlich"]
const BANDS: Array[Vector2] = [Vector2(0, 0.38), Vector2(0.25, 0.68), Vector2(0.55, 0.9), Vector2(0.8, 1)]
const DAMAGE := Vector2(0.60, 1.70)
const INTERVAL := Vector2(0.72, 1.35)
const REACH := Vector2(0.80, 1.25)
const CRIT := Vector2(0, 0.10)


static func roll(wave: int, luck: float, rng: RandomNumberGenerator) -> Dictionary:
	var progress := clampf(float(wave - 1) / 19.0, 0.0, 1.0)
	var fortune := maxf(luck, 0.0) / (maxf(luck, 0.0) + 60.0)
	var chance := rng.randf()
	var quality := 4 if chance < 0.01 + progress * 0.04 + fortune * 0.04 else (3 if chance < 0.08 + progress * 0.14 + fortune * 0.10 else (2 if chance < 0.35 + progress * 0.20 + fortune * 0.12 else 1))
	var band := BANDS[quality - 1]
	return {"quality": quality,
		"damage": snappedf(lerpf(DAMAGE.x, DAMAGE.y, rng.randf_range(band.x, band.y)), 0.001),
		"interval": snappedf(lerpf(INTERVAL.y, INTERVAL.x, rng.randf_range(band.x, band.y)), 0.001),
		"range": snappedf(lerpf(REACH.x, REACH.y, rng.randf_range(band.x, band.y)), 0.001),
		"crit": snappedf(lerpf(CRIT.x, CRIT.y, rng.randf_range(band.x, band.y)), 0.001)}


static func sanitize(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var result := {"quality": clampi(int(value.get("quality", 2)), 1, 4)}
	var bounds := {"damage": DAMAGE, "interval": INTERVAL, "range": REACH, "crit": CRIT}
	for key: String in bounds:
		var number := float(value.get(key, 0.0 if key == "crit" else 1.0))
		if not is_finite(number):
			return {}
		result[key] = clampf(number, bounds[key].x, bounds[key].y)
	return result


static func resolve(data: WeaponData, value: Dictionary, upgrades: Dictionary = {}) -> WeaponData:
	var values := sanitize(value)
	var template := WeaponCatalog.by_id(data.id)
	if template == null:
		template = data
	if values.is_empty() and upgrades.is_empty():
		return template
	var result := template.duplicate() as WeaponData
	result.rolls = values
	result.chest_upgrades = {"mk": maxi(int(upgrades.get("mk", 0)), 0), "range": maxf(float(upgrades.get("range", 0)), 0), "tempo": maxf(float(upgrades.get("tempo", 0)), 0)}
	var levels := int(result.chest_upgrades.mk)
	var reach := (float(values.get("range", 1)) * (1.0 + float(result.chest_upgrades.range) / 100.0 + levels * 0.03))
	result.base_damage *= float(values.get("damage", 1)) * (1.0 + levels * 0.10)
	result.interval *= float(values.get("interval", 1)) / (1.0 + float(result.chest_upgrades.tempo) / 100.0 + levels * 0.03)
	result.attack_range *= reach
	result.range_tiers = template.range_tiers.duplicate()
	for index in result.range_tiers.size():
		result.range_tiers[index] *= reach
	result.crit_bonus += float(values.get("crit", 0))
	return result


static func fuse(primary: WeaponData, partner: WeaponData) -> WeaponData:
	var left := sanitize(primary.rolls)
	var right := sanitize(partner.rolls)
	var values: Dictionary = {}
	if not left.is_empty() or not right.is_empty():
		values["quality"] = maxi(int(left.get("quality", 2)), int(right.get("quality", 2)))
		for key in ["damage", "interval", "range", "crit"]:
			var neutral := 0.0 if key == "crit" else 1.0
			var a := float(left.get(key, neutral))
			var b := float(right.get(key, neutral))
			values[key] = minf(a, b) if key == "interval" else maxf(a, b)
	var upgrades: Dictionary = {}
	if not primary.chest_upgrades.is_empty() or not partner.chest_upgrades.is_empty():
		upgrades["mk"] = maxi(int(primary.chest_upgrades.get("mk", 0)), int(partner.chest_upgrades.get("mk", 0)))
	# Resolve from the catalog, so previews and repeated fusions never compound factors.
	return resolve(primary, values, upgrades)


static func with_affixes(data: WeaponData, affixes: Array[Dictionary]) -> WeaponData:
	var upgrades := {"mk": int(data.chest_upgrades.get("mk", 0)), "range": 0.0, "tempo": 0.0}
	for affix in affixes:
		var definition := WeaponAffixes.by_id(StringName(affix.id))
		if definition.stat_key != &"":
			upgrades[str(definition.stat_key)] += float(affix.damage)
	if float(upgrades.range) == 0 and float(upgrades.tempo) == 0 and int(upgrades.mk) == 0:
		upgrades = {}
	return resolve(data, data.rolls, upgrades)


static func title(data: WeaponData) -> String:
	return NAMES[clampi(int(data.rolls.get("quality", 2)), 1, 4) - 1] if not data.rolls.is_empty() else "Standard"


static func description(data: WeaponData) -> String:
	if data.rolls.is_empty():
		return ""
	return "%s · Schaden %+.0f %% · Pause %+.0f %%\nReichweite %+.0f %% · Crit +%.1f %%" % [title(data),
		(float(data.rolls.damage) - 1.0) * 100, (float(data.rolls.interval) - 1.0) * 100,
		(float(data.rolls.range) - 1.0) * 100, float(data.rolls.crit) * 100]


static func attribute_quality(data: WeaponData, key: String) -> int:
	if data.rolls.is_empty():
		return 1
	var bounds: Vector2 = {"damage": DAMAGE, "interval": INTERVAL, "range": REACH, "crit": CRIT}[key]
	var score := inverse_lerp(bounds.x, bounds.y, float(data.rolls[key]))
	if key == "interval":
		score = 1.0 - score
	return 4 if score >= 0.90 else (3 if score >= 0.68 else (2 if score >= 0.38 else 1))
