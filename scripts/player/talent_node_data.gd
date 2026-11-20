class_name TalentNodeData
extends Resource

## One cell of a WoW-style talent grid. A node with `stat` set is a small
## attribute path node: each rank grants that attribute with the earned
## level's rolled rarity, exactly like the former stat cards. Every other node
## is a talent that changes the class verb via `effects`/`stat_changes`.

const BRANCHES := 3
const COLUMNS := 3
const ROWS := 6

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var branch: int = 0
@export var row: int = 0
@export var column: int = 1
@export var stat: StringName
## PoE2-style travel node: the attribute is chosen when the point is spent.
@export var free_attribute := false
## Optional arrow prerequisite inside the same branch (D2/WoW style).
@export var parent: StringName
@export var parent_rank: int = 1
@export var max_ranks: int = 1
@export var cost: int = 1
@export var exclusive_group: StringName
@export var stat_changes: Dictionary = {}
@export var effects: Dictionary = {}
@export var icon_index: int = -1

func is_attribute() -> bool:
	return stat != &"" or free_attribute

func valid() -> bool:
	if id == &"" or max_ranks < 1 or cost < 1 or parent_rank < 1: return false
	if branch < 0 or branch >= BRANCHES or row < 0 or row >= ROWS or column < 0 or column >= COLUMNS: return false
	if free_attribute and stat != &"": return false
	if is_attribute():
		if (not free_attribute and stat not in PlayerStatKeys.ALL) or cost != 1 or not stat_changes.is_empty() or not effects.is_empty(): return false
	elif display_name.is_empty():
		return false
	for key in stat_changes:
		if StringName(str(key)) not in PlayerStatKeys.ALL: return false
		if not (stat_changes[key] is float or stat_changes[key] is int) or not is_finite(float(stat_changes[key])): return false
	for value in effects.values():
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0: return false
	return true
