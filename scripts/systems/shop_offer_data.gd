class_name ShopOfferData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: String = "Gewöhnlich"
@export var price: int = 3
@export_range(0, 11) var icon_index: int = 0
@export var stat_changes: Dictionary = {}
@export var weapon_data: WeaponData
@export var icon_texture: Texture2D
