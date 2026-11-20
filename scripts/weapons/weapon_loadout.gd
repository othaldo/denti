class_name WeaponLoadout
extends Node2D

const MAX_TIER := 4

var stats: PlayerStats
var capacity: int:
	get: return stats.root_capacity if is_instance_valid(stats) else PlayerStats.DEFAULT_ROOT_CAPACITY


func evolution_ready(index: int, recipe: WeaponEvolutionRecipe, items: ItemInventory) -> bool:
	var weapons := equipped()
	if recipe == null or index < 0 or index >= weapons.size():
		return false
	if not weapon_allowed(recipe.result): return false
	var selected := weapons[index]
	if selected.tier != MAX_TIER or selected.data.id not in [recipe.base_weapon, recipe.partner_weapon]:
		return false
	var other_id := recipe.partner_weapon if selected.data.id == recipe.base_weapon else recipe.base_weapon
	var partner := _find_tier(other_id, MAX_TIER, selected) if other_id != &"" else null
	if other_id != &"" and partner == null:
		return false
	for family in recipe.families:
		if items.family_count(family) < 1:
			return false
	for id in recipe.items:
		if items.count(id) < 1:
			return false
	return used_slots() - selected.data.hands - (partner.data.hands if partner != null else 0) + recipe.result.hands <= capacity


func ready_evolutions(index: int, items: ItemInventory) -> Array[WeaponEvolutionRecipe]:
	var result: Array[WeaponEvolutionRecipe] = []
	for recipe in WeaponEvolutions.ALL:
		if evolution_ready(index, recipe, items):
			result.append(recipe)
	return result


func evolve(index: int, recipe: WeaponEvolutionRecipe, items: ItemInventory) -> bool:
	if not evolution_ready(index, recipe, items):
		return false
	# Direct callers may inherit compatible effects; conflicts require a draft.
	var plan := fusion_plan(index, recipe, items)
	if plan.refund() > 0 or not plan.valid(): return false
	return commit_fusion(plan, items, WeaponUpgradeState.new())


func fusion_partner(index: int) -> WeaponInstance:
	var weapons := equipped()
	if index < 0 or index >= weapons.size() or weapons[index].tier >= MAX_TIER: return null
	var primary := weapons[index]
	var compatible := _merge_partner(primary)
	return compatible if compatible != null else _find_tier(primary.data.id, primary.tier, primary)


func fusion_plan(index: int, recipe: WeaponEvolutionRecipe = null, items: ItemInventory = null) -> WeaponFusionPlan:
	var weapons := equipped()
	if index < 0 or index >= weapons.size(): return null
	var primary := weapons[index]
	var partner: WeaponInstance
	var result: WeaponData
	var result_tier := MAX_TIER
	if recipe != null:
		if items == null or not evolution_ready(index, recipe, items): return null
		var other_id := recipe.partner_weapon if primary.data.id == recipe.base_weapon else recipe.base_weapon
		partner = _find_tier(other_id, MAX_TIER, primary) if other_id != &"" else null
		result = WeaponAscension.inherit(recipe.result, primary.data, partner.data if partner != null else null)
	else:
		partner = fusion_partner(index)
		if partner == null: return null
		result = WeaponRolls.fuse(primary.data, partner.data)
		result_tier = primary.tier + 1
	var plan := WeaponFusionPlan.new()
	plan.configure(primary, partner, result, result_tier, recipe.id if recipe != null else &"")
	return plan


