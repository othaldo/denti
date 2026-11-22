class_name RelicData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(0, 5) var icon_index: int = 0
@export var tags: Array[StringName] = []
## Class relics are only offered to this class; empty = every class.
@export var class_id: StringName = &""
## Placeholder: a class talent icon until the relic atlas has painted cells
## for the class relics. -1 uses `icon_index` in the relic atlas.
@export var talent_icon: int = -1
