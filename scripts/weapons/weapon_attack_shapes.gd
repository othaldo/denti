class_name WeaponAttackShapes
extends RefCounted


static func contains(weapon: WeaponData, tier: int, origin: Vector2, direction: Vector2, target: Vector2, radius: float) -> bool:
	var offset := target - origin
	var reach := weapon.range_at_tier(tier)
	if offset.length_squared() > (reach + radius) * (reach + radius):
		return false
	match weapon.attack_mode:
		&"thrust", &"beam_line":
			var closest := Geometry2D.get_closest_point_to_segment(target, origin, origin + direction * reach)
			var hit_radius := weapon.attack_width * 0.5 + radius
			return closest.distance_squared_to(target) <= hit_radius * hit_radius
		&"cone", &"sweep":
			# Include enemy circles touching a cone edge; large bosses stay hittable.
			var distance := offset.length()
			if distance <= radius:
				return true
			var allowance := asin(clampf(radius / distance, 0.0, 1.0))
			return absf(direction.angle_to(offset)) <= deg_to_rad(weapon.arc_degrees * 0.5) + allowance
	return true


static func hit(enemy: Enemy, weapon: WeaponData, tier: int, damage: float, critical: bool, items: ItemInventory, direction: Vector2) -> void:
	if enemy.health <= 0.0:
		return
	var value := items.modify_damage(enemy, weapon, damage) if items != null else damage
	enemy.take_damage(weapon.damage_against(enemy, value, tier), weapon, critical)
	if enemy.health > 0.0:
		var push := weapon.knockback_at_tier(tier) * (1.0 - enemy.data.knockback_resistance)
		enemy.global_position += direction * push
