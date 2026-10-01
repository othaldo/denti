class_name BossEncounter
extends RefCounted

# The scene owns the bosses. Do not keep a second, unsaved ownership list.
static func remaining(enemies: Node, include_dying: bool = true) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child in enemies.get_children():
		if child is Enemy and child.data.is_boss and not child.is_queued_for_deletion() and (include_dying or not child.dying):
			result.append(child)
	return result

static func primary(enemies: Node) -> Enemy:
	var bosses := remaining(enemies)
	for enemy in bosses:
		if not enemy.dying:
			return enemy
	return bosses[0] if not bosses.is_empty() else null
