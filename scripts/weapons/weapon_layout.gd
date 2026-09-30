class_name WeaponLayout
extends RefCounted

# Shared proportions for the ~70 px player body; independent of atlas resolution.
const MAX_CONTACT_SIZE := 100.0
const MAX_RANGED_SIZE := 76.0
const HAND_RADIUS := 50.0
const ROW_SPACING := 28.0
const CROWD_SCALE := 0.88


static func density_scale(count: int) -> float:
	return lerpf(1.0, CROWD_SCALE, clampf(float(count - 2) / 4.0, 0.0, 1.0))


static func home(index: int, count: int) -> Vector2:
	var row := index / 2
	var side := 1.0 if index % 2 == 0 else -1.0
	var rows := ceili(float(count) / 2.0)
	var y := 16.0 + float(rows - 1) * 7.0 - row * ROW_SPACING
	return Vector2(side * (HAND_RADIUS + (8.0 if row == 1 else 0.0)), y)


static func is_contact(data: WeaponData) -> bool:
	return data.attack_mode in [&"melee", &"area", &"thrust", &"sweep"]


static func phase(index: int, count: int) -> float:
	return float(index) / float(maxi(count, 1)) * 0.75


static func visual_size(data: WeaponData, density: float = 1.0) -> float:
	var limit := MAX_CONTACT_SIZE if is_contact(data) else MAX_RANGED_SIZE
	return minf(data.visual_size, limit) * density
