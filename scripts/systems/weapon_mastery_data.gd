class_name WeaponMasteryData
extends Resource

@export var id: StringName
@export var flag: int = 1
@export var display_name: String
@export var requirement: String
@export var minimum_difficulty: StringName = &"easy"
@export var requires_victory := false
@export var boss_wave := 5
@export var icon_index := 0
