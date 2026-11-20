class_name TalentProgression
extends RefCounted

const VERSION := 1
var enabled := false
var spent := 0
var ranks: Dictionary = {}
# Offers are rolled once for the queued earned levels, never on Undo/resume.
var tiers: Array[int] = []
var actions: Array[Dictionary] = []
var cursor: Dictionary = {}

func prepare(count: int, first_level: int, luck: float) -> void:
	while tiers.size() < count:
		tiers.append(DentiRarity.upgrade_tier(first_level + tiers.size(), luck))

func used(tree: TalentTreeData) -> int:
	var total := 0
	for action in actions:
		var node := tree.by_id(StringName(action.id)) if action.kind == "talent" else null
		total += node.cost if node != null else 1
	return total

func draft_ranks() -> Dictionary:
	var result := ranks.duplicate()
	for action in actions:
		if action.kind == "talent": result[action.id] = int(result.get(action.id, 0)) + 1
	return result

static func template_for(upgrades: Array[UpgradeData], key: StringName) -> UpgradeData:
	for upgrade in upgrades:
		if upgrade.stat == key: return upgrade
	return null

func _reason(node: TalentNodeData, tree: TalentTreeData, current: Dictionary) -> String:
	if node == null: return "Unbekanntes Talent"
	if int(current.get(str(node.id), 0)) >= node.max_ranks: return "Ausgebaut"
	var needed := tree.row_requirement(node.row)
	if tree.branch_points(current, node.branch) < needed:
		return "%d Punkte in %s benötigt" % [needed, tree.branches[node.branch]]
	if node.parent != &"" and int(current.get(str(node.parent), 0)) < node.parent_rank:
		return "%s · Rang %d benötigt" % [tree.by_id(node.parent).display_name, node.parent_rank]
	if node.exclusive_group != &"":
		for other in tree.nodes:
			if other.id != node.id and other.exclusive_group == node.exclusive_group and int(current.get(str(other.id), 0)) > 0:
				return "Abschlussweg bereits gewählt"
	return ""

## Row gate and arrow satisfied; ignores free points and attribute limits.
func structurally_open(id: StringName, tree: TalentTreeData) -> bool:
	return _reason(tree.by_id(id), tree, draft_ranks()).is_empty()

func reason(id: StringName, stats: PlayerStats, upgrades: Array[UpgradeData], count: int) -> String:
	var tree := stats.class_data.talent_tree
	if tree == null: return "Kein Talentbaum"
	var node := tree.by_id(id)
	var blocked := _reason(node, tree, draft_ranks())
	if not blocked.is_empty(): return blocked
	if used(tree) + node.cost > count: return "Keine freien Levelpunkte"
	if node.free_attribute:
		return "" if not free_choices(stats, upgrades).is_empty() else "Attributgrenze erreicht"
	if node.is_attribute():
		return "" if attribute_choice(node, stats, upgrades) != null else "Attributgrenze erreicht"
	var preview := preview_stats(stats, upgrades)
	var useful := not node.effects.is_empty()
	for key in node.stat_changes:
		useful = useful or preview.upgrade_has_effect(StringName(key), float(node.stat_changes[key]))
	preview.free()
	return "" if useful else "Attributgrenze erreicht"

## `stat` is required for free attribute nodes and ignored otherwise.
func plan_talent(id: StringName, stats: PlayerStats, upgrades: Array[UpgradeData], count: int, stat: StringName = &"") -> bool:
	if not enabled or not reason(id, stats, upgrades, count).is_empty(): return false
	var node := stats.class_data.talent_tree.by_id(id)
	if node.free_attribute:
		if stat not in free_choices(stats, upgrades): return false
		actions.append({"kind": "talent", "id": str(id), "stat": str(stat)})
		return true
	actions.append({"kind": "talent", "id": str(id)})
	return true

## Attributes a free node may grant right now: every class-usable level-up
## attribute that would still have an effect at the next point's grade.
func free_choices(stats: PlayerStats, upgrades: Array[UpgradeData]) -> Array[StringName]:
	var result: Array[StringName] = []
	for upgrade in upgrades:
		if not class_allows(upgrade.stat, stats.class_data): continue
		if stat_choice(upgrade.stat, stats, upgrades) != null: result.append(upgrade.stat)
	return result

static func class_allows(key: StringName, profile: PlayerClassData) -> bool:
	return not (key == &"ranged_damage" and profile.allowed_weapon_roles == [&"contact"])

