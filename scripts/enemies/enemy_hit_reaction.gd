class_name EnemyHitReaction
extends RefCounted
## Cosmetic hit punch for an enemy sprite: a quick squash in the hit direction,
## a short recoil and one small overshoot. No nodes, no gameplay effect.

const DURATION := 0.16
## Squash at full strength; 0.24 compresses the sprite by about a quarter along the hit.
const SQUASH := 0.24
## Recoil as a fraction of the enemy radius, so large and small enemies match.
const RECOIL := 0.2
## Hits worth this share of maximum health or more play at full strength.
const FULL_SHARE := 0.25
const MIN_STRENGTH := 0.35
const CRITICAL_BONUS := 1.3
## Damage over time and other indirect procs only nudge the sprite.
const INDIRECT_FACTOR := 0.45
const BOSS_FACTOR := 0.35
const ELITE_FACTOR := 0.65

var time := 0.0
var strength := 0.0
var direction := Vector2.RIGHT


func register(share: float, critical: bool, indirect: bool, hit_direction: Vector2, size_factor: float = 1.0) -> void:
	var value := lerpf(MIN_STRENGTH, 1.0, clampf(share / FULL_SHARE, 0.0, 1.0))
	if critical: value *= CRITICAL_BONUS
	if indirect: value *= INDIRECT_FACTOR
	value = minf(value * size_factor, CRITICAL_BONUS)
	# Constant fire keeps a lively wobble instead of freezing on frame one:
	# a weaker hit only restarts once the previous punch has mostly played.
	if active() and value < strength and time > DURATION * 0.45:
		return
	strength = value
	time = DURATION
	if hit_direction.is_finite() and not hit_direction.is_zero_approx():
		direction = hit_direction.normalized()


func active() -> bool:
	return time > 0.0


func advance(delta: float) -> void:
	time = maxf(time - delta, 0.0)


func clear() -> void:
	time = 0.0


## Fraction of the punch already played, 0 at the hit and 1 at rest.
func progress() -> float:
	return 1.0 - time / DURATION


## Signed squash: positive compresses along the hit, negative overshoots.
func squash() -> float:
	var played := progress()
	return strength * SQUASH * cos(played * PI * 1.5) * (1.0 - played)


func scale_factor() -> Vector2:
	var amount := squash()
	var along := direction.abs()
	# Axis-aligned approximation of a squash along the hit: the sprite keeps its
	# upright bob/rotation and the area stays roughly constant.
	return Vector2(1.0 - amount * along.x + amount * 0.5 * along.y, 1.0 - amount * along.y + amount * 0.5 * along.x)


func offset(radius: float) -> Vector2:
	var remaining := 1.0 - progress()
	return direction * radius * RECOIL * strength * remaining * remaining
