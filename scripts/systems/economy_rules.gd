class_name EconomyRules
extends RefCounted

const GOLD_DECAY_START_WAVE := 5
const GOLD_DECAY_PER_WAVE := 0.015
const GOLD_DROP_MIN := 0.70
const PRICE_INCREASE_PER_WAVE := 0.10
const EARLY_GOLD_BONUS := 0.60
const EARLY_GOLD_BONUS_END_WAVE := 4


static func gold_drop_factor(wave_number: int) -> float:
	return 1.0 if wave_number < GOLD_DECAY_START_WAVE else maxf(1.0 - GOLD_DECAY_PER_WAVE * wave_number, GOLD_DROP_MIN)


static func coin_chance(data: EnemyData, wave_number: int, difficulty_factor: float = 1.0) -> float:
	var start_bonus := EARLY_GOLD_BONUS * clampf(float(EARLY_GOLD_BONUS_END_WAVE - wave_number) / float(EARLY_GOLD_BONUS_END_WAVE - 1), 0.0, 1.0)
	return 1.0 if data.is_elite else clampf(data.coin_drop_chance * (1.0 + start_bonus) * gold_drop_factor(wave_number) * difficulty_factor, 0.0, 1.0)


static func shop_price(base_price: int, wave_number: int) -> int:
	var number := maxi(wave_number, 0)
	return maxi(floori(base_price * (1.0 + PRICE_INCREASE_PER_WAVE * number) + number), 1)
