class_name RelicData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
## Cell in the painted relic atlases: 0-5 original relics, 6+ the expansion atlas.
@export_range(0, 17) var icon_index: int = 0
@export var tags: Array[StringName] = []
## Placeholder item icon while the expansion atlas cell is not painted yet.
@export var placeholder_item_icon: int = -1
