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
@export var sprite: Texture2D
@export var grip_anchor: Vector2 = Vector2(0.25, 0.85)
@export var projectile_color: Color = Color(0.75, 0.96, 1.0)
@export var visual_angle_degrees: float = 45.0
@export var price: int = 8


func damage_at_tier(tier: int) -> float:
	return base_damage * pow(1.38, clampi(tier, 1, 4) - 1)


func interval_at_tier(tier: int) -> float:
	return interval * pow(0.94, clampi(tier, 1, 4) - 1)


func stats_text(tier: int) -> String:
	return "%d Basis-Schaden · %.2f s · %d Reichweite" % [roundi(damage_at_tier(tier)), interval_at_tier(tier), roundi(attack_range)]


func damage_against(enemy: Node2D, attack_damage: float) -> float:
	var enemy_data: EnemyData = enemy.get("data") as EnemyData
	if damage_type == "Bohrung" and enemy_data.is_boss:
		return attack_damage * 1.25
	if damage_type == "Schnitt" and float(enemy.get("health")) >= float(enemy.get("max_health")) * 0.95:
		return attack_damage * 1.15
	return attack_damage
