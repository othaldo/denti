class_name BossMinion
extends Node2D

## Shared interface between an Enemy and the boss lieutenant role it plays.
## The owning boss fight advances the clock; Enemy only uses these hooks.

## Distance the minion keeps from the outer arena edge while repositioning.
const ARENA_MARGIN := 60.0

var enemy: Enemy
## Damage the minion may still take before its guard needs to recharge.
var budget := 0.0


func advance(_delta: float) -> void:
	pass


## The boss interrupts the minion's current attack, e.g. at a phase change.
func pause_attack() -> void:
	pass


func limit(amount: float) -> float:
	return minf(amount, budget)


func spend(amount: float) -> void:
	budget = maxf(budget - amount, 0)


## Lieutenants can be hit while their boss is alive.
func targetable() -> bool:
	var owner := enemy.boss_objective_owner
	return is_instance_valid(owner) and owner.health > 0


func save_data() -> Dictionary:
	return {}


func restore(_saved: Dictionary) -> void:
	pass


## Clamps `at` into the boss's framing `view` and away from the arena walls.
func bounded_to(at: Vector2, view: Rect2) -> Vector2:
	var bounds := view.intersection(enemy.target.arena.inner_rect(ARENA_MARGIN))
	return at.clamp(bounds.position, bounds.end)
