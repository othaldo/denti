extends Player
## Only input is replaced. Movement, collisions, floor slows and hit frames run normally.

var probe_direction := Vector2.ZERO


func movement_direction() -> Vector2:
	return probe_direction
