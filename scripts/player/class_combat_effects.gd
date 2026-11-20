class_name ClassCombatEffects
extends RefCounted

## Short combat windows granted by the class profile and its talents.
## The dash cut trail itself lives in ClassDashCut; this object only holds the
## rules/powers both read, plus the optional opener talent of Good Old Molar.

var profile: PlayerClassData
var powers: Dictionary = {}
var opener_time := 0.0
var fallback := ClassCombatData.new()

func rules() -> ClassCombatData:
	return profile.combat_rules if profile != null and profile.combat_rules != null else fallback

func power(id: String) -> float:
	return float(powers.get(id, 0))

func reset_wave() -> void:
	opener_time = 0

func on_dash() -> void:
	if rules().opener_bonus + power("opener_bonus") > 0: opener_time = rules().opener_duration

func advance(delta: float) -> void:
	opener_time = maxf(opener_time - delta, 0)

func _eligible(weapon: WeaponData) -> bool:
	return rules().opener_roles.is_empty() or rules().opener_roles.any(func(role: StringName) -> bool: return role in weapon.class_roles)

func damage_bonus(_enemy: Enemy, weapon: WeaponData) -> float:
	if not _eligible(weapon) or opener_time <= 0: return 0
	return rules().opener_bonus + power("opener_bonus")

func after_hit(effects: ItemEffectContext, _enemy: Enemy, weapon: WeaponData, _tier: int, dealt: float) -> void:
	if dealt <= 0 or not _eligible(weapon) or opener_time <= 0: return
	opener_time = 0
	effects.enchantment_support.emit(&"class_openers", 1)

func save_data(_indices: Dictionary) -> Dictionary:
	return {"opener_time": opener_time}

static func valid(saved: Dictionary) -> bool:
	for key in saved:
		if key == "trails":
			if not ClassDashCut.valid(saved[key]): return false
		elif not (saved[key] is int or saved[key] is float) or not is_finite(float(saved[key])): return false
	return true

func restore(saved: Dictionary, _enemies: Array[Node]) -> void:
	reset_wave()
	opener_time = clampf(float(saved.get("opener_time", 0)), 0, rules().opener_duration)
