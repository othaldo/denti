class_name WeaponUpgradeIncome
extends RefCounted
## Counts real pickups and resolves bonus income once after the loot sweep.

const LUCK_CAP := 0.25
const LUCK_HALF := 150.0

var polish_progress := 0
var polish_bonus := 0
var luck_bonus := 0
var resolved := false


static func luck_chance(luck: float) -> float:
	var positive := maxf(luck, 0)
	return LUCK_CAP * positive / (positive + LUCK_HALF)


func begin_wave() -> void:
	polish_bonus = 0
	luck_bonus = 0
	resolved = false


func collect(items: ItemInventory) -> int:
	var every := roundi(items.power(&"capsule_polish")) if items != null else 0
	if every <= 0: return 0
	polish_progress += 1
	if polish_progress < every: return 0
	polish_progress = 0
	polish_bonus += 1
	return WeaponUpgrades.POINTS_PER_CAPSULE


func finish_wave(luck: float, roll: float) -> int:
	if resolved: return 0
	resolved = true
	if roll >= luck_chance(luck): return 0
	luck_bonus = 1
	return WeaponUpgrades.POINTS_PER_CAPSULE


func details() -> String:
	var result := "Glück: +%d Punkte · Runenpolitur: +%d Punkte" % [luck_bonus * WeaponUpgrades.POINTS_PER_CAPSULE, polish_bonus * WeaponUpgrades.POINTS_PER_CAPSULE]
	if polish_progress > 0:
		result += "\nRunenpolitur: %d/%d Kapseln" % [polish_progress, int(ItemCatalog.by_id(&"rune_polish").effect_value)]
	return result


func save_data() -> Dictionary:
	return {"polish_progress": polish_progress, "polish_bonus": polish_bonus, "luck_bonus": luck_bonus, "resolved": resolved}


func restore(saved: Dictionary) -> void:
	polish_progress = clampi(int(saved.get("polish_progress", 0)), 0, int(ItemCatalog.by_id(&"rune_polish").effect_value) - 1)
	polish_bonus = maxi(int(saved.get("polish_bonus", 0)), 0)
	luck_bonus = clampi(int(saved.get("luck_bonus", 0)), 0, 1)
	resolved = bool(saved.get("resolved", false))
