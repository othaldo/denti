class_name WeaponData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var hands: int = 1
@export var attack_mode: StringName = &"projectile"
@export var damage_type: String = "Schmelz"
@export var base_damage: float = 18.0
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


func damage_at_tier(tier: int) -> float:
	if damage_tiers.size() >= clampi(tier, 1, 4):
		return base_damage * damage_tiers[clampi(tier, 1, 4) - 1]
	return base_damage * pow(1.38, clampi(tier, 1, 4) - 1)


func interval_at_tier(tier: int) -> float:
	return interval * pow(0.94, clampi(tier, 1, 4) - 1)


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
	elif pierce_tiers.size() > 0:
		result += " · %d Durchschlag" % pierce_at_tier(tier)
	elif splash_tiers.size() > 0:
		result += " · %d Explosionsradius" % roundi(splash_at_tier(tier))
	elif boss_bonus_tiers.size() > 0:
		result += " · +%d %% Boss" % roundi(boss_bonus_tiers[clampi(tier, 1, 4) - 1] * 100.0)
	return result


func estimated_dps(tier: int, player_damage: float, crit_chance: float, attack_interval: float, item_interval_factor: float) -> float:
	var hit := player_damage * damage_at_tier(tier) / 18.0 * (1.0 + crit_chance * 0.5)
	var cooldown := interval_at_tier(tier) * attack_interval / 0.65 * item_interval_factor
	return hit * (1.0 + 0.55 * float(projectile_count_at_tier(tier) - 1)) / maxf(cooldown, 0.01)


func damage_against(enemy: Node2D, attack_damage: float, tier: int = 1) -> float:
	var enemy_data: EnemyData = enemy.get("data") as EnemyData
	if damage_type == "Bohrung" and enemy_data.is_boss:
		var bonus := boss_bonus_tiers[clampi(tier, 1, 4) - 1] if boss_bonus_tiers.size() >= clampi(tier, 1, 4) else 0.25
		return attack_damage * (1.0 + bonus)
	if damage_type == "Schnitt" and float(enemy.get("health")) >= float(enemy.get("max_health")) * 0.95:
		return attack_damage * 1.15
	return attack_damage