func commit_fusion(plan: WeaponFusionPlan, items: ItemInventory, points: WeaponUpgradeState) -> bool:
	if plan == null or not plan.valid() or points == null or not points.actions.is_empty(): return false
	if not weapon_allowed(plan.result_data): return false
	var weapons := equipped()
	var selected: WeaponInstance
	var partner: WeaponInstance
	for weapon in weapons:
		if weapon.instance_uid == plan.primary_uid: selected = weapon
		if weapon.instance_uid == plan.partner_uid: partner = weapon
	if selected == null or (not plan.partner_uid.is_empty() and partner == null): return false
	if WeaponFusionPlan.snapshot(selected) != plan.ingredients[0]: return false
	if partner != null and WeaponFusionPlan.snapshot(partner) != plan.ingredients[1]: return false
	var index := weapons.find(selected)
	var recipe := WeaponEvolutions.by_id(plan.recipe_id) if plan.recipe_id != &"" else null
	if plan.recipe_id != &"":
		if recipe == null or items == null or not evolution_ready(index, recipe, items): return false
	elif partner == null or selected.tier >= MAX_TIER or partner.tier != selected.tier or partner.data.id != selected.data.id:
		return false
	# Rebuild from live sources so a stale or altered preview cannot mint points.
	var fresh := WeaponFusionPlan.new()
	var fresh_data := WeaponRolls.fuse(selected.data, partner.data) if recipe == null else fusion_plan(index, recipe, items).result_data
	fresh.configure(selected, partner, fresh_data, selected.tier + 1 if recipe == null else MAX_TIER, plan.recipe_id)
	fresh.selected.assign(plan.selected)
	if not fresh.valid() or not weapon_allowed(fresh.result_data): return false
	var inherited := fresh.effects()
	var refund := fresh.refund()
	var invested := selected.invested_coins + (partner.invested_coins if partner != null else 0)
	var uid := selected.instance_uid
	if recipe == null:
		selected.data = fresh.result_data
		selected.affixes.assign(inherited)
		selected.tier = fresh.tier
		selected.affix_slots = WeaponUpgrades.slots(fresh.tier)
		selected.invested_coins = invested
		partner.free()
		selected.refresh_affix_stats()
	else:
		if partner != null: partner.free()
		selected.free()
		var evolved := _add(fresh.result_data, MAX_TIER, invested)
		evolved.affixes.assign(inherited)
		evolved.affix_slots = WeaponUpgrades.slots(MAX_TIER)
		evolved.instance_uid = uid
		evolved.refresh_affix_stats()
	points.points += refund
	_refresh_positions()
	return true


func evolution_hit(enemy: Enemy, amount: float, data: WeaponData, critical: bool) -> void:
	if data.evolution_kind == &"":
		return
	# Preserve first-equipped dispatch without allocating two arrays per hit.
	for index in get_child_count():
		var weapon := get_child(index) as WeaponInstance
		if weapon != null and weapon.data.id == data.id and weapon.evolution != null:
			weapon.evolution.on_hit(enemy, amount, critical)
			return


func equipped() -> Array[WeaponInstance]:
	var result: Array[WeaponInstance] = []
	for child in get_children():
		if child is WeaponInstance:
			result.append(child)
	return result


func used_slots() -> int:
	var total := 0
	for weapon in equipped():
		total += weapon.data.hands
	return total


func can_acquire(data: WeaponData, tier: int = 1) -> bool:
	if not weapon_allowed(data) or data.evolution_kind != &"":
		return false
	return used_slots() + data.hands <= capacity or (tier < MAX_TIER and _find_tier(data.id, tier) != null)


func weapon_allowed(data: WeaponData) -> bool:
	return WeaponEligibility.allowed(data, stats.class_data if is_instance_valid(stats) else null)


func acquire(data: WeaponData, tier: int = 1, paid_coins: int = -1) -> bool:
	if not can_acquire(data, tier):
		return false
	var value := paid_coins if paid_coins >= 0 else _legacy_value(data, tier)
	if used_slots() + data.hands <= capacity:
		_add(data, tier, value)
	else:
		var matching := purchase_fusion_target(data, tier)
		matching.data = WeaponRolls.fuse(matching.data, data)
		matching.tier += 1
		matching.refresh_affix_stats()
		matching.invested_coins += value
	_refresh_positions()
	return true


func purchase_fusion_target(data: WeaponData, tier: int = 1) -> WeaponInstance:
	if not weapon_allowed(data) or tier >= MAX_TIER or used_slots() + data.hands <= capacity:
		return null
	return _best_fusion_partner(data, tier)


func merge_partner(index: int) -> WeaponInstance:
	var weapons := equipped()
	if index < 0 or index >= weapons.size() or weapons[index].tier >= MAX_TIER:
		return null
	return _merge_partner(weapons[index])


