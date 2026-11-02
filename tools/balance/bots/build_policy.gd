extends RefCounted
## Explicit heuristics, not an optimal-build claim. Same earned budget/offer rules.

static func level_choice(game) -> UpgradeData:
	var selected: UpgradeData = game.choice_panel.current_upgrades[0]
	var best := -INF
	for upgrade: UpgradeData in game.choice_panel.current_upgrades:
		var score := stat_weight(upgrade.stat, game) * upgrade.amount
		if score > best:
			best = score
			selected = upgrade
	return selected

static func stat_weight(key: StringName, game) -> float:
	var weapon: WeaponData = game.player.loadout.equipped()[0].data
	var fragile: bool = game.player.stats.health < game.player.stats.max_health * 0.55
	match key:
		&"melee_damage": return 2.5 * weapon.stat_scaling if weapon.damage_stat == "melee" else 0.0
		&"ranged_damage": return 2.5 * weapon.stat_scaling if weapon.damage_stat == "ranged" else 0.0
		&"attack_speed": return 0.8
		&"damage_bonus": return 0.65
		&"max_health": return 1.3 if fragile else 0.5
		&"armor": return 4.0 if fragile else 2.0
		&"regen": return 4.0 if fragile else 1.5
		&"crit_chance": return 45.0 if weapon.crit_cycle > 0 or game.items.power(&"crit_burst") > 0 else 12.0
		&"speed_bonus": return 0.7
		&"luck": return 0.25
	return 0.1

static func item_score(offer: ShopOfferData, game) -> float:
	var score := 0.0
	for key: StringName in offer.stat_changes:
		score += stat_weight(key, game) * float(offer.stat_changes[key])
	var tags: Array[StringName] = game.items.preferred_tags(game.player.loadout)
	for tag in offer.tags:
		if tag in tags: score += 3.0
	var weapon: WeaponData = game.player.loadout.equipped()[0].data
	if offer.effect_kind == &"crit_burst" and (weapon.crit_cycle > 0 or weapon.crit_bonus > 0): score += 10
	if offer.effect_kind == &"conductive_wet" and weapon.wet_duration > 0: score += 12
	if offer.effect_kind != &"": score += 1
	return score / maxf(offer.price, 1)

static func affix_order(weapon: WeaponData) -> Array[StringName]:
	if weapon.crit_cycle > 0 or weapon.crit_bonus >= 0.1: return [&"ice", &"crit_damage", &"crit"]
	if weapon.wet_duration > 0: return [&"electric", &"tempo", &"wet"]
	if weapon.bleed_dps > 0: return [&"bleed", &"tempo", &"leech"]
	return [&"fire", &"tempo", &"leech"]

static func next_upgrade(game, state: WeaponUpgradeState) -> Dictionary:
	var selected: WeaponInstance
	var selected_kind: StringName
	var best := INF
	for weapon: WeaponInstance in game.player.loadout.equipped():
		if state.remaining() < WeaponUpgrades.cost(weapon.data): continue
		var values := state.preview(weapon)
		var order := affix_order(weapon.data)
		for index in order.size():
			var kind := order[index]
			var found := WeaponAffixes.find(values, kind)
			var rank := WeaponUpgrades.level(values[found]) if found >= 0 else 0
			if rank >= 10 or WeaponUpgrades.advance(values, kind, weapon.data, weapon.tier).is_empty(): continue
			# Establish the primary effect first, then diversify when slots permit.
			var priority := rank + index * 3
			if priority < best:
				best = priority
				selected = weapon
				selected_kind = kind
	return {} if selected == null else {"weapon": selected, "id": selected_kind}

static func shop_item_index(game) -> int:
	var best := 0.0
	var selected := -1
	for index in game.shop.offers.size():
		var offer: ShopOfferData = game.shop.offers[index]
		if offer == null or offer.weapon_data != null or offer.price > game.coins or not game.items.can_acquire(offer): continue
		var score := item_score(offer, game)
		if score > best:
			best = score
			selected = index
	return selected
