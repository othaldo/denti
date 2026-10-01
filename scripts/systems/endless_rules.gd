class_name EndlessRules
extends RefCounted

const FIRST_WAVE := 21
const WAVE_DURATION := 60.0
const HP_WEIGHT := 2.25
const SPEED_DIVISOR := 13.33
const MAX_SPEED_BONUS := 1.75
const PRICE_DIVISOR := 5.0
const MAX_DENSITY_FACTOR := 2.0
const MAX_ELITE_GROUP := 4

# Brotato's triangular factor, with an additional ramp after wave 35.
static func factor(wave_number: int) -> float:
	var extra := maxf(float(wave_number) - 20.0, 0.0)
	var ramp := 2.0 + maxf((float(wave_number) - 35.0) * 0.2, 0.0)
	return extra * (extra + 1.0) / 200.0 * ramp

static func baseline_wave(wave_number: int) -> int:
	return mini(wave_number, FIRST_WAVE - 1)

static func health_factor(wave_number: int) -> float:
	return 1.0 + factor(wave_number) * HP_WEIGHT

static func damage_factor(wave_number: int) -> float:
	return 1.0 + factor(wave_number)

static func speed_factor(wave_number: int) -> float:
	return 1.0 + minf(factor(wave_number) / SPEED_DIVISOR, MAX_SPEED_BONUS)

static func price_factor(wave_number: int) -> float:
	return 1.0 + factor(wave_number) / PRICE_DIVISOR

static func density_factor(wave_number: int) -> float:
	return minf(1.0 + factor(wave_number) * 0.10, MAX_DENSITY_FACTOR)

static func extra_elites(wave_number: int) -> int:
	return maxi(ceili((float(wave_number) - 20.0) / 10.0), 0)

static func shop_reroll_start(wave_number: int) -> int:
	return maxi(ceili(2.0 * price_factor(wave_number)), 2)

static func shop_reroll_step(wave_number: int) -> int:
	return maxi(roundi(sqrt(1.0 + factor(wave_number))), 1)
