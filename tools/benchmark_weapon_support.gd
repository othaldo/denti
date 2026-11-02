extends "res://tools/benchmark_weapon_roster.gd"
## Same boss route for every two-root replacement; weapon choice cannot steer it.
const SUPPORT_REACH := 225.0


func movement_direction(game, movement: String, elapsed: float) -> Vector2:
	if movement != "pursuit": return super.movement_direction(game, movement, elapsed)
	var target: Enemy = game.boss if is_instance_valid(game.boss) and game.boss.health > 0 else null
	if target == null: return Vector2.ZERO
	var offset: Vector2 = target.global_position - game.player.global_position
	var inward := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	var radial := clampf((offset.length() - target.data.radius - SUPPORT_REACH * 0.75) / 100.0, -1.0, 1.0)
	return (inward * radial + inward.orthogonal() * 0.65).normalized()
