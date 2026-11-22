class_name WeaponLayout
extends RefCounted

# Shared proportions for the ~70 px player body; independent of atlas resolution.
const MAX_CONTACT_SIZE := 100.0
const MAX_RANGED_SIZE := 76.0
const HAND_RADIUS := 50.0
## Minimum arc between neighbouring roots before the ring widens for large classes.
const ROOT_SPACING := 30.0
const CROWD_SCALE := 0.88


static func density_scale(count: int) -> float:
	return lerpf(1.0, CROWD_SCALE, clampf(float(count - 2) / 4.0, 0.0, 1.0))


static func ring_radius(capacity: int) -> float:
	return maxf(HAND_RADIUS, ROOT_SPACING * float(maxi(capacity, 1)) / TAU)


## Angle of the first root. Roots form a regular polygon around Denti, start at
## the right-hand side and continue clockwise. Rings whose corner would sit
## directly on top of Denti's head are turned half a step instead.
static func start_angle(capacity: int) -> float:
	var count := maxi(capacity, 1)
	return -PI / float(count) if count % 4 == 0 else 0.0


## Fixed anchor of one root relative to Denti. Root positions never depend on
## how many weapons are equipped, only on the class's root capacity.
static func root_position(root: int, capacity: int) -> Vector2:
	return anchor(root, 1, capacity)


## Grip anchor of a weapon occupying `hands` neighbouring roots from `root`.
## Two-root weapons sit on the ring halfway between both corners.
static func anchor(root: int, hands: int, capacity: int) -> Vector2:
	var count := maxi(capacity, 1)
	var middle := float(root) + float(maxi(hands, 1) - 1) * 0.5
	return Vector2.from_angle(start_angle(count) + middle * TAU / float(count)) * ring_radius(count)


static func is_contact(data: WeaponData) -> bool:
	return data.attack_mode in [&"melee", &"area", &"thrust", &"sweep"]


static func phase(index: int, count: int) -> float:
	return float(index) / float(maxi(count, 1)) * 0.75


static func visual_size(data: WeaponData, density: float = 1.0) -> float:
	var limit := MAX_CONTACT_SIZE if is_contact(data) else MAX_RANGED_SIZE
	return minf(data.visual_size, limit) * density
