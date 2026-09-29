class_name ChestRewards
extends RefCounted

const BASE_DROP_CHANCE := 0.0018
const LUCK_BONUS_CAP := 1.0
const SCRAP_FRACTION := 0.6


static func drop_chance(luck: float) -> float:
	return BASE_DROP_CHANCE * (1.0 + minf(maxf(luck, 0.0) / 100.0, LUCK_BONUS_CAP))


static func roll_item(wave_number: int, luck: float, inventory: ItemInventory, rng: RandomNumberGenerator = null) -> Dictionary:
	var tier := DentiRarity.roll(wave_number, luck, rng)
	for candidate_tier in range(tier, 0, -1):
		var pool: Array[ShopOfferData] = []
		for item in ShopController.CATALOG:
			if item.weapon_data == null and item.rarity_tier == candidate_tier and inventory.can_acquire(item):
				pool.append(item)
		if not pool.is_empty():
			var index := rng.randi_range(0, pool.size() - 1) if rng != null else randi_range(0, pool.size() - 1)
			var selected := pool[index]
			return {"item_id": str(selected.id), "scrap_coins": maxi(roundi(float(selected.price) * SCRAP_FRACTION), 1)}
	return {}
