class_name DentiRarity
extends RefCounted

const NAMES: Array[String] = ["Gewöhnlich", "Ungewöhnlich", "Selten", "Legendär", "Mythisch"]
const COLORS: Array[Color] = [
	Color("8f777a"), Color("4289b6"), Color("8753b8"), Color("bc7424"),
	Color("c33e76"),
]


static func name_for(tier: int) -> String:
	return NAMES[clampi(tier, 1, 5) - 1]


static func color_for(tier: int) -> Color:
	return COLORS[clampi(tier, 1, 5) - 1]


static func cumulative_chance(tier: int, progress: int, luck: float) -> float:
	var luck_factor := maxf(1.0 + luck / 100.0, 0.0)
	match tier:
		2:
			return minf(maxi(progress - 1, 0) * 0.06 * luck_factor, 0.60)
		3:
			return minf(maxi(progress - 3, 0) * 0.02 * luck_factor, 0.25)
		4:
			return minf(maxi(progress - 7, 0) * 0.0023 * luck_factor, 0.08)
		5:
			# Item-only rarity: first possible after wave 12, hard cap at 1%.
			return minf(maxi(progress - 11, 0) * 0.00035 * luck_factor, 0.01)
	return 1.0


static func roll(progress: int, luck: float, rng: RandomNumberGenerator = null) -> int:
	var value := rng.randf() if rng != null else randf()
	for tier in [4, 3, 2]:
		if value < cumulative_chance(tier, progress, luck):
			return tier
	return 1


static func roll_item(progress: int, luck: float, rng: RandomNumberGenerator = null) -> int:
	var value := rng.randf() if rng != null else randf()
	for tier in [5, 4, 3, 2]:
		if value < cumulative_chance(tier, progress, luck):
			return tier
	return 1


static func upgrade_tier(level: int, luck: float, rng: RandomNumberGenerator = null) -> int:
	if level >= 25 and level % 5 == 0:
		return 4
	if level == 10 or level == 15 or level == 20:
		return 3
	if level == 5:
		return 2
	return roll(level, luck, rng)
