class_name TalentTreeData
extends Resource

## Three branches side by side. Row N of a branch opens once N ×
## `points_per_row` points are invested in that branch, attribute path nodes
## included, so attributes are the way into deeper talents.

@export var branches: PackedStringArray = ["", "", ""]
@export var points_per_row := 3
@export var nodes: Array[TalentNodeData] = []

func by_id(id: StringName) -> TalentNodeData:
	for node in nodes:
		if node != null and node.id == id: return node
	return null

func branch_nodes(branch: int) -> Array[TalentNodeData]:
	var result: Array[TalentNodeData] = []
	for node in nodes:
		if node.branch == branch: result.append(node)
	return result

func row_requirement(row: int) -> int:
	return row * points_per_row

func branch_points(ranks: Dictionary, branch: int) -> int:
	var total := 0
	for node in nodes:
		if node.branch == branch: total += node.cost * int(ranks.get(str(node.id), 0))
	return total

func rows(branch: int) -> int:
	var last := -1
	for node in nodes:
		if node.branch == branch: last = maxi(last, node.row)
	return last + 1

func capacity() -> int:
	var total := 0
	for node in nodes: total += node.cost * node.max_ranks
	return total

func valid() -> bool:
	if branches.size() != TalentNodeData.BRANCHES or nodes.is_empty() or points_per_row < 1: return false
	var ids: Array[StringName] = []
	var cells := {}
	for node in nodes:
		if node == null or not node.valid() or node.id in ids: return false
		ids.append(node.id)
		var cell := Vector3i(node.branch, node.row, node.column)
		if cells.has(cell): return false
		cells[cell] = true
	for node in nodes:
		if node.parent == &"": continue
		var previous := by_id(node.parent)
		# Arrows point downward inside one branch, so no cycles are possible.
		if previous == null or previous.max_ranks < node.parent_rank or previous.branch != node.branch or previous.row >= node.row: return false
	for branch in TalentNodeData.BRANCHES:
		var opening := false
		for node in branch_nodes(branch):
			if node.row == 0: opening = true
		if not opening: return false
	return true
