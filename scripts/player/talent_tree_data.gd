class_name TalentTreeData
extends Resource

@export var branches: PackedStringArray = ["", ""]
@export var nodes: Array[TalentNodeData] = []

func by_id(id: StringName) -> TalentNodeData:
	for node in nodes:
		if node != null and node.id == id: return node
	return null

func valid() -> bool:
	if branches.size() != 2 or nodes.is_empty(): return false
	var ids: Array[StringName] = []
	for node in nodes:
		if node == null or not node.valid() or node.id in ids: return false
		ids.append(node.id)
	for node in nodes:
		if node.parent != &"" and (by_id(node.parent) == null or by_id(node.parent).max_ranks < node.parent_rank): return false
		var path: Array[StringName] = [node.id]
		var parent := node.parent
		while parent != &"":
			var previous := by_id(parent)
			if previous == null or parent in path: return false
			path.append(parent)
			parent = previous.parent
	return true
