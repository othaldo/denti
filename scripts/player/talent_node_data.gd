class_name TalentNodeData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var branch: int = 0
@export var parent: StringName
@export var parent_rank: int = 1
@export var max_ranks: int = 1
@export var cost: int = 1
@export var exclusive_group: StringName
@export var stat_changes: Dictionary = {}
@export var effects: Dictionary = {}
@export var icon_index: int = 0

func valid() -> bool:
	if id == &"" or display_name.is_empty() or branch not in [0, 1] or max_ranks < 1 or cost < 1 or parent_rank < 1: return false
	for key in stat_changes:
		if StringName(str(key)) not in PlayerStatKeys.ALL: return false
		if not (stat_changes[key] is float or stat_changes[key] is int) or not is_finite(float(stat_changes[key])): return false
	for value in effects.values():
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0: return false
	return true
