class_name ClassCombatEffects
extends RefCounted

## Short combat windows granted by the class profile and its talents.
## The dash cut trail itself lives in ClassDashCut; this object only holds the
## rules/powers both read, plus the optional opener talent of Good Old Molar.

const MIX_KEY_DUPLICATE_PENALTY := 10.0
const SPEC_KEY_VARIETY_PENALTY := 8.0

var profile: PlayerClassData
var powers: Dictionary = {}
var loadout: WeaponLoadout
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
	var bonus := toolkit_bonus(weapon)
	if _eligible(weapon) and opener_time > 0: bonus += rules().opener_bonus + power("opener_bonus")
	return bonus

## Good Old Molar's loadout talents, read from the equipped weapons:
## Werkzeugvielfalt/Elementmix reward mixed loadouts, Gleiches Werkzeug rewards
## copies of one weapon. Each keystone doubles its side and taxes the other.
func toolkit_bonus(weapon: WeaponData) -> float:
	if loadout == null or not is_instance_valid(loadout) or weapon == null: return 0.0
	var variety := power("tool_variety")
	var elements := power("tool_elements")
	var twin := power("tool_twin")
	var mix_key := power("tool_mix_key") > 0.0
	var spec_key := power("tool_spec_key") > 0.0
	if variety <= 0.0 and elements <= 0.0 and twin <= 0.0 and not mix_key and not spec_key: return 0.0
	var counts := {}
	var element_ids := {}
	for instance in loadout.equipped():
		counts[instance.data.id] = int(counts.get(instance.data.id, 0)) + 1
		var element := WeaponAffixes.element(instance.affixes)
		if element != &"": element_ids[element] = true
	var types := counts.size()
	var copies := maxi(int(counts.get(weapon.id, 1)) - 1, 0)
	var bonus := variety * types * (2.0 if mix_key else 1.0)
	bonus += elements * element_ids.size()
	bonus += twin * copies * (2.0 if spec_key else 1.0)
	if mix_key: bonus -= MIX_KEY_DUPLICATE_PENALTY * copies
	if spec_key: bonus -= SPEC_KEY_VARIETY_PENALTY * maxi(types - 1, 0)
	return bonus

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
		elif key == "molar":
			if not MolarSkills.valid(saved[key]): return false
		elif key == "assassin":
			if not AssassinSkills.valid(saved[key]): return false
		elif key == "modules":
			if not saved[key] is Dictionary or not ClassSkillModule.valid_state(saved[key]): return false
		elif not (saved[key] is int or saved[key] is float) or not is_finite(float(saved[key])): return false
	return true

func restore(saved: Dictionary, _enemies: Array[Node]) -> void:
	reset_wave()
	opener_time = clampf(float(saved.get("opener_time", 0)), 0, rules().opener_duration)
