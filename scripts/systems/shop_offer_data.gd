class_name ShopOfferData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: String = "Gewöhnlich"
@export var price: int = 3
@export var stat_changes: Dictionary = {}
@export var weapon_scene: PackedScene
