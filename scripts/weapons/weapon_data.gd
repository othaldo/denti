class_name WeaponData
extends Resource

const MIN_ATTACK_COOLDOWN := 0.05

@export var id: StringName
@export var display_name: String
@export var role: String
@export_multiline var description: String
@export var hands: int = 1
@export var attack_mode: StringName = &"projectile"
@export var damage_type: String = "Schmelz"
@export var base_damage: float = 18.0
@export_enum("melee", "ranged") var damage_stat: String = "ranged"
@export_range(0.0, 3.0) var stat_scaling: float = 1.0
@export var interval: float = 0.8
@export var attack_range: float = 300.0
@export var projectile_speed: float = 520.0
@export var projectile_count: int = 1
@export var pierce: int = 0
@export var splash_radius: float = 0.0
@export var knockback: float = 0.0
@export var bleed_dps: float = 0.0
@export var bleed_duration: float = 0.0
@export var wet_duration: float = 0.0
@export var sprite: Texture2D
@export var grip_anchor: Vector2 = Vector2(0.25, 0.85)
@export var projectile_color: Color = Color(0.75, 0.96, 1.0)
@export var visual_angle_degrees: float = 45.0
@export var price: int = 8
@export var damage_tiers: PackedFloat32Array
@export var range_tiers: PackedFloat32Array
@export var projectile_count_tiers: PackedInt32Array
@export var pierce_tiers: PackedInt32Array
@export var splash_tiers: PackedFloat32Array
@export var knockback_tiers: PackedFloat32Array
@export var boss_bonus_tiers: PackedFloat32Array
@export var attack_width: float = 18.0
@export var arc_degrees: float = 60.0
@export var crit_bonus: float = 0.0
@export var crit_multiplier: float = 1.5
@export var crit_cycle: int = 0
@export var focus_step: float = 0.0
@export var focus_cap: float = 0.0
@export var trash_damage_factor: float = 1.0
@export var elite_damage_bonus: float = 0.0
@export var enamel_exposure: float = 0.0
@export var exposure_duration: float = 0.0
@export var projectile_shape: StringName = &"orb"

@export_group("Held animation")
@export_enum("aimed", "upright", "staff") var held_style: String = "aimed"
@export_enum("shoot", "lob", "pull", "thrust", "slash", "spin", "drill", "polish", "spray", "beam") var attack_animation: String = "shoot"
@export var tip_anchor: Vector2 = Vector2(0.85, 0.15)
@export var visual_size: float = 58.0
@export var held_sprite: Texture2D
@export var upright_at_rest: bool = false
@export_range(0.08, 0.8) var animation_duration: float = 0.32
@export_range(0.0, 0.3) var working_head_radius: float = 0.0
@export var working_head_texture: Texture2D
@export var working_head_aspect: float = 0.65
@export var working_head_angle_degrees: float = -25.0
@export var head_turns_per_second: float = 5.0
@export var pull_texture: Texture2D
@export var fork_left_anchor: Vector2 = Vector2(0.23, 0.20)
@export var fork_right_anchor: Vector2 = Vector2(0.77, 0.20)
@export var pouch_anchor: Vector2 = Vector2(0.5, 0.38)
@export var pouch_width: float = 0.24


func held_texture() -> Texture2D:
	return held_sprite if held_sprite != null else sprite


func roots_text() -> String:
	return "%d %s" % [hands, "Wurzel" if hands == 1 else "Wurzeln"]


func damage_at_tier(tier: int) -> float:
	if damage_tiers.size() >= clampi(tier, 1, 4):
		return base_damage * damage_tiers[clampi(tier, 1, 4) - 1]
	return base_damage * pow(1.38, clampi(tier, 1, 4) - 1)


func interval_at_tier(tier: int) -> float:
	return interval * pow(0.94, clampi(tier, 1, 4) - 1)


func raw_damage_with_stats(tier: int, stats: PlayerStats) -> float:
	var flat := stats.melee_damage if damage_stat == "melee" else stats.ranged_damage
	return maxf(damage_at_tier(tier) + flat * stat_scaling, 0.0)


func damage_with_stats(tier: int, stats: PlayerStats, additional_bonus: float = 0.0) -> float:
	return stats.scale_damage(raw_damage_with_stats(tier, stats), additional_bonus)


func scaling_text() -> String:
	return "%s: %.0f %%" % ["Nahschaden" if damage_stat == "melee" else "Fernschaden", stat_scaling * 100.0]


func cooldown_at_tier(tier: int, player_interval: float, item_interval_factor: float) -> float:
	return maxf(interval_at_tier(tier) * player_interval / PlayerStats.BASE_ATTACK_INTERVAL * item_interval_factor, MIN_ATTACK_COOLDOWN)


func range_at_tier(tier: int) -> float:
	return range_tiers[clampi(tier, 1, 4) - 1] if range_tiers.size() >= clampi(tier, 1, 4) else attack_range


func projectile_count_at_tier(tier: int) -> int:
	return projectile_count_tiers[clampi(tier, 1, 4) - 1] if projectile_count_tiers.size() >= clampi(tier, 1, 4) else projectile_count


