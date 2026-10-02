class_name ShopOfferData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(1, 5) var rarity_tier: int = 1
@export_range(1, 4) var weapon_tier: int = 1
@export var price: int = 3
@export_range(0, 85) var icon_index: int = 0
@export var stat_changes: Dictionary = {}
@export var weapon_data: WeaponData
@export var icon_texture: Texture2D
@export var effect_kind: StringName = &""
@export var effect_value: float = 0.0
@export_range(0, 9) var max_stacks: int = 0
@export var tags: Array[StringName] = []
@export var family_id: StringName = &""
@export_range(0, 9) var family_limit: int = 0


func effect_text() -> String:
	return DentiAttributes.resolve_text(description)


func limit_text() -> String:
	if rarity_tier == 5:
		return "Einmalig pro Run"
	if family_id != &"" and family_limit > 0:
		return "Familienlimit: %d · alle Seltenheiten zusammen" % family_limit
	return "Stapellimit: %d" % max_stacks if max_stacks > 0 else "Unbegrenzt stapelbar"
