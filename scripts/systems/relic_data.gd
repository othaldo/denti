class_name RelicData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(0, 5) var icon_index: int = 0
@export var tags: Array[StringName] = []

