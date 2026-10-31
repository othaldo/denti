class_name WeaponAscension
extends RefCounted
## Mk IV remains the attack chassis; ascensions add to its saved base bonuses.

const ID := &"mk"
const FIRST_POINT_COST := 3
const FIRST_GOLD_COST := 60
const GOLD_CURVE_STEP := 20


static func level(data: WeaponData) -> int:
	return maxi(int(data.chest_upgrades.get("mk", 0)), 0)


static func quote(data: WeaponData, wave: int) -> Dictionary:
	var step := level(data) + 1
	var roots := WeaponUpgrades.cost(data)
	var progression := step * (step + 1) / 2 - 1
	return {"cost": roots * (FIRST_POINT_COST + progression),
		"coins": ceili(roots * (FIRST_GOLD_COST + GOLD_CURVE_STEP * progression) * EndlessRules.price_factor(wave))}


static func advance(data: WeaponData) -> WeaponData:
	var upgrades := data.chest_upgrades.duplicate(true)
	upgrades["mk_legacy"] = int(upgrades.get("mk_legacy", level(data)))
	upgrades["mk_points"] = invested_points(data) + int(quote(data, 1).cost)
	upgrades["mk"] = level(data) + 1
	return WeaponRolls.resolve(data, data.rolls, upgrades)


static func invested_points(data: WeaponData) -> int:
	return maxi(int(data.chest_upgrades.get("mk_points", 0)), 0)


static func point_value(data: WeaponData) -> int:
	var count := level(data)
	return WeaponUpgrades.cost(data) * ((FIRST_POINT_COST - 1) * count + count * (count + 1) * (count + 2) / 6)


static func inherit(result: WeaponData, primary: WeaponData, partner: WeaponData = null) -> WeaponData:
	var legacy := 0
	var budget := 0
	var historic_value := 0
	for source in [primary, partner]:
		if source == null: continue
		legacy += int(source.chest_upgrades.get("mk_legacy", level(source)))
		budget += invested_points(source)
		historic_value += maxi(point_value(source) - invested_points(source), 0)
	var data := WeaponRolls.resolve(result, primary.rolls, {"mk": legacy})
	# A saved free Mk acquired after a paid step retains the value of that later
	# step. Historic finds stay non-refundable, including the old additive floor.
	historic_value = maxi(historic_value, point_value(data))
	budget += historic_value - point_value(data)
	# Convert the actual point investment at the result's root cost. Repeated
	# evolution cannot create paid Mk ranks; unused points join the fusion refund.
	while budget >= int(quote(data, 1).cost):
		budget -= int(quote(data, 1).cost)
		data = advance(data)
	var upgrades := data.chest_upgrades.duplicate(true)
	upgrades["mk_legacy"] = legacy
	upgrades["mk_points"] = maxi(point_value(data) - historic_value, 0)
	return WeaponRolls.resolve(result, primary.rolls, upgrades)
