extends RefCounted

const BASE = preload("res://tools/balance/build_comparison_profiles.gd")
# Four roots of fixed damage, two roots to compare support/opportunity cost.
const MIXES := {
	"support_turbine": ["magic_toothbrush", "magic_toothbrush", "water_turbine"],
	"support_jets": ["magic_toothbrush", "magic_toothbrush", "water_jet", "water_jet"],
	"support_push": ["magic_toothbrush", "magic_toothbrush", "amalgam_slingshot", "amalgam_slingshot"],
	"support_uv": ["magic_toothbrush", "magic_toothbrush", "uv_lamp"],
	"support_damage": ["magic_toothbrush", "magic_toothbrush", "enamel_mirror", "enamel_mirror"],
	"support_fluoride": ["magic_toothbrush", "magic_toothbrush", "fluoride_sprayer"],
}


static func ids() -> Array:
	var result: Array = []
	for data in WeaponCatalog.ALL: result.append(str(data.id))
	return result


static func setup(build: String, wave_number: int, mode: String) -> Dictionary:
	var equipment: Array = MIXES.get(build, []).duplicate()
	if equipment.is_empty():
		var weapon := WeaponCatalog.by_id(StringName(build))
		assert(weapon != null and weapon in WeaponCatalog.ALL, "Unknown regular weapon")
		for slot in int(6 / weapon.hands): equipment.append(build)
	var config: Dictionary = BASE.setup_equipment(equipment, build, wave_number, "shop" if mode == "electric_shop" else mode)
	if mode == "electric_shop":
		config.mode = mode
		for entry: Dictionary in config.equipment:
			var data := WeaponCatalog.by_id(StringName(entry.id))
			var affixes: Array[Dictionary] = []
			for effect: String in BASE.RANKS[int(config.tier) - 1]:
				for rank in int(BASE.RANKS[int(config.tier) - 1][effect]):
					affixes = WeaponUpgrades.advance(affixes, &"electric" if effect == "fire" else StringName(effect), data, int(config.tier))
			entry.affixes = affixes
	return config


static func pursuit_direction(game) -> Vector2:
	var target: Enemy = game.boss if is_instance_valid(game.boss) and game.boss.health > 0 else null
	if target == null: return Vector2.ZERO
	var reach := INF
	for weapon: WeaponInstance in game.player.loadout.equipped():
		reach = minf(reach, weapon.data.range_at_tier(weapon.tier))
	if not is_finite(reach): return Vector2.ZERO
	var offset: Vector2 = target.global_position - game.player.global_position
	var inward := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	var radial := clampf((offset.length() - target.data.radius - reach * 0.75) / 100.0, -1.0, 1.0)
	return (inward * radial + inward.orthogonal() * 0.65).normalized()
