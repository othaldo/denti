class_name ElementReactionData
extends Resource

@export var id: StringName
@export var display_name: String
@export var elements: Array[StringName] = []
@export var power_element: StringName
@export var damage_element: StringName
@export var damage_factor: float = 0.0
@export var radius: float = 0.0
@export var targets: int = 0
@export var include_source: bool = true
@export var cooldown: float = 1.0