func fusion_data(primary: WeaponInstance, data: WeaponData, partner: WeaponInstance = null) -> WeaponData:
	var affixes := _combined_affixes(primary, partner) if partner != null else primary.affixes
	return WeaponRolls.with_affixes(WeaponRolls.fuse(primary.data, data), affixes)


func can_merge(index: int) -> bool:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return false
	var weapon := weapons[index]
	return weapon_allowed(weapon.data) and weapon.tier < MAX_TIER and _merge_partner(weapon) != null


func merge_affix_conflict(index: int) -> bool:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return false
	var weapon := weapons[index]
	return weapon.tier < MAX_TIER and _find_tier(weapon.data.id, weapon.tier, weapon) != null and _merge_partner(weapon) == null


func merge_conflict_reason(index: int) -> String:
	if not merge_affix_conflict(index): return ""
	var weapon := equipped()[index]
	var partner := _find_tier(weapon.data.id, weapon.tier, weapon)
	var reason := WeaponUpgrades.fusion_block_reason(weapon.affixes, partner.affixes)
	return reason if not reason.is_empty() else "Nicht genug Verzauberungsplätze"


func merge(index: int) -> bool:
	if not can_merge(index):
		return false
	var weapon := equipped()[index]
	var partner := _merge_partner(weapon)
	weapon.data = WeaponRolls.fuse(weapon.data, partner.data)
	weapon.affixes = _combined_affixes(weapon, partner)
	weapon.tier += 1
	weapon.affix_slots = maxi(WeaponUpgrades.slots(weapon.tier), maxi(weapon.affix_slots, partner.affix_slots))
	weapon.refresh_affix_stats()
	weapon.invested_coins += partner.invested_coins
	partner.free()
	_refresh_positions()
	return true


func restore(saved: Array, enforce_capacity: bool = true) -> bool:
	# Reject the whole operation before deleting any owned equipment.
	for entry in saved:
		if entry is Dictionary:
			var data := WeaponCatalog.by_id(StringName(str(entry.get("id", ""))))
			if data != null and not weapon_allowed(data): return false
	for weapon in equipped():
		weapon.free()
	for entry in saved:
		if not entry is Dictionary:
			continue
		var data := WeaponCatalog.by_id(StringName(str(entry.get("id", ""))))
		if weapon_allowed(data) and (not enforce_capacity or used_slots() + data.hands <= capacity):
			var tier := clampi(int(entry.get("tier", 1)), 1, MAX_TIER)
			var weapon := _add(WeaponRolls.resolve(data, entry.get("rolls", {}), entry.get("upgrades", {})), tier, maxi(int(entry.get("invested_coins", _legacy_value(data, tier))), 0))
			weapon.affixes = WeaponAffixes.sanitize(entry.get("affixes", []))
			weapon.affix_slots = clampi(maxi(int(entry.get("affix_slots", 1)), weapon.affixes.size()), 1, WeaponAffixes.MAX_SLOTS)
			weapon.instance_uid = str(entry.get("uid", weapon.instance_uid))
			weapon.refresh_affix_stats()
	_refresh_positions()
	return true


func save_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for weapon in equipped():
		result.append({"id": str(weapon.data.id), "tier": weapon.tier, "invested_coins": weapon.invested_coins, "uid": weapon.instance_uid, "rolls": weapon.data.rolls.duplicate(true), "upgrades": weapon.data.chest_upgrades.duplicate(true), "affix_slots": weapon.affix_slots, "affixes": weapon.affixes.duplicate(true)})
	return result


func sell(index: int) -> int:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return 0
	var weapon := weapons[index]
	var refund := refund_for(index)
	weapon.free()
	_refresh_positions()
	return refund


func refund_for(index: int) -> int:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return 0
	var weapon := weapons[index]
	return roundi(float(weapon.invested_coins) * 0.5)


func _add(data: WeaponData, tier: int, value: int) -> WeaponInstance:
	var weapon := WeaponInstance.new()
	CombatDiagnostics.instrument(weapon, "weapon", self)
	weapon.configure(data, tier)
	weapon.invested_coins = value
	add_child(weapon)
	return weapon


