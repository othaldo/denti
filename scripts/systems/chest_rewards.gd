class_name ChestRewards
extends RefCounted

const BASE_DROP_CHANCE := 0.016
const MAX_RANDOM_CHESTS_PER_WAVE := 3
const TREASURE_SPAWN_CHANCE := 0.0017
const TREASURE_FIRST_WAVE := 3
const TREASURE_HEALTH_FACTOR := 2.8
const TREASURE_SPEED_FACTOR := 0.85
const TREASURE_COLOR := Color(1.0, 0.8, 0.25)
const ELITE_DROP_CHANCE := 0.16
const LUCK_BONUS_CAP := 3.0
const SCRAP_FRACTION := 0.6


static func drop_chance(luck: float, is_elite: bool = false) -> float:
	var base := ELITE_DROP_CHANCE if is_elite else BASE_DROP_CHANCE
	var positive_luck := maxf(luck, 0.0)
	return base * (1.0 + LUCK_BONUS_CAP * positive_luck / (positive_luck + 100.0))


static func roll_item(wave_number: int, luck: float, inventory: ItemInventory, rng: RandomNumberGenerator = null) -> Dictionary:
	var tier := DentiRarity.roll_item(wave_number, luck, rng)
	for candidate_tier in range(tier, 0, -1):
		var pool: Array[ShopOfferData] = []
		for item in ItemCatalog.ALL:
			if item.weapon_data == null and item.rarity_tier == candidate_tier and inventory.can_acquire(item):
				pool.append(item)
		if not pool.is_empty():
			var index := rng.randi_range(0, pool.size() - 1) if rng != null else randi_range(0, pool.size() - 1)
			var selected := pool[index]
			return {"item_id": str(selected.id), "scrap_coins": maxi(roundi(float(selected.price) * SCRAP_FRACTION), 1)}
	return {}
