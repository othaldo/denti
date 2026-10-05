class_name WeaponLoadout
extends Node2D

const CAPACITY := 6
const MAX_TIER := 4


func evolution_ready(index: int, recipe: WeaponEvolutionRecipe, items: ItemInventory) -> bool:
	var weapons := equipped()
	if recipe == null or index < 0 or index >= weapons.size():
		return false
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
	return used_slots() - selected.data.hands - (partner.data.hands if partner != null else 0) + recipe.result.hands <= CAPACITY


func ready_evolutions(index: int, items: ItemInventory) -> Array[WeaponEvolutionRecipe]:
	var result: Array[WeaponEvolutionRecipe] = []
	for recipe in WeaponEvolutions.ALL:
		if evolution_ready(index, recipe, items):
			result.append(recipe)
	return result


func evolve(index: int, recipe: WeaponEvolutionRecipe, items: ItemInventory) -> bool:
	if not evolution_ready(index, recipe, items):
		return false
	var selected := equipped()[index]
	var other_id := recipe.partner_weapon if selected.data.id == recipe.base_weapon else recipe.base_weapon
	var partner := _find_tier(other_id, MAX_TIER, selected) if other_id != &"" else null
	var invested := selected.invested_coins + (partner.invested_coins if partner != null else 0)
	if partner != null:
		partner.free()
	selected.free()
	_add(recipe.result, MAX_TIER, invested)
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
	if data.evolution_kind != &"":
		return false
	return used_slots() + data.hands <= CAPACITY or (tier < MAX_TIER and _find_tier(data.id, tier) != null)


func acquire(data: WeaponData, tier: int = 1, paid_coins: int = -1) -> bool:
	if not can_acquire(data, tier):
		return false
	var value := paid_coins if paid_coins >= 0 else _legacy_value(data, tier)
	if used_slots() + data.hands <= CAPACITY:
		_add(data, tier, value)
	else:
		var matching := _find_tier(data.id, tier)
		matching.tier += 1
		matching.invested_coins += value
	_refresh_positions()
	return true


func can_merge(index: int) -> bool:
	var weapons := equipped()
	if index < 0 or index >= weapons.size():
		return false
	var weapon := weapons[index]
	return weapon.tier < MAX_TIER and _find_tier(weapon.data.id, weapon.tier, weapon) != null


func merge(index: int) -> bool:
	if not can_merge(index):
		return false
	var weapon := equipped()[index]
	var partner := _find_tier(weapon.data.id, weapon.tier, weapon)
	weapon.tier += 1
	weapon.invested_coins += partner.invested_coins
	partner.free()
	_refresh_positions()
	return true


func restore(saved: Array) -> void:
	for weapon in equipped():
		weapon.free()
	for entry in saved:
		if not entry is Dictionary:
			continue
		var data := WeaponCatalog.by_id(StringName(str(entry.get("id", ""))))
		if data != null and used_slots() + data.hands <= CAPACITY:
			var tier := clampi(int(entry.get("tier", 1)), 1, MAX_TIER)
			_add(data, tier, maxi(int(entry.get("invested_coins", _legacy_value(data, tier))), 0))
	_refresh_positions()


func save_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for weapon in equipped():
		result.append({"id": str(weapon.data.id), "tier": weapon.tier, "invested_coins": weapon.invested_coins})
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


func _add(data: WeaponData, tier: int, value: int) -> void:
	var weapon := WeaponInstance.new()
	CombatDiagnostics.instrument(weapon, "weapon", self)
	weapon.configure(data, tier)
	weapon.invested_coins = value
	add_child(weapon)


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
	var pool: PlayerProjectilePool
	if DisplayServer.get_name() != "headless":
		pool = get_parent().get_parent().get_node_or_null("Projectiles") as PlayerProjectilePool
	if pool != null:
		pool.prepare_loadout(weapons)
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
