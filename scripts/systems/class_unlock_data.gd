class_name ClassUnlockData
extends Resource
## A class opens when a run ends (death or victory) with at least `min_wave`
## reached while Denti carries a weapon of one of `elements`: its damage type
## (water, light) or an element enchantment (fire, ice, poison, bleed, electric, water).

@export var class_id: StringName
@export var elements: Array[StringName] = []
@export var min_wave := 10
@export var victory := false
## Minimum difficulty id for victory rules; empty = any.
@export var min_difficulty: StringName = &""
