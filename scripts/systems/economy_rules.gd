class_name EconomyRules
extends RefCounted

const GOLD_DECAY_START_WAVE := 5
const GOLD_DECAY_PER_WAVE := 0.015
const GOLD_LATE_DECAY_PER_WAVE := 0.009375
const GOLD_DROP_MIN := 0.40
const PRICE_INCREASE_PER_WAVE := 0.10


static func gold_drop_factor(wave_number: int) -> float:
	if wave_number < GOLD_DECAY_START_WAVE:
		return 1.0
	return maxf(1.0 - GOLD_DECAY_PER_WAVE * wave_number - GOLD_LATE_DECAY_PER_WAVE * (wave_number - 4), GOLD_DROP_MIN)


static func coin_chance(data: EnemyData, wave_number: int, difficulty_factor: float = 1.0) -> float:
	return 1.0 if data.is_elite else clampf(data.coin_drop_chance * gold_drop_factor(wave_number) * difficulty_factor, 0.0, 1.0)


static func level_reroll_cost(earned_level: int, rerolls: int) -> int:
	return maxi(ceili(float(earned_level) / 2.0), 2) + reroll_surcharge(rerolls)


static func reroll_surcharge(rerolls: int) -> int:
	var count := clampi(rerolls, 0, 10000)
	return count * (count + 1) / 2


static func shop_reroll_cost(wave_number: int, rerolls: int) -> int:
	return EndlessRules.shop_reroll_start(wave_number) + EndlessRules.shop_reroll_step(wave_number) * reroll_surcharge(rerolls)


static func shop_price(base_price: int, wave_number: int) -> int:
	var number := maxi(wave_number, 0)
	return maxi(floori((base_price * (1.0 + PRICE_INCREASE_PER_WAVE * number) + number) * EndlessRules.price_factor(number)), 1)
