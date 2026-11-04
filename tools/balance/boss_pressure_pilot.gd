extends "res://tools/balance/bots/pilot_brain.gd"
## Objective knowledge is explicit; only the inherited delayed sensor avoids attacks.
var target := Vector2.ZERO
var stopping_distance := 140.0
var circle_target := true

func goal_direction(world: Dictionary) -> Vector2:
	var offset := target - Vector2(world.position)
	var inward := offset.normalized()
	var radial := clampf((offset.length() - stopping_distance) / 45.0, -1, 1)
	return (inward * radial + inward.orthogonal() * (0.4 if circle_target else 0.0)).limit_length(1)