## The attribute a path node would grant with the next unspent level's grade.
func attribute_choice(node: TalentNodeData, stats: PlayerStats, upgrades: Array[UpgradeData]) -> UpgradeData:
	return stat_choice(node.stat, stats, upgrades) if node != null and node.is_attribute() and not node.free_attribute else null

func stat_choice(key: StringName, stats: PlayerStats, upgrades: Array[UpgradeData]) -> UpgradeData:
	var tree := stats.class_data.talent_tree
	var index := used(tree)
	if index >= tiers.size(): return null
	var template := template_for(upgrades, key)
	if template == null: return null
	var preview := preview_stats(stats, upgrades)
	var choice := template.with_tier(tiers[index]).with_stat_context(preview)
	var useful := preview.upgrade_has_effect(key, choice.amount)
	preview.free()
	return choice if useful else null

# Legacy drafts from the former separate attribute tab; the tree UI no longer offers this.
func plan_stat(key: StringName, stats: PlayerStats, upgrades: Array[UpgradeData], count: int) -> bool:
	if key == &"ranged_damage" and stats.class_data.allowed_weapon_roles == [&"contact"]: return false
	if not enabled or used(stats.class_data.talent_tree) >= count or stat_choice(key, stats, upgrades) == null: return false
	actions.append({"kind": "stat", "id": str(key)})
	return true

func undo() -> void:
	if not actions.is_empty(): actions.pop_back()

func preview_stats(stats: PlayerStats, upgrades: Array[UpgradeData]) -> PlayerStats:
	var preview := PlayerStats.new()
	preview.load_save_data(stats.to_save_data(), stats.class_save_data())
	var index := 0
	for action in actions:
		index += _apply(action, preview, upgrades, index)
	return preview

func _apply(action: Dictionary, stats: PlayerStats, upgrades: Array[UpgradeData], index: int) -> int:
	if action.kind == "stat":
		var template := template_for(upgrades, StringName(action.id))
		if template == null or index >= tiers.size(): return 0
		var choice := template.with_tier(tiers[index]).with_stat_context(stats)
		stats.apply_upgrade(choice.stat, choice.amount)
		return 1
	var node := stats.class_data.talent_tree.by_id(StringName(action.id))
	if node == null: return 0
	if node.is_attribute():
		var template := template_for(upgrades, StringName(str(action.get("stat", ""))) if node.free_attribute else node.stat)
		if template == null or index >= tiers.size(): return node.cost
		var choice := template.with_tier(tiers[index]).with_stat_context(stats)
		stats.apply_upgrade(choice.stat, choice.amount)
		return node.cost
	for key in node.stat_changes: stats.apply_upgrade(StringName(key), float(node.stat_changes[key]))
	return node.cost

func commit(stats: PlayerStats, upgrades: Array[UpgradeData], count: int) -> bool:
	if not enabled or count <= 0 or tiers.size() != count or used(stats.class_data.talent_tree) != count: return false
	# Validate the whole saved draft before mutating health, stats or ranks.
	var simulation := TalentProgression.new()
	simulation.enabled = true
	simulation.ranks = ranks.duplicate()
	simulation.tiers = tiers.duplicate()
	for action in actions:
		var accepted := simulation.plan_talent(StringName(action.id), stats, upgrades, count, StringName(str(action.get("stat", "")))) if action.kind == "talent" else simulation.plan_stat(StringName(action.id), stats, upgrades, count)
		if not accepted: return false
	var index := 0
	for action in actions: index += _apply(action, stats, upgrades, index)
	ranks = draft_ranks()
	spent += count
	actions.clear()
	tiers.clear()
	return true

func powers(tree: TalentTreeData) -> Dictionary:
	var result := {}
	if not enabled or tree == null: return result
	for node in tree.nodes:
		var rank := int(ranks.get(str(node.id), 0))
		for key in node.effects: result[key] = float(result.get(key, 0)) + float(node.effects[key]) * rank
	return result

func save_data() -> Dictionary:
	return {"version": VERSION, "enabled": enabled, "spent": spent, "ranks": ranks.duplicate(), "tiers": tiers.duplicate(), "actions": actions.duplicate(true), "cursor": cursor.duplicate()}

