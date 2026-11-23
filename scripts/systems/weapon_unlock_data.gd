class_name WeaponUnlockData
extends Resource
## A standard weapon that starts locked. It opens either when a lifetime
## counter (MetaCounters.KEYS) reaches `amount`, or after the first wave-20
## victory with `class_victory`. Never depends on another locked weapon.

@export var weapon_id: StringName
## Lifetime counter key such as &"kills"; empty when a class victory is needed.
@export var counter: StringName = &""
@export var amount := 0
## Class whose first wave-20 victory opens the weapon.
@export var class_victory: StringName = &""