func _affixes_fit(primary: WeaponInstance, partner: WeaponInstance) -> bool:
	var kinds: Array[String] = []
	for affix in primary.affixes + partner.affixes:
		if not kinds.has(str(affix.id)):
			kinds.append(str(affix.id))
	var capacity_after := maxi(WeaponUpgrades.slots(primary.tier + 1), maxi(primary.affix_slots, partner.affix_slots))
	return kinds.size() <= capacity_after and WeaponUpgrades.fusion_fits(primary.affixes, partner.affixes)


func _combined_affixes(primary: WeaponInstance, partner: WeaponInstance) -> Array[Dictionary]:
	return WeaponAffixes.sanitize(primary.affixes + partner.affixes)


func _merge_partner(weapon: WeaponInstance) -> WeaponInstance:
	return _best_fusion_partner(weapon.data, weapon.tier, weapon)


func _best_fusion_partner(data: WeaponData, tier: int, primary: WeaponInstance = null) -> WeaponInstance:
	var best: WeaponInstance
	var best_data: WeaponData
	for partner in equipped():
		if partner == primary or partner.data.id != data.id or partner.tier != tier:
			continue
		if primary != null and not _affixes_fit(primary, partner):
			continue
		var result := fusion_data(primary, partner.data, partner) if primary != null else fusion_data(partner, data)
		if best == null or _better_fusion(result, best_data, tier + 1):
			best = partner
			best_data = result
	return best


func _better_fusion(candidate: WeaponData, current: WeaponData, tier: int) -> bool:
	var candidate_dps := _fusion_dps(candidate, tier)
	var current_dps := _fusion_dps(current, tier)
	if not is_equal_approx(candidate_dps, current_dps):
		return candidate_dps > current_dps
	return candidate.range_at_tier(tier) > current.range_at_tier(tier)


func _fusion_dps(data: WeaponData, tier: int) -> float:
	var player := get_parent() as Player
	if player != null:
		return data.estimated_dps(tier, player.stats, player.items.attack_interval_factor(), player.items.base_weapon_damage_bonus())
	return data.damage_at_tier(tier) * (1.0 + data.crit_bonus * (data.crit_multiplier - 1.0)) / maxf(data.interval_at_tier(tier), WeaponData.MIN_ATTACK_COOLDOWN)


func _find_tier(id: StringName, tier: int, except: WeaponInstance = null) -> WeaponInstance:
	for weapon in equipped():
		if weapon != except and weapon.data.id == id and weapon.tier == tier:
			return weapon
	return null


func _legacy_value(data: WeaponData, tier: int) -> int:
	return data.price * (1 << (tier - 1))


func _refresh_positions() -> void:
	var weapons := equipped()
	# Prepare after every equipment change, including an in-place tier fusion.
	prepare_projectile_visuals()
	for index in weapons.size():
		weapons[index].position = Vector2.ZERO
		weapons[index].home_position = WeaponLayout.home(index, weapons.size())
		weapons[index].visual_density = WeaponLayout.density_scale(weapons.size())
		weapons[index].attack_phase = WeaponLayout.phase(index, weapons.size())
		if not WeaponMotion.is_contact(weapons[index].data):
			if weapons[index].focus_target_id == 0 and weapons[index].attack_time <= 0.0:
				weapons[index].aim = Vector2.RIGHT if weapons[index].home_position.x > 0.0 else Vector2.LEFT
			weapons[index].hold_position = WeaponMotion.hand_position(weapons[index].home_position, weapons[index].aim)
		else:
			weapons[index].hold_position = weapons[index].home_position
		weapons[index].update_visual()

func prepare_projectile_visuals() -> void:
	if get_parent() == null or get_parent().get_parent() == null:
		return
	var pool := get_parent().get_parent().get_node_or_null("Projectiles") as PlayerProjectilePool
	if pool == null:
		return
	var weapons := equipped()
	if DisplayServer.get_name() == "headless":
		pool.prepare_skins(weapons)
	else:
		pool.prepare_loadout(weapons)