static func valid(saved: Dictionary, profile: PlayerClassData) -> bool:
	if saved.is_empty(): return true
	if saved.get("version") != VERSION or not saved.get("enabled") is bool: return false
	if not saved.get("spent") is float and not saved.get("spent") is int: return false
	if float(saved.spent) < 0 or int(saved.spent) != float(saved.spent): return false
	if not saved.get("ranks") is Dictionary or not saved.get("tiers") is Array or not saved.get("actions") is Array: return false
	if not saved.get("cursor", {}) is Dictionary: return false
	var cursor_value: Dictionary = saved.get("cursor", {})
	if cursor_value.has("tab") and cursor_value.tab not in ["talent", "stat"]: return false
	if cursor_value.has("id") and not cursor_value.id is String: return false
	if not saved.enabled and (not saved.ranks.is_empty() or not saved.tiers.is_empty() or not saved.actions.is_empty() or saved.spent != 0): return false
	var tree := profile.talent_tree
	if tree == null: return not saved.enabled
	var points := 0
	var groups := {}
	for key in saved.ranks:
		var node := tree.by_id(StringName(str(key)))
		var value: Variant = saved.ranks[key]
		if node == null or not (value is int or value is float) or float(value) != int(value) or int(value) < 1 or int(value) > node.max_ranks: return false
		if node.exclusive_group != &"":
			if groups.has(str(node.exclusive_group)): return false
			groups[str(node.exclusive_group)] = true
		points += node.cost * int(value)
	for key in saved.ranks:
		var node := tree.by_id(StringName(str(key)))
		if node.parent != &"" and int(saved.ranks.get(str(node.parent), 0)) < node.parent_rank: return false
	if points > int(saved.spent): return false
	for tier in saved.tiers:
		if not (tier is int or tier is float) or float(tier) != int(tier) or int(tier) not in [1, 2, 3, 4]: return false
	var current: Dictionary = saved.ranks.duplicate()
	var used_points := 0
	var checker := TalentProgression.new()
	for action in saved.actions:
		if not action is Dictionary or action.get("kind") not in ["stat", "talent"] or not action.get("id") is String: return false
		if action.kind == "talent" and tree.by_id(StringName(action.id)) == null: return false
		if action.kind == "stat" and StringName(action.id) not in PlayerStatKeys.ALL: return false
		if action.kind == "talent":
			var node := tree.by_id(StringName(action.id))
			if not checker._reason(node, tree, current).is_empty(): return false
			if node.free_attribute:
				var chosen := StringName(str(action.get("stat", "")))
				if chosen not in PlayerStatKeys.ALL or not class_allows(chosen, profile): return false
			current[action.id] = int(current.get(action.id, 0)) + 1
			used_points += node.cost
		else:
			if StringName(action.id) == &"ranged_damage" and profile.allowed_weapon_roles == [&"contact"]: return false
			used_points += 1
	if used_points > saved.tiers.size(): return false
	return true

## Removed talents (e.g. the retired Antritt/Fokus nodes) are refunded as
## pending level points instead of rejecting the whole run. The open draft is
## dropped because it may reference removed nodes; its offers are rolled again.
static func migrate(root: Dictionary) -> void:
	var saved: Variant = root.get("talents")
	var player: Variant = root.get("player")
	if not saved is Dictionary or not player is Dictionary or not saved.get("enabled") is bool or not saved.enabled: return
	if not saved.get("ranks") is Dictionary or not (saved.get("spent") is int or saved.get("spent") is float): return
	var state: Variant = player.get("class_state", {})
	var profile := ClassCatalog.by_id(StringName(str(state.get("id", "good_old_molar")))) if state is Dictionary else null
	if profile == null or profile.talent_tree == null: return
	var tree := profile.talent_tree
	var refund := 0
	var kept := {}
	for key in saved.ranks:
		var value: Variant = saved.ranks[key]
		if not (value is int or value is float): return
		if tree.by_id(StringName(str(key))) == null: refund += int(value)
		else: kept[key] = value
	if refund <= 0: return
	var rewards: Variant = root.get("rewards", {})
	if not rewards is Dictionary: return
	var pending: Variant = rewards.get("pending_levels", 0)
	if not (pending is int or pending is float): return
	saved.ranks = kept
	saved.spent = maxi(int(saved.spent) - refund, 0)
	saved.actions = []
	saved.tiers = []
	rewards.pending_levels = int(pending) + refund
	root.rewards = rewards

func restore(saved: Dictionary) -> void:
	enabled = bool(saved.get("enabled", false))
	spent = int(saved.get("spent", 0))
	ranks = saved.get("ranks", {}).duplicate()
	tiers.assign(saved.get("tiers", []))
	actions.assign(saved.get("actions", []))
	cursor = saved.get("cursor", {}).duplicate()
