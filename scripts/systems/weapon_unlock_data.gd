class_name WeaponUnlockData
extends Resource
## A standard weapon that starts locked. Any listed source weapon holding the
## required mastery seal unlocks it; no separate progress is stored.

@export var weapon_id: StringName
@export var source_ids: Array[StringName] = []
@export var mastery_id: StringName = &"exam"
