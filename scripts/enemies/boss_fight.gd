class_name BossFight
extends Node2D

## Shared interface between an Enemy and the scripted fight that drives it.
## Enemy talks only to these hooks; each boss overrides the ones it needs.

var enemy: Enemy


## Runs the boss's movement and attacks instead of the generic special attack.
func advance(_delta: float) -> void:
	pass


## Stops attacks and warnings, e.g. when the boss dies.
func cancel() -> void:
	pass


## Contact damage is suppressed while a trial or ritual is running.
func blocks_contact() -> bool:
	return false


## The boss is currently untargetable.
func blocks_damage() -> bool:
	return false


## Body contact counts as a charge hit (attack damage instead of contact damage).
func charging() -> bool:
	return false


## A vulnerability window in which damage bypasses the normal boss guard.
func opening_open() -> bool:
	return false


## Scales and caps incoming damage before guard and phase floors apply.
func modify_damage(applied: float, _incoming: Vector2, _proc_id: StringName, _opening: bool) -> float:
	return applied


## Consumes damage dealt during an open vulnerability window.
func spend_opening(_counted: float, _proc_id: StringName) -> void:
	pass


func guard_recharge_factor() -> float:
	return 1.0


## A new health phase interrupts the running attack.
func begin_health_phase() -> void:
	cancel()


## Summoned helpers that the HUD lists beside the boss bar.
func live_minions() -> Array[Enemy]:
	return []
