class_name CloakStrikeData
extends Resource
## Shape and pose of a single announced cloak strike.

enum Kind { FAN, THRUST, RING }
@export var kind := Kind.FAN
@export var reach := 340.0
@export var inner_radius := 0.0
@export var half_angle_degrees := 40.0
@export var edge_half_angle_degrees := 22.0

func half_angle(near_wall: bool) -> float:
	return deg_to_rad(edge_half_angle_degrees if near_wall else half_angle_degrees)

func placement_distance(angle: float) -> float:
	if kind == Kind.RING: return (inner_radius + reach) * 0.5
	return reach / (1.0 + sin(angle))
