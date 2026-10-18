class_name BuildPresentation
extends RefCounted


static func item_entries(inventory: ItemInventory) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for template in ItemCatalog.ALL:
		var copies := inventory.count(template.id)
		if template.weapon_data == null and copies > 0:
			var description := template.effect_text() + "\n" + template.limit_text()
			if template.effect_kind == &"armor_damage":
				description += "\n\n" + armor_explanation(inventory)
			result.append({"name": template.display_name, "count": copies, "description": description, "tier": template.rarity_tier, "icon": template.icon_texture if template.icon_texture != null else DentiUIIcons.item(template.icon_index)})
	return result


static func armor_explanation(inventory: ItemInventory) -> String:
	return "Aktuell: +%s %% Waffenschaden\n%s Härte × %s %% je Härte\nMaximal +60 %%. Negative Härte gibt keinen Bonus.\nAddiert sich zu Bisskraft; ist bereits in den Waffenwerten enthalten." % [
		("%.1f" % inventory.armor_damage_bonus()).trim_suffix(".0"), ("%.1f" % inventory.player.stats.armor).trim_suffix(".0"),
		("%.1f" % (inventory.power(&"armor_damage") * 100.0)).trim_suffix(".0")]


static func collected_entries(items: ItemInventory, relics: RelicInventory, prefix_relics: bool = false) -> Array[Dictionary]:
	var result := item_entries(items)
	for id in relics.owned:
		var relic := RelicCatalog.by_id(StringName(id))
		if relic != null:
			result.append({"name": ("Relikt: " if prefix_relics else "") + relic.display_name, "count": 1, "description": DentiAttributes.resolve_text(relic.description), "tier": 4, "icon": DentiUIIcons.relic(relic.icon_index), "relic": true})
	return result


static func shop_view(player: Player, shop: ShopController, items: ItemInventory, relics: RelicInventory, wave_number: int, coins: int) -> ShopViewData:
	var model := ShopViewData.new()
	var equipment: Array[Dictionary] = []
	var weapons := player.loadout.equipped()
	for index in weapons.size():
		var weapon := weapons[index]
		equipment.append({"data": weapon.data, "hands": weapon.data.hands, "icon": weapon.data.sprite, "uid": weapon.get_instance_id(), "name": WeaponPresentation.weapon_name(weapon), "tier": weapon.tier, "refund": player.loadout.refund_for(index), "stats": weapon.data.stats_text(weapon.tier), "combat": weapon.data.combat_text() + "\n" + AffixPresentation.summary(weapon, player.stats, items), "description": weapon.data.description, "dps": _dps(weapon.data, weapon.tier, player), "mergeable": player.loadout.can_merge(index)})
	var buyable: Array[bool] = []
	var offer_dps: Array[float] = []
	for offer in shop.offers:
		buyable.append(offer == null or (player.loadout.can_acquire(offer.weapon_data, offer.weapon_tier) if offer.weapon_data != null else items.can_acquire(offer)))
		offer_dps.append(_dps(offer.weapon_data, offer.weapon_tier, player) if offer != null and offer.weapon_data != null else 0.0)
	var owned_display := collected_entries(items, relics, true)
	model.wave_number = wave_number
	model.coins = coins
	model.reroll_cost = shop.reroll_cost
	model.offers = shop.offers
	model.equipment = equipment
	model.used_slots = player.loadout.used_slots()
	model.capacity = WeaponLoadout.CAPACITY
	model.buyable = buyable
	model.luck = player.stats.luck
	model.collected = owned_display
	model.counts = items.owned
	model.offer_dps = offer_dps
	model.reserved = shop.reserved
	return model


static func _dps(data: WeaponData, tier: int, player: Player) -> float:
	return data.estimated_dps(tier, player.stats, player.items.attack_interval_factor(), player.items.base_weapon_damage_bonus())