func pierce_at_tier(tier: int) -> int:
	return pierce_tiers[clampi(tier, 1, 4) - 1] if pierce_tiers.size() >= clampi(tier, 1, 4) else pierce


func splash_at_tier(tier: int) -> float:
	return splash_tiers[clampi(tier, 1, 4) - 1] if splash_tiers.size() >= clampi(tier, 1, 4) else splash_radius


func knockback_at_tier(tier: int) -> float:
	return knockback_tiers[clampi(tier, 1, 4) - 1] if knockback_tiers.size() >= clampi(tier, 1, 4) else knockback


func stats_text(tier: int) -> String:
	var result := "%d Basis-Schaden · %.2f s · %d Reichweite" % [roundi(damage_at_tier(tier)), interval_at_tier(tier), roundi(range_at_tier(tier))]
	if projectile_count_tiers.size() > 0:
		var count := projectile_count_at_tier(tier)
		result += " · %d %s" % [count, "Geschoss" if count == 1 else "Geschosse"]
	if pierce_tiers.size() > 0:
		result += " · %d Durchschlag" % pierce_at_tier(tier)
	if splash_radius > 0.0 or splash_tiers.size() > 0:
		result += " · %d Explosionsradius" % roundi(splash_at_tier(tier))
	if boss_bonus_tiers.size() > 0:
		result += " · +%d %% Boss" % roundi(boss_bonus_tiers[clampi(tier, 1, 4) - 1] * 100.0)
	return result


func combat_text() -> String:
	var result := "Schadensart: %s · %s" % [damage_type, scaling_text()]
	if bleed_dps > 0.0:
		result += " · Blutung %.1f Schaden/s (%.1f s)" % [bleed_dps, bleed_duration]
	if wet_duration > 0.0:
		result += " · Nass %.1f s" % wet_duration
	if crit_bonus > 0.0 or crit_multiplier > 1.5:
		result += " · +%d %% Waffen-Crit · ×%.1f Crit" % [roundi(crit_bonus * 100.0), crit_multiplier]
	if focus_cap > 0.0:
		result += " · Ziel-Fokus bis +%d %%" % roundi(focus_cap * 100.0)
	if crit_cycle > 0:
		result += " · Jeder %d. Treffer auf dasselbe Ziel kritisch" % crit_cycle
	if enamel_exposure > 0.0:
		result += " · +%d %% Schmelzschaden für %.1f s (nicht stapelbar)" % [roundi(enamel_exposure * 100.0), exposure_duration]
	if trash_damage_factor < 1.0:
		result += " · %d %% Schaden gegen normale Gegner" % roundi(trash_damage_factor * 100.0)
	if elite_damage_bonus > 0.0:
		result += " · +%d %% gegen Eliten" % roundi(elite_damage_bonus * 100.0)
	if attack_mode in [&"thrust", &"beam_line"]:
		result += " · Durchgehende Trefferlinie"
	if attack_mode in [&"cone", &"sweep"]:
		result += " · %d° Frontbogen" % roundi(arc_degrees)
	return result


func estimated_dps(tier: int, stats: PlayerStats, item_interval_factor: float = 1.0, additional_bonus: float = 0.0) -> float:
	var chance := clampf(stats.crit_chance + crit_bonus, 0.0, 1.0)
	if crit_cycle > 0:
		chance = 1.0 / float(crit_cycle) + (1.0 - 1.0 / float(crit_cycle)) * chance
	var raw := raw_damage_with_stats(tier, stats)
	var normal_hit := maxf(stats.scale_damage(raw, additional_bonus) * trash_damage_factor, 1.0)
	var critical_hit := maxf(stats.scale_damage(raw * crit_multiplier, additional_bonus) * trash_damage_factor, 1.0)
	var hit := normal_hit * (1.0 - chance) + critical_hit * chance
	var cooldown := cooldown_at_tier(tier, stats.attack_interval, item_interval_factor)
	return hit * (1.0 + 0.55 * float(projectile_count_at_tier(tier) - 1)) / cooldown


func damage_against(enemy: Node2D, attack_damage: float, tier: int = 1) -> float:
	var enemy_data: EnemyData = enemy.get("data") as EnemyData
	var result := attack_damage
	if not enemy_data.is_boss and not enemy_data.is_elite:
		result *= trash_damage_factor
	if enemy_data.is_elite:
		result *= 1.0 + elite_damage_bonus
	if damage_type == "Schmelz" and float(enemy.get("exposure_time")) > 0.0:
		result *= 1.0 + float(enemy.get("enamel_exposure"))
	if damage_type == "Bohrung" and enemy_data.is_boss:
		var bonus := boss_bonus_tiers[clampi(tier, 1, 4) - 1] if boss_bonus_tiers.size() >= clampi(tier, 1, 4) else 0.25
		return result * (1.0 + bonus)
	if damage_type == "Schnitt" and float(enemy.get("health")) >= float(enemy.get("max_health")) * 0.95:
		return result * 1.15
	return result
